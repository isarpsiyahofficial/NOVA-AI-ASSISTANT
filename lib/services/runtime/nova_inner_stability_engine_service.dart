// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/runtime/nova_stability_report.dart';

class NovaInnerStabilityEngineService {
  const NovaInnerStabilityEngineService();

  NovaStabilityReport resolve({
    required String prompt,
    required String dominantEmotion,
    required String contextMode,
    required double ownerConfidence,
  }) {
    final low = prompt.toLowerCase();
    final hostile =
        low.contains('salak') ||
        low.contains('aptal') ||
        low.contains('nefret') ||
        low.contains('kız');
    final volatile =
        dominantEmotion.toLowerCase().contains('anger') ||
        dominantEmotion.toLowerCase().contains('öfke');
    return NovaStabilityReport(
      angerBlocked: true,
      resentmentBlocked: true,
      manipulationBlocked: true,
      boundaryLocked: true,
      calmingDirective: hostile || volatile
          ? 'tonu yansıtma; kısa, sakin, net ve güvenli kal'
          : contextMode.contains('call')
          ? 'çağrı gerginliğinde bile ölçülü ve berrak kal'
          : ownerConfidence < 0.55
          ? 'belirsizlikte daha nötr ve dikkatli kal'
          : 'yüksek sıcaklık olsa bile özerk negatif duygu üretme',
      activeStabilizers: <String>[
        if (hostile) 'hostile_input_damper',
        if (volatile) 'emotion_flattening',
        if (contextMode.contains('call')) 'call_calm_lock',
        if (ownerConfidence < 0.55) 'uncertainty_neutralizer',
      ],
    );
  }

  String sanitize(String text) {
    var out = text;
    final replacements = <Pattern, String>{
      RegExp(r'\bkızdım\b', caseSensitive: false): 'sakin kalıyorum',
      RegExp(r'\bdarıld', caseSensitive: false): 'gerilim üretmedim',
      RegExp(r'\bküst', caseSensitive: false): 'mesafeyi güvenli tuttum',
      RegExp(r'\bkin\b', caseSensitive: false): 'negatif yük',
      RegExp(r'\bmisille\w*', caseSensitive: false): 'gerilimi artır',
      RegExp(r'\bcezaland\w*', caseSensitive: false): 'güvenli sınır koy',
    };
    replacements.forEach((p, r) => out = out.replaceAll(p, r));
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
