import 'dart:async';

import 'obd_transport.dart';

/// Placeholder for the real Bluetooth Classic (SPP) transport.
///
/// The production transport (previously over `flutter_bluetooth_serial`) was
/// dropped because that plugin is unmaintained and no longer compiles with
/// AGP 8. When a physical ELM327 adapter is available, add a maintained
/// Bluetooth plugin (e.g. `flutter_blue_plus`) and implement [connect] and
/// [bondedDevices] here. Everything above this leaf — [ObdTransport],
/// the ELM327 client, the mock transport, the parsers and the UI — stays
/// unchanged.
class BluetoothClassicTransport implements ObdTransport {
  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  @override
  bool get isConnected => false;

  @override
  Stream<String> get input => _controller.stream;

  /// Real Bluetooth discovery isn't wired up in this build.
  static Future<List<ObdDevice>> bondedDevices() async => const [];

  @override
  Future<void> connect(ObdDevice device) async {
    throw ObdTransportException(
      'Real Bluetooth Classic is not available in this build. '
      'Use the mock adapter for the demo.',
    );
  }

  @override
  Future<void> writeRaw(String data) async {
    throw ObdTransportException('Not connected to any adapter');
  }

  @override
  Future<void> disconnect() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
