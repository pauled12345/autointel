import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import 'diagnostics_screen.dart';

class GarageScreen extends StatelessWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vehicles = context.watch<VehicleProvider>().vehicles;

    return Scaffold(
      appBar: AppBar(title: const Text('Garage')),
      body: vehicles.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              itemBuilder: (context, index) =>
                  _VehicleCard(vehicle: vehicles[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVehicle(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
      ),
    );
  }

  Future<void> _showAddVehicle(BuildContext context) async {
    final provider = context.read<VehicleProvider>();
    final make = TextEditingController();
    final model = TextEditingController();
    final year = TextEditingController();
    final nickname = TextEditingController();

    final result = await showDialog<Vehicle>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vehicle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: make,
                decoration: const InputDecoration(labelText: 'Make'),
                textCapitalization: TextCapitalization.words,
              ),
              TextField(
                controller: model,
                decoration: const InputDecoration(labelText: 'Model'),
                textCapitalization: TextCapitalization.words,
              ),
              TextField(
                controller: year,
                decoration: const InputDecoration(labelText: 'Year'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: nickname,
                decoration: const InputDecoration(labelText: 'Nickname (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                Vehicle(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  make: make.text.trim().isEmpty ? 'Unknown' : make.text.trim(),
                  model: model.text.trim().isEmpty ? 'Vehicle' : model.text.trim(),
                  year: int.tryParse(year.text.trim()) ?? DateTime.now().year,
                  nickname: nickname.text.trim().isEmpty
                      ? null
                      : nickname.text.trim(),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) provider.addVehicle(result);
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.directions_car,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          vehicle.nickname ?? '${vehicle.year} ${vehicle.make} ${vehicle.model}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${vehicle.make} ${vehicle.model} · ${vehicle.year}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DiagnosticsScreen(vehicleId: vehicle.id, autoRun: true),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.garage,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text('No vehicles yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Vehicle" to get started.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
