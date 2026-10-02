import 'dart:async';

import 'obd_transport.dart';

/// An in-app simulator of a real ELM327 adapter.
///
/// It speaks the same "language" as the hardware over an [ObdTransport], so the
/// [Elm327Client] and the UI behave identically whether they talk to this mock
/// or a real adapter on a car. That is the whole point: you can develop and
/// test the connection + init sequence with no hardware.
///
/// Behaviours modelled from real ELM327 firmware:
/// - Commands are terminated with `\r` and responses end with the `>` prompt.
/// - After a reset (`ATZ`) the adapter **echoes commands** back by default.
/// - `ATE0` turns echo off.
/// - `ATZ` takes ~1 second to boot and returns a banner such as `ELM327 v1.5`.
/// - An unknown AT command returns `?`.
class MockElm327Transport implements ObdTransport {
  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  bool _connected = false;
  bool _echo = true;

  /// Delay before the mock answers `ATZ`, mimicking the real reset/boot time.
  final Duration bootDelay;

  /// When true, [connect] fails — handy for demonstrating error handling.
  bool failConnect;

  /// When true, the adapter never answers — handy for demonstrating timeouts.
  bool silent;

  /// Commands received, in order. Used by tests to assert the init sequence.
  final List<String> receivedCommands = [];

  MockElm327Transport({
    this.bootDelay = const Duration(milliseconds: 1200),
    this.failConnect = false,
    this.silent = false,
  });

  /// Whether command echo is currently enabled (visible to tests).
  bool get echoEnabled => _echo;

  @override
  bool get isConnected => _connected;

  @override
  Stream<String> get input => _controller.stream;

  @override
  Future<void> connect(ObdDevice device) async {
    if (failConnect) {
      throw ObdTransportException('Mock adapter refused connection');
    }
    // A fresh adapter starts in its power-on state: echo ON.
    _echo = true;
    _connected = true;
  }

  @override
  Future<void> writeRaw(String data) async {
    if (!_connected) {
      throw ObdTransportException('Mock adapter is not connected');
    }
    final command = data.replaceAll('\r', '').replaceAll('\n', '').trim();
    if (command.isEmpty) return;
    receivedCommands.add(command.toUpperCase());
    await _respondTo(command.toUpperCase());
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  Future<void> _respondTo(String command) async {
    if (silent) return;

    // Echo the command back while echo is enabled. `ATZ` itself is not echoed
    // because the device is mid-reset, but it re-enables echo afterwards.
    if (_echo && command != 'ATZ') {
      _emit('$command\r');
    }

    switch (command) {
      case 'ATZ':
        await Future.delayed(bootDelay);
        _echo = true; // reset restores the power-on state
        // The banner and the prompt are emitted as two separate chunks on
        // purpose — a real link is packetised, so the client must buffer until
        // it sees the `>` prompt.
        _emit('ELM327 v1.5\r');
        _emit('\r>');
        return;
      case 'ATE0':
        _echo = false;
        _emit('OK\r');
        _emit('>');
        return;
      case 'ATSP0':
        _emit('OK\r');
        _emit('>');
        return;
    }

    // Canned responses for later phases (Mode 01/03/04), kept here so the mock
    // stays a single forward-compatible simulator.
    final canned = _cannedResponses[command];
    if (canned != null) {
      _emit('$canned\r');
      _emit('>');
      return;
    }

    if (command.startsWith('AT')) {
      _emit('?\r'); // real firmware replies `?` to an unknown AT command
      _emit('>');
      return;
    }

    _emit('NO DATA\r');
    _emit('>');
  }

  void _emit(String chunk) {
    if (!_controller.isClosed) {
      _controller.add(chunk);
    }
  }

  static const Map<String, String> _cannedResponses = {
    // Mode 03 — stored DTCs (two P-codes: P0133 and P0301).
    '03': '43 01 33 03 01 00 00',
    // Mode 04 — clear DTCs.
    '04': '44',
    // Mode 01 — live PIDs.
    '010C': '41 0C 1A F8', // RPM = 1726
    '010D': '41 0D 3C', // Speed = 60 km/h
    '0105': '41 05 7B', // Coolant temp = 83 °C
    '0104': '41 04 80', // Engine load = 50 %
  };
}
