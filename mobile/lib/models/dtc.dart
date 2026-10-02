/// A Diagnostic Trouble Code (DTC) read from the vehicle.
class Dtc {
  final String code;
  final String description;
  final String severity; // low | medium | high | critical
  final String? explanation;

  const Dtc({
    required this.code,
    this.description = 'Unknown fault',
    this.severity = 'medium',
    this.explanation,
  });

  Dtc copyWith({String? description, String? severity, String? explanation}) {
    return Dtc(
      code: code,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      explanation: explanation ?? this.explanation,
    );
  }
}
