import '../models/app_user.dart';

/// Authentication backend. The UI depends on this interface rather than on a
/// specific provider, so a real backend can be swapped in later without
/// touching the screens.
///
/// The app currently runs against [MockAuthService]. When Firebase is wired up
/// (via `flutterfire configure`), add back the `firebase_core`/`firebase_auth`
/// dependencies and a `FirebaseAuthService` implementing this interface.
abstract class AuthService {
  Stream<AppUser?> get authStateChanges;

  AppUser? get currentUser;

  Future<void> signInWithEmail(String email, String password);

  Future<void> registerWithEmail(String email, String password);

  Future<void> signOut();

  Future<String?> getIdToken();
}
