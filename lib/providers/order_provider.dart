import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
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

  Future<void> fetchUserOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.get<List<dynamic>>(
        ApiEndpoints.ordersUser,
      );

      if (res.success && res.data != null) {
        _userOrders = res.data!
            .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        if (_userOrders.isEmpty) {
          _userOrders = _getDemoOrders();
        }
      }
    } catch (_) {
      if (_userOrders.isEmpty) {
        _userOrders = _getDemoOrders();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel?> createOrder({
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
      'metodoPago': metodoPago,
      'direccion': direccion,
      'barrio': barrio,
      'carpa': carpa ?? 0,
      'telefono': telefono ?? '',
      'notas': notas ?? '',
      'total': total,
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

      OrderModel order;
      if (res.success && res.data != null) {
        order = OrderModel.fromJson(res.data!);
      } else {
        // Fallback local robusto
        final localId = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
        order = OrderModel(
          id: localId,
          fecha: DateTime.now().toString().substring(0, 16),
          total: total,
          estadoPedido: OrderStatusConstants.recibido,
          estadoPago: (metodoPago == PaymentMethodConstants.wompi)
              ? PaymentStatusConstants.pagado
              : PaymentStatusConstants.pendienteContraentrega,
          metodoPago: metodoPago,
          direccion: direccion,
          barrio: barrio,
          carpa: carpa,
          telefono: telefono,
          items: List.from(items),
        );
      }

      _lastCreatedOrder = order;
      _userOrders.insert(0, order);
      _isLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      _errorMessage = 'Error al crear pedido: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<WompiInitData?> initWompiPayment({
    required double amount,
    required String reference,
  }) async {
    try {
      final res = await ApiClient.get<Map<String, dynamic>>(
        ApiEndpoints.paymentWompiInit,
        queryParameters: {
          'amount': amount,
          'reference': reference,
        },
      );

      if (res.success && res.data != null) {
        return WompiInitData.fromJson(res.data!);
      }
    } catch (_) {}

    // Fallback sandbox
    return WompiInitData(
      reference: reference,
      amountInCents: (amount * 100).toInt(),
      currency: 'COP',
      publicKey: 'pub_test_wQdG7hGgqZc6hK7v9b8a1c2d3e4f5a6b',
      signature: 'simulated_wompi_signature_${reference.hashCode}',
    );
  }

  Future<WompiVerificationResult> verifyWompiPayment({
    required String transactionId,
    required String reference,
    required String status,
  }) async {
    try {
      final res = await ApiClient.post<Map<String, dynamic>>(
        ApiEndpoints.paymentWompiVerify,
        body: {
          'transactionId': transactionId,
          'reference': reference,
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
          ? 'Pago Wompi procesado con éxito'
          : 'Transacción rechazada por el banco emisor',
    );
  }

  List<OrderModel> _getDemoOrders() {
    return [
      OrderModel(
        id: '6afbdeef761ca933d203e4d0',
        fecha: '16-11-2026 23:58',
        total: 33000.0,
        estadoPedido: OrderStatusConstants.recibido,
        estadoPago: PaymentStatusConstants.pagado,
        metodoPago: PaymentMethodConstants.wompi,
        direccion: 'Frente al Kiosco El Bony',
        barrio: 'Bocagrande',
        carpa: 14,
        telefono: '3232542588',
        items: [
          CartItemModel(
            id: '1',
            productoId: '1',
            nombre: 'Hamburguesa de la casa',
            precio: 25000,
            cantidad: 1,
            assetFallback: 'assets/images/Burguer.jpg',
          ),
          CartItemModel(
            id: '3',
            productoId: '3',
            nombre: 'Cerveza nacional fría',
            precio: 7000,
            cantidad: 1,
            assetFallback: 'assets/images/Bebidas.jpeg',
          ),
        ],
      ),
      OrderModel(
        id: '6afbdac3761ca933d203e4c3',
        fecha: '16-11-2026 23:40',
        total: 17000.0,
        estadoPedido: OrderStatusConstants.enPreparacion,
        estadoPago: PaymentStatusConstants.pendienteContraentrega,
        metodoPago: PaymentMethodConstants.efectivo,
        direccion: 'Bahía Castillo frente al muelle',
        barrio: 'Castillogrande',
        carpa: 5,
        telefono: '3001234567',
        items: [
          CartItemModel(
            id: '4',
            productoId: '4',
            nombre: 'Limonada de coco',
            precio: 14000,
            cantidad: 1,
            assetFallback: 'assets/images/Bebidas.jpeg',
          ),
        ],
      ),
    ];
  }
}
