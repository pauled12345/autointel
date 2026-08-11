import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';

class VehicleProvider extends ChangeNotifier {
  List<Vehicle> _vehicles = [];

  List<Vehicle> get vehicles => _vehicles;

  void setVehicles(List<Vehicle> vehicles) {
    _vehicles = vehicles;
    notifyListeners();
  }

  void addVehicle(Vehicle vehicle) {
    _vehicles.add(vehicle);
    notifyListeners();
  }
}
