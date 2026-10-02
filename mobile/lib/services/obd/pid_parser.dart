/// A live sensor (PID) the app knows how to display.
class PidSpec {
  final String pid;
  final String name;
  final String unit;

  const PidSpec(this.pid, this.name, this.unit);
}

/// The live PIDs required for Phase 4.
const List<PidSpec> kLivePids = [
  PidSpec('010C', 'RPM', 'rpm'),
  PidSpec('010D', 'Speed', 'km/h'),
  PidSpec('0105', 'Coolant Temp', '°C'),
  PidSpec('0104', 'Engine Load', '%'),
];

/// A decoded live reading.
class PidReading {
  final PidSpec spec;
  final double value;

  const PidReading(this.spec, this.value);
}

/// Decodes a Mode 01 reply for [pid] (e.g. `41 0C 1A F8`) into a value.
///
/// Formula per PID (from the OBD-II standard):
/// - `010C` RPM        = ((A * 256) + B) / 4
/// - `010D` Speed      = A
/// - `0105` Coolant    = A - 40
/// - `0104` EngineLoad = A * 100 / 255
///
/// Returns null if the reply is missing, an error, or too short.
PidReading? decodePid(PidSpec pid, String response) {
  final bytes = _dataBytes(response);
  if (bytes.isEmpty) return null;

  final a = bytes[0];
  switch (pid.pid) {
    case '010C':
      if (bytes.length < 2) return null;
      final b = bytes[1];
      return PidReading(pid, ((a * 256) + b) / 4);
    case '010D':
      return PidReading(pid, a.toDouble());
    case '0105':
      return PidReading(pid, (a - 40).toDouble());
    case '0104':
      return PidReading(pid, a * 100 / 255);
    default:
      return null;
  }
}

/// Extracts the data bytes from a Mode 01 reply, skipping the echoed command,
/// the `41` mode byte, and the PID byte.
List<int> _dataBytes(String response) {
  final all = <int>[];
  for (final token in response.split(RegExp(r'[\s\r\n]+'))) {
    if (token.isEmpty) continue;
    final value = int.tryParse(token, radix: 16);
    if (value != null) all.add(value);
  }
  final start = all.indexOf(0x41);
  final body = start == -1 ? all : all.sublist(start + 1);
  // body[0] is the PID byte; the actual data follows it.
  return body.length >= 2 ? body.sublist(1) : <int>[];
}
