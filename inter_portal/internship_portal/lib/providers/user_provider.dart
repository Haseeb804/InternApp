import 'package:flutter/material.dart';
import 'package:internship_portal/models/user.dart';
import 'package:internship_portal/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  final AuthService _authService = AuthService();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.role == 'admin';

  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'token');
    if (token != null) {
      try {
        _isLoading = true;
        notifyListeners();
        // TODO: Implement getCurrentUser in AuthService
        _user = await _authService.getCurrentUser();
      } catch (e) {
        await _storage.delete(key: 'token');
        _user = null;
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await _authService.login(username, password);
      if (success) {
        // TODO: Implement getCurrentUser in AuthService
        _user = await _authService.getCurrentUser();
        notifyListeners();
        return true;
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _storage.delete(key: 'token');
    _user = null;

    _isLoading = false;
    notifyListeners();
  }

  Future<dynamic> register(String username, String email, String password, String role, String name) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.register(email, password, username, role, name);
      return user;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
