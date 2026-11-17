import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../config/env_config.dart';

class SessionManager {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'current_user';
  static const String _keyBaseUrl = 'api_base_url';
  static const String _keyCookie = 'session_cookie';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final customUrl = _prefs?.getString(_keyBaseUrl);
    if (customUrl != null && customUrl.isNotEmpty) {
      EnvConfig.apiBaseUrl = customUrl;
    }
  }

  static Future<void> setBaseUrl(String url) async {
    EnvConfig.apiBaseUrl = url;
    await _prefs?.setString(_keyBaseUrl, url);
  }

  static String getBaseUrl() {
    return _prefs?.getString(_keyBaseUrl) ?? EnvConfig.defaultBaseUrl;
  }

  static Future<void> saveSession({
    required String token,
    required UserModel user,
    String? sessionCookie,
  }) async {
    await _prefs?.setString(_keyToken, token);
    await _prefs?.setString(_keyUser, jsonEncode(user.toJson()));
    if (sessionCookie != null) {
      await _prefs?.setString(_keyCookie, sessionCookie);
    }
  }

  static String? getToken() {
    return _prefs?.getString(_keyToken);
  }

  static String? getSessionCookie() {
    return _prefs?.getString(_keyCookie);
  }

  static Future<void> setSessionCookie(String cookie) async {
    await _prefs?.setString(_keyCookie, cookie);
  }

  static UserModel? getUser() {
    final raw = _prefs?.getString(_keyUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearSession() async {
    await _prefs?.remove(_keyToken);
    await _prefs?.remove(_keyUser);
    await _prefs?.remove(_keyCookie);
  }

  static bool get isLoggedIn => getToken() != null && getUser() != null;
}
