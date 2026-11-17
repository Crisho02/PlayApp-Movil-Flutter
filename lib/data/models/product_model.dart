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
    return ProductModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? 'Producto',
      descripcion: json['descripcion']?.toString() ?? '',
      precio: (json['precio'] is num) ? (json['precio'] as num).toDouble() : 0.0,
      cantidadDisponible: (json['cantidadDisponible'] is num)
          ? (json['cantidadDisponible'] as num).toInt()
          : 0,
      categoriaId: (json['categoriaId'] is num)
          ? (json['categoriaId'] as num).toInt()
          : 1,
      categoriaNombre: json['categoriaNombre']?.toString() ?? 'Comidas',
      hasImage: json['hasImage'] == true,
      imagenUrl: json['imagenUrl']?.toString(),
      imagenSrc: json['imagenSrc']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'cantidadDisponible': cantidadDisponible,
      'categoriaId': categoriaId,
      'categoriaNombre': categoriaNombre,
      'hasImage': hasImage,
      'imagenUrl': imagenUrl,
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
    return null;
  }
}
