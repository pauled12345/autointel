import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/demo_data.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import 'connection_screen.dart';
import 'diagnostics_screen.dart';

class DashboardScreen extends StatelessWidget {
  final void Function(int index) onSwitchTab;

  const DashboardScreen({super.key, required this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicles = context.watch<VehicleProvider>().vehicles;
    final vehicle = vehicles.isNotEmpty ? vehicles.first : demoVehicle;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AutoIntel'),
        actions: [
          IconButton(
            icon: const Badge(
              label: Text('2'),
              child: Icon(Icons.notifications_outlined),
            ),
            tooltip: 'Notifications',
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HealthCard(vehicle: vehicle),
          const SizedBox(height: 16),
          _buildStatsGrid(theme),
          const SizedBox(height: 16),
          _buildQuickActions(context, vehicle.id, theme),
          const SizedBox(height: 16),
          _buildUpcomingMaintenance(theme),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ThemeData theme) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.9,
      children: const [
        _StatTile(
          icon: Icons.warning_amber,
          color: Colors.orange,
          value: '2',
          label: 'Active DTCs',
        ),
        _StatTile(
          icon: Icons.build,
          color: Colors.redAccent,
          value: '1',
          label: 'Maintenance due',
        ),
        _StatTile(
          icon: Icons.local_gas_station,
          color: Colors.tealAccent,
          value: '8.4 L',
          label: 'Avg / 100 km',
        ),
        _StatTile(
          icon: Icons.event,
          color: Colors.lightBlueAccent,
          value: 'Oct 15',
          label: 'Next service',
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, String vehicleId, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick actions', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.speed,
                label: 'Diagnose',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiagnosticsScreen(
                      vehicleId: vehicleId,
                      autoRun: true,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.build,
                label: 'Maintenance',
                onTap: () => onSwitchTab(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.local_gas_station,
                label: 'Fuel',
                onTap: () => onSwitchTab(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.bluetooth,
                label: 'OBD Link',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConnectionScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpcomingMaintenance(ThemeData theme) {
    final upcoming = demoMaintenanceLogs.where((m) => !m.done).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upcoming maintenance', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final log in upcoming)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(log.title),
              subtitle: Text('${formatDate(log.date)} · ${formatKm(log.mileageKm)}'),
              trailing: Text(
                formatMoney(log.cost),
                style: theme.textTheme.titleSmall,
              ),
            ),
          ),
      ],
    );
  }
}

class _HealthCard extends StatelessWidget {
  final Vehicle vehicle;

  const _HealthCard({required this.vehicle});

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
          Row(
            children: [
              const Icon(Icons.directions_car, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.nickname ?? '${vehicle.year} ${vehicle.make} ${vehicle.model}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    Text(
                      '${vehicle.year} ${vehicle.make} ${vehicle.model}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, size: 16, color: Colors.amber),
                    SizedBox(width: 4),
                    Text('Needs attention', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '2 active fault codes detected (P0133, P0301).',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.onPrimary,
                foregroundColor: theme.colorScheme.primary,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DiagnosticsScreen(
                    vehicleId: vehicle.id,
                    autoRun: true,
                  ),
                ),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run Full Diagnostic'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 28),
              const SizedBox(height: 8),
              Text(label, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
