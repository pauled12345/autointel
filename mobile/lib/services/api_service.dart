import 'package:dio/dio.dart';

import '../models/auth_result.dart';
import '../models/fault_code.dart';
import '../models/fuel_log.dart';
import '../models/maintenance_log.dart';
import '../models/vehicle.dart';

/// Backend connection settings.
class ApiConfig {
  /// The AutoIntel FastAPI base URL.
  ///
  /// Set at build time with the `--dart-define` flag:
  ///
  ///   flutter build apk --dart-define=API_BASE_URL=https://<service>.onrender.com
  ///
  /// When not set, falls back to the local-network address used for local dev.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.100.134:8000',
  );
}

/// Thin wrapper around Dio for the AutoIntel FastAPI backend.
class ApiService {
  /// Shared JWT attached to every request once the user signs in. Kept static
  /// so all ApiService instances (repository, auth, screens) stay in sync.
  static String? token;

  final Dio _dio;

  ApiService({String baseUrl = ApiConfig.baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 15),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final t = token;
        if (t != null) options.headers['Authorization'] = 'Bearer $t';
        handler.next(options);
      },
    ));
  }

  Future<AuthResult> register(String email, String password, {String? displayName}) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      if (displayName != null) 'display_name': displayName,
    });
    return AuthResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResult> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return AuthResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Vehicle>> getVehicles() async {
    final response = await _dio.get('/vehicles/');
    return (response.data as List)
        .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    final response = await _dio.post('/vehicles/', data: vehicle.toJson());
    return Vehicle.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MaintenanceLog> createMaintenance(
      String vehicleId, MaintenanceLog log) async {
    final response = await _dio.post('/maintenance/', data: {
      'vehicle_id': vehicleId,
      ...log.toJson(),
    });
    return MaintenanceLog.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FuelLog> createFuel(String vehicleId, FuelLog log) async {
    final response = await _dio.post('/fuel/', data: {
      'vehicle_id': vehicleId,
      ...log.toJson(),
    });
    return FuelLog.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<MaintenanceLog>> getMaintenance(String vehicleId) async {
    final response = await _dio.get('/maintenance/vehicle/$vehicleId');
    return (response.data as List)
        .map((e) => MaintenanceLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FuelLog>> getFuel(String vehicleId) async {
    final response = await _dio.get('/fuel/vehicle/$vehicleId');
    return (response.data as List)
        .map((e) => FuelLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> startDiagnosticsSession(String vehicleId) async {
    final response = await _dio.post(
      '/diagnostics/sessions',
      data: {'vehicle_id': vehicleId},
    );
    return (response.data as Map<String, dynamic>)['id'] as String;
  }

  Future<FaultCode> reportFaultCode(String sessionId, String code) async {
    final response = await _dio.post(
      '/diagnostics/fault-codes',
      data: {'session_id': sessionId, 'code': code},
    );
    return FaultCode.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> reportSensorReading(
    String sessionId,
    String pid,
    double value,
    String unit,
  ) async {
    await _dio.post(
      '/diagnostics/sensor-readings',
      data: {
        'session_id': sessionId,
        'pid': pid,
        'value': value,
        'unit': unit,
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Future<void> endDiagnosticsSession(String sessionId) async {
    await _dio.post('/diagnostics/sessions/$sessionId/end');
  }

  Future<String> chat(List<Map<String, String>> messages) async {
    final response = await _dio.post('/chat/', data: {'messages': messages});
    return (response.data as Map<String, dynamic>)['reply'] as String;
  }
}
