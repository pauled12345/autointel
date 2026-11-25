import 'dart:async';

import 'package:dio/dio.dart';

import '../models/app_user.dart';
import '../models/auth_result.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// Real authentication against the AutoIntel FastAPI backend (email/password
/// with a JWT). Replaces the old Firebase/mock implementations.
class BackendAuthService implements AuthService {
  final ApiService _api = ApiService();
  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();

  AppUser? _currentUser;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    final result = await _guard(() => _api.login(email, password), 'sign in');
    _setSession(result);
  }

  @override
  Future<void> registerWithEmail(String email, String password) async {
    final result =
        await _guard(() => _api.register(email, password), 'create an account');
    _setSession(result);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    ApiService.token = null;
    _controller.add(null);
  }

  @override
  Future<String?> getIdToken() async => ApiService.token;

  /// Runs [action], converting transport failures into an [AuthException] with
  /// a message that is safe to show in the UI.
  Future<AuthResult> _guard(
    Future<AuthResult> Function() action,
    String verb,
  ) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw AuthException(_describe(e, verb));
    }
  }

  String _describe(DioException e, String verb) {
    final statusCode = e.response?.statusCode;
    final detail = _detail(e.response?.data);

    if (statusCode != null) {
      if (statusCode == 409) {
        return detail ?? 'An account with this email already exists.';
      }
      if (statusCode == 401) {
        return detail ?? 'Invalid email or password.';
      }
      if (statusCode == 422) {
        return detail ?? 'Please check the details you entered.';
      }
      return detail ?? 'Could not $verb right now. Please try again.';
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'The server took too long to respond. Please try again.';
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Check your connection and that the '
            'API is running, then try again.';
      case DioExceptionType.badCertificate:
        return 'Could not establish a secure connection to the server.';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
      case DioExceptionType.transformTimeout:
        return 'Cannot reach the server. Check your connection and that the '
            'API is running, then try again.';
    }
  }

  /// FastAPI reports errors as `{"detail": "..."}`; validation failures use a
  /// list of per-field objects.
  String? _detail(dynamic data) {
    if (data is! Map) return null;
    final detail = data['detail'];
    if (detail is String && detail.trim().isNotEmpty) return detail.trim();
    if (detail is List && detail.isNotEmpty) {
      final messages = detail
          .whereType<Map>()
          .map((e) => e['msg'])
          .whereType<String>()
          .map((msg) => msg.replaceFirst(RegExp(r'^Value error,\s*'), ''))
          .toSet()
          .toList();
      if (messages.isNotEmpty) return messages.join('\n');
    }
    return null;
  }

  void _setSession(AuthResult result) {
    ApiService.token = result.accessToken;
    _currentUser = result.user;
    _controller.add(_currentUser);
  }
}