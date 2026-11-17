import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
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
    try {
      final res = await ApiClient.get<List<dynamic>>(
        ApiEndpoints.adminOrders,
      );

      if (res.success && res.data != null) {
        _adminOrders = res.data!
            .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        if (_adminOrders.isEmpty) {
          _adminOrders = _getDemoAdminOrders();
        }
      }
    } catch (_) {
      if (_adminOrders.isEmpty) {
        _adminOrders = _getDemoAdminOrders();
      }
    }
  }

  Future<void> fetchMetrics() async {
    try {
      final res = await ApiClient.get<Map<String, dynamic>>(
        ApiEndpoints.adminMetrics,
      );

      if (res.success && res.data != null) {
        _metrics = res.data!;
      } else {
        _metrics = _getDemoMetrics();
      }
    } catch (_) {
      _metrics = _getDemoMetrics();
    }
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final res = await ApiClient.post(
        ApiEndpoints.adminOrderStatus(orderId),
        body: {'estado': newStatus},
      );

      // Actualizar localmente de inmediato
      final idx = _adminOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        final current = _adminOrders[idx];
        _adminOrders[idx] = OrderModel(
          id: current.id,
          fecha: current.fecha,
          total: current.total,
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
      final idx = _adminOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        final current = _adminOrders[idx];
        _adminOrders[idx] = OrderModel(
          id: current.id,
          fecha: current.fecha,
          total: current.total,
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
      return true;
    }
  }

  Future<bool> markOrderAsPaid(String orderId) async {
    try {
      final res = await ApiClient.post(
        ApiEndpoints.adminOrderMarkPaid(orderId),
      );

      final idx = _adminOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        final current = _adminOrders[idx];
        _adminOrders[idx] = OrderModel(
          id: current.id,
          fecha: current.fecha,
          total: current.total,
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
      final idx = _adminOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        final current = _adminOrders[idx];
        _adminOrders[idx] = OrderModel(
          id: current.id,
          fecha: current.fecha,
          total: current.total,
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
      return true;
    }
  }

  Future<bool> createProduct({
    required String nombre,
    required String descripcion,
    required double precio,
    required int cantidad,
    required int categoriaId,
  }) async {
    try {
      final res = await ApiClient.post(
        ApiEndpoints.adminProducts,
        body: {
          'nombre': nombre,
          'descripcion': descripcion,
          'precio': precio,
          'cantidadDisponible': cantidad,
          'categoriaId': categoriaId,
        },
      );
      return res.success;
    } catch (_) {
      return true;
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
    try {
      final res = await ApiClient.put(
        ApiEndpoints.adminProductDetail(id),
        body: {
          'nombre': nombre,
          'descripcion': descripcion,
          'precio': precio,
          'cantidadDisponible': cantidad,
          'categoriaId': categoriaId,
        },
      );
      return res.success;
    } catch (_) {
      return true;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      final res = await ApiClient.delete(
        ApiEndpoints.adminProductDetail(id),
      );
      return res.success;
    } catch (_) {
      return true;
    }
  }

  List<OrderModel> _getDemoAdminOrders() {
    return [
      OrderModel(
        id: '6afbdeef761ca933d203e4d0',
        fecha: '16-11-2026 23:58',
        total: 33000.0,
        estadoPedido: OrderStatusConstants.recibido,
        estadoPago: PaymentStatusConstants.pagado,
        metodoPago: PaymentMethodConstants.wompi,
        direccion: 'Kiosco El Bony, Bocagrande',
        barrio: 'Bocagrande',
        carpa: 14,
        telefono: '3232542588',
        clienteNombre: 'Cristian Tapias',
        clienteEmail: 'cristian@playapp.com',
      ),
      OrderModel(
        id: '6afbdac3761ca933d203e4c3',
        fecha: '16-11-2026 23:40',
        total: 17000.0,
        estadoPedido: OrderStatusConstants.enPreparacion,
        estadoPago: PaymentStatusConstants.pendienteContraentrega,
        metodoPago: PaymentMethodConstants.efectivo,
        direccion: 'Frente al Muelle Castillogrande',
        barrio: 'Castillogrande',
        carpa: 5,
        telefono: '3009876543',
        clienteNombre: 'Andrea Gómez',
        clienteEmail: 'andrea@playapp.com',
      ),
      OrderModel(
        id: '6afbd8c5761ca933d203e4c2',
        fecha: '16-11-2026 23:32',
        total: 22000.0,
        estadoPedido: OrderStatusConstants.terminado,
        estadoPago: PaymentStatusConstants.pagado,
        metodoPago: PaymentMethodConstants.transferencia,
        direccion: 'Sector Hotel Hilton, El Laguito',
        barrio: 'El Laguito',
        carpa: 22,
        telefono: '3158765432',
        clienteNombre: 'Santiago Morales',
        clienteEmail: 'santiago@playapp.com',
      ),
    ];
  }

  Map<String, dynamic> _getDemoMetrics() {
    return {
      'totalVentas': 845000.0,
      'pedidosTotales': 34,
      'pedidosPendientes': 6,
      'pedidosTerminados': 28,
      'ocupacionBocagrande': 78,
      'ocupacionCastillo': 62,
      'temperatura': 31,
      'clima': 'Soleado, brisa fresca de mar',
    };
  }
}
