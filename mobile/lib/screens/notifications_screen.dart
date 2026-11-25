import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_alert.dart';
import '../providers/notification_provider.dart';
import '../utils/severity.dart';

/// Lists the user's alerts (fault codes, maintenance reminders, fuel tips) with
/// severity-coloured icons. Reached from the dashboard bell.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final alerts = provider.alerts;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: provider.markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: alerts.isEmpty
          ? const Center(child: Text('No notifications'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _AlertTile(
                alert: alerts[index],
                onTap: () => provider.markRead(alerts[index].id),
              ),
            ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final AppAlert alert;
  final VoidCallback onTap;

  const _AlertTile({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = severityColor(alert.severity);
    final icon = switch (alert.kind) {
      'maintenance' => Icons.schedule,
      'fuel' => Icons.local_gas_station,
      _ => Icons.warning_amber,
    };
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                alert.title,
                style: TextStyle(
                  fontWeight: alert.read ? FontWeight.w400 : FontWeight.w700,
                ),
              ),
            ),
            if (!alert.read)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Text(
          alert.message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          _timeAgo(alert.timestamp),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

String _timeAgo(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
