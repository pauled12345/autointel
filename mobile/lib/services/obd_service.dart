import 'obd/obd_transport.dart';
import 'obd/elm327_client.dart';
import 'obd/bluetooth_classic_transport.dart';

/// High-level entry point the UI uses to talk to an ELM327 adapter over
/// Bluetooth Classic (SPP).
class ObdService {
  ObdTransport? _transport;
  Elm327Client? _client;

  bool get isConnected => _transport?.isConnected ?? false;

  /// The active AT client, available once [connect] has succeeded. Used by
  /// [DiagnosticsService] to issue Mode 01/03/04 commands.
  Elm327Client? get client => _client;

  /// Lists already-paired (bonded) Bluetooth devices.
  Future<List<ObdDevice>> scanForAdapters() =>
      BluetoothClassicTransport.bondedDevices();

  /// Opens an SPP link to [device] and prepares the AT client.
  Future<void> connect(
    ObdDevice device, {
    void Function(String line)? onLog,
  }) async {
    await disconnect();
    _transport = BluetoothClassicTransport();
    _client = Elm327Client(_transport!, onLog: onLog);
    await _transport!.connect(device);
  }

  /// Runs the ELM327 init sequence (`ATZ` → `ATE0` → `ATSP0`).
  Future<Elm327InitResult> initialize() {
    final client = _client;
    if (client == null) {
      throw ObdTransportException('Not connected to any adapter');
    }
    return client.initialize();
  }

  Future<void> disconnect() async {
    await _client?.dispose();
    _client = null;
    final transport = _transport;
    _transport = null;
    await transport?.disconnect();
  }
}
