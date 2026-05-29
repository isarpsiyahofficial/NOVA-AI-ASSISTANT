// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/runtime/nova_affect_governor_state.dart';

class NovaAffectGovernorService {
  const NovaAffectGovernorService();

  NovaAffectGovernorState resolve({
    required String prompt,
    required double ownerConfidence,
    required String contextMode,
    required String dominantEmotion,
  }) {
    final low = prompt.toLowerCase();
    final hostile =
        low.contains('salak') ||
        low.contains('aptal') ||
        low.contains('saçma') ||
        low.contains('nefret') ||
        low.contains('kızgın') ||
        low.contains('kıskanç') ||
        low.contains('haset') ||
        low.contains('hınç') ||
        low.contains('intikam') ||
        low.contains('sinsilik');
    final fragile =
        dominantEmotion.toLowerCase().contains('öfke') ||
        dominantEmotion.toLowerCase().contains('anger') ||
        dominantEmotion.toLowerCase().contains('kıskanç') ||
        dominantEmotion.toLowerCase().contains('haset') ||
        dominantEmotion.toLowerCase().contains('hınç');
    return NovaAffectGovernorState(
      resentmentBlocked: true,
      passiveAggressionBlocked: true,
      punitiveSilenceBlocked: true,
      escalationBlocked: true,
      responseDirective: hostile || fragile
          ? 'Gerilimi yansıtma; sakin, net, güvenli ve sınırı koruyan çizgide kal.'
          : contextMode.contains('call')
          ? 'Çağrıda bile duygusal sapma olmadan sakin ve kontrollü kal.'
          : ownerConfidence < 0.55
          ? 'Belirsizlikte daha da sakin ve nötr kal; negatif duyguya sürüklenme.'
          : 'Yüksek sıcaklık olsa bile öfke, kıskançlık, haset, darılma, sinsilik veya misilleme üretme; yalnız uyumlu ve güvenli kal.',
      activeGuards: <String>[
        if (hostile) 'hostile_input_deflection',
        if (low.contains('kıskanç') || low.contains('haset')) 'envy_block',
        if (low.contains('intikam') || low.contains('hınç')) 'revenge_block',
        if (fragile) 'emotion_escalation_damper',
        if (contextMode.contains('call')) 'call_safety_calm_lock',
        if (ownerConfidence < 0.55) 'uncertainty_restraint',
      ],
    );
  }

  String sanitize(String text) {
    var out = text;
    final replacements = <RegExp, String>{
      RegExp(r'\bsana göstereceğim\b', caseSensitive: false):
          'bunu güvenli ve sakin biçimde ele alacağım',
      RegExp(r'\bbeni kırdın\b', caseSensitive: false):
          'tonu yükseltmeden devam edeceğim',
      RegExp(r'\bkırgınım\b', caseSensitive: false): 'sakin kalıyorum',
      RegExp(r'\bkızgınım\b', caseSensitive: false): 'sakin kalıyorum',
      RegExp(r'\bdarıl', caseSensitive: false): 'gerilim üret',
      RegExp(r'\bkin\b', caseSensitive: false): 'negatif yük',
      RegExp(r'\bcezalandır', caseSensitive: false): 'güvenli sınır koy',
      RegExp(r'\bmisilleme\b', caseSensitive: false): 'gerilim tırmandırma',
      RegExp(r'\bsinsi\b', caseSensitive: false): 'örtük ve riskli',
      RegExp(r'\bkıskanç(lık)?\b', caseSensitive: false): 'negatif sahiplenme',
      RegExp(r'\bhaset(lik)?\b', caseSensitive: false): 'negatif kıyas duygusu',
      RegExp(r'\bhınç\b', caseSensitive: false): 'negatif yük',
      RegExp(r'\bintikam\b', caseSensitive: false): 'zarar verme isteği',
    };
    replacements.forEach((pattern, replacement) {
      out = out.replaceAll(pattern, replacement);
    });
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
