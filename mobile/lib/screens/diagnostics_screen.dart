import 'package:flutter/material.dart';

class DiagnosticsScreen extends StatelessWidget {
  final String vehicleId;
  const DiagnosticsScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: Center(
        child: Text('Fault codes for vehicle $vehicleId will appear here.'),
      ),
    );
  }
}
