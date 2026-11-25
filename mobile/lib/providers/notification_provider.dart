import 'package:flutter/foundation.dart';

import '../models/app_alert.dart';

/// Holds the user's in-app alerts and tracks the unread count so the dashboard
/// bell can show a live badge. Starts empty for new accounts; push-backed
/// alerts (maintenance reminders, fault alerts) will populate this later.
class NotificationProvider extends ChangeNotifier {
  List<AppAlert> _alerts = [];

  List<AppAlert> get alerts => List.unmodifiable(_alerts);

  int get unreadCount => _alerts.where((a) => !a.read).length;

  void markRead(String id) {
    _alerts =
        _alerts.map((a) => a.id == id ? a.copyWith(read: true) : a).toList();
    notifyListeners();
  }

  void markAllRead() {
    _alerts = _alerts.map((a) => a.copyWith(read: true)).toList();
    notifyListeners();
  }
}
