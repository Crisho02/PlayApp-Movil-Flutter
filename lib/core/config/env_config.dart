import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EnvConfig {
  /// URL base configurada en tiempo de compilación mediante:
  /// flutter run --dart-define=API_BASE_URL=http://<IP>:8080
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// URL resuelta dinámicamente según disponibilidad de host
  static String _resolvedBaseUrl = '';

  /// Resuelve la URL base automáticamente según la plataforma y conectividad:
  /// 1. Prioridad: --dart-define=API_BASE_URL=...
  /// 2. URL autodetectada y verificada
  /// 3. En Web: http://localhost:8080
  /// 4. En Android (USB con 'adb reverse tcp:8080 tcp:8080'): http://127.0.0.1:8080
  /// 5. En iOS / Desktop / otros: http://localhost:8080
  static String get apiBaseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    if (_resolvedBaseUrl.isNotEmpty) {
      return _resolvedBaseUrl;
    }
    if (kIsWeb) {
      final currentUri = Uri.base;
      if (currentUri.scheme == 'https') {
        return 'https://${currentUri.host}';
      }
      if (currentUri.host.isNotEmpty &&
          currentUri.host != 'localhost' &&
          currentUri.host != '127.0.0.1') {
        return 'http://${currentUri.host}:8080';
      }
      return 'http://localhost:8080';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (kReleaseMode) {
        return 'https://playapp-api.up.railway.app';
      }
      return 'http://127.0.0.1:8080';
    }
    if (kReleaseMode) {
      return 'https://playapp-api.up.railway.app';
    }
    return 'http://localhost:8080';
  }

  /// Permite fijar manualmente o tras probing la URL base activa
  static void setActiveBaseUrl(String url) {
    _resolvedBaseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
  }

  /// Autodetecta el host activo probando de forma rápida los candidatos conocidos
  static Future<String> resolveBaseUrl({bool forceRefresh = false}) async {
    if (_envBaseUrl.isNotEmpty) {
      _resolvedBaseUrl = _envBaseUrl;
      return _resolvedBaseUrl;
    }
    if (kIsWeb) {
      final currentUri = Uri.base;
      if (currentUri.scheme == 'https') {
        _resolvedBaseUrl = 'https://${currentUri.host}';
        return _resolvedBaseUrl;
      }
      if (currentUri.host.isNotEmpty &&
          currentUri.host != 'localhost' &&
          currentUri.host != '127.0.0.1') {
        _resolvedBaseUrl = 'http://${currentUri.host}:8080';
        return _resolvedBaseUrl;
      }
      _resolvedBaseUrl = 'http://localhost:8080';
      return _resolvedBaseUrl;
    }
    if (!forceRefresh && _resolvedBaseUrl.isNotEmpty) {
      return _resolvedBaseUrl;
    }

    if (kReleaseMode) {
      _resolvedBaseUrl = 'https://playapp-api.up.railway.app';
      return _resolvedBaseUrl;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // Candidatos ordenados por probabilidad de uso en desarrollo móvil:
      // 1. 127.0.0.1:8080 (USB con adb reverse tcp:8080 tcp:8080)
      // 2. 192.168.1.34:8080 (Wi-Fi en red local del computador anfitrión)
      // 3. 192.168.1.88:8080 (Wi-Fi alternativo)
      // 4. 10.0.2.2:8080 (Emulador Android estándar)
      final candidates = [
        'http://127.0.0.1:8080',
        'http://192.168.1.34:8080',
        'http://192.168.1.88:8080',
        'http://10.0.2.2:8080',
      ];

      for (final candidate in candidates) {
        try {
          final uri = Uri.parse('$candidate/api/products');
          final response = await http
              .get(uri)
              .timeout(const Duration(milliseconds: 1200));
          if (response.statusCode >= 200 && response.statusCode < 400) {
            _resolvedBaseUrl = candidate;
            debugPrint('[EnvConfig] Base URL conectada exitosamente: $candidate');
            return candidate;
          }
        } catch (_) {
          // Continuar con el siguiente candidato
        }
      }

      // Si ninguno respondió en el timeout, usar 127.0.0.1 para USB
      _resolvedBaseUrl = 'http://127.0.0.1:8080';
      return _resolvedBaseUrl;
    }

    _resolvedBaseUrl = 'http://localhost:8080';
    return _resolvedBaseUrl;
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
    'Playas de Bocagrande, Cartagena',
    'Castillogrande (Bahía tranquila)',
    'El Laguito (Zona Hotel Hilton)',
    'Marbella / Cabrero',
    'La Boquilla / Morros',
  ];
}
