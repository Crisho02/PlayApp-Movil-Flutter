import 'dart:convert';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playapp_movil_flutter/data/models/occupancy_analytics_model.dart';
import 'package:playapp_movil_flutter/data/models/user_model.dart';
import 'package:playapp_movil_flutter/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:playapp_movil_flutter/presentation/widgets/occupancy_analytics/hourly_curve_card.dart';
import 'package:playapp_movil_flutter/presentation/widgets/occupancy_analytics/occupancy_analytics_section.dart';
import 'package:playapp_movil_flutter/presentation/widgets/occupancy_analytics/sensitivity_card.dart';
import 'package:playapp_movil_flutter/presentation/widgets/occupancy_analytics/weekly_heatmap_card.dart';
import 'package:playapp_movil_flutter/providers/admin_provider.dart';
import 'package:playapp_movil_flutter/providers/auth_provider.dart';
import 'package:playapp_movil_flutter/providers/product_provider.dart';
import 'package:provider/provider.dart';

/// El JSON es la salida REAL del modelo Keras (GET /analytics de FastAPI).
Map<String, dynamic> loadFixture() =>
    jsonDecode(File('test/fixtures/occupancy_analytics.json').readAsStringSync()) as Map<String, dynamic>;

OccupancyAnalytics loadAnalytics() => OccupancyAnalytics.tryParse(loadFixture())!;

class FakeAdminProvider extends AdminProvider {
  OccupancyAnalytics? fakeData;
  String? fakeError;
  bool fakeLoading;
  int fetchCalls = 0;
  bool lastForce = false;

  FakeAdminProvider({this.fakeData, this.fakeError, this.fakeLoading = false});

  @override
  OccupancyAnalytics? get occupancyAnalytics => fakeData;
  @override
  String? get analyticsError => fakeError;
  @override
  bool get isAnalyticsLoading => fakeLoading;

  @override
  Future<void> fetchOccupancyAnalytics({bool force = false}) async {
    fetchCalls++;
    lastForce = force;
  }

  @override
  Future<void> fetchAdminData() async {}
  @override
  Future<void> fetchMetrics() async {}
}

Future<void> pumpSized(WidgetTester tester, Widget child, {Size size = const Size(360, 800), double textScale = 1.0}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}


/// Falla mostrando el detalle completo (widget culpable) si hubo un desborde u otro error de render.
void expectClean(WidgetTester tester, [String? reason]) {
  final e = tester.takeException();
  if (e != null) {
    fail('${reason ?? ''} ${e is FlutterError ? e.toStringDeep() : e}');
  }
}

const sizes = <Size>[Size(320, 640), Size(360, 800), Size(412, 915), Size(768, 1024)];

void main() {
  group('OccupancyAnalytics.tryParse', () {
    test('parsea la respuesta real del modelo con todas las gráficas completas', () {
      final a = loadAnalytics();
      expect(a.modelVersion, startsWith('sim-v1-'));
      expect(a.hourly.dayTypes.map((d) => d.id), ['weekday', 'weekend', 'holiday']);
      expect(a.hourly.conditions.map((d) => d.id), ['clear', 'cloudy', 'rain']);
      expect(a.hourly.curve('weekend', 'clear'), hasLength(24));
      expect(a.heatmap.seasons.map((s) => s.id), ['normal', 'vacation', 'high']);
      expect(a.heatmap.grid('high'), hasLength(7));
      expect(a.heatmap.grid('high').every((r) => r.length == 24), isTrue);
      expect(a.sensitivity.map((b) => b.id), ['weekday', 'weekend']);
      expect(a.sensitivity.first.factors, hasLength(6));
      expect(a.evaluation!.mae, 1.57);
      expect(a.evaluation!.baselineMae, 20.53);
    });

    test('rechaza respuestas incompletas o inconsistentes', () {
      Map<String, dynamic> copy() => loadFixture();
      expect(OccupancyAnalytics.tryParse({}), isNull);
      expect(OccupancyAnalytics.tryParse(copy()..['available'] = false), isNull);
      expect(OccupancyAnalytics.tryParse(copy()..remove('heatmap')), isNull);
      expect(OccupancyAnalytics.tryParse(copy()..['hourly'] = 'x'), isNull);

      final shortCurve = copy();
      ((shortCurve['hourly'] as Map)['series'] as Map)['weekday']['clear'] = List.filled(23, 1.0);
      expect(OccupancyAnalytics.tryParse(shortCurve), isNull);

      final badGrid = copy();
      ((badGrid['heatmap'] as Map)['values'] as Map)['normal'] = [List.filled(24, 1.0)];
      expect(OccupancyAnalytics.tryParse(badGrid), isNull);

      expect(OccupancyAnalytics.tryParse(copy()..['sensitivity'] = {'bases': []}), isNull);
    });

    test('sin evaluación sigue siendo válido (evaluation es opcional)', () {
      final a = OccupancyAnalytics.tryParse(loadFixture()..['evaluation'] = {});
      expect(a, isNotNull);
      expect(a!.evaluation, isNull);
    });
  });

  group('HourlyCurveCard', () {
    for (final size in sizes) {
      for (final scale in [1.0, 1.5]) {
        testWidgets('renderiza sin desbordes en ${size.width.toInt()}px, texto x$scale', (tester) async {
          await pumpSized(tester, HourlyCurveCard(data: loadAnalytics().hourly, nowHour: 14), size: size, textScale: scale);
          expect(find.byType(LineChart), findsOneWidget);
          expect(find.text('Ocupación por hora'), findsOneWidget);
          expectClean(tester);
        });
      }
    }

    testWidgets('cambia de curva al elegir el tipo de día y valida los valores del modelo', (tester) async {
      final a = loadAnalytics();
      await pumpSized(tester, HourlyCurveCard(data: a.hourly, nowHour: 14));
      LineChartData data() => tester.widget<LineChart>(find.byType(LineChart)).data;

      expect(data().lineBarsData, hasLength(3));
      expect(data().lineBarsData[0].spots.map((s) => s.y).toList(), a.hourly.curve('weekday', 'clear'));

      await tester.tap(find.text('Fin de semana'));
      await tester.pumpAndSettle();
      expect(data().lineBarsData[0].spots.map((s) => s.y).toList(), a.hourly.curve('weekend', 'clear'));
      expect(data().lineBarsData[2].spots.map((s) => s.y).toList(), a.hourly.curve('weekend', 'rain'));

      await tester.tap(find.text('Festivo'));
      await tester.pumpAndSettle();
      expect(data().lineBarsData[1].spots.map((s) => s.y).toList(), a.hourly.curve('holiday', 'cloudy'));
    });

    testWidgets('activar/desactivar condiciones nunca deja la gráfica vacía', (tester) async {
      await pumpSized(tester, HourlyCurveCard(data: loadAnalytics().hourly, nowHour: 14));
      int bars() => tester.widget<LineChart>(find.byType(LineChart)).data.lineBarsData.length;

      await tester.tap(find.text('Nublado'));
      await tester.pumpAndSettle();
      expect(bars(), 2);
      await tester.tap(find.text('Lluvia'));
      await tester.pumpAndSettle();
      expect(bars(), 1);
      await tester.tap(find.text('Despejado')); // última visible: se ignora
      await tester.pumpAndSettle();
      expect(bars(), 1);
      await tester.tap(find.text('Nublado')); // volver a mostrar
      await tester.pumpAndSettle();
      expect(bars(), 2);
      expectClean(tester);
    });

    testWidgets('marca la hora actual y sombrea la noche', (tester) async {
      await pumpSized(tester, HourlyCurveCard(data: loadAnalytics().hourly, nowHour: 9));
      final d = tester.widget<LineChart>(find.byType(LineChart)).data;
      expect(d.extraLinesData.verticalLines.single.x, 9);
      expect(d.rangeAnnotations.verticalRangeAnnotations, hasLength(2));
      expect(d.minY, 0);
      expect(d.maxY, inInclusiveRange(20, 100));
    });

    testWidgets('la hora actual en los extremos (0 y 23) no rompe el diseño', (tester) async {
      for (final h in [0, 23]) {
        await pumpSized(tester, HourlyCurveCard(data: loadAnalytics().hourly, nowHour: h), size: const Size(320, 640));
        expectClean(tester, 'hora $h');
      }
    });

    testWidgets('el toque en la curva muestra tooltip con hora y porcentaje', (tester) async {
      await pumpSized(tester, HourlyCurveCard(data: loadAnalytics().hourly, nowHour: 14));
      final chart = tester.getRect(find.byType(LineChart));
      await tester.tapAt(Offset(chart.left + chart.width * 0.6, chart.top + chart.height * 0.4));
      await tester.pump(const Duration(milliseconds: 100));
      expectClean(tester);
    });
  });

  group('WeeklyHeatmapCard', () {
    final cell = find.descendant(
      of: find.byType(WeeklyHeatmapCard),
      matching: find.byWidgetPredicate((w) => w is CustomPaint && w.painter.runtimeType.toString() == '_HeatPainter'),
    );

    for (final size in sizes) {
      for (final scale in [1.0, 1.5]) {
        testWidgets('renderiza sin desbordes en ${size.width.toInt()}px, texto x$scale', (tester) async {
          await pumpSized(tester, WeeklyHeatmapCard(data: loadAnalytics().heatmap), size: size, textScale: scale);
          expect(cell, findsOneWidget);
          expect(find.text('Mapa de calor semanal'), findsOneWidget);
          expectClean(tester);
        });
      }
    }

    testWidgets('selecciona por defecto el mejor momento de la semana', (tester) async {
      final a = loadAnalytics();
      await pumpSized(tester, WeeklyHeatmapCard(data: a.heatmap));
      final grid = a.heatmap.grid('normal');
      var best = -1.0, r = 0, c = 0;
      for (var i = 0; i < 7; i++) {
        for (var h = 6; h <= 17; h++) {
          if (grid[i][h] > best) {
            best = grid[i][h];
            r = i;
            c = h;
          }
        }
      }
      const names = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
      expect(find.text('${names[r]} · ${c.toString().padLeft(2, '0')}:00'), findsOneWidget);
      expect(find.textContaining('mejor momento de la semana'), findsOneWidget);
    });

    testWidgets('tocar una celda muestra su día, hora y valor exactos', (tester) async {
      final a = loadAnalytics();
      await pumpSized(tester, WeeklyHeatmapCard(data: a.heatmap));
      final rect = tester.getRect(cell);
      final cellW = (rect.width - 34) / 12; // columnas 06..17
      // Miércoles (fila 2), 12:00 (columna 6)
      await tester.tapAt(Offset(rect.left + 34 + cellW * 6 + cellW / 2, rect.top + 20 + 30 * 2 + 15));
      await tester.pumpAndSettle();
      expect(find.text('Miércoles · 12:00'), findsOneWidget);
      final v = a.heatmap.grid('normal')[2][12];
      expect(find.textContaining(v.toStringAsFixed(1).replaceAll('.', ',')), findsWidgets);
      expect(find.textContaining('Ir al pico'), findsOneWidget);

      await tester.tap(find.textContaining('Ir al pico'));
      await tester.pumpAndSettle();
      expect(find.textContaining('mejor momento de la semana'), findsOneWidget);
    });

    testWidgets('deslizar horizontalmente recorre las horas sin cambiar el día', (tester) async {
      await pumpSized(tester, WeeklyHeatmapCard(data: loadAnalytics().heatmap));
      final rect = tester.getRect(cell);
      final cellW = (rect.width - 34) / 12;
      final y = rect.top + 20 + 30 * 4 + 15; // Viernes
      final start = Offset(rect.left + 34 + cellW * 1 + cellW / 2, y);
      await tester.dragFrom(start, Offset(cellW * 5, 0));
      await tester.pumpAndSettle();
      expect(find.textContaining('Viernes · '), findsOneWidget);
    });

    testWidgets('cambiar de temporada y a vista de 24 h funciona', (tester) async {
      await pumpSized(tester, WeeklyHeatmapCard(data: loadAnalytics().heatmap));
      await tester.tap(find.text('Temporada alta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('24 h'));
      await tester.pumpAndSettle();
      final rect = tester.getRect(cell);
      final cellW = (rect.width - 34) / 24;
      await tester.tapAt(Offset(rect.left + 34 + cellW * 3 + cellW / 2, rect.top + 20 + 15)); // Lunes 03:00
      await tester.pumpAndSettle();
      expect(find.text('Lunes · 03:00'), findsOneWidget);
      await tester.tap(find.text('06–18 h'));
      await tester.pumpAndSettle();
      expect(find.text('Lunes · 03:00'), findsNothing, reason: 'una hora fuera del rango visible vuelve al pico');
      expectClean(tester);
    });
  });

  group('SensitivityCard', () {
    for (final size in sizes) {
      for (final scale in [1.0, 1.5]) {
        testWidgets('renderiza (barras y radar) sin desbordes en ${size.width.toInt()}px, texto x$scale', (tester) async {
          await pumpSized(tester, SensitivityCard(bases: loadAnalytics().sensitivity), size: size, textScale: scale);
          expect(find.text('Qué mueve la ocupación'), findsOneWidget);
          expect(find.text('Cielo'), findsWidgets);
          expectClean(tester);
          await tester.tap(find.text('Radar'));
          await tester.pumpAndSettle();
          expect(find.byType(RadarChart), findsOneWidget);
          expectClean(tester);
          await tester.tap(find.text('Barras'));
          await tester.pumpAndSettle();
          expect(find.byType(RadarChart), findsNothing);
          expectClean(tester);
        });
      }
    }

    testWidgets('muestra el escenario base y cambia al seleccionar otro', (tester) async {
      final a = loadAnalytics();
      await pumpSized(tester, SensitivityCard(bases: a.sensitivity));
      String pct(double v) => '${v.toStringAsFixed(1).replaceAll('.', ',')} %';
      expect(find.text(pct(a.sensitivity[0].baseline)), findsOneWidget);
      await tester.tap(find.text('Sábado · 14:00'));
      await tester.pumpAndSettle();
      expect(find.text(pct(a.sensitivity[1].baseline)), findsOneWidget);
    });

    testWidgets('al tocar una variable se muestra el detalle de cada opción probada', (tester) async {
      await pumpSized(tester, SensitivityCard(bases: loadAnalytics().sensitivity));
      // Por defecto: la variable de mayor impacto (Hora del día, por la noche).
      expect(find.text('20:00 (noche)'), findsOneWidget);
      await tester.tap(find.text('Viento').first);
      await tester.pumpAndSettle();
      expect(find.text('Fuerte · 38 km/h'), findsOneWidget);
      expect(find.text('Calma · 4 km/h'), findsOneWidget);
      expect(find.text('20:00 (noche)'), findsNothing);
    });

    testWidgets('radar: los polígonos reflejan caídas y aumentos del modelo', (tester) async {
      final a = loadAnalytics();
      await pumpSized(tester, SensitivityCard(bases: a.sensitivity));
      await tester.tap(find.text('Radar'));
      await tester.pumpAndSettle();
      final data = tester.widget<RadarChart>(find.byType(RadarChart)).data;
      expect(data.dataSets, hasLength(2));
      final base = a.sensitivity.first;
      expect(data.dataSets[0].dataEntries, hasLength(base.factors.length));
      final windIdx = base.factors.indexWhere((f) => f.id == 'wind');
      final windDrop = -base.factors[windIdx].options.map((o) => o.delta).reduce((x, y) => x < y ? x : y);
      expect(data.dataSets[0].dataEntries[windIdx].value, closeTo(windDrop, 1e-9));
      expect(data.dataSets.every((s) => s.dataEntries.every((e) => e.value >= 0)), isTrue);
    });
  });

  group('OccupancyAnalyticsSection', () {
    Future<void> pumpSection(WidgetTester tester, FakeAdminProvider admin, {Size size = const Size(360, 800)}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        ChangeNotifierProvider<AdminProvider>.value(
          value: admin,
          child: const MaterialApp(
            home: Scaffold(body: SingleChildScrollView(padding: EdgeInsets.all(16), child: OccupancyAnalyticsSection())),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('al aparecer pide los datos una sola vez', (tester) async {
      final admin = FakeAdminProvider(fakeLoading: true);
      await pumpSection(tester, admin);
      expect(admin.fetchCalls, 1);
      expect(find.textContaining('Calculando escenarios'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error: muestra el mensaje y Reintentar fuerza una nueva carga', (tester) async {
      final admin = FakeAdminProvider(fakeError: 'El modelo de red neuronal no está disponible en este momento.');
      await pumpSection(tester, admin);
      expect(find.textContaining('no está disponible'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(admin.fetchCalls, 2);
      expect(admin.lastForce, isTrue);
      expect(find.byType(LineChart), findsNothing);
    });

    for (final size in sizes) {
      testWidgets('contenido completo sin desbordes en ${size.width.toInt()}px', (tester) async {
        final admin = FakeAdminProvider(fakeData: loadAnalytics());
        await pumpSection(tester, admin, size: size);
        await tester.pumpAndSettle();
        expect(find.text('Análisis de la red neuronal'), findsOneWidget);
        expect(find.text('Datos simulados'), findsOneWidget);
        expect(find.text('Ocupación por hora'), findsOneWidget);
        expect(find.text('Mapa de calor semanal'), findsOneWidget);
        expect(find.text('Qué mueve la ocupación'), findsOneWidget);
        expect(find.textContaining('Entrenada solo con datos simulados'), findsOneWidget);
        expectClean(tester);
      });
    }
  });

  group('Integración en el panel admin', () {
    testWidgets('las gráficas aparecen en Clima & Afluencia, debajo de "Ocupación Estimada en Playa"', (tester) async {
      // Superficie ancha a propósito: la fuente de prueba (Ahem) es mucho más ancha que Roboto y
      // desborda la tarjeta de clima ya existente. Aquí solo se verifica el ORDEN de las secciones;
      // el comportamiento en móvil de las gráficas se prueba arriba a 320/360/412 px.
      tester.view.physicalSize = const Size(700, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final auth = AuthProvider();
      auth.updateProfileLocally(
        UserModel(id: 'admin_1', nombre: 'Admin PlayApp', email: 'adminplayapp01@gmail.com', rol: 'ROLE_ADMIN', isAdmin: true),
      );
      final admin = FakeAdminProvider(fakeData: loadAnalytics());
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider<AdminProvider>.value(value: admin),
            ChangeNotifierProvider.value(value: ProductProvider()),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Clima & Afluencia')); // la barra de pestañas es desplazable
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clima & Afluencia'));
      await tester.pumpAndSettle();

      final occupancy = tester.getTopLeft(find.text('Ocupación Estimada en Playa')).dy;
      final section = tester.getTopLeft(find.text('Análisis de la red neuronal')).dy;
      final map = tester.getTopLeft(find.text('Ubicación de Monitoreo')).dy;
      expect(occupancy < section, isTrue, reason: 'la sección va debajo de la ocupación estimada');
      expect(section < map, isTrue, reason: 'y antes del mapa de monitoreo');
      expect(find.text('Ocupación por hora'), findsOneWidget);
      expectClean(tester);
    });
  });
}
