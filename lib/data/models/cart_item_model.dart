import '../../core/utils/image_helper.dart';
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
  String? get imageSrc => imagenSrc;

  factory CartItemModel.fromProduct(ProductModel product, {int cantidad = 1}) {
    return CartItemModel(
      id: product.id,
      productoId: product.id,
      nombre: product.nombre,
      precio: product.precio,
      cantidad: cantidad,
      imagenUrl: product.imagenUrl ?? ImageHelper.productImageUrl(product.id),
      imagenSrc: product.imagenSrc,
      assetFallback: product.localAssetFallback,
    );
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? prodMap;
    if (json['producto'] is Map<String, dynamic>) {
      prodMap = json['producto'] as Map<String, dynamic>;
    } else if (json['producto'] is Map) {
      prodMap = Map<String, dynamic>.from(json['producto'] as Map);
    }

    final pId = prodMap?['id']?.toString() ??
        prodMap?['_id']?.toString() ??
        json['productoId']?.toString() ??
        json['id']?.toString() ??
        '';

    final name = prodMap?['nombre']?.toString() ??
        json['nombre']?.toString() ??
        'Producto';

    final rawPrice = prodMap?['precio'] ??
        json['precioUnitario'] ??
        json['precio'] ??
        0.0;
    final price = (rawPrice is num) ? rawPrice.toDouble() : 0.0;

    final rawCant = json['cantidad'] ?? prodMap?['cantidad'] ?? 1;
    final cant = (rawCant is num) ? rawCant.toInt() : 1;

    final rawImageSrc = prodMap?['imageSRC']?.toString() ??
        prodMap?['imagenSrc']?.toString() ??
        prodMap?['imagen']?.toString() ??
        json['imageSRC']?.toString() ??
        json['imagenSrc']?.toString();

    final rawImageUrl = prodMap?['imageUrl']?.toString() ??
        prodMap?['imagenUrl']?.toString() ??
        json['imagenUrl']?.toString() ??
        (pId.isNotEmpty ? ImageHelper.productImageUrl(pId) : null);

    final assetFallback = prodMap?['assetFallback']?.toString() ??
        json['assetFallback']?.toString() ??
        ProductModel.inferAssetFallback(name);

    return CartItemModel(
      id: json['id']?.toString() ?? pId,
      productoId: pId,
      nombre: name,
      precio: price,
      cantidad: cant,
      imagenUrl: rawImageUrl,
      imagenSrc: rawImageSrc,
      assetFallback: assetFallback,
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
