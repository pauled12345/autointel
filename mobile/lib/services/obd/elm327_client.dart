import 'dart:async';

import 'obd_transport.dart';

/// The outcome of the ELM327 init sequence.
class Elm327InitResult {
  /// Adapter banner returned by `ATZ`, e.g. `ELM327 v1.5`.
  final String banner;

  /// Response to `ATE0` (echo off), normally `OK`.
  final String echoOff;

  /// Response to `ATSP0` (auto-detect protocol), normally `OK`.
  final String protocol;

  const Elm327InitResult({
    required this.banner,
    required this.echoOff,
    required this.protocol,
  });

  @override
  String toString() => 'ATZ="$banner" ATE0="$echoOff" ATSP0="$protocol"';
}

/// Speaks the ELM327 AT-command protocol over any [ObdTransport].
///
/// Responsibilities (all of which are worth explaining in a viva):
/// - Terminate commands with `\r` and wait for the `>` prompt.
/// - Buffer across packets, because a response can arrive in several chunks.
/// - Strip the echoed command: after `ATZ` the adapter echoes by default, so
///   the reply to `ATE0` literally comes back as `ATE0\rOK\r>`.
/// - Enforce a timeout so a missing adapter can't hang the app.
class Elm327Client {
  final ObdTransport transport;

  /// Receives human-readable log lines, e.g. `> ATZ` / `< ELM327 v1.5`.
  final void Function(String line)? onLog;

  final Duration commandTimeout;

  StreamSubscription<String>? _subscription;
  final StringBuffer _buffer = StringBuffer();
  Completer<String>? _pending;
  String _lastCommand = '';

  Elm327Client(
    this.transport, {
    this.onLog,
    this.commandTimeout = const Duration(seconds: 5),
  });

  /// Runs the ELM327 initialisation sequence: `ATZ` → `ATE0` → `ATSP0`.
  ///
  /// `ATZ` resets the adapter, `ATE0` disables command echo (so later replies
  /// are clean), and `ATSP0` lets the adapter auto-detect the car's protocol.
  Future<Elm327InitResult> initialize({
    Duration settleAfterReset = const Duration(seconds: 1),
  }) async {
    final banner = await sendCommand('ATZ');
    // Give the adapter a moment to finish settling after its reset.
    await Future.delayed(settleAfterReset);
    final echoOff = await sendCommand('ATE0');
    final protocol = await sendCommand('ATSP0');
    return Elm327InitResult(
      banner: banner,
      echoOff: echoOff,
      protocol: protocol,
    );
  }

  /// Sends a single [command] and returns the adapter's cleaned response.
  Future<String> sendCommand(String command) async {
    _ensureListening();

    final cmd = command.trim().toUpperCase();
    _lastCommand = cmd;
    _buffer.clear();
    _pending = Completer<String>();

    onLog?.call('> $cmd');
    await transport.writeRaw('$cmd\r');

    final completer = _pending!;
    final response = await completer.future.timeout(
      commandTimeout,
      onTimeout: () {
        _pending = null;
        throw ObdTransportException('Timeout waiting for "$cmd" response');
      },
    );

    _logResponse(response);
    return response;
  }

  void _ensureListening() {
    _subscription ??= transport.input.listen(
      _onData,
      onError: (Object error) {
        final completer = _pending;
        _pending = null;
        if (completer != null && !completer.isCompleted) {
          completer.completeError(ObdTransportException('Transport error: $error'));
        }
      },
    );
  }

  void _onData(String chunk) {
    _buffer.write(chunk);
    final text = _buffer.toString();
    final promptIndex = text.indexOf('>');
    if (promptIndex == -1) return; // still waiting for the prompt

    final raw = text.substring(0, promptIndex);
    final remainder = text.substring(promptIndex + 1);
    _buffer
      ..clear()
      ..write(remainder);

    final completer = _pending;
    _pending = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(_clean(raw));
    }
  }

  /// Turns the raw reply into clean text: splits on line breaks, trims, drops
  /// blank lines, and drops the echoed command (if echo was on).
  String _clean(String raw) {
    final echoedUpper = _lastCommand.toUpperCase();
    final lines = raw
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .where((line) => line.toUpperCase() != echoedUpper);
    return lines.join('\n');
  }

  void _logResponse(String response) {
    if (response.trim().isEmpty) {
      onLog?.call('< (no data)');
      return;
    }
    for (final line in response.split('\n')) {
      onLog?.call('< $line');
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
