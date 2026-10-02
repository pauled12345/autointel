import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/vehicle_provider.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'services/auth_service.dart';

class AutoIntelApp extends StatelessWidget {
  final AuthService authService;
  final VehicleProvider vehicleProvider;

  const AutoIntelApp({
    super.key,
    required this.authService,
    required this.vehicleProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider<VehicleProvider>.value(value: vehicleProvider),
      ],
      child: MaterialApp(
        title: 'AutoIntel',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF17A398),
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) =>
              auth.isSignedIn ? const ShellScreen() : const LoginScreen(),
        ),
      ),
    );
  }
}
