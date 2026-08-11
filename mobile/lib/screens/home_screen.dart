import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vehicle_provider.dart';
import 'diagnostics_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vehicles = context.watch<VehicleProvider>().vehicles;

    return Scaffold(
      appBar: AppBar(title: const Text('My Vehicles')),
      body: vehicles.isEmpty
          ? const Center(child: Text('No vehicles added yet.'))
          : ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final v = vehicles[index];
                return ListTile(
                  title: Text(v.nickname ?? '${v.year} ${v.make} ${v.model}'),
                  subtitle: Text('${v.make} ${v.model} (${v.year})'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DiagnosticsScreen(vehicleId: v.id)),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: navigate to add-vehicle screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
