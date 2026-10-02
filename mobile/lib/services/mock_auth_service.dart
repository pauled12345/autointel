import 'dart:async';

import '../models/app_user.dart';
import 'auth_service.dart';

/// In-memory auth used for the offline demo. Accepts any credentials and signs
/// in immediately, so the auth flow can be shown without a Firebase project.
class MockAuthService implements AuthService {
  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();

  AppUser? _currentUser;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _currentUser = _buildUser(email);
    _controller.add(_currentUser);
  }

  @override
  Future<void> registerWithEmail(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _currentUser = _buildUser(email);
    _controller.add(_currentUser);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<String?> getIdToken() async => 'mock-token';

  AppUser _buildUser(String email) => AppUser(
        id: 'demo-user',
        email: email,
        displayName: 'Demo Driver',
      );
}
