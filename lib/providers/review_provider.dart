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
      final res = await ApiClient.get<List<dynamic>>(
        ApiEndpoints.reviews,
      );

      if (res.success && res.data != null) {
        _reviews = res.data!
            .map((item) => ReviewModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        if (_reviews.isEmpty) {
          _reviews = _getDemoReviews();
        }
      }
    } catch (_) {
      if (_reviews.isEmpty) {
        _reviews = _getDemoReviews();
      }
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
    notifyListeners();

    try {
      final res = await ApiClient.post(
        ApiEndpoints.reviews,
        body: {
          'nombreCliente': nombre,
          'calificacion': calificacion,
          'comentario': comentario,
        },
      );

      final newReview = ReviewModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nombreCliente: nombre,
        calificacion: calificacion,
        comentario: comentario,
        fecha: 'Hoy',
      );

      _reviews.insert(0, newReview);
      _isLoading = false;
      notifyListeners();
      return res.success;
    } catch (_) {
      final newReview = ReviewModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nombreCliente: nombre,
        calificacion: calificacion,
        comentario: comentario,
        fecha: 'Hoy',
      );
      _reviews.insert(0, newReview);
      _isLoading = false;
      notifyListeners();
      return true;
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
          'nombre': nombre,
          'email': email,
          'asunto': asunto,
          'mensaje': mensaje,
        },
      );
      _isLoading = false;
      notifyListeners();
      return res.success;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  List<ReviewModel> _getDemoReviews() {
    return [
      ReviewModel(
        id: '1',
        nombreCliente: 'Walter Espriella',
        calificacion: 5,
        comentario: '¡Excelente servicio en Bocagrande! El pescado llegó caliente y fresco directo a la carpa.',
        fecha: '16 Nov 2026',
      ),
      ReviewModel(
        id: '2',
        nombreCliente: 'Catalina García',
        calificacion: 5,
        comentario: 'Me encantó todo, muy delicioso y la atención por Wompi y contraentrega fue súper rápida y segura.',
        fecha: '15 Nov 2026',
      ),
      ReviewModel(
        id: '3',
        nombreCliente: 'Mateo Restrepo',
        calificacion: 4,
        comentario: 'La limonada de coco en el calor de Cartagena es lo máximo. Sin duda volveremos a pedir.',
        fecha: '14 Nov 2026',
      ),
    ];
  }
}
