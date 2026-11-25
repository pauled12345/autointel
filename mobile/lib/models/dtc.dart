import 'ai_diagnosis.dart';

/// A Diagnostic Trouble Code (DTC) read from the vehicle.
class Dtc {
  final String code;
  final String description;
  final String severity; // low | medium | high | critical
  final AiDiagnosis? diagnosis;

  const Dtc({
    required this.code,
    this.description = 'Unknown fault',
    this.severity = 'medium',
    this.diagnosis,
  });

  /// Short explanation text for list rows; the full detail is in [diagnosis].
  String? get explanation {
    final d = diagnosis;
    if (d == null || d.plainExplanation.isEmpty) return null;
    return d.plainExplanation;
  }
}
