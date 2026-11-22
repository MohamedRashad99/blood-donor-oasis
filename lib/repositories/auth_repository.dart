import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_session.dart';

abstract class AuthRepository {
  Future<UserSession?> getCurrentUser();
  Future<UserSession> login(String username, String password);
  Future<void> logout();
}

class LocalAuthRepository implements AuthRepository {
  static const String _sessionKey = 'blood_auth_session_v1';
  final SharedPreferences _prefs;

  LocalAuthRepository(this._prefs);

  static Future<LocalAuthRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalAuthRepository(prefs);
  }

  @override
  Future<UserSession?> getCurrentUser() async {
    final jsonStr = _prefs.getString(_sessionKey);
    if (jsonStr == null || jsonStr.trim().isEmpty) {
      // Default initial session for immediate access, or require login
      return const UserSession(
        username: 'admin',
        displayName: 'إدارة جمعية كفالة اليتيم',
        role: 'مدير النظام',
        isAuthenticated: true,
      );
    }
    try {
      return UserSession.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserSession> login(String username, String password) async {
    // Demo authentication check
    // In production, this calls a secure backend with token-based authentication (OAuth2 / JWT / Firebase Auth)
    if (username.trim().isEmpty) {
      throw 'يرجى إدخال اسم المستخدم';
    }
    if (password.trim().isEmpty) {
      throw 'يرجى إدخال كلمة المرور';
    }

    // Accept valid demo credentials
    final session = UserSession(
      username: username.trim(),
      displayName: username == 'admin' ? 'إدارة جمعية كفالة اليتيم' : username,
      role: 'مدير النظام',
      isAuthenticated: true,
      loginTime: DateTime.now(),
    );

    await _prefs.setString(_sessionKey, jsonEncode(session.toJson()));
    return session;
  }

  @override
  Future<void> logout() async {
    await _prefs.remove(_sessionKey);
  }
}
