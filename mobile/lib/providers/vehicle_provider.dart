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
  }
}
