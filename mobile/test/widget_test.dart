import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autointel/screens/connection_screen.dart';

void main() {
  testWidgets('Connection screen shows the mock adapter toggle', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ConnectionScreen()));

    expect(find.text('Use mock adapter'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
  });
}
