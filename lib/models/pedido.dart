import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../theme/playapp_theme.dart';
import 'producto.dart';

/// Estado operativo del pedido (0: Recibido, 1: En preparación, 2: Terminado).
enum EstadoPedido {
  recibido(0, 'Recibido', PlayAppColors.primaryBlue),
  enPreparacion(1, 'En preparación', PlayAppColors.warningAmber),
  terminado(2, 'Terminado', PlayAppColors.successGreen);

  const EstadoPedido(this.codigo, this.etiqueta, this.color);

  final int codigo;
  final String etiqueta;
  final Color color;

  Color get textColor =>
      this == EstadoPedido.enPreparacion ? const Color(0xFF1F2937) : Colors.white;

  static EstadoPedido fromCodigo(dynamic codigo) {
    final intCode = codigo is int
        ? codigo
        : (codigo is num ? codigo.toInt() : int.tryParse('$codigo') ?? 0);
    return EstadoPedido.values.firstWhere(
      (e) => e.codigo == intCode,
      orElse: () => EstadoPedido.recibido,
    );
  }
}

/// Estado del pago asociado al pedido (0: En espera, 1: Terminado, 2: Cancelado).
enum EstadoPago {
  enEspera(0, 'En espera', PlayAppColors.infoCyan),
  terminado(1, 'Terminado', PlayAppColors.successGreen),
  cancelado(2, 'Cancelado', PlayAppColors.dangerRed);

  const EstadoPago(this.codigo, this.etiqueta, this.color);

  final int codigo;
  final String etiqueta;
  final Color color;

  Color get textColor =>
      this == EstadoPago.enEspera ? const Color(0xFF1F2937) : Colors.white;

  static EstadoPago fromCodigo(dynamic codigo) {
    final intCode = codigo is int
        ? codigo
        : (codigo is num ? codigo.toInt() : int.tryParse('$codigo') ?? 0);
    return EstadoPago.values.firstWhere(
      (e) => e.codigo == intCode,
      orElse: () => EstadoPago.enEspera,
    );
  }
}

/// Línea de producto incluida dentro de un pedido confirmado.
class PedidoItem {
  const PedidoItem({
    required this.productoId,
    required this.nombre,
    required this.precioUnitario,
    required this.cantidad,
    required this.entidadNombre,
    this.producto,
  });

  final String productoId;
  final String nombre;
  final double precioUnitario;
  final int cantidad;
  final String entidadNombre;
  final Producto? producto;

  double get subtotal => precioUnitario * cantidad;

  factory PedidoItem.fromMongo(Map<String, dynamic> doc) {
    final prodDoc = doc['producto'] as Map<String, dynamic>?;
    final cantidad = (doc['cantidad'] as num?)?.toInt() ?? 1;

    String prodId = '';
    String prodNombre = 'Producto';
    double precio = 0.0;
    String entidad = 'PlayApp';
    Producto? fullProd;

    if (prodDoc != null) {
      fullProd = Producto.fromMongo(prodDoc);
      prodId = fullProd.id;
      prodNombre = fullProd.nombre;
      precio = fullProd.precio;
      entidad = fullProd.entidadNombre;
    } else {
      prodId = doc['productoId']?.toString() ?? '';
      prodNombre = doc['nombre']?.toString() ?? 'Producto';
      precio = (doc['precioUnitario'] as num?)?.toDouble() ??
          (doc['subtotal'] as num?)?.toDouble() ??
          0.0;
      entidad = doc['entidadNombre']?.toString() ?? 'PlayApp';
    }

    return PedidoItem(
      productoId: prodId,
      nombre: prodNombre,
      precioUnitario: precio,
      cantidad: cantidad,
      entidadNombre: entidad,
      producto: fullProd,
    );
  }

  Map<String, dynamic> toMongo() {
    return {
      'cantidad': cantidad,
      'subtotal': subtotal,
      'producto': (producto ??
              Producto(
                id: productoId,
                nombre: nombre,
                descripcion: '',
                precio: precioUnitario,
                stock: 0,
                categoria: CategoriaProducto.comida,
                imagenAsset: '',
                entidadNombre: entidadNombre,
              ))
          .toMongo(),
    };
  }
}

/// Datos de geolocalización y entrega en playa del pedido.
class Envio {
  const Envio({
    required this.latitud,
    required this.longitud,
    required this.direccion,
    required this.mesaCarpa,
    required this.descripcion,
    this.id,
    this.fecha,
    this.clienteId,
  });

  final String? id;
  final double latitud;
  final double longitud;
  final String direccion;
  final int mesaCarpa;
  final String descripcion;
  final DateTime? fecha;
  final String? clienteId;

  factory Envio.fromMongo(Map<String, dynamic> doc) {
    return Envio(
      id: doc['_id']?.toString(),
      latitud: (doc['latitud'] as num?)?.toDouble() ?? 10.3945,
      longitud: (doc['longitud'] as num?)?.toDouble() ?? -75.5571,
      direccion: doc['dirreccion']?.toString() ??
          doc['direccion']?.toString() ??
          'Bocagrande, Cartagena',
      mesaCarpa: (doc['mesa'] as num?)?.toInt() ??
          (doc['carpa'] as num?)?.toInt() ??
          (doc['mesaCarpa'] as num?)?.toInt() ??
          1,
      descripcion: doc['descripcion']?.toString() ?? '',
      fecha: doc['fecha'] is DateTime ? doc['fecha'] as DateTime : null,
      clienteId: doc['clienteId']?.toString(),
    );
  }

  Map<String, dynamic> toMongo() {
    return {
      if (id != null) '_id': id,
      'latitud': latitud,
      'longitud': longitud,
      'dirreccion': direccion,
      'descripcion': descripcion,
      'mesa': mesaCarpa,
      'carpa': mesaCarpa,
      'fecha': fecha ?? DateTime.now(),
      if (clienteId != null) 'clienteId': clienteId,
      '_class': 'com.proyecto.PlayApp.entity.Envio',
    };
  }
}

/// Información de pago vinculada al pedido.
class Pago {
  const Pago({
    required this.metodo,
    required this.valor,
    required this.estado,
    required this.fecha,
    this.id,
    this.clienteId,
  });

  final String? id;
  final String metodo;
  final double valor;
  final EstadoPago estado;
  final DateTime fecha;
  final String? clienteId;

  Pago copyWith({
    EstadoPago? estado,
    String? metodo,
    DateTime? fecha,
    double? valor,
  }) {
    return Pago(
      id: id,
      metodo: metodo ?? this.metodo,
      valor: valor ?? this.valor,
      estado: estado ?? this.estado,
      fecha: fecha ?? this.fecha,
      clienteId: clienteId,
    );
  }

  factory Pago.fromMongo(Map<String, dynamic> doc) {
    return Pago(
      id: doc['_id']?.toString(),
      metodo: doc['metodo']?.toString() ?? 'Mercado Pago',
      valor: (doc['valor'] as num?)?.toDouble() ?? 0.0,
      estado: EstadoPago.fromCodigo(doc['estado']),
      fecha: doc['fecha'] is DateTime
          ? doc['fecha'] as DateTime
          : (DateTime.tryParse('${doc['fecha']}') ?? DateTime.now()),
      clienteId: doc['clienteId']?.toString(),
    );
  }

  Map<String, dynamic> toMongo() {
    return {
      if (id != null) '_id': id,
      'metodo': metodo,
      'valor': valor,
      'estado': estado.codigo,
      'fecha': fecha,
      if (clienteId != null) 'clienteId': clienteId,
      '_class': 'com.proyecto.PlayApp.entity.Pago',
    };
  }
}

/// Pedido completo realizado en PlayApp.
class Pedido {
  const Pedido({
    required this.id,
    required this.clienteCorreo,
    required this.clienteNombre,
    required this.estado,
    required this.total,
    required this.timestamp,
    required this.items,
    required this.pago,
    required this.envio,
    this.clienteId,
    this.restaurantes = const [],
  });

  final String id;
  final String clienteCorreo;
  final String clienteNombre;
  final String? clienteId;
  final EstadoPedido estado;
  final double total;
  final DateTime timestamp;
  final List<PedidoItem> items;
  final Pago pago;
  final Envio envio;
  final List<String> restaurantes;

  Pedido copyWith({
    EstadoPedido? estado,
    Pago? pago,
  }) {
    return Pedido(
      id: id,
      clienteCorreo: clienteCorreo,
      clienteNombre: clienteNombre,
      clienteId: clienteId,
      estado: estado ?? this.estado,
      total: total,
      timestamp: timestamp,
      items: items,
      pago: pago ?? this.pago,
      envio: envio,
      restaurantes: restaurantes,
    );
  }

  /// Deserializa un documento MongoDB de la colección `pedidos`.
  factory Pedido.fromMongo(Map<String, dynamic> doc) {
    final rawId = doc['_id'];
    final id = rawId is mongo.ObjectId ? rawId.oid : '$rawId';

    // Cliente
    String correo = 'invitado@playapp.co';
    String nombre = 'Cliente PlayApp';
    String? cId;
    final cliente = doc['cliente'];
    if (cliente is Map) {
      correo = cliente['correo']?.toString() ?? correo;
      nombre = cliente['nombreCompleto']?.toString() ?? nombre;
      final rawCId = cliente['_id'];
      cId = rawCId is mongo.ObjectId ? rawCId.oid : rawCId?.toString();
    }

    // Carrito / Items
    final rawCarrito = doc['carrito'];
    final items = <PedidoItem>[];
    if (rawCarrito is List) {
      for (final item in rawCarrito) {
        if (item is Map) {
          items.add(PedidoItem.fromMongo(Map<String, dynamic>.from(item)));
        }
      }
    }

    // Pago
    final rawPago = doc['pago'];
    final pago = rawPago is Map
        ? Pago.fromMongo(Map<String, dynamic>.from(rawPago))
        : Pago(
            metodo: 'Mercado Pago',
            valor: (doc['total'] as num?)?.toDouble() ?? 0.0,
            estado: EstadoPago.enEspera,
            fecha: DateTime.now(),
          );

    // Envio
    final rawEnvio = doc['envio'];
    final envio = rawEnvio is Map
        ? Envio.fromMongo(Map<String, dynamic>.from(rawEnvio))
        : const Envio(
            latitud: 10.39459,
            longitud: -75.55711,
            direccion: 'Bocagrande, Cartagena',
            mesaCarpa: 1,
            descripcion: '',
          );

    // Restaurantes
    final rawRests = doc['restaurantes'];
    final rests = <String>[];
    if (rawRests is List) {
      for (final r in rawRests) {
        if (r != null) rests.add(r.toString());
      }
    }

    // Fecha
    final rawTime = doc['timestamp'];
    final ts = rawTime is DateTime
        ? rawTime
        : (DateTime.tryParse('$rawTime') ?? DateTime.now());

    return Pedido(
      id: id,
      clienteCorreo: correo,
      clienteNombre: nombre,
      clienteId: cId,
      estado: EstadoPedido.fromCodigo(doc['estado']),
      total: (doc['total'] as num?)?.toDouble() ?? 0.0,
      timestamp: ts,
      items: items,
      pago: pago,
      envio: envio,
      restaurantes: rests,
    );
  }

  /// Serializa a formato documento para MongoDB en la colección `pedidos`.
  Map<String, dynamic> toMongo() {
    final doc = <String, dynamic>{
      'estado': estado.codigo,
      'total': total,
      'timestamp': timestamp,
      'carrito': items.map((i) => i.toMongo()).toList(),
      'restaurantes': restaurantes,
      'cliente': {
        if (clienteId != null) '_id': clienteId,
        'nombreCompleto': clienteNombre,
        'correo': clienteCorreo,
        'rol': 'ROLE_USER',
      },
      'pago': pago.toMongo(),
      'envio': envio.toMongo(),
      '_class': 'com.proyecto.PlayApp.entity.Pedido',
    };

    if (id.length == 24 && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id)) {
      doc['_id'] = mongo.ObjectId.fromHexString(id);
    } else {
      doc['_id'] = id;
    }

    return doc;
  }
}
