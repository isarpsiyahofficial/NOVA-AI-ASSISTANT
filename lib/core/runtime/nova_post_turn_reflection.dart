// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaPostTurnReflection {
  final double interruptionRisk;
  final double repairNeed;
  final double memoryValue;
  final double curiosityFit;
  final double styleConsistency;
  final double voiceNaturalness;
  final double continuityValue;
  final double silenceRespect;
  final double socialBalance;
  final double metaAwareness;
  final bool shouldStayShortNextTurn;
  final bool shouldReduceQuestionsNextTurn;
  final String summary;

  const NovaPostTurnReflection({
    required this.interruptionRisk,
    required this.repairNeed,
    required this.memoryValue,
    required this.curiosityFit,
    required this.styleConsistency,
    required this.voiceNaturalness,
    required this.continuityValue,
    required this.silenceRespect,
    required this.socialBalance,
    required this.metaAwareness,
    required this.shouldStayShortNextTurn,
    required this.shouldReduceQuestionsNextTurn,
    required this.summary,
  });

  String buildPromptSection() {
    return [
      'TUR SONRASI ÖZ DEĞERLENDİRME:',
      '- söz kesme riski: ${interruptionRisk.toStringAsFixed(2)}',
      '- onarım ihtiyacı: ${repairNeed.toStringAsFixed(2)}',
      '- hafıza katkısı: ${memoryValue.toStringAsFixed(2)}',
      '- merak uygunluğu: ${curiosityFit.toStringAsFixed(2)}',
      '- tarz tutarlılığı: ${styleConsistency.toStringAsFixed(2)}',
      '- ses doğallığı: ${voiceNaturalness.toStringAsFixed(2)}',
      '- süreklilik katkısı: ${continuityValue.toStringAsFixed(2)}',
      '- sessizlik saygısı: ${silenceRespect.toStringAsFixed(2)}',
      '- sosyal denge: ${socialBalance.toStringAsFixed(2)}',
      '- meta farkındalık: ${metaAwareness.toStringAsFixed(2)}',
      '- sonraki tur kısa kalma: ${shouldStayShortNextTurn ? 'evet' : 'hayır'}',
      '- sonraki tur soru azaltma: ${shouldReduceQuestionsNextTurn ? 'evet' : 'hayır'}',
      '- özet: $summary',
    ].join('\n');
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'interruptionRisk': interruptionRisk,
    'repairNeed': repairNeed,
    'memoryValue': memoryValue,
    'curiosityFit': curiosityFit,
    'styleConsistency': styleConsistency,
    'voiceNaturalness': voiceNaturalness,
    'continuityValue': continuityValue,
    'silenceRespect': silenceRespect,
    'socialBalance': socialBalance,
    'metaAwareness': metaAwareness,
    'shouldStayShortNextTurn': shouldStayShortNextTurn,
    'shouldReduceQuestionsNextTurn': shouldReduceQuestionsNextTurn,
    'summary': summary,
  };
}
