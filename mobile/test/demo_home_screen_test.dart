import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autointel/screens/demo_home_screen.dart';

void main() {
  testWidgets('demo home shows branding, vehicle and actions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DemoHomeScreen()));

    expect(find.text('AutoIntel'), findsOneWidget);
    expect(find.text('AI Vehicle Diagnostics'), findsOneWidget);
    expect(find.text('2019 Toyota Corolla'), findsOneWidget);
    expect(find.text('Run Full Diagnostic'), findsOneWidget);
    expect(find.text('OBD-II Connection'), findsOneWidget);
  });

  testWidgets('demo home navigates to the connection screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DemoHomeScreen()));

    await tester.tap(find.text('OBD-II Connection'));
    await tester.pumpAndSettle();

    expect(find.text('Use mock adapter'), findsOneWidget);
  });
}
