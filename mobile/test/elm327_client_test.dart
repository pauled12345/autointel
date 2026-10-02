import 'package:flutter_test/flutter_test.dart';

import 'package:autointel/services/obd/elm327_client.dart';
import 'package:autointel/services/obd/mock_elm327_transport.dart';
import 'package:autointel/services/obd/obd_transport.dart';
import 'package:autointel/services/obd_service.dart';

void main() {
  late MockElm327Transport mock;
  late Elm327Client client;

  setUp(() async {
    mock = MockElm327Transport(bootDelay: const Duration(milliseconds: 10));
    await mock.connect(const ObdDevice(name: 'Mock', address: '00:00:00:00:00:00'));
    client = Elm327Client(mock, commandTimeout: const Duration(seconds: 2));
  });

  tearDown(() async {
    await client.dispose();
    await mock.disconnect();
  });

  group('Elm327Client init sequence', () {
    test('runs ATZ, ATE0, ATSP0 in that exact order', () async {
      await client.initialize(settleAfterReset: Duration.zero);

      expect(mock.receivedCommands, ['ATZ', 'ATE0', 'ATSP0']);
    });

    test('surfaces the adapter banner and OK acknowledgements', () async {
      final result = await client.initialize(settleAfterReset: Duration.zero);

      expect(result.banner, 'ELM327 v1.5');
      expect(result.echoOff, 'OK');
      expect(result.protocol, 'OK');
    });

    test('strips the echoed command from the ATE0 reply', () async {
      // After ATZ echo is ON, so the adapter echoes "ATE0" before "OK".
      expect(mock.echoEnabled, isTrue);

      final result = await client.initialize(settleAfterReset: Duration.zero);

      // If echo were not stripped this would be "ATE0\nOK".
      expect(result.echoOff, 'OK');
    });

    test('ATZ re-enables echo even after it was turned off', () async {
      await client.sendCommand('ATE0');
      expect(mock.echoEnabled, isFalse);

      await client.sendCommand('ATZ');
      expect(mock.echoEnabled, isTrue);
    });

    test('buffers a response split across multiple packets until the prompt', () async {
      // The mock emits the ATZ banner and the ">" prompt as separate chunks.
      final banner = await client.sendCommand('ATZ');

      expect(banner, 'ELM327 v1.5');
    });

    test('unknown AT command returns "?"', () async {
      final response = await client.sendCommand('ATXX');

      expect(response, '?');
    });

    test('throws ObdTransportException when the adapter stays silent', () async {
      final silentMock = MockElm327Transport(
        bootDelay: Duration.zero,
        silent: true,
      );
      await silentMock.connect(
        const ObdDevice(name: 'Silent', address: '00:00:00:00:00:00'),
      );
      final silentClient = Elm327Client(
        silentMock,
        commandTimeout: const Duration(milliseconds: 100),
      );

      await expectLater(
        silentClient.sendCommand('ATZ'),
        throwsA(isA<ObdTransportException>()),
      );

      await silentClient.dispose();
      await silentMock.disconnect();
    });
  });

  group('ObdService with the mock adapter', () {
    test('scans, connects and initializes end to end', () async {
      final service = ObdService();
      final log = <String>[];

      final devices = await service.scanForAdapters(useMock: true);
      expect(devices, hasLength(1));

      // Use the service's own mock transport (boot delay is the real default,
      // so this also checks the sequence is not order-dependent on timing).
      await service.connect(devices.first, useMock: true, onLog: log.add);
      expect(service.isConnected, isTrue);

      final result = await service.initialize();
      expect(result.banner, 'ELM327 v1.5');
      expect(result.echoOff, 'OK');
      expect(result.protocol, 'OK');

      expect(log, contains('> ATZ'));
      expect(log, contains('< ELM327 v1.5'));

      await service.disconnect();
      expect(service.isConnected, isFalse);
    });
  });
}
