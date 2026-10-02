import '../data/demo_data.dart';
import '../models/fault_code.dart';
import '../models/fuel_log.dart';
import '../models/maintenance_log.dart';
import '../models/vehicle.dart';
import 'api_service.dart';

/// Loads data from the backend API, falling back to bundled demo data when the
/// backend is unreachable or empty — so the app always renders something.
class DataRepository {
  final ApiService _api = ApiService();

  Future<List<Vehicle>> fetchVehicles() async {
    try {
      final vehicles = await _api.getVehicles();
      if (vehicles.isNotEmpty) return vehicles;
    } catch (_) {
      // backend unreachable — fall through to demo data
    }
    return [demoVehicle];
  }

  Future<List<MaintenanceLog>> fetchMaintenance(String vehicleId) async {
    try {
      final logs = await _api.getMaintenance(vehicleId);
      if (logs.isNotEmpty) return logs;
    } catch (_) {
      // fall through to demo data
    }
    return demoMaintenanceLogs;
  }

  Future<List<FuelLog>> fetchFuel(String vehicleId) async {
    try {
      final logs = await _api.getFuel(vehicleId);
      if (logs.isNotEmpty) return logs;
    } catch (_) {
      // fall through to demo data
    }
    return demoFuelLogs;
  }

  /// The diagnostics methods intentionally throw when the backend is
  /// unreachable — callers decide whether to fall back to local behaviour.
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
