import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Requests the runtime Bluetooth permissions Android 12+ requires to list and
/// connect to a paired (bonded) Classic SPP adapter. Returns true when granted.
Future<bool> ensureBluetoothPermissions() async {
  if (!Platform.isAndroid) return true;
  final statuses = await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
  ].request();
  return statuses.values.every((status) => status.isGranted);
}
