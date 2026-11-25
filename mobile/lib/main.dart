import 'package:flutter/material.dart';

import 'app.dart';
import 'providers/vehicle_provider.dart';
import 'services/backend_auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = BackendAuthService();
  final vehicleProvider = VehicleProvider();

  // Load the user's vehicles when they sign in, clear them when they sign out.
  authService.authStateChanges.listen((user) {
    if (user != null) {
      vehicleProvider.load();
    } else {
      vehicleProvider.setVehicles([]);
    }
  });

  runApp(
    AutoIntelApp(
      authService: authService,
      vehicleProvider: vehicleProvider,
    ),
  );
}
