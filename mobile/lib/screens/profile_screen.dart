import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _maintenanceReminders = true;
  bool _criticalAlerts = true;
  bool _fuelTips = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                user?.displayName ?? user?.email ?? 'Driver',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(user?.email ?? ''),
            ),
          ),
          const SizedBox(height: 16),
          Text('Notifications', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Maintenance reminders'),
                  subtitle: const Text('Get notified before services are due'),
                  value: _maintenanceReminders,
                  onChanged: (v) =>
                      setState(() => _maintenanceReminders = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Critical fault alerts'),
                  subtitle: const Text('Immediate alerts for serious DTCs'),
                  value: _criticalAlerts,
                  onChanged: (v) => setState(() => _criticalAlerts = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Fuel economy tips'),
                  subtitle: const Text('Suggestions to improve efficiency'),
                  value: _fuelTips,
                  onChanged: (v) => setState(() => _fuelTips = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Safety & Legal', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.health_and_safety_outlined),
                  title: const Text('Safety disclaimer'),
                  subtitle: const Text('Not a substitute for a mechanic'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDisclaimer(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.gavel_outlined),
                  title: const Text('Terms & Privacy'),
                  subtitle: const Text('Your data and the rules of use'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showTerms(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About'),
                  subtitle: Text('AutoIntel v0.1.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  onTap: () => context.read<AuthProvider>().signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDisclaimer(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Safety disclaimer'),
        content: const SingleChildScrollView(
          child: Text(
            'AutoIntel provides informational guidance only and is not a '
            'substitute for a qualified mechanic. AI explanations can be '
            'inaccurate or incomplete. Never rely solely on this app to decide '
            'whether your vehicle is safe to drive — if you are unsure, stop '
            'driving and have the vehicle inspected by a professional.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTerms(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Privacy'),
        content: const SingleChildScrollView(
          child: Text(
            'By using AutoIntel you agree to the Terms of Service. We collect '
            'your account email, vehicles, and diagnostic data to provide the '
            'service, and we do not sell your personal information. Fault-code '
            'data may be sent to an AI provider to generate explanations. See '
            'the full Terms of Service and Privacy Policy published with the app.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
