import 'package:dio/dio.dart';
import 'auth_service.dart';

/// Thin wrapper around Dio for talking to the AutoIntel FastAPI backend.
/// Attaches the Firebase ID token to every request as a Bearer header.
class ApiService {
  final Dio _dio;
  final AuthService _authService;

  ApiService(this._authService, {String baseUrl = 'http://10.0.2.2:8000'})
      : _dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Future<List<dynamic>> getVehicles() async {
    final response = await _dio.get('/vehicles/');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createVehicle(Map<String, dynamic> payload) async {
    final response = await _dio.post('/vehicles/', data: payload);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getFaultCodes(String sessionId) async {
    final response = await _dio.get('/diagnostics/sessions/$sessionId/fault-codes');
    return response.data as List<dynamic>;
  }
}
