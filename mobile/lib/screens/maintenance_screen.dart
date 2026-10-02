import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/demo_data.dart';
import '../models/maintenance_log.dart';
import '../providers/vehicle_provider.dart';
import '../services/data_repository.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final DataRepository _repo = DataRepository();
  List<MaintenanceLog> _logs = demoMaintenanceLogs;
  String? _loadedForVehicleId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vehicles = context.watch<VehicleProvider>().vehicles;
    final id = vehicles.isNotEmpty ? vehicles.first.id : 'demo';
    if (id != _loadedForVehicleId) {
      _loadedForVehicleId = id;
      _fetch(id);
    }
  }

  Future<void> _fetch(String vehicleId) async {
    final logs = await _repo.fetchMaintenance(vehicleId);
    if (mounted) setState(() => _logs = logs);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _logs.length,
        itemBuilder: (context, index) {
          final log = _logs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (log.done ? Colors.green : Colors.orange)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  log.done ? Icons.check_circle : Icons.schedule,
                  color: log.done ? Colors.green : Colors.orange,
                ),
              ),
              title: Text(
                log.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${formatDate(log.date)} · ${formatKm(log.mileageKm)}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMoney(log.cost),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    log.done ? 'Done' : 'Scheduled',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: log.done ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showComingSoon(context),
        icon: const Icon(Icons.add),
        label: const Text('Log Service'),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Service logging is coming soon.')),
    );
  }
}
