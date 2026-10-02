import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/demo_data.dart';
import '../models/fuel_log.dart';
import '../providers/vehicle_provider.dart';
import '../services/data_repository.dart';

class FuelScreen extends StatefulWidget {
  const FuelScreen({super.key});

  @override
  State<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen> {
  final DataRepository _repo = DataRepository();
  List<FuelLog> _logs = demoFuelLogs;
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
    final logs = await _repo.fetchFuel(vehicleId);
    if (mounted) setState(() => _logs = logs);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalLiters = _logs.fold<double>(0, (sum, f) => sum + f.liters);
    final totalCost = _logs.fold<double>(0, (sum, f) => sum + f.totalCost);

    return Scaffold(
      appBar: AppBar(title: const Text('Fuel')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(totalLiters: totalLiters, totalCost: totalCost),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showComingSoon(context),
        icon: const Icon(Icons.add),
        label: const Text('Log Fill-up'),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fuel logging is coming soon.')),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double totalLiters;
  final double totalCost;

  const _SummaryCard({
    required this.totalLiters,
    required this.totalCost,
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
            '8.4 L/100 km',
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
