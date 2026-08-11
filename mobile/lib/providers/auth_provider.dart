import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;

  AuthProvider() {
    _authService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  bool get isSignedIn => _user != null;
  User? get user => _user;

  Future<void> signIn(String email, String password) async {
    await _authService.signInWithEmail(email, password);
  }

  Future<void> register(String email, String password) async {
    await _authService.registerWithEmail(email, password);
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
