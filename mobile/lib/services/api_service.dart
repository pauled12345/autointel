import 'package:dio/dio.dart';

import '../models/fault_code.dart';
import '../models/fuel_log.dart';
import '../models/maintenance_log.dart';
import '../models/vehicle.dart';

/// Backend connection settings.
class ApiConfig {
  /// The AutoIntel FastAPI base URL.
  ///
  /// - Physical device on the same Wi-Fi: use your PC's LAN IP.
  /// - Android emulator: use `http://10.0.2.2:8000`.
  static const String baseUrl = 'http://192.168.100.134:8000';
}

/// Thin wrapper around Dio for the AutoIntel FastAPI backend.
class ApiService {
  final Dio _dio;

  ApiService({String baseUrl = ApiConfig.baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ));

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
}
