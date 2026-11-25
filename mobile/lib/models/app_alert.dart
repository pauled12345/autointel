/// An in-app alert — a fault, maintenance reminder, or fuel tip — surfaced on
/// the notifications screen. Same shape a push notification would carry once
/// FCM is wired up; delivered locally for the demo.
class AppAlert {
  final String id;
  final String title;
  final String message;
  final String severity; // low | medium | high | critical
  final String kind; // fault | maintenance | fuel
  final DateTime timestamp;
  final bool read;

  const AppAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.kind,
    required this.timestamp,
    this.read = false,
  });

  AppAlert copyWith({bool? read}) => AppAlert(
        id: id,
        title: title,
        message: message,
        severity: severity,
        kind: kind,
        timestamp: timestamp,
        read: read ?? this.read,
      );
}
