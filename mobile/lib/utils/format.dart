import 'package:intl/intl.dart';

import '../models/fuel_log.dart';

final DateFormat _dateFmt = DateFormat('MMM d, yyyy');
final NumberFormat _kmFmt = NumberFormat('#,##0');

String formatDate(DateTime d) => _dateFmt.format(d);

String formatKm(int km) => '${_kmFmt.format(km)} km';

String formatMoney(double v) => '\$${v.toStringAsFixed(2)}';

/// Average fuel economy in km/l computed from consecutive fill-ups. Each fill's
/// economy is the distance driven since the previous fill divided by the litres
/// added at that fill; the first fill (no baseline) is skipped.
double averageFuelEconomyKml(List<FuelLog> logs) {
  if (logs.length < 2) return 0;
  final sorted = [...logs]..sort((a, b) => a.odometerKm.compareTo(b.odometerKm));
  var totalDistance = 0.0;
  var totalLiters = 0.0;
  for (var i = 1; i < sorted.length; i++) {
    final distance = sorted[i].odometerKm - sorted[i - 1].odometerKm;
    if (distance <= 0) continue;
    totalDistance += distance;
    totalLiters += sorted[i].liters;
  }
  return totalLiters == 0 ? 0 : totalDistance / totalLiters;
}
