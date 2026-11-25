import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/notification_provider.dart';
import '../providers/vehicle_provider.dart';
import 'connection_screen.dart';
import 'diagnostics_screen.dart';
import 'notifications_screen.dart';

class DashboardScreen extends StatelessWidget {
  final void Function(int index) onSwitchTab;

  const DashboardScreen({super.key, required this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicles = context.watch<VehicleProvider>().vehicles;
    final notifications = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AutoIntel'),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${notifications.unreadCount}'),
              isLabelVisible: notifications.unreadCount > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: 'Notifications',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
        ],
      ),
      body: vehicles.isEmpty
          ? _EmptyGarage(onAddVehicle: () => onSwitchTab(1))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(
                  'Good to see you',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your garage',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 20),
                _VehicleCard(vehicle: vehicles.first),
                const SizedBox(height: 28),
                _buildQuickActions(context, vehicles.first.id, theme),
              ],
            ),
    );
  }

  Widget _buildQuickActions(
      BuildContext context, String vehicleId, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What do you need?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _QuickAction(
          icon: Icons.speed,
          label: 'Run a diagnostic',
          detail: 'Read fault codes and live data',
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
        _QuickAction(
          icon: Icons.build_outlined,
          label: 'Service history',
          detail: 'Log and review maintenance',
          onTap: () => onSwitchTab(3),
        ),
        _QuickAction(
          icon: Icons.local_gas_station_outlined,
          label: 'Fuel log',
          detail: 'Track fills and economy',
          onTap: () => onSwitchTab(2),
        ),
        _QuickAction(
          icon: Icons.bluetooth,
          label: 'OBD link',
          detail: 'Pair an ELM327 adapter',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ConnectionScreen()),
          ),
        ),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;

  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'READY',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            vehicle.nickname ?? '${vehicle.make} ${vehicle.model}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${vehicle.year}  ·  ${vehicle.make} ${vehicle.model}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
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
              label: const Text('Run diagnostic'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGarage extends StatelessWidget {
  final VoidCallback onAddVehicle;

  const _EmptyGarage({required this.onAddVehicle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car_outlined,
                size: 72, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Welcome to AutoIntel',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Add your first vehicle to start running diagnostics.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddVehicle,
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle'),
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
  final String detail;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        detail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
