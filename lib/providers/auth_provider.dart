import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/storage/session_manager.dart';
import '../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  AuthProvider() {
    _loadUserFromStorage();
  }

  void _loadUserFromStorage() {
    _currentUser = SessionManager.getUser();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.post<Map<String, dynamic>>(
        ApiEndpoints.authLogin,
        body: {
          'correo': email.trim(),
          'username': email.trim(),
          'password': password,
        },
      );

      if (res.success && res.data != null) {
        final userData = (res.data!['usuario'] ?? res.data!['user']) as Map<String, dynamic>;
        final token = res.data!['token']?.toString() ?? 'session_${userData['id']}';
        _currentUser = UserModel.fromJson(userData);
        await SessionManager.saveSession(token: token, user: _currentUser!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res.message ?? 'Credenciales incorrectas. Por favor verifica tu correo y contraseña.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (_) {
      _errorMessage = 'No se pudo conectar con el servidor. Verifica tu conexión de red.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
    String? direccion,
    int? mesa,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.post<Map<String, dynamic>>(
        ApiEndpoints.authRegister,
        body: {
          'nombreCompleto': nombre.trim(),
          'nombre': nombre.trim(),
          'correo': email.trim().toLowerCase(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'telefono': telefono?.trim(),
          'direccion': direccion?.trim(),
          'mesa': mesa,
        },
      );

      if (res.success && res.data != null) {
        final userData = (res.data!['usuario'] ?? res.data!['user']) as Map<String, dynamic>;
        final token = res.data!['token']?.toString() ?? 'session_${userData['id']}';
        _currentUser = UserModel.fromJson(userData);
        await SessionManager.saveSession(token: token, user: _currentUser!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res.message ?? 'No se pudo registrar la cuenta. Intenta con otro correo.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (_) {
      _errorMessage = 'Error de conexión al registrar. Intenta nuevamente.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await SessionManager.clearSession();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void updateProfileLocally(UserModel updated) {
    _currentUser = updated;
    SessionManager.saveSession(
      token: SessionManager.getToken() ?? 'token',
      user: updated,
    );
    notifyListeners();
  }
}
