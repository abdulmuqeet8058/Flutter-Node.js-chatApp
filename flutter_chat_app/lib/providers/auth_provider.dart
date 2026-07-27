import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  final StorageService _storage;

  AuthProvider({ApiService? api, StorageService? storage})
    : _api = api ?? ApiService(),
      _storage = storage ?? StorageService();

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _token;
  bool _busy = false;
  String? _error;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get token => _token;
  bool get busy => _busy;
  String? get error => _error;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _token != null;

  Future<void> tryAutoLogin() async {
    final token = await _storage.getToken();
    if (token == null) {
      _setStatus(AuthStatus.unauthenticated);
      return;
    }

    try {
      final user = await _api.me(token);
      _user = user;
      _token = token;
      _setStatus(AuthStatus.authenticated);
    } catch (_) {
      await _storage.clear();
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  Future<bool> register(String username, String password) {
    return _run(() => _api.register(username.trim(), password));
  }

  Future<bool> login(String username, String password) {
    return _run(() => _api.login(username.trim(), password));
  }

  Future<bool> _run(Future<AuthResult> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final result = await action();
      _user = result.user;
      _token = result.token;
      await _storage.saveToken(result.token);
      _busy = false;
      _setStatus(AuthStatus.authenticated);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _busy = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Something went wrong. Please try again.';
      _busy = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.clear();
    _user = null;
    _token = null;
    _error = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
}
