import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/storage/session_manager.dart';
import '../data/models/admin_report_model.dart';
import '../data/models/admin_user_model.dart';
import '../data/models/admin_weather_model.dart';
import '../data/models/order_model.dart';
import '../data/models/review_model.dart';

class AdminProvider extends ChangeNotifier {
  List<OrderModel> _adminOrders = [];
  Map<String, dynamic> _metrics = {};
  AdminWeatherModel? _weather;
  AdminReportModel? _report;
  List<AdminUserModel> _users = [];
  List<ReviewModel> _adminReviews = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Prediction state
  bool _isPredicting = false;
  Map<String, dynamic>? _lastPredictionResult;

  List<OrderModel> get adminOrders => _adminOrders;
  Map<String, dynamic> get metrics => _metrics;
  AdminWeatherModel? get weather => _weather;
  AdminReportModel? get report => _report;
  List<AdminUserModel> get users => _users;
  List<ReviewModel> get adminReviews => _adminReviews;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPredicting => _isPredicting;
  Map<String, dynamic>? get lastPredictionResult => _lastPredictionResult;

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
      fetchReports(),
      fetchUsers(),
      fetchAdminReviews(),
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
        if (_metrics['clima'] is Map<String, dynamic>) {
          Map<String, dynamic>? loc;
          if (_metrics['ubicacion'] is Map<String, dynamic>) {
            loc = _metrics['ubicacion'] as Map<String, dynamic>;
          }
          _weather = AdminWeatherModel.fromJson(
            _metrics['clima'] as Map<String, dynamic>,
            location: loc,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> fetchReports() async {
    final correo = _getAdminEmail();
    if (correo == null) return;

    try {
      final res = await ApiClient.get<Map<String, dynamic>>(
        ApiEndpoints.adminReports,
        queryParameters: {'correo': correo},
      );

      if (res.success && res.data != null) {
        _report = AdminReportModel.fromJson(res.data!);
      }
    } catch (_) {}
  }

  Future<void> fetchUsers() async {
    final correo = _getAdminEmail();
    if (correo == null) return;

    try {
      final res = await ApiClient.get<dynamic>(
        ApiEndpoints.adminUsers,
        queryParameters: {'correo': correo},
      );

      if (res.success && res.data is List) {
        _users = (res.data as List)
            .map((u) => AdminUserModel.fromJson(u as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> fetchAdminReviews() async {
    final correo = _getAdminEmail();
    if (correo == null) return;

    try {
      final res = await ApiClient.get<dynamic>(
        ApiEndpoints.adminReviews,
        queryParameters: {'correo': correo},
      );

      if (res.success && res.data is List) {
        _adminReviews = (res.data as List)
            .map((r) => ReviewModel.fromJson(r as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> predictSales({
    required String diaSemana,
    required String producto,
    required String categoria,
    required int precio,
    required String clima,
    required String temporada,
  }) async {
    final correo = _getAdminEmail();
    _isPredicting = true;
    notifyListeners();

    try {
      final res = await ApiClient.post<Map<String, dynamic>>(
        ApiEndpoints.adminPredictionSales,
        body: {
          'correo': correo,
          'diaSemana': diaSemana,
          'producto': producto,
          'categoria': categoria,
          'precio': precio,
          'clima': clima,
          'temporada': temporada,
        },
      );

      _isPredicting = false;
      if (res.success && res.data != null) {
        _lastPredictionResult = res.data;
        notifyListeners();
        return res.data;
      }
    } catch (_) {
      _isPredicting = false;
      notifyListeners();
    }
    return null;
  }

  Future<bool> createAdminUser({
    required String nombreCompleto,
    required String correo,
    required String password,
  }) async {
    final adminCorreo = _getAdminEmail();
    try {
      final res = await ApiClient.post(
        ApiEndpoints.adminUsersCreate,
        body: {
          'adminCorreo': adminCorreo,
          'nombreCompleto': nombreCompleto,
          'correo': correo,
          'password': password,
        },
      );

      if (res.success) {
        await fetchUsers();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAdminReview(String reviewId) async {
    final correo = _getAdminEmail();
    try {
      final res = await ApiClient.delete(
        ApiEndpoints.adminReviewDetail(reviewId),
        queryParameters: {'correo': correo},
      );

      if (res.success) {
        _adminReviews.removeWhere((r) => r.id == reviewId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    final correo = _getAdminEmail();
    int estadoNum = 0;
    if (newStatus.toLowerCase().contains('preparaci')) estadoNum = 1;
    if (newStatus.toLowerCase().contains('terminado')) estadoNum = 2;
    if (newStatus.toLowerCase().contains('cancelado')) estadoNum = 3;

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
    String? base64Image,
  }) async {
    final correo = _getAdminEmail();

    try {
      final Map<String, dynamic> body = {
        'correo': correo,
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'stock': cantidad,
        'categoria': categoriaId,
      };
      if (base64Image != null && base64Image.isNotEmpty) {
        body['base64Image'] = base64Image;
      }

      final res = await ApiClient.post(
        ApiEndpoints.adminProducts,
        body: body,
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
    String? base64Image,
  }) async {
    final correo = _getAdminEmail();

    try {
      final Map<String, dynamic> body = {
        'correo': correo,
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'stock': cantidad,
        'categoria': categoriaId,
      };
      if (base64Image != null && base64Image.isNotEmpty) {
        body['base64Image'] = base64Image;
      }

      final res = await ApiClient.put(
        ApiEndpoints.adminProductDetail(id),
        body: body,
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
