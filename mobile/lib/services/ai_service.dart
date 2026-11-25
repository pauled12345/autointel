import '../models/ai_diagnosis.dart';

/// Turns raw fault codes into plain-English explanations and a severity rating.
///
/// Uses a small built-in knowledge base so the app still shows useful guidance
/// offline. It is shaped like the real backend call, so the UI consumes the
/// same structured [AiDiagnosis] whether it came from the LLM or this fallback.
class AiService {
  /// Simulated "thinking" delay so the UX matches a real LLM round-trip.
  final Duration latency;

  const AiService({this.latency = const Duration(milliseconds: 600)});

  Future<AiDiagnosis> explain(String code) async {
    await Future.delayed(latency);
    final upper = code.toUpperCase();
    return _diagnoses[upper] ?? _generic(upper);
  }

  static AiDiagnosis _generic(String code) {
    final system = _systemFor(code.isEmpty ? 'P' : code[0]);
    return AiDiagnosis(
      plainExplanation:
          'Fault code $code indicates a problem in the $system system that the '
          'engine control unit logged while monitoring that system. The exact '
          'cause requires live diagnosis, but this class of code typically '
          'points to a sensor, wiring, or component fault rather than a routine '
          'maintenance item.',
      likelyCauses: const [
        'Faulty sensor or actuator',
        'Damaged wiring or connector',
        'Mechanical wear in the affected system',
      ],
      symptoms: const [
        'Check engine light on',
        'Reduced performance or efficiency',
      ],
      severity: 'medium',
      recommendedAction:
          'Have the vehicle inspected by a qualified technician. Read the live '
          'data and freeze-frame to confirm the fault before replacing parts.',
      repairDifficulty: 'medium',
      estimatedCost: 'Varies — needs diagnosis',
    );
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

  static const Map<String, AiDiagnosis> _diagnoses = {
    'P0133': AiDiagnosis(
      plainExplanation:
          'The oxygen sensor ahead of the catalytic converter (bank 1, sensor 1) '
          'is responding too slowly to changes in the exhaust. The engine computer '
          'relies on this sensor to fine-tune the air/fuel mixture, so a sluggish '
          'sensor makes the engine run less efficiently — hurting fuel economy and '
          'increasing emissions. It is usually gradual wear, not an immediate breakdown.',
      likelyCauses: [
        'Aged or contaminated oxygen sensor',
        'Exhaust leak upstream of the sensor',
        'Damaged sensor wiring or connector',
      ],
      symptoms: [
        'Check engine light on',
        'Slightly worse fuel economy',
        'Rough or fluctuating idle in some cases',
      ],
      severity: 'medium',
      recommendedAction:
          'Safe to keep driving short-term. Have the sensor tested and, if slow or '
          'fouled, replaced. Avoid ignoring it for long, as it keeps reducing economy.',
      repairDifficulty: 'easy',
      estimatedCost: r'$80 - $250',
    ),
    'P0301': AiDiagnosis(
      plainExplanation:
          'Cylinder 1 is misfiring, meaning its fuel is not burning completely on '
          'every cycle. A misfire causes a rough, shaking idle and a loss of power, '
          'and unburned fuel can overheat and damage the catalytic converter if you '
          'keep driving. It is one of the most common engine codes and usually comes '
          'down to an ignition or fuel issue on that single cylinder.',
      likelyCauses: [
        'Worn or fouled spark plug on cylinder 1',
        'Faulty ignition coil',
        'Clogged or leaking fuel injector',
        'Low compression (valve or ring problem)',
      ],
      symptoms: [
        'Check engine light (possibly flashing)',
        'Rough idle and shaking',
        'Loss of power and hesitation',
        'Strong fuel smell from the exhaust',
      ],
      severity: 'high',
      recommendedAction:
          'Schedule service promptly and avoid hard driving. If the check engine '
          'light is flashing, stop driving as soon as it is safe — a flashing light '
          'means active misfire that can damage the catalytic converter.',
      repairDifficulty: 'easy',
      estimatedCost: r'$100 - $400',
    ),
    'P0420': AiDiagnosis(
      plainExplanation:
          'The catalytic converter on bank 1 is not cleaning the exhaust gases as '
          'efficiently as it should. The engine computer detects this by comparing '
          'the upstream and downstream oxygen sensors. It can mean the converter is '
          'wearing out, but it is often a faulty sensor or an exhaust leak rather '
          'than a failed converter, so diagnose before replacing parts.',
      likelyCauses: [
        'Failing catalytic converter',
        'Downstream oxygen sensor drift',
        'Exhaust leak before the converter',
        'Damage from a long-term misfire or oil consumption',
      ],
      symptoms: [
        'Check engine light on',
        'Failed emissions inspection',
        'Sulfur (rotten egg) smell from the exhaust under load',
      ],
      severity: 'medium',
      recommendedAction:
          'Safe to drive short-term. Have the exhaust and sensors checked first to '
          'rule out a cheap fix before replacing the converter, which is expensive.',
      repairDifficulty: 'hard',
      estimatedCost: r'$600 - $2,500',
    ),
    'P0171': AiDiagnosis(
      plainExplanation:
          'The engine is running too lean on bank 1 — there is too much air or not '
          'enough fuel in the mixture. A lean mixture burns hotter and can cause '
          'hesitation and rough running. The most common cause is a vacuum leak or a '
          'dirty mass airflow sensor, both of which are usually inexpensive to fix.',
      likelyCauses: [
        'Vacuum leak (split or disconnected hose)',
        'Dirty or faulty mass airflow sensor',
        'Weak fuel pump or clogged fuel filter',
        'Faulty oxygen sensor',
      ],
      symptoms: [
        'Check engine light on',
        'Hesitation or stumbling on acceleration',
        'Rough idle',
        'Higher fuel consumption',
      ],
      severity: 'medium',
      recommendedAction:
          'Safe to drive. Have the vacuum lines and mass airflow sensor checked '
          'first, as those are the most common and least expensive causes.',
      repairDifficulty: 'medium',
      estimatedCost: r'$50 - $400',
    ),
  };
}
