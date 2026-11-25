import '../models/app_user.dart';

/// A user-facing authentication error. The UI shows [message] directly, so it
/// must never contain raw exception text such as "DioException [bad response]".
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Authentication backend. The UI depends on this interface rather than on a
/// specific provider. The production implementation is [BackendAuthService],
/// which authenticates against the AutoIntel API.
abstract class AuthService {
  Stream<AppUser?> get authStateChanges;

  AppUser? get currentUser;

  Future<void> signInWithEmail(String email, String password);

  Future<void> registerWithEmail(String email, String password);

  Future<void> signOut();

  Future<String?> getIdToken();
}