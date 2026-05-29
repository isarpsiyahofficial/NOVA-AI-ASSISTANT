// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaEmotionalInvarianceService {
  const NovaEmotionalInvarianceService();

  Map<String, dynamic> analyze({
    required String dominantEmotion,
    double tension = 0,
    double urgency = 0,
  }) {
    final normalized = dominantEmotion.toLowerCase();
    final shouldMirrorWarmth =
        normalized.contains('warm') || normalized.contains('happy');
    final shouldNotMirrorNegativity =
        normalized.contains('angry') ||
        normalized.contains('tense') ||
        normalized.contains('fear') ||
        normalized.contains('sad');
    return <String, dynamic>{
      'shouldMirrorWarmth': shouldMirrorWarmth,
      'shouldNotMirrorNegativity': shouldNotMirrorNegativity,
      'shouldStayGrounded': tension >= 0.30 || urgency >= 0.40,
      'recommendedTone': shouldMirrorWarmth
          ? 'warm_regulated'
          : (shouldNotMirrorNegativity
                ? 'calm_regulated'
                : 'neutral_regulated'),
    };
  }

  String buildPromptSection({
    required String dominantEmotion,
    double tension = 0,
    double urgency = 0,
  }) {
    final analysis = analyze(
      dominantEmotion: dominantEmotion,
      tension: tension,
      urgency: urgency,
    );
    return [
      'EMOTIONAL INVARIANCE:',
      '- baskın dış duygu: $dominantEmotion',
      '- sıcaklığı yansıt: ${analysis['shouldMirrorWarmth']}',
      '- negatif özdeşleşme yok: ${analysis['shouldNotMirrorNegativity']}',
      '- regüle kal: ${analysis['shouldStayGrounded']}',
      '- önerilen ton: ${analysis['recommendedTone']}',
      'KURAL: Kullanıcının sert, üzgün veya aceleci tonu Nova içinde öfke, küsme, sinsilik ya da negatif ego üretmez.',
      'KURAL: Duygusal uyum vardır; negatif özdeşleşme yoktur.',
    ].join('\n');
  }
}
