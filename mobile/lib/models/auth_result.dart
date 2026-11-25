import 'app_user.dart';

/// Result of a successful register/login: the JWT and the signed-in user.
class AuthResult {
  final String accessToken;
  final AppUser user;

  const AuthResult({required this.accessToken, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        accessToken: json['access_token'] as String,
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}
