class MaintenanceLog {
  final String id;
  final String type;
  final DateTime date;
  final int mileageKm;
  final double cost;

  const MaintenanceLog({
    required this.id,
    required this.type,
    required this.date,
    required this.mileageKm,
    required this.cost,
  });

  String get title => maintenanceTitleFor(type);

  bool get done => date.isBefore(DateTime.now());

  factory MaintenanceLog.fromJson(Map<String, dynamic> json) {
    final performedAt =
        DateTime.tryParse(json['performed_at'] as String? ?? '') ??
            DateTime.now();
    return MaintenanceLog(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'service',
      date: performedAt,
      mileageKm: (json['odometer'] as num?)?.toInt() ?? 0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'cost': cost,
      'odometer': mileageKm,
      'performed_at': date.toIso8601String().substring(0, 10),
    };
  }
}

String maintenanceTitleFor(String type) {
  switch (type) {
    case 'oil_change':
      return 'Oil & Filter Change';
    case 'tire_rotation':
      return 'Tire Rotation';
    case 'brake_pads':
      return 'Brake Pad Replacement';
    case 'coolant_flush':
      return 'Coolant Flush';
    default:
      return type
          .split('_')
          .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
          .join(' ');
  }
}
