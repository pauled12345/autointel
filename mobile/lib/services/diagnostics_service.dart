import 'obd/elm327_client.dart';
import 'obd/dtc_parser.dart';
import 'obd/pid_parser.dart';

/// Decodes a Mode 03 reply into a list of fault-code strings.
class DiagnosticsService {
  final Elm327Client client;

  DiagnosticsService(this.client);

  /// Mode 03 — read stored diagnostic trouble codes.
  Future<List<String>> readFaultCodes() async {
    final response = await client.sendCommand('03');
    return parseDtcCodes(response);
  }

  /// Mode 04 — clear stored codes and the malfunction indicator lamp.
  Future<bool> clearFaultCodes() async {
    final response = await client.sendCommand('04');
    final upper = response.toUpperCase();
    return upper.contains('44') || upper.contains('OK');
  }

  /// Mode 01 — read all [kLivePids] once.
  Future<List<PidReading>> readLiveData() async {
    final readings = <PidReading>[];
    for (final pid in kLivePids) {
      final response = await client.sendCommand(pid.pid);
      final reading = decodePid(pid, response);
      if (reading != null) readings.add(reading);
    }
    return readings;
  }
}
