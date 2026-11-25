import '../models/fault_code.dart';
import '../models/fuel_log.dart';
import '../models/maintenance_log.dart';
import '../models/vehicle.dart';
import 'api_service.dart';

/// Loads data from the backend API. Fetch methods return empty lists on failure
/// so the UI degrades gracefully instead of crashing.
class DataRepository {
  final ApiService _api;

  DataRepository([ApiService? api]) : _api = api ?? ApiService();

  Future<List<Vehicle>> fetchVehicles() async {
    try {
      return await _api.getVehicles();
    } catch (_) {
      return const [];
    }
  }

  /// Registers the vehicle on the backend and returns it with the server UUID.
  /// Falls back to the local copy when the backend is unreachable.
  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    try {
      return await _api.createVehicle(vehicle);
    } catch (_) {
      return vehicle;
    }
  }

  Future<List<MaintenanceLog>> fetchMaintenance(String vehicleId) async {
    try {
      return await _api.getMaintenance(vehicleId);
    } catch (_) {
      return const [];
    }
  }

  Future<List<FuelLog>> fetchFuel(String vehicleId) async {
    try {
      return await _api.getFuel(vehicleId);
    } catch (_) {
      return const [];
    }
  }

  Future<MaintenanceLog> createMaintenance(
      String vehicleId, MaintenanceLog log) async {
    try {
      return await _api.createMaintenance(vehicleId, log);
    } catch (_) {
      return log; // backend unreachable — keep the local entry
    }
  }

  Future<FuelLog> createFuel(String vehicleId, FuelLog log) async {
    try {
      return await _api.createFuel(vehicleId, log);
    } catch (_) {
      return log; // backend unreachable — keep the local entry
    }
  }

  Future<String> startDiagnosticsSession(String vehicleId) =>
      _api.startDiagnosticsSession(vehicleId);

  Future<FaultCode> reportFaultCode(String sessionId, String code) =>
      _api.reportFaultCode(sessionId, code);

  Future<void> reportSensorReading(
    String sessionId,
    String pid,
    double value,
    String unit,
  ) =>
      _api.reportSensorReading(sessionId, pid, value, unit);

  Future<void> endDiagnosticsSession(String sessionId) =>
      _api.endDiagnosticsSession(sessionId);
}
