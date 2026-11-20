import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playapp_movil_flutter/data/models/admin_weather_model.dart';
import 'package:playapp_movil_flutter/data/models/user_model.dart';
import 'package:playapp_movil_flutter/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:playapp_movil_flutter/providers/admin_provider.dart';
import 'package:playapp_movil_flutter/providers/auth_provider.dart';
import 'package:playapp_movil_flutter/providers/product_provider.dart';
import 'package:provider/provider.dart';

import 'support/test_helpers.dart';

void main() {
  group('Tarjeta "Ocupación Estimada en Playa"', () {
    // Estructura real devuelta por /api/admin/metrics (clima) del backend PlayApp-main.
    Map<String, dynamic> clima({bool withPrediction = true, bool withEstimate = true}) => {
          'description': 'nubes dispersas',
          'observedAt': '19/11/2026 16:59:00',
          'consultedAt': '19/11/2026 16:59:01',
          'metrics': [
            {'label': 'Temperatura', 'value': '32,0 °C'},
            {'label': 'Viento', 'value': '11,1 km/h'},
          ],
          if (withEstimate)
            'estimate': {
              'minimum': 50,
              'maximum': 70,
              'condition': 'Parcialmente nublado y cálido',
              'explanation': 'Explicación de las reglas.',
              'summary': 'El ambiente cálido con nubes parciales favorece una afluencia moderada a alta.',
            },
          'artwork': {'night': false},
          'prediction': withPrediction ? {'percentage': 28.6, 'version': 'sim-v1-6556cf29a859'} : null,
        };

    test('el modelo lee la predicción de la red neuronal y descarta valores inválidos', () {
      final w = AdminWeatherModel.fromJson(clima());
      expect(w.prediction!.percentage, 28.6);
      expect(w.prediction!.formatted, '28,6 %');
      expect(w.estimate!.maximum, 70, reason: 'las reglas se siguen leyendo igual');
      expect(AdminWeatherModel.fromJson(clima(withPrediction: false)).prediction, isNull);
      expect(AdminNeuralPrediction.tryParse({'percentage': 101}), isNull);
      expect(AdminNeuralPrediction.tryParse({'percentage': -1}), isNull);
      expect(AdminNeuralPrediction.tryParse({'percentage': 'x'}), isNull);
      expect(AdminNeuralPrediction.tryParse('x'), isNull);
      expect(AdminNeuralPrediction.tryParse({'percentage': 0.4})!.formatted, '0,4 %');
    });

    Future<void> pumpWeatherTab(WidgetTester tester, AdminWeatherModel? weather) async {
      // Superficie ancha: la fuente de prueba (Ahem) es mucho más ancha que Roboto y desborda la
      // tarjeta de clima existente; aquí se verifica el contenido, no el ajuste en móvil.
      setSurface(tester, const Size(700, 1400));
      final auth = AuthProvider();
      auth.updateProfileLocally(
        UserModel(id: 'admin_1', nombre: 'Admin PlayApp', email: 'adminplayapp01@gmail.com', rol: 'ROLE_ADMIN', isAdmin: true),
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider<AdminProvider>.value(value: FakeAdminProvider(fakeWeather: weather)),
            ChangeNotifierProvider.value(value: ProductProvider()),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Clima & Afluencia'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clima & Afluencia'));
      await tester.pumpAndSettle();
    }

    testWidgets('con red neuronal: muestra su valor como dato principal y las reglas como respaldo', (tester) async {
      await pumpWeatherTab(tester, AdminWeatherModel.fromJson(clima()));
      expect(find.text('28,6 %'), findsOneWidget);
      expect(find.text('Red neuronal'), findsOneWidget);
      expect(find.text('Según Clima'), findsNothing);
      expect(find.textContaining('Reglas de respaldo: 50 % – 70 %'), findsOneWidget);
      expect(find.text('0 % – 1 %'), findsNothing);
    });

    testWidgets('sin red neuronal: se comporta como antes (rango por reglas)', (tester) async {
      await pumpWeatherTab(tester, AdminWeatherModel.fromJson(clima(withPrediction: false)));
      expect(find.text('50 % – 70 %'), findsOneWidget);
      expect(find.text('Según Clima'), findsOneWidget);
      expect(find.text('Red neuronal'), findsNothing);
      expect(find.textContaining('Reglas de respaldo'), findsNothing);
    });

    testWidgets('sin clima en vivo: dice "Sin datos" en lugar de un falso 0 % – 1 %', (tester) async {
      await pumpWeatherTab(tester, null);
      expect(find.text('Sin datos'), findsOneWidget);
      expect(find.text('0 % – 1 %'), findsNothing);
      expect(find.textContaining('No fue posible obtener el clima en vivo'), findsOneWidget);
    });

    testWidgets('Clima & Afluencia quedó como antes: sin las gráficas del modelo y con el mapa debajo', (tester) async {
      await pumpWeatherTab(tester, AdminWeatherModel.fromJson(clima()));
      expect(find.text('Análisis de la red neuronal'), findsNothing);
      expect(find.text('Ocupación por hora'), findsNothing);
      final occupancy = tester.getTopLeft(find.text('Ocupación Estimada en Playa')).dy;
      final map = tester.getTopLeft(find.text('Ubicación de Monitoreo')).dy;
      expect(occupancy < map, isTrue);
    });
  });
}
