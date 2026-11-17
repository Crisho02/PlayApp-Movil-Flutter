import 'package:flutter/material.dart';
import '../core/config/env_config.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/order_model.dart';
import '../data/models/wompi_models.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel> _userOrders = [];
  bool _isLoading = false;
  String? _errorMessage;
  OrderModel? _lastCreatedOrder;

  List<OrderModel> get userOrders => _userOrders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  OrderModel? get lastCreatedOrder => _lastCreatedOrder;

  Future<void> fetchUserOrders(String? userEmail) async {
    if (userEmail == null || userEmail.trim().isEmpty) {
      _userOrders = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.get<List<dynamic>>(
        ApiEndpoints.ordersUser,
        queryParameters: {'correo': userEmail.trim()},
      );

      if (res.success && res.data != null) {
        _userOrders = res.data!
            .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = res.message;
      }
    } catch (_) {
      _errorMessage = 'No se pudieron sincronizar los pedidos.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel?> fetchOrderDetail(String orderId) async {
    try {
      final res = await ApiClient.get<Map<String, dynamic>>(
        ApiEndpoints.orderDetail(orderId),
      );

      if (res.success && res.data != null) {
        return OrderModel.fromJson(res.data!);
      }
    } catch (_) {}
    return null;
  }

  Future<OrderModel?> createOrder({
    required String correo,
    required String metodoPago,
    required String direccion,
    required String barrio,
    required int? carpa,
    required String? telefono,
    required String? notas,
    required double total,
    required List<CartItemModel> items,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final orderPayload = {
      'correo': correo.trim(),
      'metodoPago': metodoPago,
      'direccion': direccion,
      'zona': barrio,
      'barrio': barrio,
      'referencia': notas ?? '',
      'carpa': carpa ?? 1,
      'mesa': carpa ?? 1,
      'telefono': telefono ?? '',
      'items': items.map((i) => {
        'productoId': i.productoId,
        'nombre': i.nombre,
        'precio': i.precio,
        'cantidad': i.cantidad,
      }).toList(),
    };

    try {
      final res = await ApiClient.post<Map<String, dynamic>>(
        ApiEndpoints.ordersCreate,
        body: orderPayload,
      );

      if (res.success && res.data != null) {
        final order = OrderModel.fromJson(res.data!);
        _lastCreatedOrder = order;
        _userOrders.insert(0, order);
        _isLoading = false;
        notifyListeners();
        return order;
      } else {
        _errorMessage = res.message ?? 'No fue posible crear el pedido.';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (_) {
      _errorMessage = 'Error de conexión al procesar el pedido.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<WompiInitData?> initWompiPayment({
    required String orderId,
    required double amount,
  }) async {
    try {
      final res = await ApiClient.get<Map<String, dynamic>>(
        ApiEndpoints.paymentWompiInit,
        queryParameters: {
          'ordenId': orderId,
          'valor': amount,
        },
      );

      if (res.success && res.data != null) {
        return WompiInitData.fromJson(res.data!);
      }
    } catch (_) {}

    return WompiInitData(
      reference: 'WOMPI_${DateTime.now().millisecondsSinceEpoch}',
      amountInCents: (amount * 100).toInt(),
      currency: 'COP',
      publicKey: EnvConfig.wompiPublicKey,
      signature: 'wompi_signature',
    );
  }

  Future<WompiVerificationResult> verifyWompiPayment({
    required String transactionId,
    required String orderId,
    required String status,
  }) async {
    try {
      final res = await ApiClient.post<Map<String, dynamic>>(
        ApiEndpoints.paymentWompiVerify,
        body: {
          'transaccionId': transactionId,
          'ordenId': orderId,
          'status': status,
        },
      );

      if (res.success && res.data != null) {
        return WompiVerificationResult.fromJson(res.data!);
      }
    } catch (_) {}

    return WompiVerificationResult(
      status: status,
      message: status.toUpperCase() == 'APPROVED'
          ? 'Pago procesado exitosamente.'
          : 'Transacción no aprobada por la entidad financiera.',
      orderId: orderId,
    );
  }
}
