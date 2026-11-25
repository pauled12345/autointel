import 'package:flutter/foundation.dart';

import '../models/vehicle.dart';
import '../services/data_repository.dart';

class VehicleProvider extends ChangeNotifier {
  final DataRepository _repo = DataRepository();
  List<Vehicle> _vehicles = [];

  List<Vehicle> get vehicles => _vehicles;

  /// Fetches the signed-in user's vehicles from the backend.
  Future<void> load() async {
    _vehicles = await _repo.fetchVehicles();
    notifyListeners();
  }

  void setVehicles(List<Vehicle> vehicles) {
    _vehicles = vehicles;
    notifyListeners();
  }

  void addVehicle(Vehicle vehicle) {
    _vehicles.add(vehicle);
    notifyListeners();
    _syncVehicle(vehicle);
  }

  /// Pushes a locally created vehicle to the backend and swaps in the server
  /// version (real UUID) so maintenance/fuel/diagnostics calls work.
  Future<void> _syncVehicle(Vehicle vehicle) async {
    final saved = await _repo.createVehicle(vehicle);
    if (saved.id == vehicle.id) return;
    final i = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (i < 0) return;
    _vehicles[i] = saved;
    notifyListeners();
  }
}
