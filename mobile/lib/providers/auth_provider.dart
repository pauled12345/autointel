import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  AppUser? _user;

  AuthProvider(this._authService) {
    _authService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  bool get isSignedIn => _user != null;
  AppUser? get user => _user;

  Future<void> signIn(String email, String password) {
    return _authService.signInWithEmail(email, password);
  }

  Future<void> register(String email, String password) {
    return _authService.registerWithEmail(email, password);
  }

  Future<void> signOut() => _authService.signOut();
}
