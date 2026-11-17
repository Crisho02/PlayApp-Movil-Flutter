import 'package:flutter/material.dart';
import '../core/config/env_config.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/product_model.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItemModel> _items = {};

  Map<String, CartItemModel> get items => _items;
  List<CartItemModel> get itemsList => _items.values.toList();

  int get itemCount {
    int count = 0;
    _items.forEach((key, item) {
      count += item.cantidad;
    });
    return count;
  }

  double get subtotal {
    double total = 0.0;
    _items.forEach((key, item) {
      total += item.subtotal;
    });
    return total;
  }

  double get shippingFee {
    if (_items.isEmpty) return 0.0;
    return EnvConfig.standardDeliveryFee;
  }

  double get total {
    if (_items.isEmpty) return 0.0;
    return subtotal + shippingFee;
  }

  bool get isEmpty => _items.isEmpty;

  void addToCart(ProductModel product, {int quantity = 1}) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.cantidad += quantity;
    } else {
      _items[product.id] = CartItemModel.fromProduct(product, cantidad: quantity);
    }
    notifyListeners();
    _syncAdd(product.id, quantity);
  }

  void updateQuantity(String productId, int newQuantity) {
    if (!_items.containsKey(productId)) return;

    if (newQuantity <= 0) {
      _items.remove(productId);
      _syncRemove(productId);
    } else {
      _items[productId]!.cantidad = newQuantity;
      _syncUpdate(productId, newQuantity);
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    if (_items.containsKey(productId)) {
      _items.remove(productId);
      notifyListeners();
      _syncRemove(productId);
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
    _syncClear();
  }

  // Sincronizaciones silenciosas con backend
  void _syncAdd(String productId, int quantity) {
    ApiClient.post(ApiEndpoints.cartAdd, body: {
      'productoId': productId,
      'cantidad': quantity,
    }).catchError((_) => ApiResponse(success: false, statusCode: 0));
  }

  void _syncUpdate(String productId, int quantity) {
    ApiClient.post(ApiEndpoints.cartUpdate, body: {
      'productoId': productId,
      'cantidad': quantity,
    }).catchError((_) => ApiResponse(success: false, statusCode: 0));
  }

  void _syncRemove(String productId) {
    ApiClient.post(ApiEndpoints.cartRemove, body: {
      'productoId': productId,
    }).catchError((_) => ApiResponse(success: false, statusCode: 0));
  }

  void _syncClear() {
    ApiClient.post(ApiEndpoints.cartClear).catchError((_) => ApiResponse(success: false, statusCode: 0));
  }
}
