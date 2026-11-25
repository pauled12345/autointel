import 'dart:convert';

/// A rich, structured AI diagnosis for a single fault code.
class AiDiagnosis {
  final String plainExplanation;
  final List<String> likelyCauses;
  final List<String> symptoms;
  final String severity;
  final String recommendedAction;
  final String repairDifficulty;
  final String estimatedCost;

  const AiDiagnosis({
    required this.plainExplanation,
    this.likelyCauses = const [],
    this.symptoms = const [],
    this.severity = 'medium',
    this.recommendedAction = '',
    this.repairDifficulty = 'medium',
    this.estimatedCost = '',
  });

  /// Parses a backend `ai_explanation` value, which is a JSON string. Falls
  /// back to treating plain text as the explanation when it isn't JSON.
  factory AiDiagnosis.fromRaw(String? raw, {String fallbackSeverity = 'medium'}) {
    if (raw == null || raw.trim().isEmpty) {
      return AiDiagnosis(
        plainExplanation: 'No explanation available.',
        severity: fallbackSeverity,
      );
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AiDiagnosis.fromJson(decoded);
      }
    } catch (_) {
      // not JSON — fall through to plain text
    }
    return AiDiagnosis(
      plainExplanation: raw.trim(),
      severity: fallbackSeverity,
    );
  }

  factory AiDiagnosis.fromJson(Map<String, dynamic> json) {
    return AiDiagnosis(
      plainExplanation: (json['plain_explanation'] as String?)?.trim() ?? '',
      likelyCauses: _stringList(json['likely_causes']),
      symptoms: _stringList(json['symptoms']),
      severity: (json['severity'] as String?) ?? 'medium',
      recommendedAction: (json['recommended_action'] as String?)?.trim() ?? '',
      repairDifficulty: (json['repair_difficulty'] as String?) ?? 'medium',
      estimatedCost: (json['estimated_cost'] as String?)?.trim() ?? '',
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }
}
