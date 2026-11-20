import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../storage/session_manager.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    required this.statusCode,
  });
}

class ApiClient {
  static final http.Client _client = http.Client();

  static Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };

    final token = SessionManager.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final cookie = SessionManager.getSessionCookie();
    if (cookie != null && cookie.isNotEmpty) {
      headers['Cookie'] = cookie;
    }

    return headers;
  }

  static void _captureCookie(http.Response response) {
    final rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      final jsessionid = rawCookie.split(';').firstWhere(
            (part) => part.trim().startsWith('JSESSIONID='),
            orElse: () => '',
          );
      if (jsessionid.isNotEmpty) {
        SessionManager.setSessionCookie(jsessionid.trim());
      }
    }
  }

  static Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final baseUrl = EnvConfig.apiBaseUrl;
    final baseUri = Uri.parse(baseUrl);

    // Normalizar ruta
    String cleanPath = path;
    if (!cleanPath.startsWith('/')) cleanPath = '/$cleanPath';

    Map<String, String>? queryParams;
    if (queryParameters != null && queryParameters.isNotEmpty) {
      queryParams = {};
      queryParameters.forEach((k, v) {
        if (v != null) queryParams![k] = v.toString();
      });
    }

    return Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: cleanPath,
      queryParameters: queryParams,
    );
  }

  static Future<http.Response> _executeWithFallback(
    Future<http.Response> Function(Uri uri) requestFn,
    String path, [
    Map<String, dynamic>? queryParameters,
  ]) async {
    final initialBaseUrl = EnvConfig.apiBaseUrl;
    try {
      final uri = _buildUri(path, queryParameters);
      return await requestFn(uri);
    } catch (_) {
      // Reintentar si se detecta un host alternativo (ej. cambio entre USB y Wi-Fi)
      final newBaseUrl = await EnvConfig.resolveBaseUrl(forceRefresh: true);
      if (newBaseUrl != initialBaseUrl) {
        final retryUri = _buildUri(path, queryParameters);
        return await requestFn(retryUri);
      }
      rethrow;
    }
  }

  /// El servidor respondió, pero no con el JSON esperado (por ejemplo, una página HTML porque
  /// esa ruta no existe en el backend que está corriendo).
  static const String unexpectedFormatMessage =
      'El servidor respondió en un formato inesperado. Verifica que el backend de PlayApp esté actualizado.';

  /// La petición superó el tiempo máximo de espera.
  static const String timeoutMessage = 'El servidor de PlayApp tardó demasiado en responder. Intenta nuevamente.';

  /// [timeout] es opcional; por defecto 10 segundos (comportamiento de siempre).
  /// statusCode 0 significa que no hubo respuesta del servidor (sin conexión o tiempo agotado).
  static Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? parser,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final response = await _executeWithFallback(
        (uri) => _client.get(uri, headers: _buildHeaders()).timeout(timeout),
        path,
        queryParameters,
      );

      _captureCookie(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final T data;
        try {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          data = parser != null ? parser(decoded) : decoded as T;
        } catch (_) {
          return ApiResponse(success: false, message: unexpectedFormatMessage, statusCode: response.statusCode);
        }
        return ApiResponse(success: true, data: data, statusCode: response.statusCode);
      } else {
        String msg = 'No fue posible completar la solicitud.';
        try {
          final errJson = jsonDecode(utf8.decode(response.bodyBytes));
          if (errJson is Map) {
            msg = errJson['error']?.toString() ?? errJson['message']?.toString() ?? msg;
          }
        } catch (_) {}
        return ApiResponse(success: false, message: msg, statusCode: response.statusCode);
      }
    } on TimeoutException {
      return ApiResponse(success: false, message: timeoutMessage, statusCode: 0);
    } catch (_) {
      return ApiResponse(
        success: false,
        message: 'No se pudo conectar con el servicio de PlayApp. Por favor verifica tu conexión.',
        statusCode: 0,
      );
    }
  }

  static Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic body,
    T Function(dynamic json)? parser,
  }) async {
    try {
      final bodyBytes = body != null ? jsonEncode(body) : null;
      final response = await _executeWithFallback(
        (uri) => _client
            .post(
              uri,
              headers: _buildHeaders(),
              body: bodyBytes,
            )
            .timeout(const Duration(seconds: 12)),
        path,
      );

      _captureCookie(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final data = parser != null ? parser(decoded) : decoded as T;
        return ApiResponse(success: true, data: data, statusCode: response.statusCode);
      } else {
        String msg = 'No fue posible procesar la solicitud.';
        try {
          final errJson = jsonDecode(utf8.decode(response.bodyBytes));
          if (errJson is Map) {
            msg = errJson['error']?.toString() ?? errJson['message']?.toString() ?? msg;
          }
        } catch (_) {}
        return ApiResponse(success: false, message: msg, statusCode: response.statusCode);
      }
    } catch (_) {
      return ApiResponse(
        success: false,
        message: 'No se pudo conectar con el servicio de PlayApp. Intenta nuevamente.',
        statusCode: 0,
      );
    }
  }

  static Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic body,
    T Function(dynamic json)? parser,
  }) async {
    try {
      final bodyBytes = body != null ? jsonEncode(body) : null;
      final response = await _executeWithFallback(
        (uri) => _client
            .put(
              uri,
              headers: _buildHeaders(),
              body: bodyBytes,
            )
            .timeout(const Duration(seconds: 12)),
        path,
      );

      _captureCookie(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final data = parser != null ? parser(decoded) : decoded as T;
        return ApiResponse(success: true, data: data, statusCode: response.statusCode);
      } else {
        return ApiResponse(success: false, message: 'Operación no completada.', statusCode: response.statusCode);
      }
    } catch (_) {
      return ApiResponse(success: false, message: 'No se pudo conectar con el servidor.', statusCode: 0);
    }
  }

  static Future<ApiResponse<T>> postMultipart<T>(
    String path, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    T Function(dynamic json)? parser,
  }) async {
    try {
      final uri = _buildUri(path);
      final request = http.MultipartRequest('POST', uri);

      final token = SessionManager.getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      final cookie = SessionManager.getSessionCookie();
      if (cookie != null && cookie.isNotEmpty) {
        request.headers['Cookie'] = cookie;
      }
      request.headers['Accept'] = 'application/json';

      if (fields != null) {
        request.fields.addAll(fields);
      }
      if (files != null) {
        request.files.addAll(files);
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamedResponse);

      _captureCookie(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final data = parser != null ? parser(decoded) : decoded as T;
        return ApiResponse(success: true, data: data, statusCode: response.statusCode);
      } else {
        String msg = 'No fue posible subir la información del producto.';
        try {
          final errJson = jsonDecode(utf8.decode(response.bodyBytes));
          if (errJson is Map) {
            msg = errJson['error']?.toString() ?? errJson['message']?.toString() ?? msg;
          }
        } catch (_) {}
        return ApiResponse(success: false, message: msg, statusCode: response.statusCode);
      }
    } catch (_) {
      return ApiResponse(
        success: false,
        message: 'No se pudo conectar con el servicio al subir archivos.',
        statusCode: 0,
      );
    }
  }

  static Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? parser,
  }) async {
    try {
      final response = await _executeWithFallback(
        (uri) => _client.delete(uri, headers: _buildHeaders()).timeout(const Duration(seconds: 12)),
        path,
        queryParameters,
      );

      _captureCookie(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final data = parser != null ? parser(decoded) : decoded as T;
        return ApiResponse(success: true, data: data, statusCode: response.statusCode);
      } else {
        return ApiResponse(success: false, message: 'No se pudo eliminar el elemento.', statusCode: response.statusCode);
      }
    } catch (_) {
      return ApiResponse(success: false, message: 'Error de conexión con el servidor.', statusCode: 0);
    }
  }
}
