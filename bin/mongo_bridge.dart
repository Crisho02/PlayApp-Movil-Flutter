// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

/// Servidor Puente HTTP local para permitir que Flutter Web se comunique
/// en tiempo real con MongoDB Atlas (`playappdb`) superando las restricciones
/// de sockets TCP directos de los navegadores web.
void main(List<String> args) async {
  const port = 8081;
  const mongoUri =
      'mongodb+srv://playapp_user:PlayAppadmin123@playapp-prod.0ibspwi.mongodb.net/playappdb?retryWrites=true&w=majority';

  print('==================================================');
  print('  PlayApp - Puente HTTP para MongoDB Atlas');
  print('==================================================');
  print('Conectando a MongoDB Atlas (playappdb)...');

  mongo.Db? db;
  final dBCrypt = DBCrypt();

  try {
    db = await mongo.Db.create(mongoUri);
    await db.open();
    print('Conexión establecida exitosamente con MongoDB Atlas!');
  } catch (e) {
    print('ADVERTENCIA: No se pudo conectar de inmediato a MongoDB Atlas: $e');
  }

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('Puente HTTP escuchando en http://localhost:$port');
  print('Listo para recibir peticiones de PlayApp Mobile Web.');
  print('==================================================');

  await for (HttpRequest request in server) {
    // Configuración universal de CORS para navegadores
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, DELETE, PUT');
    request.response.headers.add('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept, Authorization');
    request.response.headers.add('Content-Type', 'application/json; charset=utf-8');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      continue;
    }

    final path = request.uri.path;

    try {
      if (db == null || !db.isConnected) {
        try {
          db = await mongo.Db.create(mongoUri);
          await db.open();
        } catch (_) {}
      }

      final isDbReady = db != null && db.isConnected;

      if (path == '/api/status' && request.method == 'GET') {
        final body = jsonEncode({
          'status': isDbReady ? 'conectado' : 'desconectado',
          'database': 'playappdb',
          'bridge': 'active',
          'timestamp': DateTime.now().toIso8601String(),
        });
        request.response.write(body);
      } else if (path == '/api/stats' && request.method == 'GET') {
        final stats = <String, int>{};
        if (isDbReady) {
          final collections = [
            'productos',
            'entidades',
            'pedidos',
            'reseñas',
            'mensajes_contacto',
            'chat_messages',
          ];
          for (final col in collections) {
            try {
              stats[col] = await db.collection(col).count();
            } catch (_) {
              stats[col] = 0;
            }
          }
        }
        request.response.write(jsonEncode(stats));
      } else if (path == '/api/productos' && request.method == 'GET') {
        if (!isDbReady) {
          request.response.statusCode = HttpStatus.serviceUnavailable;
          request.response.write(jsonEncode({'error': 'Base de datos no conectada'}));
        } else {
          final list = await db.collection('productos').find().toList();
          request.response.write(jsonEncode(list));
        }
      } else if (path == '/api/pedidos' && request.method == 'GET') {
        if (!isDbReady) {
          request.response.write(jsonEncode([]));
        } else {
          final list = await db.collection('pedidos').find().toList();
          request.response.write(jsonEncode(list));
        }
      } else if (path == '/api/pedidos' && request.method == 'POST') {
        final content = await utf8.decoder.bind(request).join();
        final data = jsonDecode(content) as Map<String, dynamic>;
        if (isDbReady) {
          await db.collection('pedidos').insert(data);
          // Descontar inventario si viene items
          if (data['items'] is List) {
            for (final item in data['items']) {
              final prodId = item['productoId'] ?? item['id'];
              final cant = (item['cantidad'] as num?)?.toInt() ?? 1;
              if (prodId != null) {
                await db.collection('productos').updateOne(
                  mongo.where.eq('_id', prodId),
                  mongo.modify.inc('stock', -cant),
                );
              }
            }
          }
          request.response.statusCode = HttpStatus.created;
          request.response.write(jsonEncode({'success': true, 'pedido': data}));
        } else {
          request.response.statusCode = HttpStatus.serviceUnavailable;
          request.response.write(jsonEncode({'error': 'MongoDB no disponible'}));
        }
      } else if (path == '/api/resenas' && request.method == 'GET') {
        if (!isDbReady) {
          request.response.write(jsonEncode([]));
        } else {
          final list = await db.collection('reseñas').find().toList();
          request.response.write(jsonEncode(list));
        }
      } else if (path == '/api/resenas' && request.method == 'POST') {
        final content = await utf8.decoder.bind(request).join();
        final data = jsonDecode(content) as Map<String, dynamic>;
        if (isDbReady) {
          await db.collection('reseñas').insert(data);
          request.response.statusCode = HttpStatus.created;
          request.response.write(jsonEncode({'success': true, 'resena': data}));
        } else {
          request.response.statusCode = HttpStatus.serviceUnavailable;
          request.response.write(jsonEncode({'error': 'MongoDB no disponible'}));
        }
      } else if (path == '/api/login' && request.method == 'POST') {
        final content = await utf8.decoder.bind(request).join();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final email = (data['email'] as String? ?? '').trim().toLowerCase();
        final password = data['password'] as String? ?? '';

        if (!isDbReady) {
          request.response.statusCode = HttpStatus.serviceUnavailable;
          request.response.write(jsonEncode({'error': 'MongoDB no disponible'}));
        } else {
          final userDoc = await db.collection('entidades').findOne(
            mongo.where.eq('email', email),
          );
          if (userDoc == null) {
            request.response.statusCode = HttpStatus.unauthorized;
            request.response.write(jsonEncode({'error': 'Usuario no encontrado'}));
          } else {
            final storedHash = (userDoc['password'] ?? userDoc['contrasena'])?.toString() ?? '';
            final ok = storedHash.isNotEmpty && dBCrypt.checkpw(password, storedHash);
            if (ok) {
              request.response.write(jsonEncode({
                'success': true,
                'usuario': userDoc,
              }));
            } else {
              request.response.statusCode = HttpStatus.unauthorized;
              request.response.write(jsonEncode({'error': 'Contraseña incorrecta'}));
            }
          }
        }
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write(jsonEncode({'error': 'Endpoint no encontrado'}));
      }
    } catch (err) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(jsonEncode({'error': err.toString()}));
    } finally {
      await request.response.close();
    }
  }
}
