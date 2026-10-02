import 'package:flutter_test/flutter_test.dart';

import 'package:autointel/services/diagnostics_service.dart';
import 'package:autointel/services/obd/dtc_parser.dart';
import 'package:autointel/services/obd/elm327_client.dart';
import 'package:autointel/services/obd/mock_elm327_transport.dart';
import 'package:autointel/services/obd/obd_transport.dart';
import 'package:autointel/services/obd/pid_parser.dart';

void main() {
  group('parseDtcCodes', () {
    test('decodes two codes and ignores padding', () {
      expect(parseDtcCodes('43 01 33 03 01 00 00'), ['P0133', 'P0301']);
    });

    test('returns empty list when there are no codes', () {
      expect(parseDtcCodes('43 00 00 00 00 00 00'), isEmpty);
    });

    test('decodes chassis/body/network letters', () {
      expect(parseDtcCodes('43 41 23 81 23 C1 23'), ['C0123', 'B0123', 'U0123']);
    });
  });

  group('decodePid', () {
    PidSpec spec(String pid) => kLivePids.firstWhere((p) => p.pid == pid);

    test('RPM = ((A*256)+B)/4', () {
      expect(decodePid(spec('010C'), '41 0C 1A F8')!.value, 1726);
    });

    test('speed = A', () {
      expect(decodePid(spec('010D'), '41 0D 3C')!.value, 60);
    });

    test('coolant = A - 40', () {
      expect(decodePid(spec('0105'), '41 05 7B')!.value, 83);
    });

    test('engine load = A*100/255', () {
      expect(decodePid(spec('0104'), '41 04 80')!.value, closeTo(50.2, 0.1));
    });

    test('returns null for NO DATA', () {
      expect(decodePid(spec('010C'), 'NO DATA'), isNull);
    });
  });

  group('DiagnosticsService against the mock', () {
    late MockElm327Transport mock;
    late Elm327Client client;
    late DiagnosticsService service;

    setUp(() async {
      mock = MockElm327Transport(bootDelay: Duration.zero);
      await mock.connect(const ObdDevice(name: 'Mock', address: '00'));
      client = Elm327Client(mock, commandTimeout: const Duration(seconds: 2));
      await client.initialize(settleAfterReset: Duration.zero);
      service = DiagnosticsService(client);
    });

    tearDown(() async {
      await client.dispose();
      await mock.disconnect();
    });

    test('reads fault codes (Mode 03)', () async {
      expect(await service.readFaultCodes(), ['P0133', 'P0301']);
    });

    test('clears fault codes (Mode 04)', () async {
      expect(await service.clearFaultCodes(), isTrue);
    });

    test('reads all four live PIDs (Mode 01)', () async {
      final readings = await service.readLiveData();
      expect(readings.map((r) => r.spec.name),
          ['RPM', 'Speed', 'Coolant Temp', 'Engine Load']);
      expect(readings.first.value, 1726);
    });
  });
}
