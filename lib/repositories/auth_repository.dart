import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_session.dart';

abstract class AuthRepository {
  Future<UserSession?> getCurrentUser();
  Future<UserSession> login(String username, String password);
  Future<void> logout();
}

/// Local demo gate only. These client-side checks are not production security.
class LocalAuthRepository implements AuthRepository {
  // Ignore sessions from the old permissive demo authentication.
  static const String _sessionKey = 'blood_auth_session_v2';
  static const String _legacySessionKey = 'blood_auth_session_v1';
  final SharedPreferences _prefs;

  LocalAuthRepository(this._prefs);

  static Future<LocalAuthRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalAuthRepository(prefs);
  }

  @override
  Future<UserSession?> getCurrentUser() async {
    final jsonStr = _prefs.getString(_sessionKey);
    if (jsonStr == null || jsonStr.trim().isEmpty) return null;
    try {
      final session = UserSession.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
      return session.username == '2026' && session.isAuthenticated
          ? session
          : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserSession> login(String username, String password) async {
    if (username.trim().isEmpty) throw 'يرجى إدخال اسم المستخدم';
    if (password.trim().isEmpty) throw 'يرجى إدخال كلمة المرور';
    if (username != '2026' || password != '100100') {
      throw 'اسم المستخدم أو كلمة المرور غير صحيحة';
    }
    final session = UserSession(
      username: username,
      displayName: 'إدارة جمعية كفالة اليتيم',
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
    await _prefs.remove(_legacySessionKey);
  }
}
