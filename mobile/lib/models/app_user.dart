/// A signed-in user, decoupled from any specific auth backend (Firebase or the
/// offline mock) so the UI doesn't care which one is active.
class AppUser {
  final String id;
  final String? email;
  final String? displayName;

  const AppUser({required this.id, this.email, this.displayName});
}
