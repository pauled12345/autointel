class FuelLog {
  final String id;
  final DateTime date;
  final int odometerKm;
  final double liters;
  final double totalCost;

  const FuelLog({
    required this.id,
    required this.date,
    required this.odometerKm,
    required this.liters,
    required this.totalCost,
  });

  double get pricePerLiter => liters == 0 ? 0 : totalCost / liters;

  factory FuelLog.fromJson(Map<String, dynamic> json) {
    final recordedAt =
        DateTime.tryParse(json['recorded_at'] as String? ?? '') ??
            DateTime.now();
    return FuelLog(
      id: json['id'] as String,
      date: recordedAt,
      odometerKm: (json['odometer'] as num?)?.toInt() ?? 0,
      liters: (json['liters_or_gallons'] as num?)?.toDouble() ?? 0,
      totalCost: (json['cost'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'liters_or_gallons': liters,
      'cost': totalCost,
      'odometer': odometerKm,
      'recorded_at': date.toIso8601String().substring(0, 10),
    };
  }
}
