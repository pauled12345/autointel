/// Turns raw fault codes into plain-English explanations and a severity rating.
///
/// For the moment this uses a small built-in knowledge base so the app is
/// demoable offline. It is deliberately shaped like the real backend call
/// (`explain(code) -> {explanation, severity}`) so Phase 6 can swap the body
/// for an HTTP request to `/diagnostics/fault-codes` with no UI changes.
class AiService {
  /// Simulated "thinking" delay so the UX matches a real LLM round-trip.
  final Duration latency;

  const AiService({this.latency = const Duration(milliseconds: 600)});

  Future<AiExplanation> explain(String code) async {
    await Future.delayed(latency);
    final upper = code.toUpperCase();
    return AiExplanation(
      explanation: _explanations[upper] ?? _generic(upper),
      severity: _severities[upper] ?? 'medium',
    );
  }

  static String _generic(String code) {
    final system = _systemFor(code.isEmpty ? 'P' : code[0]);
    return 'Fault code $code affects the $system system. '
        'The engine control unit logged this while monitoring that system. '
        'Have a technician inspect the related components and wiring; '
        'clearing the code without a repair will likely bring it back.';
  }

  static String _systemFor(String letter) {
    switch (letter.toUpperCase()) {
      case 'P':
        return 'powertrain / engine';
      case 'C':
        return 'chassis (brakes, suspension)';
      case 'B':
        return 'body (airbags, comfort)';
      case 'U':
        return 'network / communication';
      default:
        return 'vehicle';
    }
  }

  static const Map<String, String> _explanations = {
    'P0133':
        'The oxygen sensor ahead of the catalytic converter (bank 1, sensor 1) '
        'is responding too slowly. The sensor is likely aged or contaminated, '
        'which can hurt fuel economy and emissions.',
    'P0301':
        'Cylinder 1 is misfiring. Common causes are a worn spark plug, a faulty '
        'ignition coil, or a fuel injector problem. Continued driving can damage '
        'the catalytic converter.',
    'P0420':
        'The catalytic converter is operating below its efficiency threshold. '
        'This may be a failing converter or an upstream sensor issue.',
    'P0171':
        'The engine is running too lean on bank 1 — too much air or too little '
        'fuel. Look for vacuum leaks, a dirty mass-airflow sensor, or weak fuel '
        'pressure.',
  };

  static const Map<String, String> _severities = {
    'P0133': 'medium',
    'P0301': 'high',
    'P0420': 'medium',
    'P0171': 'medium',
  };
}

class AiExplanation {
  final String explanation;
  final String severity;

  const AiExplanation({required this.explanation, required this.severity});
}
