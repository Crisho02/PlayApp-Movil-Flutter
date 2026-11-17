import 'product_model.dart';

class CartItemModel {
  final String id;
  final String productoId;
  final String nombre;
  final double precio;
  int cantidad;
  final String? imagenUrl;
  final String? imagenSrc;
  final String? assetFallback;

  CartItemModel({
    required this.id,
    required this.productoId,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    this.imagenUrl,
    this.imagenSrc,
    this.assetFallback,
  });

  double get subtotal => precio * cantidad;

  factory CartItemModel.fromProduct(ProductModel product, {int cantidad = 1}) {
    return CartItemModel(
      id: product.id,
      productoId: product.id,
      nombre: product.nombre,
      precio: product.precio,
      cantidad: cantidad,
      imagenUrl: product.imagenUrl,
      imagenSrc: product.imagenSrc,
      assetFallback: product.localAssetFallback,
    );
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id']?.toString() ?? json['productoId']?.toString() ?? '',
      productoId: json['productoId']?.toString() ?? json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? 'Producto',
      precio: (json['precio'] is num) ? (json['precio'] as num).toDouble() : 0.0,
      cantidad: (json['cantidad'] is num) ? (json['cantidad'] as num).toInt() : 1,
      imagenUrl: json['imagenUrl']?.toString(),
      imagenSrc: json['imagenSrc']?.toString(),
      assetFallback: json['assetFallback']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productoId': productoId,
      'nombre': nombre,
      'precio': precio,
      'cantidad': cantidad,
      'subtotal': subtotal,
      'imagenUrl': imagenUrl,
      'imagenSrc': imagenSrc,
      'assetFallback': assetFallback,
    };
  }

  CartItemModel copyWith({
    String? id,
    String? productoId,
    String? nombre,
    double? precio,
    int? cantidad,
    String? imagenUrl,
    String? imagenSrc,
    String? assetFallback,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      cantidad: cantidad ?? this.cantidad,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      imagenSrc: imagenSrc ?? this.imagenSrc,
      assetFallback: assetFallback ?? this.assetFallback,
    );
  }
}
