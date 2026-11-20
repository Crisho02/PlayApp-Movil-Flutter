import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playapp_movil_flutter/data/models/sales_charts_model.dart';
import 'package:playapp_movil_flutter/data/models/user_model.dart';
import 'package:playapp_movil_flutter/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:playapp_movil_flutter/presentation/widgets/charts/category_mix_card.dart';
import 'package:playapp_movil_flutter/presentation/widgets/charts/charts_common.dart';
import 'package:playapp_movil_flutter/presentation/widgets/charts/charts_tab.dart';
import 'package:playapp_movil_flutter/presentation/widgets/charts/kpi_section.dart';
import 'package:playapp_movil_flutter/presentation/widgets/charts/orders_heatmap_card.dart';
import 'package:playapp_movil_flutter/presentation/widgets/charts/pareto_card.dart';
import 'package:playapp_movil_flutter/presentation/widgets/charts/product_comparator_card.dart';
import 'package:playapp_movil_flutter/presentation/widgets/charts/product_ranking_card.dart';
import 'package:playapp_movil_flutter/presentation/widgets/charts/sales_trend_card.dart';
import 'package:playapp_movil_flutter/providers/admin_provider.dart';
import 'package:playapp_movil_flutter/providers/auth_provider.dart';
import 'package:playapp_movil_flutter/providers/product_provider.dart';
import 'package:provider/provider.dart';

import 'support/test_helpers.dart';

/// Copia de una respuesta real con todas las ventas en cero (periodo sin pedidos).
Map<String, dynamic> emptyJson() {
  final j = loadChartsJson('charts_30d');
  List<double> zeros(List l) => List<double>.filled(l.length, 0);
  final t = j['trend'] as Map<String, dynamic>;
  for (final k in ['ingresos', 'pedidos', 'unidades']) {
    t[k] = zeros(t[k] as List);
  }
  for (final p in (j['products'] as List).cast<Map<String, dynamic>>()) {
    p['unidades'] = 0;
    p['ingresos'] = 0;
    p['pedidos'] = 0;
    p['ticketPromedio'] = 0;
    p['frecuenciaPct'] = 0;
    p['serieUnidades'] = zeros(p['serieUnidades'] as List);
    p['serieIngresos'] = zeros(p['serieIngresos'] as List);
  }
  j['heatmap'] = {
    'pedidos': List.generate(7, (_) => List<double>.filled(24, 0)),
    'ingresos': List.generate(7, (_) => List<double>.filled(24, 0)),
  };
  for (final c in (j['categoryMix'] as List).cast<Map<String, dynamic>>()) {
    c['ingresos'] = 0;
    c['unidades'] = 0;
    c['pedidos'] = 0;
  }
  for (final k in (j['kpis'] as Map<String, dynamic>).values.cast<Map<String, dynamic>>()) {
    k['actual'] = 0;
  }
  j['resumen'] = {'pedidos': 0, 'lineas': 0};
  return j;
}

Future<void> pumpCard(WidgetTester tester, Widget child, {Size size = const Size(360, 800), double textScale = 1.0}) async {
  setSurface(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Monta la pestaña completa. Superficie muy alta para que se construyan las 7 gráficas a la vez.
Future<FakeAdminProvider> pumpTab(WidgetTester tester, FakeAdminProvider admin,
    {double width = 360, double textScale = 1.0, double height = 9000}) async {
  final size = Size(width, height);
  setSurface(tester, size);
  await tester.pumpWidget(
    ChangeNotifierProvider<AdminProvider>.value(
      value: admin,
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
          child: const Scaffold(body: ChartsTab()),
        ),
      ),
    ),
  );
  await tester.pump();
  if (admin.fakeCharts != null) await tester.pumpAndSettle();
  return admin;
}

void main() {
  // ------------------------------------------------------------------ modelo
  group('SalesChartsData.tryParse (respuestas reales)', () {
    test('"Todo": 82 meses, 12 productos y cifras coherentes entre gráficas', () {
      final d = loadCharts('charts_todo');
      expect(d.rango, 'todo');
      expect(d.granularidad, 'month');
      expect(d.hasPrevious, isFalse);
      expect(d.trend.labels, hasLength(82));
      expect(d.products, hasLength(12));
      final sumProducts = d.products.fold<double>(0, (a, p) => a + p.ingresos);
      final sumTrend = d.trend.ingresos.fold<double>(0, (a, v) => a + v);
      expect(sumProducts, closeTo(d.ingresos.actual, 0.01));
      expect(sumTrend, closeTo(d.ingresos.actual, 0.01));
      final heatOrders = d.heatmapPedidos.expand((r) => r).fold<double>(0, (a, v) => a + v);
      expect(heatOrders, d.pedidos.actual);
      expect(d.products.first.nombre, 'Pescado frito');
      expect(d.products.first.ingresos, 6240000);
    });

    test('"30 días": diario con periodo anterior alineado', () {
      final d = loadCharts('charts_30d');
      expect(d.granularidad, 'day');
      expect(d.trend.labels, hasLength(30));
      expect(d.hasPrevious, isTrue);
      expect(d.trend.ingresosAnterior, hasLength(30));
      expect(d.anteriorDesde, isNotNull);
    });

    test('filtro de categoría: solo bebidas en el ranking, mezcla con todas las categorías', () {
      final d = loadCharts('charts_7d_bebida');
      expect(d.categoria, 2);
      expect(d.products.every((p) => p.categoria == 2), isTrue);
      expect(d.categoryMix.map((c) => c.nombre), containsAll(['Comida', 'Bebida', 'Servicio']));
    });

    test('rechaza respuestas incompletas o inconsistentes', () {
      Map<String, dynamic> j() => loadChartsJson('charts_30d');
      expect(SalesChartsData.tryParse({}), isNull);
      expect(SalesChartsData.tryParse(j()..remove('filters')), isNull);
      expect(SalesChartsData.tryParse(j()..remove('kpis')), isNull);
      final shortTrend = j();
      (shortTrend['trend'] as Map)['ingresos'] = [1, 2];
      expect(SalesChartsData.tryParse(shortTrend), isNull);
      final badProduct = j();
      ((badProduct['products'] as List).first as Map)['serieIngresos'] = [1];
      expect(SalesChartsData.tryParse(badProduct), isNull);
      final badHeat = j();
      (badHeat['heatmap'] as Map)['pedidos'] = [List.filled(24, 0)];
      expect(SalesChartsData.tryParse(badHeat), isNull);
    });

    test('ChartsFilter genera los parámetros correctos', () {
      expect(const ChartsFilter().toQuery(), {'rango': '30d', 'granularidad': 'auto'});
      final f = const ChartsFilter().copyWith(rango: 'personalizado', desde: DateTime(2026, 5, 1), hasta: DateTime(2026, 5, 31), categoria: 2);
      expect(f.toQuery(), {'rango': 'personalizado', 'desde': '2026-05-01', 'hasta': '2026-05-31', 'categoria': '2', 'granularidad': 'auto'});
      expect(f.copyWith(clearCategoria: true).categoria, isNull);
      expect(f.copyWith(rango: '7d').toQuery().containsKey('desde'), isFalse);
    });
  });

  group('Formatos y cálculos auxiliares', () {
    test('moneda, números y etiquetas de periodo en español', () {
      expect(formatMoneyCompact(28229500), r'28 M $');
      expect(formatMoneyCompact(1250000), r'1,3 M $');
      expect(formatMoneyCompact(85000), r'85 mil $');
      expect(formatMoneyCompact(900), r'900 $');
      expect(formatNumber(1720), '1.720');
      expect(formatNumber(12.5), '12,5');
      expect(formatChange(12.34), '+12,3 %');
      expect(formatChange(-5), '−5,0 %');
      expect(bucketLabel('2026-11-18', 'day'), '18 nov');
      expect(bucketLabel('2026-11-16', 'week'), 'sem 16 nov');
      expect(bucketLabel('2026-11', 'month'), 'nov 26');
      expect(bucketLabel('2026-11', 'month', long: true), 'nov 2026');
    });

    test('Pareto: acumulado llega a 100 % y el 80 % se calcula con los datos reales', () {
      final d = loadCharts('charts_todo');
      final items = buildPareto(d.products);
      expect(items.last.cumulativePct, closeTo(100, 0.01));
      for (var i = 1; i < items.length; i++) {
        expect(items[i].cumulativePct >= items[i - 1].cumulativePct, isTrue);
      }
      final k = productsFor80(d.products);
      final sorted = [...d.products]..sort((a, b) => b.ingresos.compareTo(a.ingresos));
      final total = sorted.fold<double>(0, (a, p) => a + p.ingresos);
      final accK = sorted.take(k).fold<double>(0, (a, p) => a + p.ingresos);
      final accPrev = sorted.take(k - 1).fold<double>(0, (a, p) => a + p.ingresos);
      expect(accK >= total * 0.8 - 1e-6, isTrue);
      expect(accPrev < total * 0.8, isTrue);
      expect(buildPareto(d.products, maxBars: 5), hasLength(5));
      expect(buildPareto(d.products, maxBars: 5).last.nombre, startsWith('Otros'));
    });
  });

  // ------------------------------------------------------------------ diseño móvil
  group('Pestaña completa sin desbordes', () {
    for (final fixture in ['charts_todo', 'charts_30d']) {
      for (final size in mobileSizes) {
        for (final scale in [1.0, 1.5]) {
          testWidgets('$fixture · ${size.width.toInt()}px · texto x$scale', (tester) async {
            await pumpTab(tester, FakeAdminProvider(fakeCharts: loadCharts(fixture)), width: size.width, textScale: scale);
            for (final t in ['Gráficos de ventas', 'Tendencia de ventas', 'Productos más y menos vendidos', 'Comparador de productos',
                'Pareto de ingresos (80/20)', '¿Cuándo se compra?', 'Mix por categoría']) {
              expect(find.text(t), findsOneWidget, reason: t);
            }
            expectClean(tester);
          });
        }
      }
    }

    testWidgets('periodo sin ventas: cada gráfica muestra su estado vacío sin errores', (tester) async {
      await pumpTab(tester, FakeAdminProvider(fakeCharts: SalesChartsData.tryParse(emptyJson())!), width: 320);
      expect(find.byType(ChartEmpty), findsWidgets);
      expect(find.textContaining('No hay ventas en el periodo'), findsWidgets);
      expectClean(tester);
    });
  });

  // ------------------------------------------------------------------ estados y filtros
  group('ChartsTab: estados y filtros', () {
    testWidgets('sin datos: pide los datos al abrir y muestra la carga', (tester) async {
      final admin = await pumpTab(tester, FakeAdminProvider(), height: 800);
      expect(admin.fetchCalls, hasLength(1));
      expect(find.text('Consultando la base de datos…'), findsOneWidget);
    });

    testWidgets('error: muestra el mensaje y Reintentar vuelve a consultar', (tester) async {
      final admin = await pumpTab(tester, FakeAdminProvider(fakeChartsError: 'No se pudo conectar con el servicio.'), height: 800);
      expect(find.text('No se pudo conectar con el servicio.'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(admin.fetchCalls.length, greaterThanOrEqualTo(2));
    });

    testWidgets('los chips de rango y el selector de categoría consultan con el filtro correcto', (tester) async {
      final admin = await pumpTab(tester, FakeAdminProvider(fakeCharts: loadCharts('charts_30d')));
      expect(admin.fetchCalls, isEmpty, reason: 'con datos ya cargados no vuelve a pedir al abrir');
      await tester.tap(find.text('7 días'));
      await tester.pump();
      expect(admin.fetchCalls.last!.rango, '7d');
      await tester.tap(find.text('Comida').first);
      await tester.pump();
      expect(admin.fetchCalls.last!.categoria, 1);
      expect(admin.fetchCalls.last!.rango, '7d', reason: 'conserva el rango elegido');
      await tester.tap(find.text('Todas'));
      await tester.pump();
      expect(admin.fetchCalls.last!.categoria, isNull);
    });

    testWidgets('muestra el periodo consultado y el de comparación', (tester) async {
      await pumpTab(tester, FakeAdminProvider(fakeCharts: loadCharts('charts_30d')));
      expect(find.textContaining('comparado con'), findsOneWidget);
      expect(find.textContaining('En vivo desde la base de datos'), findsOneWidget);
    });
  });

  // ------------------------------------------------------------------ interacciones
  group('Interacciones de cada gráfica', () {
    testWidgets('1 → 2: tocar un indicador cambia la métrica de la tendencia', (tester) async {
      final d = loadCharts('charts_todo');
      await pumpTab(tester, FakeAdminProvider(fakeCharts: d));
      List<double> firstLine() => tester
          .widgetList<LineChart>(find.descendant(of: find.byType(SalesTrendCard), matching: find.byType(LineChart)))
          .first
          .data
          .lineBarsData
          .first
          .spots
          .map((s) => s.y)
          .toList();
      expect(firstLine(), d.trend.ingresos);
      await tester.tap(find.descendant(of: find.byType(KpiSection), matching: find.text('Pedidos')));
      await tester.pumpAndSettle();
      expect(firstLine(), d.trend.pedidos);
    });

    testWidgets('2: granularidad pide datos agrupados y la comparación se puede ocultar', (tester) async {
      final admin = await pumpTab(tester, FakeAdminProvider(fakeCharts: loadCharts('charts_30d')));
      await tester.tap(find.text('Semana'));
      await tester.pump();
      expect(admin.fetchCalls.last!.granularidad, 'week');
      int bars() => tester
          .widgetList<LineChart>(find.descendant(of: find.byType(SalesTrendCard), matching: find.byType(LineChart)))
          .first
          .data
          .lineBarsData
          .length;
      expect(bars(), 2);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(bars(), 1);
    });

    testWidgets('3: más/menos vendidos, ver todos y ficha del producto', (tester) async {
      final d = loadCharts('charts_todo');
      await pumpCard(tester, ProductRankingCard(data: d), size: const Size(360, 2400));
      final byUnits = [...d.products]..sort((a, b) => b.unidades.compareTo(a.unidades));
      expect(find.text(byUnits.first.nombre), findsOneWidget);
      await tester.tap(find.text('Menos vendidos'));
      await tester.pumpAndSettle();
      expect(find.text(byUnits.last.nombre), findsOneWidget);
      await tester.tap(find.text('Ver todos (12)'));
      await tester.pumpAndSettle();
      for (final p in d.products) {
        expect(find.text(p.nombre), findsOneWidget, reason: p.nombre);
      }
      await tester.tap(find.text('Pescado frito'));
      await tester.pumpAndSettle();
      expect(find.text('Unidades vendidas'), findsOneWidget);
      expect(find.text('Puesto #1 en ingresos'), findsOneWidget);
      expect(find.text('Tendencia del producto'), findsOneWidget);
      expectClean(tester);
    });

    testWidgets('4: comparador con 2 por defecto, máximo 3, radar y tabla', (tester) async {
      final d = loadCharts('charts_todo');
      await pumpCard(tester, ProductComparatorCard(data: d), size: const Size(360, 2400));
      int lines() => tester.widget<LineChart>(find.byType(LineChart)).data.lineBarsData.length;
      expect(lines(), 2);
      await tester.tap(find.text(d.products[2].nombre).first);
      await tester.pumpAndSettle();
      expect(lines(), 3);
      await tester.tap(find.text(d.products[3].nombre).first);
      await tester.pumpAndSettle();
      expect(lines(), 3, reason: 'no permite más de 3');
      final radar = tester.widget<RadarChart>(find.byType(RadarChart)).data;
      expect(radar.dataSets, hasLength(4), reason: '3 productos + escala fija invisible');
      expect(radar.dataSets.first.dataEntries.every((e) => e.value >= 0 && e.value <= 100), isTrue);
      expect(find.byIcon(Icons.emoji_events_rounded), findsWidgets);
      await tester.tap(find.text(d.products[0].nombre).first);
      await tester.pumpAndSettle();
      expect(lines(), 2);
      expectClean(tester);
    });

    testWidgets('5: Pareto resume el 80 % y al tocar una barra muestra su detalle', (tester) async {
      final d = loadCharts('charts_todo');
      await pumpCard(tester, ParetoCard(data: d), size: const Size(360, 1400));
      expect(find.textContaining('de 12 productos'), findsOneWidget);
      expect(find.textContaining('#1 · Pescado frito'), findsOneWidget);
      final chart = find.byWidgetPredicate((w) => w is CustomPaint && w.painter.runtimeType.toString() == '_ParetoPainter');
      final r = tester.getRect(chart);
      final slot = (r.width - 48 - 34) / buildPareto(d.products).length;
      await tester.tapAt(Offset(r.left + 48 + slot * 1.5, r.center.dy));
      await tester.pumpAndSettle();
      expect(find.textContaining('#2 · '), findsOneWidget);
      expectClean(tester);
    });

    testWidgets('6: mapa de calor arranca en la franja más fuerte y cambia de métrica y rango', (tester) async {
      final d = loadCharts('charts_todo');
      await pumpCard(tester, OrdersHeatmapCard(data: d), size: const Size(360, 1400));
      expect(find.text('Franja más fuerte del periodo'), findsOneWidget);
      await tester.tap(find.text('Ingresos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('24 h'));
      await tester.pumpAndSettle();
      final grid = find.byWidgetPredicate((w) => w is CustomPaint && w.painter.runtimeType.toString() == '_HeatPainter');
      final r = tester.getRect(grid);
      final cell = (r.width - 34) / 24;
      await tester.tapAt(Offset(r.left + 34 + cell * 3 + cell / 2, r.top + 18 + 15)); // Lunes 03:00
      await tester.pumpAndSettle();
      expect(find.textContaining('Lunes · 03:00'), findsOneWidget);
      expectClean(tester);
    });

    testWidgets('7: "Filtrar" aplica la categoría a toda la pestaña y se puede quitar', (tester) async {
      int? applied = -1;
      await pumpCard(tester, CategoryMixCard(data: loadCharts('charts_todo'), onFilter: (c) => applied = c), size: const Size(360, 1400));
      await tester.tap(find.widgetWithText(TextButton, 'Filtrar').at(1)); // Bebida
      await tester.pump();
      expect(applied, 2);
      await pumpCard(tester, CategoryMixCard(data: loadCharts('charts_7d_bebida'), onFilter: (c) => applied = c), size: const Size(360, 1400));
      expect(find.text('Filtrado'), findsOneWidget);
      await tester.tap(find.text('Quitar filtro de categoría'));
      await tester.pump();
      expect(applied, isNull);
      expectClean(tester);
    });
  });

  // ------------------------------------------------------------------ integración
  group('Integración en el panel admin', () {
    testWidgets('la pestaña "Gráficos" está justo después de "Predicción IA" y muestra las gráficas', (tester) async {
      setSurface(tester, const Size(700, 1400));
      final auth = AuthProvider();
      auth.updateProfileLocally(
        UserModel(id: 'admin_1', nombre: 'Admin PlayApp', email: 'adminplayapp01@gmail.com', rol: 'ROLE_ADMIN', isAdmin: true),
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider<AdminProvider>.value(value: FakeAdminProvider(fakeCharts: loadCharts('charts_30d'))),
            ChangeNotifierProvider.value(value: ProductProvider()),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );
      await tester.pump();
      final tabs = tester.widget<TabBar>(find.byType(TabBar)).tabs.cast<Tab>().map((t) => t.text).toList();
      expect(tabs.indexOf('Gráficos'), tabs.indexOf('Predicción IA') + 1);
      await tester.ensureVisible(find.text('Gráficos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gráficos'));
      await tester.pumpAndSettle();
      expect(find.text('Gráficos de ventas'), findsOneWidget);
      expect(find.text('Tendencia de ventas'), findsOneWidget);
    });
  });
}
