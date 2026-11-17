import 'package:flutter/foundation.dart';

class EnvConfig {
  /// URL base configurada en tiempo de compilación mediante:
  /// flutter run --dart-define=API_BASE_URL=http://<IP>:8080
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Resuelve la URL base automáticamente según la plataforma:
  /// - Si se define por --dart-define, tiene prioridad.
  /// - En Android (emulador): http://10.0.2.2:8080
  /// - En Web: http://localhost:8080
  /// - En iOS / Desktop / otros: http://localhost:8080
  static String get apiBaseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  /// Tarifa estándar de entrega en carpa en playas de Cartagena
  static const double standardDeliveryFee = 5000.0;

  /// Llave pública de Wompi Sandbox (Bancolombia)
  static const String wompiPublicKey = 'pub_test_wQdG7hGgqZc6hK7v9b8a1c2d3e4f5a6b';
  static const String wompiCurrency = 'COP';

  /// Tarjetas de prueba Wompi Sandbox
  static const String testCardApproved = '4242424242424242';
  static const String testCardRejected = '4111111111111111';

  /// Playas admitidas para entrega en Cartagena
  static const List<String> beachZones = [
    'Bocagrande (Frente a Kiosco El Bony)',
    'Castillogrande (Bahía tranquila)',
    'El Laguito (Zona Hotel Hilton)',
    'Marbella / Cabrero',
    'La Boquilla / Morros',
  ];
}
