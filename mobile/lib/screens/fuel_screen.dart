import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/fuel_log.dart';
import '../providers/vehicle_provider.dart';
import '../services/data_repository.dart';
import '../utils/format.dart';

class FuelScreen extends StatefulWidget {
  const FuelScreen({super.key});

  @override
  State<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen> {
  final DataRepository _repo = DataRepository();
  List<FuelLog> _logs = [];
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
    final logs = await _repo.fetchFuel(vehicleId);
    if (mounted) setState(() => _logs = logs);
  }

  Future<void> _showAddFill() async {
    final vehicleId = _loadedForVehicleId;
    if (vehicleId == null) return;
    final result = await showDialog<FuelLog>(
      context: context,
      builder: (_) => const _AddFillDialog(),
    );
    if (result == null || !mounted) return;
    final created = await _repo.createFuel(vehicleId, result);
    if (!mounted) return;
    setState(() => _logs = [created, ..._logs]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalLiters = _logs.fold<double>(0, (sum, f) => sum + f.liters);
    final totalCost = _logs.fold<double>(0, (sum, f) => sum + f.totalCost);
    final economyKml = averageFuelEconomyKml(_logs);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel'),
        actions: [
          IconButton(
            onPressed: _loadedForVehicleId == null ? null : _showAddFill,
            icon: const Icon(Icons.add),
            tooltip: 'Log Fill-up',
          ),
        ],
      ),
      body: _logs.isEmpty
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryCard(
                  totalLiters: totalLiters,
                  totalCost: totalCost,
                  economyKml: economyKml,
                ),
                const SizedBox(height: 16),
                Text('Recent fills', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final log in _logs)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.local_gas_station),
                      title: Text(formatDate(log.date)),
                      subtitle: Text(
                        '${formatKm(log.odometerKm)} · ${log.liters.toStringAsFixed(1)} L',
                      ),
                      trailing: Text(
                        formatMoney(log.totalCost),
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ),
              ],
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
          Icon(Icons.local_gas_station_outlined,
              size: 64, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('No fuel logs yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Add your first fill-up to start tracking economy.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double totalLiters;
  final double totalCost;
  final double economyKml;

  const _SummaryCard({
    required this.totalLiters,
    required this.totalCost,
    required this.economyKml,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Average economy',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            economyKml == 0 ? '— km/l' : '${economyKml.toStringAsFixed(1)} km/l',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: 'Total fuel',
                  value: '${totalLiters.toStringAsFixed(1)} L',
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              Expanded(
                child: _SummaryStat(
                  label: 'Total spend',
                  value: formatMoney(totalCost),
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _AddFillDialog extends StatefulWidget {
  const _AddFillDialog();

  @override
  State<_AddFillDialog> createState() => _AddFillDialogState();
}

class _AddFillDialogState extends State<_AddFillDialog> {
  final _formKey = GlobalKey<FormState>();
  final _liters = TextEditingController();
  final _cost = TextEditingController();
  final _odometer = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _liters.dispose();
    _cost.dispose();
    _odometer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Fill-up'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _liters,
                decoration: const InputDecoration(labelText: 'Litres'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Enter litres';
                  return null;
                },
              ),
              TextFormField(
                controller: _cost,
                decoration: const InputDecoration(labelText: 'Cost (\$)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              TextFormField(
                controller: _odometer,
                decoration: const InputDecoration(labelText: 'Odometer (km)'),
                keyboardType: TextInputType.number,
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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      FuelLog(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        date: _date,
        odometerKm: int.tryParse(_odometer.text.trim()) ?? 0,
        liters: double.tryParse(_liters.text.trim()) ?? 0,
        totalCost: double.tryParse(_cost.text.trim()) ?? 0,
      ),
    );
  }
}
