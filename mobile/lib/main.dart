import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/auth_provider.dart';
import 'providers/vehicle_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AutoIntelApp());
}

class AutoIntelApp extends StatelessWidget {
  const AutoIntelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
      ],
      child: MaterialApp(
        title: 'AutoIntel',
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF17A398),
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return auth.isSignedIn ? const HomeScreen() : const LoginScreen();
          },
        ),
      ),
    );
  }
}
