import 'package:flutter/material.dart';

import 'screens/demo_home_screen.dart';

/// Offline demo entry point that skips Firebase so the full OBD + AI flow can
/// be shown with the in-app mock adapter.
///
/// Run with: flutter run -t lib/main_demo.dart
void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoIntel Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF17A398),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const DemoHomeScreen(),
    );
  }
}
