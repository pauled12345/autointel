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

  /// Mode 01 — read all [kLivePids] once, then append the derived instant
  /// fuel economy (km/l = Speed ÷ Fuel Rate).
  Future<List<PidReading>> readLiveData() async {
    final readings = <PidReading>[];
    for (final pid in kLivePids) {
      final response = await client.sendCommand(pid.pid);
      final reading = decodePid(pid, response);
      if (reading != null) readings.add(reading);
    }
    final economy = _deriveFuelEconomy(readings);
    if (economy != null) readings.add(economy);
    return readings;
  }

  /// Computes instant fuel economy (km/l) from the Speed and Fuel Rate PIDs.
  /// Returns null when either is missing or the fuel rate is not positive.
  PidReading? _deriveFuelEconomy(List<PidReading> readings) {
    double? speed;
    double? fuelRate;
    for (final r in readings) {
      if (r.spec.pid == '010D') speed = r.value;
      if (r.spec.pid == '015E') fuelRate = r.value;
    }
    if (speed == null || fuelRate == null || fuelRate <= 0) return null;
    return PidReading(kFuelEconomySpec, speed / fuelRate);
  }
}
