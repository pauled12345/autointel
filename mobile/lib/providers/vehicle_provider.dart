import 'package:flutter/foundation.dart';

import '../data/demo_data.dart';
import '../models/vehicle.dart';
import '../services/data_repository.dart';

class VehicleProvider extends ChangeNotifier {
  final DataRepository _repo = DataRepository();
  List<Vehicle> _vehicles = [demoVehicle];

  List<Vehicle> get vehicles => _vehicles;

  /// Fetches vehicles from the backend, falling back to the demo vehicle.
  Future<void> load() async {
    final vehicles = await _repo.fetchVehicles();
    _vehicles = vehicles;
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
