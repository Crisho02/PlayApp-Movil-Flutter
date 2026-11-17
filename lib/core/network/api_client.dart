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

  static Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? parser,
  }) async {
    try {
      final uri = _buildUri(path, queryParameters);
      final response = await _client
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 10));

      _captureCookie(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final data = parser != null ? parser(decoded) : decoded as T;
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
      final uri = _buildUri(path);
      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 12));

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
      final uri = _buildUri(path);
      final response = await _client
          .put(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 12));

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

  static Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? parser,
  }) async {
    try {
      final uri = _buildUri(path, queryParameters);
      final response = await _client
          .delete(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 12));

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
