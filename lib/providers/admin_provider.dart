import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/storage/session_manager.dart';
import '../data/models/order_model.dart';

class AdminProvider extends ChangeNotifier {
  List<OrderModel> _adminOrders = [];
  Map<String, dynamic> _metrics = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<OrderModel> get adminOrders => _adminOrders;
  Map<String, dynamic> get metrics => _metrics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? _getAdminEmail() {
    return SessionManager.getUser()?.email ?? 'adminplayapp01@gmail.com';
  }

  Future<void> fetchAdminData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.wait([
      fetchAdminOrders(),
      fetchMetrics(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAdminOrders() async {
    final correo = _getAdminEmail();
    if (correo == null) return;

    try {
      final res = await ApiClient.get<dynamic>(
        ApiEndpoints.adminOrders,
        queryParameters: {'correo': correo},
      );

      if (res.success && res.data != null) {
        List<dynamic> list = [];
        if (res.data is Map && (res.data as Map).containsKey('pedidos')) {
          list = res.data['pedidos'] as List<dynamic>;
        } else if (res.data is List) {
          list = res.data as List<dynamic>;
        }

        _adminOrders = list
            .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = res.message;
      }
    } catch (_) {}
  }

  Future<void> fetchMetrics() async {
    final correo = _getAdminEmail();
    if (correo == null) return;

    try {
      final res = await ApiClient.get<Map<String, dynamic>>(
        ApiEndpoints.adminMetrics,
        queryParameters: {'correo': correo},
      );

      if (res.success && res.data != null) {
        _metrics = res.data!;
      }
    } catch (_) {}
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    final correo = _getAdminEmail();
    int estadoNum = 0;
    if (newStatus.contains('preparaci')) estadoNum = 1;
    if (newStatus.contains('terminado')) estadoNum = 2;
    if (newStatus.contains('cancelado')) estadoNum = 3;

    try {
      final res = await ApiClient.post(
        ApiEndpoints.adminOrderStatus(orderId),
        body: {
          'correo': correo,
          'estado': estadoNum,
          'estadoNombre': newStatus,
        },
      );

      final idx = _adminOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        final current = _adminOrders[idx];
        _adminOrders[idx] = OrderModel(
          id: current.id,
          fecha: current.fecha,
          total: current.total,
          subtotal: current.subtotal,
          costoEnvio: current.costoEnvio,
          estadoPedido: newStatus,
          estadoPago: current.estadoPago,
          metodoPago: current.metodoPago,
          direccion: current.direccion,
          barrio: current.barrio,
          carpa: current.carpa,
          telefono: current.telefono,
          clienteNombre: current.clienteNombre,
          clienteEmail: current.clienteEmail,
          items: current.items,
        );
        notifyListeners();
      }
      return res.success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markOrderAsPaid(String orderId) async {
    final correo = _getAdminEmail();

    try {
      final res = await ApiClient.post(
        ApiEndpoints.adminOrderMarkPaid(orderId),
        body: {'correo': correo},
      );

      final idx = _adminOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        final current = _adminOrders[idx];
        _adminOrders[idx] = OrderModel(
          id: current.id,
          fecha: current.fecha,
          total: current.total,
          subtotal: current.subtotal,
          costoEnvio: current.costoEnvio,
          estadoPedido: current.estadoPedido,
          estadoPago: PaymentStatusConstants.pagado,
          metodoPago: current.metodoPago,
          direccion: current.direccion,
          barrio: current.barrio,
          carpa: current.carpa,
          telefono: current.telefono,
          clienteNombre: current.clienteNombre,
          clienteEmail: current.clienteEmail,
          items: current.items,
        );
        notifyListeners();
      }
      return res.success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createProduct({
    required String nombre,
    required String descripcion,
    required double precio,
    required int cantidad,
    required int categoriaId,
  }) async {
    final correo = _getAdminEmail();

    try {
      final res = await ApiClient.post(
        ApiEndpoints.adminProducts,
        body: {
          'correo': correo,
          'nombre': nombre,
          'descripcion': descripcion,
          'precio': precio,
          'stock': cantidad,
          'categoria': categoriaId,
        },
      );
      return res.success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateProduct({
    required String id,
    required String nombre,
    required String descripcion,
    required double precio,
    required int cantidad,
    required int categoriaId,
  }) async {
    final correo = _getAdminEmail();

    try {
      final res = await ApiClient.put(
        ApiEndpoints.adminProductDetail(id),
        body: {
          'correo': correo,
          'nombre': nombre,
          'descripcion': descripcion,
          'precio': precio,
          'stock': cantidad,
          'categoria': categoriaId,
        },
      );
      return res.success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    final correo = _getAdminEmail();

    try {
      final res = await ApiClient.delete(
        ApiEndpoints.adminProductDetail(id),
        queryParameters: {'correo': correo},
      );
      return res.success;
    } catch (_) {
      return false;
    }
  }
}
