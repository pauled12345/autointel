class FaultCode {
  final String id;
  final String code;
  final String? rawDescription;
  final String? aiExplanation;
  final String? severity;
  final String status;

  FaultCode({
    required this.id,
    required this.code,
    this.rawDescription,
    this.aiExplanation,
    this.severity,
    required this.status,
  });

  factory FaultCode.fromJson(Map<String, dynamic> json) {
    return FaultCode(
      id: json['id'],
      code: json['code'],
      rawDescription: json['raw_description'],
      aiExplanation: json['ai_explanation'],
      severity: json['severity'],
      status: json['status'],
    );
  }
}
