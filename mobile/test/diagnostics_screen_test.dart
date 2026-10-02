import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autointel/screens/diagnostics_screen.dart';
import 'package:autointel/services/data_repository.dart';

/// Forces the offline fallback path so the test never touches the network.
class _OfflineRepository extends DataRepository {
  @override
  Future<String> startDiagnosticsSession(String vehicleId) async {
    throw Exception('offline');
  }
}

/// Drives the real DiagnosticsScreen end to end against the mock adapter,
/// tapping the same buttons a user would.
void main() {
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  testWidgets('connect, read codes, AI explanation, live data, clear',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: DiagnosticsScreen(
          vehicleId: 'demo',
          repository: _OfflineRepository(),
        ),
      ),
    );

    expect(find.text('Not connected'), findsOneWidget);
    expect(find.text('Fault Codes (0)'), findsOneWidget);

    await tester.tap(find.text('Connect & Init'));
    await settle(tester);
    expect(find.text('Initialized'), findsOneWidget);
    expect(find.text('< ELM327 v1.5'), findsOneWidget);

    await tester.tap(find.text('Read Codes'));
    await settle(tester);
    expect(find.text('Fault Codes (2)'), findsOneWidget);
    expect(find.text('P0133'), findsOneWidget);
    expect(find.text('P0301'), findsOneWidget);
    expect(find.text('high'), findsOneWidget);

    await tester.tap(find.text('P0301'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('AI · P0301'), findsOneWidget);
    expect(find.text('Severity: HIGH'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Refresh'));
    await settle(tester);
    expect(find.text('1726 rpm'), findsOneWidget);
    expect(find.text('60.0 km/h'), findsOneWidget);
    expect(find.text('83.0 °C'), findsOneWidget);
    expect(find.text('50.2 %'), findsOneWidget);

    await tester.tap(find.text('Clear Codes'));
    await settle(tester);
    expect(find.text('Fault Codes (0)'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
