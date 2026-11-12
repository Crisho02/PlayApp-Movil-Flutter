import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../theme/playapp_theme.dart';

/// Categorías del catálogo costero de PlayApp (1: Comida, 2: Bebida, 3: Servicio).
enum CategoriaProducto {
  comida(1, 'Comida', PlayAppColors.primaryBlue),
  bebida(2, 'Bebida', PlayAppColors.warningAmber),
  servicio(3, 'Servicio', PlayAppColors.successGreen);

  const CategoriaProducto(this.codigo, this.etiqueta, this.badgeColor);

  final int codigo;
  final String etiqueta;
  final Color badgeColor;

  Color get textColor =>
      this == CategoriaProducto.bebida ? const Color(0xFF1F2937) : Colors.white;

  static CategoriaProducto fromCodigo(dynamic codigo) {
    final intCode = codigo is int
        ? codigo
        : (codigo is num ? codigo.toInt() : int.tryParse('$codigo') ?? 1);
    return CategoriaProducto.values.firstWhere(
      (c) => c.codigo == intCode,
      orElse: () => CategoriaProducto.comida,
    );
  }
}

/// Representa un producto o servicio disponible en la tienda PlayApp.
class Producto {
  const Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.stock,
    required this.categoria,
    required this.imagenAsset,
    required this.entidadNombre,
    this.tipo = 1,
    this.imagenBytes,
    this.imagenContentType,
    this.entidadId,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int stock;
  final CategoriaProducto categoria;
  final String imagenAsset;
  final String entidadNombre;
  final int tipo;
  final Uint8List? imagenBytes;
  final String? imagenContentType;
  final String? entidadId;

  Producto copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    double? precio,
    int? stock,
    CategoriaProducto? categoria,
    String? imagenAsset,
    String? entidadNombre,
    int? tipo,
    Uint8List? imagenBytes,
    String? imagenContentType,
    String? entidadId,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      stock: stock ?? this.stock,
      categoria: categoria ?? this.categoria,
      imagenAsset: imagenAsset ?? this.imagenAsset,
      entidadNombre: entidadNombre ?? this.entidadNombre,
      tipo: tipo ?? this.tipo,
      imagenBytes: imagenBytes ?? this.imagenBytes,
      imagenContentType: imagenContentType ?? this.imagenContentType,
      entidadId: entidadId ?? this.entidadId,
    );
  }

  /// Construye el widget de imagen apropiado (binaria de MongoDB o recurso local de catálogo).
  Widget buildImageWidget({
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imagenBytes != null && imagenBytes!.isNotEmpty) {
      return Image.memory(
        imagenBytes!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _fallbackAssetImage(width, height, fit),
      );
    }
    return _fallbackAssetImage(width, height, fit);
  }

  Widget _fallbackAssetImage(double? width, double? height, BoxFit fit) {
    return Image.asset(
      imagenAsset.isNotEmpty
          ? imagenAsset
          : 'assets/images/catalogo/pescado-frito.jpg',
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => Container(
        width: width,
        height: height,
        color: const Color(0xFFE5E7EB),
        child: const Icon(Icons.beach_access, color: PlayAppColors.mutedText),
      ),
    );
  }

  /// Deserializa un documento MongoDB de la colección `productos`.
  factory Producto.fromMongo(Map<String, dynamic> doc) {
    final rawId = doc['_id'];
    final id = rawId is mongo.ObjectId ? rawId.oid : '$rawId';

    final nombre = doc['nombre']?.toString() ?? 'Producto';
    final descripcion = doc['descripcion']?.toString() ?? '';
    final precio = (doc['precio'] as num?)?.toDouble() ?? 0.0;
    final stock = (doc['stock'] as num?)?.toInt() ?? 0;
    final tipo = (doc['tipo'] as num?)?.toInt() ?? 1;
    final categoria = CategoriaProducto.fromCodigo(doc['categoria']);

    // Extracción de imagen binaria (BsonBinary en mongo_dart)
    Uint8List? bytes;
    final rawImg = doc['imagen'];
    if (rawImg is mongo.BsonBinary) {
      bytes = Uint8List.fromList(rawImg.byteList);
    } else if (rawImg is List<int>) {
      bytes = Uint8List.fromList(rawImg);
    } else if (rawImg is String && rawImg.startsWith('data:')) {
      final comma = rawImg.indexOf(',');
      if (comma != -1) {
        bytes = base64Decode(rawImg.substring(comma + 1));
      }
    }

    final imagenContentType = doc['imagenContentType']?.toString();

    // Mapeo de entidad/vendedor
    String entidadNombre = 'PlayApp';
    String? entidadId;
    final entidad = doc['entidad'];
    if (entidad is Map) {
      entidadNombre = entidad['nombreCompleto']?.toString() ?? 'PlayApp';
      final eId = entidad['_id'];
      entidadId = eId is mongo.ObjectId ? eId.oid : eId?.toString();
    }

    // Asset local fallback basado en nombre o categoría
    final fallbackAsset = _resolveFallbackAsset(nombre, categoria);

    return Producto(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      precio: precio,
      stock: stock,
      categoria: categoria,
      imagenAsset: fallbackAsset,
      entidadNombre: entidadNombre,
      tipo: tipo,
      imagenBytes: bytes,
      imagenContentType: imagenContentType,
      entidadId: entidadId,
    );
  }

  /// Convierte el producto a documento compatible con Spring Data MongoDB (`com.proyecto.PlayApp.entity.Producto`).
  Map<String, dynamic> toMongo() {
    final doc = <String, dynamic>{
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'stock': stock.toDouble(),
      'tipo': tipo,
      'categoria': categoria.codigo,
      '_class': 'com.proyecto.PlayApp.entity.Producto',
    };

    if (id.length == 24 && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id)) {
      doc['_id'] = mongo.ObjectId.fromHexString(id);
    } else {
      doc['_id'] = id;
    }

    if (imagenBytes != null && imagenBytes!.isNotEmpty) {
      doc['imagen'] = mongo.BsonBinary.from(imagenBytes!);
      doc['imagenContentType'] = imagenContentType ?? 'image/jpeg';
    }

    if (entidadId != null || entidadNombre.isNotEmpty) {
      doc['entidad'] = {
        if (entidadId != null) '_id': entidadId,
        'nombreCompleto': entidadNombre,
        'rol': 'ROLE_ADMIN',
      };
    }

    return doc;
  }

  static String _resolveFallbackAsset(
    String nombre,
    CategoriaProducto categoria,
  ) {
    final norm = nombre.toLowerCase();
    if (norm.contains('pescado') || norm.contains('frito')) {
      return 'assets/images/catalogo/pescado-frito.jpg';
    }
    if (norm.contains('mojarra')) {
      return 'assets/images/catalogo/mojarra-patacones.webp';
    }
    if (norm.contains('ceviche') || norm.contains('camaron')) {
      return 'assets/images/catalogo/ceviche-camaron.webp';
    }
    if (norm.contains('arepa')) {
      return 'assets/images/catalogo/arepa-huevo.jpg';
    }
    if (norm.contains('arroz') || norm.contains('coco')) {
      return 'assets/images/catalogo/arroz-coco.jpg';
    }
    if (norm.contains('patacon')) {
      return 'assets/images/catalogo/patacones-hogao.jpg';
    }
    if (norm.contains('limonada')) {
      return 'assets/images/catalogo/limonada-coco.jpg';
    }
    if (norm.contains('coco frio') || norm.contains('coco')) {
      return 'assets/images/catalogo/coco-frio.jpg';
    }
    if (norm.contains('maracuya') || norm.contains('jugo')) {
      return 'assets/images/catalogo/jugo-maracuya.jpg';
    }
    if (norm.contains('cerveza') || norm.contains('club')) {
      return 'assets/images/catalogo/cerveza-nacional.webp';
    }
    if (norm.contains('moto')) {
      return 'assets/images/Moto.png';
    }
    if (norm.contains('hamburguesa')) {
      return 'assets/images/Burguer.jpg';
    }
    return switch (categoria) {
      CategoriaProducto.comida => 'assets/images/catalogo/pescado-frito.jpg',
      CategoriaProducto.bebida => 'assets/images/catalogo/limonada-coco.jpg',
      CategoriaProducto.servicio => 'assets/images/ArenaDemas.jpg',
    };
  }
}
