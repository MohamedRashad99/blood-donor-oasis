import 'package:flutter/material.dart';
import '../models/user_session.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  UserSession _user = UserSession.guest;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._repository) {
    checkCurrentUser();
  }

  UserSession get user => _user;
  bool get isAuthenticated => _user.isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> checkCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final session = await _repository.getCurrentUser();
      if (session != null) {
        _user = session;
      } else {
        _user = UserSession.guest;
      }
    } catch (_) {
      _user = UserSession.guest;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _repository.login(username, password);
      _user = session;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _repository.logout();
    _user = UserSession.guest;
    _isLoading = false;
    notifyListeners();
  }
}
