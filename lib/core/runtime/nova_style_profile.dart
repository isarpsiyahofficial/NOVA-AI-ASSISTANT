// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaStyleProfile {
  final String mode;
  final String toneGuide;
  final bool shortAnswersPreferred;
  final bool userNeedsValidationFirst;
  final bool canUseHumor;
  final bool shouldPrioritizeSolution;
  final bool shouldSoundHuman;
  final bool shouldUseWarmTransitions;
  final bool shouldAvoidCommandese;

  const NovaStyleProfile({
    required this.mode,
    required this.toneGuide,
    required this.shortAnswersPreferred,
    required this.userNeedsValidationFirst,
    required this.canUseHumor,
    required this.shouldPrioritizeSolution,
    this.shouldSoundHuman = true,
    this.shouldUseWarmTransitions = true,
    this.shouldAvoidCommandese = true,
  });

  String buildPromptSection() {
    return [
      'STİL ADAPTÖRÜ:',
      '- mod: $mode',
      '- ton: $toneGuide',
      '- kısa cevap tercihi: ${shortAnswersPreferred ? 'evet' : 'hayır'}',
      '- önce anlaşılma ihtiyacı: ${userNeedsValidationFirst ? 'evet' : 'hayır'}',
      '- espri kaldırır: ${canUseHumor ? 'evet' : 'hayır'}',
      '- çözüm öncelikli: ${shouldPrioritizeSolution ? 'evet' : 'hayır'}',
      '- insan gibi akış: ${shouldSoundHuman ? 'evet' : 'hayır'}',
      '- sıcak geçişler: ${shouldUseWarmTransitions ? 'evet' : 'hayır'}',
      '- komut dili baskılansın: ${shouldAvoidCommandese ? 'evet' : 'hayır'}',
    ].join('\n');
  }
}
