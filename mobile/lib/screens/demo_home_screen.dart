import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import 'connection_screen.dart';
import 'diagnostics_screen.dart';

/// Landing screen for the offline demo. Gives the app a proper "home" that
/// tells the AutoIntel story and gets the presenter into a live diagnostic in
/// one tap — no Firebase or real car required.
class DemoHomeScreen extends StatelessWidget {
  const DemoHomeScreen({super.key});

  static final Vehicle _demoVehicle = Vehicle(
    id: 'demo-vehicle',
    make: 'Toyota',
    model: 'Corolla',
    year: 2019,
    nickname: 'My Corolla',
    vin: '1HGBH41JXMN109186',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(theme),
            const SizedBox(height: 24),
            _buildVehicleCard(theme),
            const SizedBox(height: 16),
            _buildDiagnosticCard(context, theme),
            const SizedBox(height: 16),
            _buildConnectionCard(context, theme),
            const SizedBox(height: 16),
            _buildDemoNote(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: theme.colorScheme.primary,
          child: Icon(
            Icons.directions_car,
            size: 28,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AutoIntel',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'AI Vehicle Diagnostics',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVehicleCard(ThemeData theme) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(Icons.directions_car, color: theme.colorScheme.primary),
        title: Text('${_demoVehicle.year} ${_demoVehicle.make} ${_demoVehicle.model}'),
        subtitle: Text(_demoVehicle.vin!),
        trailing: Chip(
          label: const Text('Demo'),
          backgroundColor: theme.colorScheme.primaryContainer,
        ),
      ),
    );
  }

  Widget _buildDiagnosticCard(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Full Diagnostic', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Connect to the adapter, read fault codes, get an AI '
              'explanation, and stream live sensor data.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const DiagnosticsScreen(vehicleId: 'demo', autoRun: true),
                  ),
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run Full Diagnostic'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(BuildContext context, ThemeData theme) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(Icons.bluetooth, color: theme.colorScheme.primary),
        title: const Text('OBD-II Connection'),
        subtitle: const Text('Scan, connect and watch the AT init sequence'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ConnectionScreen()),
        ),
      ),
    );
  }

  Widget _buildDemoNote(ThemeData theme) {
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'This demo runs against a simulated ELM327 adapter, so the '
                'whole flow works with no car and no hardware.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
