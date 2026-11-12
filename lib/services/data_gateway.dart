import 'dart:async';
import 'dart:convert';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../models/pedido.dart';
import '../models/producto.dart';
import '../models/resena.dart';
import '../models/usuario.dart';

/// Estado de la pasarela de datos con MongoDB Atlas.
enum GatewayStatus {
  desconectado('Desconectado'),
  conectando('Conectando a MongoDB Atlas...'),
  conectado('Conectado a MongoDB Atlas (playappdb)'),
  error('Error de conexión (Modo Local / Offline)');

  const GatewayStatus(this.etiqueta);
  final String etiqueta;
}

/// Pasarela de Datos oficial de PlayApp para sincronización y persistencia directa
/// con MongoDB Atlas (`playappdb`), reflejando la misma base de datos del proyecto Spring Boot.
class PlayAppDataGateway {
  PlayAppDataGateway({
    this.mongoUri =
        'mongodb+srv://playapp_user:PlayAppadmin123@playapp-prod.0ibspwi.mongodb.net/playappdb?retryWrites=true&w=majority',
    this.databaseName = 'playappdb',
    this.bridgeUrl = 'http://localhost:8081',
  });

  final String mongoUri;
  final String databaseName;
  final String bridgeUrl;

  mongo.Db? _db;
  GatewayStatus _status = GatewayStatus.desconectado;
  String? _lastError;
  bool _isBridgeConnected = false;
  final DBCrypt _dBCrypt = DBCrypt();

  GatewayStatus get status => _status;
  bool get isConnected =>
      _status == GatewayStatus.conectado &&
      ((_db != null && _db!.isConnected) || (kIsWeb && _isBridgeConnected));
  bool get isBridgeConnected => _isBridgeConnected;
  String? get lastError => _lastError;

  /// Abre la conexión hacia MongoDB Atlas.
  Future<bool> connect() async {
    if (isConnected) return true;

    _status = GatewayStatus.conectando;
    _lastError = null;

    if (kIsWeb) {
      try {
        final res = await http
            .get(Uri.parse('$bridgeUrl/api/status'))
            .timeout(const Duration(milliseconds: 1500));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          if (data['status'] == 'conectado') {
            _isBridgeConnected = true;
            _status = GatewayStatus.conectado;
            debugPrint('[PlayAppDataGateway] Conectado a MongoDB Atlas vía puente HTTP ($bridgeUrl)');
            return true;
          }
        }
      } catch (_) {}

      _isBridgeConnected = false;
      _status = GatewayStatus.error;
      _lastError =
          'En navegador Web los sockets TCP directos están restringidos. Inicia el puente local ("dart run bin/mongo_bridge.dart") para sincronizar en vivo o ejecuta en Android/Windows.';
      return false;
    }

    try {
      final db = await mongo.Db.create(mongoUri);
      await db.open().timeout(const Duration(seconds: 10));
      _db = db;
      _status = GatewayStatus.conectado;
      debugPrint('[PlayAppDataGateway] Conectado exitosamente a MongoDB Atlas ($databaseName)');
      return true;
    } catch (e) {
      _status = GatewayStatus.error;
      _lastError = e.toString();
      debugPrint('[PlayAppDataGateway] Fallo al conectar con MongoDB Atlas: $e');
      return false;
    }
  }

  /// Cierra la conexión de forma segura.
  Future<void> disconnect() async {
    try {
      await _db?.close();
    } catch (_) {}
    _db = null;
    _status = GatewayStatus.desconectado;
  }

  /// Obtiene estadísticas de las colecciones de la base de datos en MongoDB Atlas.
  Future<Map<String, int>> getDatabaseStats() async {
    final stats = <String, int>{};
    if (!isConnected) return stats;

    if (kIsWeb && _isBridgeConnected) {
      try {
        final res = await http
            .get(Uri.parse('$bridgeUrl/api/stats'))
            .timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final map = jsonDecode(res.body) as Map<String, dynamic>;
          return map.map((k, v) => MapEntry(k, (v as num).toInt()));
        }
      } catch (_) {}
      return stats;
    }

    if (_db == null || !_db!.isConnected) return stats;

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
        final count = await _db!.collection(col).count();
        stats[col] = count;
      } catch (_) {
        stats[col] = 0;
      }
    }
    return stats;
  }

  // ==========================================
  // PRODUCTOS
  // ==========================================

  Future<List<Producto>> fetchProductos() async {
    if (!isConnected) return [];

    if (kIsWeb && _isBridgeConnected) {
      try {
        final res = await http.get(Uri.parse('$bridgeUrl/api/productos'));
        if (res.statusCode == 200) {
          final list = jsonDecode(res.body) as List<dynamic>;
          return list
              .map((d) => Producto.fromMongo(Map<String, dynamic>.from(d as Map)))
              .toList();
        }
      } catch (e) {
        debugPrint('[PlayAppDataGateway] Error al leer productos por puente: $e');
      }
      return [];
    }

    if (_db == null || !_db!.isConnected) return [];
    try {
      final docs = await _db!
          .collection('productos')
          .find(mongo.where.sortBy('nombre'))
          .toList();
      return docs.map((d) => Producto.fromMongo(d)).toList();
    } catch (e) {
      debugPrint('[PlayAppDataGateway] Error al consultar productos: $e');
      return [];
    }
  }

  Future<bool> saveProducto(Producto producto) async {
    if (!isConnected) return false;
    try {
      final col = _db!.collection('productos');
      final data = producto.toMongo();

      if (producto.id.isNotEmpty && producto.id.length == 24 && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(producto.id)) {
        final objId = mongo.ObjectId.fromHexString(producto.id);
        data['_id'] = objId;
        final res = await col.replaceOne(mongo.where.id(objId), data, upsert: true);
        return res.isSuccess;
      } else {
        final res = await col.insertOne(data);
        return res.isSuccess;
      }
    } catch (e) {
      debugPrint('[PlayAppDataGateway] Error al guardar producto: $e');
      return false;
    }
  }

  Future<bool> deleteProducto(String id) async {
    if (!isConnected) return false;
    try {
      final col = _db!.collection('productos');
      dynamic selectorId = id;
      if (id.length == 24 && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id)) {
        selectorId = mongo.ObjectId.fromHexString(id);
      }
      final res = await col.deleteOne(mongo.where.id(selectorId));
      return res.isSuccess;
    } catch (e) {
      debugPrint('[PlayAppDataGateway] Error al eliminar producto: $e');
      return false;
    }
  }

  Future<void> updateStock(String productoId, int nuevoStock) async {
    if (!isConnected) return;
    try {
      dynamic selectorId = productoId;
      if (productoId.length == 24 && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(productoId)) {
        selectorId = mongo.ObjectId.fromHexString(productoId);
      }
      await _db!.collection('productos').updateOne(
        mongo.where.id(selectorId),
        mongo.modify.set('stock', nuevoStock.toDouble()),
      );
    } catch (e) {
      debugPrint('[PlayAppDataGateway] Error al actualizar stock: $e');
    }
  }

  // ==========================================
  // USUARIOS & AUTENTICACIÓN
  // ==========================================

  Future<List<Usuario>> fetchUsuarios() async {
    if (!isConnected) return [];
    try {
      final docs = await _db!.collection('entidades').find().toList();
      return docs.map((d) => Usuario.fromMongo(d)).toList();
    } catch (e) {
      debugPrint('[PlayAppDataGateway] Error al consultar usuarios: $e');
      return [];
    }
  }

  /// Autentica contra la colección `entidades` usando hash BCrypt (idéntico a Spring Security).
  Future<Usuario?> login(String correo, String password, RolUsuario rolEsperado) async {
    if (!isConnected) return null;

    if (kIsWeb && _isBridgeConnected) {
      try {
        final res = await http.post(
          Uri.parse('$bridgeUrl/api/login'),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode({'email': correo, 'password': password}),
        );
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          final userMap = Map<String, dynamic>.from(body['usuario'] as Map);
          final user = Usuario.fromMongo(userMap);
          if (rolEsperado == RolUsuario.admin && user.rol != RolUsuario.admin) {
            return null;
          }
          return user;
        }
        return null;
      } catch (e) {
        debugPrint('[PlayAppDataGateway] Error al autenticar por puente: $e');
        return null;
      }
    }

    if (_db == null || !_db!.isConnected) return null;
    try {
      final normEmail = correo.trim().toLowerCase();
      final doc = await _db!.collection('entidades').findOne(
        mongo.where.match('correo', '^${RegExp.escape(normEmail)}\$', caseInsensitive: true),
      );
      if (doc == null) return null;

      final user = Usuario.fromMongo(doc);
      if (user.rol != rolEsperado) return null;

      // Verificación de contraseña: soporta BCrypt o texto plano
      final dbPass = doc['password']?.toString() ?? '';
      bool match = false;
      if (dbPass.startsWith(r'$2a$') || dbPass.startsWith(r'$2b$') || dbPass.startsWith(r'$2y$')) {
        try {
          match = _dBCrypt.checkpw(password, dbPass);
        } catch (_) {
          match = false;
        }
      } else {
        match = dbPass == password;
      }

      return match ? user : null;
    } catch (e) {
      debugPrint('[PlayAppDataGateway] Error en autenticación: $e');
      return null;
    }
  }

  /// Registra una nueva cuenta en MongoDB Atlas (`entidades`) con contraseña encriptada con BCrypt.
  Future<Usuario?> registerUsuario({
    required String nombreCompleto,
    required String correo,
    required String password,
    required RolUsuario rol,
  }) async {
    if (!isConnected) return null;
    try {
      final normEmail = correo.trim().toLowerCase();
      final exists = await _db!.collection('entidades').findOne(
        mongo.where.match('correo', '^${RegExp.escape(normEmail)}\$', caseInsensitive: true),
      );
      if (exists != null) {
        throw Exception('Ya existe una cuenta con este correo.');
      }

      final hashed = _dBCrypt.hashpw(password, _dBCrypt.gensalt());
      final objId = mongo.ObjectId();
      final nuevoUsuario = Usuario(
        id: objId.oid,
        nombreCompleto: nombreCompleto.trim(),
        correo: normEmail,
        password: hashed,
        rol: rol,
      );

      final data = nuevoUsuario.toMongo();
      data['_id'] = objId;

      final res = await _db!.collection('entidades').insertOne(data);
      if (res.isSuccess) {
        return nuevoUsuario;
      }
      return null;
    } catch (e) {
      debugPrint('[PlayAppDataGateway] Error al registrar usuario: $e');
      rethrow;
    }
  }

  // ==========================================
  // PEDIDOS
  // ==========================================

  Future<List<Pedido>> fetchPedidos() async {
    if (!isConnected) return [];

    if (kIsWeb && _isBridgeConnected) {
      try {
        final res = await http.get(Uri.parse('$bridgeUrl/api/pedidos'));
        if (res.statusCode == 200) {
          final list = jsonDecode(res.body) as List<dynamic>;
          return list
              .map((d) => Pedido.fromMongo(Map<String, dynamic>.from(d as Map)))
              .toList();
        }
      } catch (e) {
        debugPrint('[PlayAppDataGateway] Error al consultar pedidos por puente: $e');
      }
      return [];
    }

    if (_db == null || !_db!.isConnected) return [];
    try {
      final docs = await _db!
          .collection('pedidos')
          .find(mongo.where.sortBy('timestamp', descending: true))
          .toList();
      return docs.map((d) => Pedido.fromMongo(d)).toList();
    } catch (e) {
      debugPrint('[PlayAppDataGateway] Error al consultar pedidos: $e');
      return [];
    }
  }

  Future<bool> savePedido(Pedido pedido) async {
    if (!isConnected) return false;

    if (kIsWeb && _isBridgeConnected) {
      try {
        final res = await http.post(
          Uri.parse('$bridgeUrl/api/pedidos'),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode(pedido.toMongo()),
        );
        return res.statusCode == 201;
      } catch (e) {
        debugPrint('[PlayAppDataGateway] Error al guardar pedido por puente: $e');
        return false;
      }
    }

    if (_db == null || !_db!.isConnected) return false;
    try {
      final col = _db!.collection('pedidos');
      final data = pedido.toMongo();

      dynamic selectorId;
      if (pedido.id.length == 24 && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(pedido.id)) {
        selectorId = mongo.ObjectId.fromHexString(pedido.id);
      } else {
        selectorId = pedido.id;
      }
      data['_id'] = selectorId;

      final res = await col.replaceOne(mongo.where.id(selectorId), data, upsert: true);

      // Descontar existencias en la base de datos de MongoDB
      for (final item in pedido.items) {
        if (item.productoId.isNotEmpty) {
          dynamic pId = item.productoId;
          if (pId.length == 24 && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(pId)) {
            pId = mongo.ObjectId.fromHexString(pId);
          }
          await _db!.collection('productos').updateOne(
            mongo.where.id(pId),
            mongo.modify.inc('stock', -item.cantidad),
          );
        }
      }

      return res.isSuccess;
    } catch (e) {
      debugPrint('[PlayAppDataGateway] Error al guardar pedido: $e');
      return false;
    }
  }

  Future<void> updatePedidoEstado(String pedidoId, EstadoPedido nuevoEstado) async {
    if (!isConnected) return;
    try {
      dynamic selectorId = pedidoId;
      if (pedidoId.length == 24 && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(pedidoId)) {
        selectorId = mongo.ObjectId.fromHexString(pedidoId);
      }
      await _db!.collection('pedidos').updateOne(
        mongo.where.id(selectorId),
        mongo.modify.set('estado', nuevoEstado.codigo),
      );
    } catch (e) {
      debugPrint('[PlayAppDataGateway] Error al actualizar estado del pedido: $e');
    }
  }

  Future<void> updatePedidoPago(String pedidoId, EstadoPago estadoPago) async {
    if (!isConnected) return;
    try {
      dynamic selectorId = pedidoId;
      if (pedidoId.length == 24 && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(pedidoId)) {
        selectorId = mongo.ObjectId.fromHexString(pedidoId);
      }
      await _db!.collection('pedidos').updateOne(
        mongo.where.id(selectorId),
        mongo.modify
            .set('pago.estado', estadoPago.codigo)
            .set('pago.fecha', DateTime.now()),
      );
    } catch (e) {
      debugPrint('[PlayAppDataGateway] Error al actualizar pago del pedido: $e');
    }
  }

  // ==========================================
  // RESEÑAS & CONTACTO
  // ==========================================

  Future<List<Resena>> fetchResenas() async {
    if (!isConnected) return [];

    if (kIsWeb && _isBridgeConnected) {
      try {
        final res = await http.get(Uri.parse('$bridgeUrl/api/resenas'));
        if (res.statusCode == 200) {
          final list = jsonDecode(res.body) as List<dynamic>;
          return list
              .map((d) => Resena.fromMongo(Map<String, dynamic>.from(d as Map)))
              .toList();
        }
      } catch (e) {
        debugPrint('[PlayAppDataGateway] Error al consultar reseñas por puente: $e');
      }
      return [];
    }

    if (_db == null || !_db!.isConnected) return [];
    try {
      final docs = await _db!
          .collection('reseñas')
          .find(mongo.where.sortBy('fecha', descending: true))
          .toList();
      return docs.map((d) => Resena.fromMongo(d)).toList();
    } catch (e) {
      debugPrint('[PlayAppDataGateway] Error al consultar reseñas: $e');
      return [];
    }
  }

  Future<bool> saveResena(Resena resena) async {
    if (!isConnected) return false;

    if (kIsWeb && _isBridgeConnected) {
      try {
        final res = await http.post(
          Uri.parse('$bridgeUrl/api/resenas'),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode(resena.toMongo()),
        );
        return res.statusCode == 201;
      } catch (e) {
        debugPrint('[PlayAppDataGateway] Error al guardar reseña por puente: $e');
        return false;
      }
    }

    if (_db == null || !_db!.isConnected) return false;
    try {
      final data = resena.toMongo();
      final res = await _db!.collection('reseñas').insertOne(data);
      return res.isSuccess;
    } catch (e) {
      debugPrint('[PlayAppDataGateway] Error al guardar reseña: $e');
      return false;
    }
  }

  Future<List<MensajeContacto>> fetchMensajes() async {
    if (!isConnected) return [];
    try {
      final docs = await _db!
          .collection('mensajes_contacto')
          .find(mongo.where.sortBy('fechaEnvio', descending: true))
          .toList();
      return docs.map((d) => MensajeContacto.fromMongo(d)).toList();
    } catch (e) {
      debugPrint('[PlayAppDataGateway] Error al consultar mensajes: $e');
      return [];
    }
  }

  Future<bool> saveMensajeContacto(MensajeContacto mensaje) async {
    if (!isConnected) return false;
    try {
      final data = mensaje.toMongo();
      final res = await _db!.collection('mensajes_contacto').insertOne(data);
      return res.isSuccess;
    } catch (e) {
      debugPrint('[PlayAppDataGateway] Error al guardar mensaje: $e');
      return false;
    }
  }

  // ==========================================
  // CHATBOT & SESIONES
  // ==========================================

  Future<void> saveChatMessage({
    required String sessionId,
    required String role,
    required String content,
  }) async {
    if (!isConnected) return;
    try {
      await _db!.collection('chat_messages').insertOne({
        'sessionId': sessionId,
        'role': role,
        'content': content,
        'timestamp': DateTime.now(),
        '_class': 'com.proyecto.PlayApp.entity.ChatMessage',
      });
    } catch (e) {
      debugPrint('[PlayAppDataGateway] Error al guardar mensaje de chat: $e');
    }
  }
}
