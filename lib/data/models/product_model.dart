import '../../core/config/env_config.dart';

class ProductModel {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int cantidadDisponible;
  final int categoriaId;
  final String categoriaNombre;
  final bool hasImage;
  final String? imagenUrl;
  final String? imagenSrc;

  ProductModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.cantidadDisponible,
    required this.categoriaId,
    required this.categoriaNombre,
    this.hasImage = false,
    this.imagenUrl,
    this.imagenSrc,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final prodId = json['id']?.toString() ?? '';
    final rawStock = json['stock'] ?? json['cantidadDisponible'] ?? 0;
    final stockInt = (rawStock is num) ? rawStock.toInt() : 0;

    final rawCat = json['categoria'] ?? json['categoriaId'] ?? json['tipo'] ?? 1;
    final catId = (rawCat is num) ? rawCat.toInt() : 1;

    final rawImageSrc = json['imageSRC']?.toString() ?? json['imagenSrc']?.toString();
    final hasImg = json['hasCustomImage'] == true || json['hasImage'] == true || (rawImageSrc != null && rawImageSrc.isNotEmpty);

    final rawImgUrl = json['imagenUrl']?.toString() ??
        (hasImg && prodId.isNotEmpty ? '${EnvConfig.apiBaseUrl}/api/products/$prodId/image' : null);

    return ProductModel(
      id: prodId,
      nombre: json['nombre']?.toString() ?? 'Producto de Playa',
      descripcion: json['descripcion']?.toString() ?? '',
      precio: (json['precio'] is num) ? (json['precio'] as num).toDouble() : 0.0,
      cantidadDisponible: stockInt,
      categoriaId: catId,
      categoriaNombre: json['categoriaNombre']?.toString() ?? (catId == 2 ? 'Bebida' : (catId == 3 ? 'Servicio' : 'Comida')),
      hasImage: hasImg,
      imagenUrl: rawImgUrl,
      imagenSrc: rawImageSrc,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'stock': cantidadDisponible,
      'cantidadDisponible': cantidadDisponible,
      'categoria': categoriaId,
      'categoriaId': categoriaId,
      'categoriaNombre': categoriaNombre,
      'hasImage': hasImage,
      'imagenUrl': imagenUrl,
      'imageSRC': imagenSrc,
      'imagenSrc': imagenSrc,
    };
  }

  bool get isAvailable => cantidadDisponible > 0;

  /// Retorna la ruta del asset local si coincide con algún producto conocido de PlayApp
  String? get localAssetFallback {
    final lower = nombre.toLowerCase();
    if (lower.contains('hamburguesa') || lower.contains('burguer')) {
      return 'assets/images/Burguer.jpg';
    }
    if (lower.contains('pescado') || lower.contains('mojarra') || lower.contains('corvina')) {
      return 'assets/images/Pescado.jpg';
    }
    if (lower.contains('cerveza') || lower.contains('bebida') || lower.contains('limonada') || lower.contains('jugo') || lower.contains('agua') || lower.contains('gaseosa')) {
      return 'assets/images/Bebidas.jpeg';
    }
    if (lower.contains('arepa')) {
      return 'assets/images/catalogo/arepa-huevo.jpg';
    }
    if (lower.contains('arroz')) {
      return 'assets/images/catalogo/arroz-coco.jpg';
    }
    if (lower.contains('ceviche')) {
      return 'assets/images/catalogo/ceviche-camaron.webp';
    }
    if (lower.contains('coco')) {
      return 'assets/images/catalogo/coco-frio.jpg';
    }
    if (lower.contains('patacon')) {
      return 'assets/images/catalogo/patacones-hogao.jpg';
    }
    return 'assets/images/blank-product.jpg';
  }
}
