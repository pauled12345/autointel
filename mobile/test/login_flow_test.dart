import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autointel/app.dart';
import 'package:autointel/providers/vehicle_provider.dart';
import 'package:autointel/services/mock_auth_service.dart';

void main() {
  testWidgets('mock auth signs in and lands on the dashboard', (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AutoIntelApp(
        authService: MockAuthService(),
        vehicleProvider: VehicleProvider(),
      ),
    );

    expect(find.text('AutoIntel'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    await tester.tap(find.text('Use demo account'));
    await tester.pumpAndSettle();

    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('Run Full Diagnostic'), findsOneWidget);
  });
}
