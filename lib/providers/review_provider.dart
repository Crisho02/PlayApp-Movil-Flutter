import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../data/models/review_model.dart';

class ReviewProvider extends ChangeNotifier {
  List<ReviewModel> _reviews = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ReviewProvider() {
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.get<dynamic>(
        ApiEndpoints.reviews,
      );

      if (res.success && res.data != null) {
        List<dynamic> list = [];
        if (res.data is List) {
          list = res.data as List<dynamic>;
        } else if (res.data is Map && (res.data as Map).containsKey('value')) {
          list = res.data['value'] as List<dynamic>;
        }

        _reviews = list
            .map((item) => ReviewModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = res.message ?? 'No se pudieron cargar las reseñas.';
      }
    } catch (_) {
      _errorMessage = 'Error al conectar con el servidor de reseñas.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addReview({
    required String nombre,
    required int calificacion,
    required String comentario,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.post(
        ApiEndpoints.reviews,
        body: {
          'nombre': nombre.trim(),
          'comentario': comentario.trim(),
          'valoracion': calificacion,
        },
      );

      if (res.success) {
        // Refrescar listado directamente desde MongoDB Atlas
        await fetchReviews();
        return true;
      } else {
        _errorMessage = res.message ?? 'No se pudo publicar la reseña.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (_) {
      _errorMessage = 'Error de conexión al enviar la reseña.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendContactMessage({
    required String nombre,
    required String email,
    required String asunto,
    required String mensaje,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiClient.post(
        ApiEndpoints.contact,
        body: {
          'nombre': nombre.trim(),
          'email': email.trim(),
          'asunto': asunto.trim(),
          'mensaje': mensaje.trim(),
        },
      );
      _isLoading = false;
      notifyListeners();
      return res.success;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
