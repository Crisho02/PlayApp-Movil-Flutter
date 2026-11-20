import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:playapp_movil_flutter/core/config/env_config.dart';
import 'package:playapp_movil_flutter/core/network/api_client.dart';

/// Pruebas de ApiClient.get contra un servidor HTTP local (sin backend real ni red externa).
/// Usa `test` (no `testWidgets`) para que las peticiones HTTP sean reales.
void main() {
  late HttpServer server;

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      final res = req.response;
      switch (req.uri.path) {
        case '/json':
          res.headers.contentType = ContentType.json;
          res.write(jsonEncode({'ok': true, 'correo': req.uri.queryParameters['correo']}));
        case '/html':
          // Lo que devuelve el backend cuando la ruta no existe: la página de la tienda con 200.
          res.headers.contentType = ContentType.html;
          res.write('<!DOCTYPE html><html><head><title>Tienda</title></head></html>');
        case '/forbidden':
          res.statusCode = 403;
          res.headers.contentType = ContentType.json;
          res.write(jsonEncode({'error': 'No tienes permisos de administrador'}));
        default:
          res.statusCode = 404;
      }
      await res.close();
    });
    EnvConfig.setActiveBaseUrl('http://127.0.0.1:${server.port}');
  });

  tearDownAll(() => server.close(force: true));

  test('respuesta JSON válida: éxito y datos', () async {
    final r = await ApiClient.get<Map<String, dynamic>>('/json', queryParameters: {'correo': 'a@b.co'});
    expect(r.success, isTrue);
    expect(r.data!['ok'], isTrue);
    expect(r.data!['correo'], 'a@b.co');
  });

  test('HTML con código 200 (ruta inexistente en el backend): mensaje de backend desactualizado, no de conexión', () async {
    final r = await ApiClient.get<Map<String, dynamic>>('/html');
    expect(r.success, isFalse);
    expect(r.message, ApiClient.unexpectedFormatMessage);
    expect(r.statusCode, 200, reason: 'el servidor sí respondió; 0 se reserva para "sin respuesta"');
  });

  test('error con JSON (403): se muestra el mensaje del servidor, igual que antes', () async {
    final r = await ApiClient.get<Map<String, dynamic>>('/forbidden');
    expect(r.success, isFalse);
    expect(r.message, 'No tienes permisos de administrador');
    expect(r.statusCode, 403);
  });

  test('los mensajes de "tiempo agotado" y "formato inesperado" son distintos y claros', () {
    expect(ApiClient.timeoutMessage, isNot(ApiClient.unexpectedFormatMessage));
    expect(ApiClient.timeoutMessage, contains('tardó demasiado'));
    expect(ApiClient.unexpectedFormatMessage, contains('actualizado'));
  });
}
