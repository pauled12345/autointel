import 'package:flutter/material.dart';

/// Shared severity → color mapping used by diagnostics and alert surfaces.
/// High and critical severities use a real, vivid red — never the dark
/// `red.shade900`, which reads as maroon on AMOLED screens.
Color severityColor(String severity) {
  switch (severity.toLowerCase()) {
    case 'critical':
      return Colors.red;
    case 'high':
      return Colors.red.shade600;
    case 'medium':
      return Colors.orange;
    case 'low':
      return Colors.green;
    default:
      return Colors.blueGrey;
  }
}
