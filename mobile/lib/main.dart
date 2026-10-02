import 'package:flutter/material.dart';

import 'app.dart';
import 'providers/vehicle_provider.dart';
import 'services/mock_auth_service.dart';

void main() {
  // Load vehicles from the backend (falls back to the demo vehicle offline).
  final vehicleProvider = VehicleProvider()..load();

  runApp(
    AutoIntelApp(
      authService: MockAuthService(),
      vehicleProvider: vehicleProvider,
    ),
  );
}
