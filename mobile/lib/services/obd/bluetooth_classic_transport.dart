import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'obd_transport.dart';

/// Real Bluetooth Classic (SPP) transport for an ELM327 adapter.
///
/// Pairs with an adapter already bonded in the OS Bluetooth settings and
/// speaks the same [ObdTransport] contract as the mock, so the ELM327 client,
/// parsers and UI behave identically whether the bytes come from a real car or
/// the simulator.
class BluetoothClassicTransport implements ObdTransport {
  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _subscription;

  @override
  bool get isConnected => _connection?.isConnected ?? false;

  @override
  Stream<String> get input => _controller.stream;

  /// Lists already-paired (bonded) devices. The ELM327 must be paired in the
  /// OS Bluetooth settings before it appears here.
  static Future<List<ObdDevice>> bondedDevices() async {
    final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    return devices
        .map((d) => ObdDevice(
              name: d.name ?? 'Unknown device',
              address: d.address,
            ))
        .toList();
  }

  @override
  Future<void> connect(ObdDevice device) async {
    final connection = await BluetoothConnection.toAddress(device.address);
    _connection = connection;
    _subscription = connection.input!.listen((data) {
      if (!_controller.isClosed) {
        _controller.add(ascii.decode(data));
      }
    });
  }

  @override
  Future<void> writeRaw(String data) async {
    final connection = _connection;
    if (connection == null || !connection.isConnected) {
      throw ObdTransportException('Not connected to any adapter');
    }
    connection.output.add(utf8.encode(data));
    await connection.output.allSent;
  }

  @override
  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _connection?.close();
    _connection = null;
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
