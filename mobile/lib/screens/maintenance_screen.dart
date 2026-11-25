import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/maintenance_log.dart';
import '../providers/vehicle_provider.dart';
import '../services/data_repository.dart';
import '../utils/format.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final DataRepository _repo = DataRepository();
  List<MaintenanceLog> _logs = [];
  String? _loadedForVehicleId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vehicles = context.watch<VehicleProvider>().vehicles;
    final id = vehicles.isNotEmpty ? vehicles.first.id : null;
    if (id != null && id != _loadedForVehicleId) {
      _loadedForVehicleId = id;
      _fetch(id);
    }
  }

  Future<void> _fetch(String vehicleId) async {
    final logs = await _repo.fetchMaintenance(vehicleId);
    if (mounted) setState(() => _logs = logs);
  }

  Future<void> _showAddService() async {
    final vehicleId = _loadedForVehicleId;
    if (vehicleId == null) return;
    final result = await showDialog<MaintenanceLog>(
      context: context,
      builder: (_) => const _AddServiceDialog(),
    );
    if (result == null || !mounted) return;
    final created = await _repo.createMaintenance(vehicleId, result);
    if (!mounted) return;
    setState(() => _logs = [created, ..._logs]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
        actions: [
          IconButton(
            onPressed: _loadedForVehicleId == null ? null : _showAddService,
            icon: const Icon(Icons.add),
            tooltip: 'Log Service',
          ),
        ],
      ),
      body: _logs.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final detail = log.notes == null || log.notes!.isEmpty
                    ? '${formatDate(log.date)} · ${formatKm(log.mileageKm)}'
                    : '${formatDate(log.date)} · ${formatKm(log.mileageKm)}\n${log.notes}';
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
                    subtitle: Text(detail),
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
          Icon(Icons.build_outlined,
              size: 64, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('No service history yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Log your first service to start tracking maintenance.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _AddServiceDialog extends StatefulWidget {
  const _AddServiceDialog();

  @override
  State<_AddServiceDialog> createState() => _AddServiceDialogState();
}

class _AddServiceDialogState extends State<_AddServiceDialog> {
  final _cost = TextEditingController();
  final _odometer = TextEditingController();
  final _notes = TextEditingController();
  String _type = 'oil_change';
  DateTime _date = DateTime.now();

  static const Map<String, String> _types = {
    'Oil & Filter Change': 'oil_change',
    'Tire Rotation': 'tire_rotation',
    'Brake Pad Replacement': 'brake_pads',
    'Coolant Flush': 'coolant_flush',
    'Air Filter': 'air_filter',
    'Spark Plugs': 'spark_plugs',
    'Battery': 'battery',
    'Other': 'other',
  };

  @override
  void dispose() {
    _cost.dispose();
    _odometer.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Service'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Service type'),
              items: _types.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.value, child: Text(e.key)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? 'oil_change'),
            ),
            TextField(
              controller: _odometer,
              decoration: const InputDecoration(labelText: 'Odometer (km)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _cost,
              decoration: const InputDecoration(labelText: 'Cost (\$)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text('Date: ${formatDate(_date)}'),
              onTap: _pickDate,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    Navigator.pop(
      context,
      MaintenanceLog(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        type: _type,
        date: _date,
        mileageKm: int.tryParse(_odometer.text.trim()) ?? 0,
        cost: double.tryParse(_cost.text.trim()) ?? 0,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ),
    );
  }
}
