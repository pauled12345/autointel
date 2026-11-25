/// A signed-in user, decoupled from the auth transport so the UI doesn't care
/// how authentication happened.
class AppUser {
  final String id;
  final String? email;
  final String? displayName;

  const AppUser({required this.id, this.email, this.displayName});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String?,
        displayName: json['display_name'] as String?,
      );
}
