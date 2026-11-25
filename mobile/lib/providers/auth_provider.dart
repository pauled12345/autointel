import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  AppUser? _user;
  String? _error;
  bool _busy = false;

  AuthProvider(this._authService) {
    _authService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  bool get isSignedIn => _user != null;
  AppUser? get user => _user;
  String? get error => _error;
  bool get busy => _busy;

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) {
    return _run(() => _authService.signInWithEmail(email, password));
  }

  Future<void> register(String email, String password) {
    return _run(() => _authService.registerWithEmail(email, password));
  }

  Future<void> signOut() {
    _error = null;
    return _authService.signOut();
  }

  Future<void> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on AuthException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Something went wrong. Please try again.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}