import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class EnvConfig {
  /// Base URL por defecto.
  /// En Android Emulator suele ser 10.0.2.2:8080
  /// En iOS / Web / Desktop suele ser localhost:8080
  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    } catch (_) {}
    return 'http://localhost:8080';
  }

  static String apiBaseUrl = defaultBaseUrl;

  /// Tarifa estándar de envío a la playa en Cartagena
  static const double standardDeliveryFee = 5000.0;

  /// Credenciales y datos de prueba Wompi Sandbox
  static const String wompiPublicKey = 'pub_test_wQdG7hGgqZc6hK7v9b8a1c2d3e4f5a6b';
  static const String wompiCurrency = 'COP';

  /// Tarjetas de prueba de Wompi Sandbox
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
