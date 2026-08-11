import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Handles discovering and connecting to an ELM327 Bluetooth OBD-II adapter.
/// Raw AT-command / PID communication is intentionally minimal here — the
/// heavy lifting (decoding fault codes and live PIDs) happens on the backend
/// via python-obd once readings are relayed up, or can be extended here for
/// fully on-device parsing.
class ObdService {
  BluetoothDevice? connectedDevice;

  Stream<List<ScanResult>> scanForAdapters() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    return FlutterBluePlus.scanResults;
  }

  Future<void> connect(BluetoothDevice device) async {
    await device.connect();
    connectedDevice = device;
  }

  Future<void> disconnect() async {
    await connectedDevice?.disconnect();
    connectedDevice = null;
  }
}
