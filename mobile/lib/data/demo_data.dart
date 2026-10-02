import 'package:intl/intl.dart';

import '../models/fuel_log.dart';
import '../models/maintenance_log.dart';
import '../models/vehicle.dart';

/// A seeded demo vehicle shown throughout the offline app.
final Vehicle demoVehicle = Vehicle(
  id: 'demo-vehicle',
  make: 'Toyota',
  model: 'Corolla',
  year: 2019,
  nickname: 'My Corolla',
  vin: '1HGBH41JXMN109186',
);

final List<MaintenanceLog> demoMaintenanceLogs = [
  MaintenanceLog(
    id: 'm1',
    type: 'oil_change',
    date: DateTime(2026, 9, 28),
    mileageKm: 45200,
    cost: 89.99,
  ),
  MaintenanceLog(
    id: 'm2',
    type: 'tire_rotation',
    date: DateTime(2026, 8, 15),
    mileageKm: 43800,
    cost: 45.00,
  ),
  MaintenanceLog(
    id: 'm3',
    type: 'brake_pads',
    date: DateTime(2026, 7, 2),
    mileageKm: 41500,
    cost: 320.00,
  ),
  MaintenanceLog(
    id: 'm4',
    type: 'coolant_flush',
    date: DateTime(2026, 10, 15),
    mileageKm: 46500,
    cost: 120.00,
  ),
];

final List<FuelLog> demoFuelLogs = [
  FuelLog(
    id: 'f1',
    date: DateTime(2026, 10, 1),
    odometerKm: 45800,
    liters: 42.5,
    totalCost: 58.20,
  ),
  FuelLog(
    id: 'f2',
    date: DateTime(2026, 9, 20),
    odometerKm: 45300,
    liters: 40.1,
    totalCost: 55.10,
  ),
  FuelLog(
    id: 'f3',
    date: DateTime(2026, 9, 8),
    odometerKm: 44750,
    liters: 43.0,
    totalCost: 59.00,
  ),
  FuelLog(
    id: 'f4',
    date: DateTime(2026, 8, 27),
    odometerKm: 44200,
    liters: 39.8,
    totalCost: 54.30,
  ),
];

final DateFormat _dateFmt = DateFormat('MMM d, yyyy');
final NumberFormat _kmFmt = NumberFormat('#,##0');

String formatDate(DateTime d) => _dateFmt.format(d);

String formatKm(int km) => '${_kmFmt.format(km)} km';

String formatMoney(double v) => '\$${v.toStringAsFixed(2)}';
