import 'obd/obd_transport.dart';
import 'obd/elm327_client.dart';
import 'obd/mock_elm327_transport.dart';
import 'obd/bluetooth_classic_transport.dart';

/// High-level entry point the UI uses to talk to an ELM327 adapter.
///
/// It wires together a chosen [ObdTransport] (real Bluetooth Classic SPP, or
/// the in-app [MockElm327Transport]) and an [Elm327Client] that runs the AT
/// init sequence. Swapping `useMock` is all it takes to run without a car.
class ObdService {
  ObdTransport? _transport;
  Elm327Client? _client;

  bool get isConnected => _transport?.isConnected ?? false;

  /// The active AT client, available once [connect] has succeeded. Used by
  /// [DiagnosticsService] to issue Mode 01/03/04 commands.
  Elm327Client? get client => _client;

  /// A stand-in adapter used when running against the mock.
  static const ObdDevice mockDevice =
      ObdDevice(name: 'ELM327 (Mock)', address: '00:00:00:00:00:00');

  /// Discovers connectable adapters. Real mode returns bonded devices; mock
  /// mode returns a single fake adapter so the UI works with no hardware.
  Future<List<ObdDevice>> scanForAdapters({bool useMock = false}) async {
    if (useMock) return const [mockDevice];
    return BluetoothClassicTransport.bondedDevices();
  }

  /// Opens a link to [device] and prepares the AT client.
  Future<void> connect(
    ObdDevice device, {
    bool useMock = false,
    void Function(String line)? onLog,
  }) async {
    await disconnect();
    _transport = useMock ? MockElm327Transport() : BluetoothClassicTransport();
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
