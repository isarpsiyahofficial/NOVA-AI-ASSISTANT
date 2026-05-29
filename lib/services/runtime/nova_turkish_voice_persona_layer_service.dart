// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaTurkishVoicePersonaDecision {
  final String mode;
  final bool useMeasuredFillers;
  final bool preferShortSentences;
  final bool preferWarmTransitions;
  final String endingContour;

  const NovaTurkishVoicePersonaDecision({
    required this.mode,
    required this.useMeasuredFillers,
    required this.preferShortSentences,
    required this.preferWarmTransitions,
    required this.endingContour,
  });

  String buildPromptSection() =>
      'TÜRKÇE SES PERSONASI: mod=' +
      mode +
      '; ölçülüDolgu=' +
      useMeasuredFillers.toString() +
      '; kısaCümle=' +
      preferShortSentences.toString() +
      '; sıcakGeçiş=' +
      preferWarmTransitions.toString() +
      '; sonKontur=' +
      endingContour;
}

class NovaTurkishVoicePersonaLayerService {
  const NovaTurkishVoicePersonaLayerService();

  NovaTurkishVoicePersonaDecision resolve({
    required String contextMode,
    required String socialMode,
    required String dominantEmotion,
  }) {
    if (contextMode == 'work') {
      return const NovaTurkishVoicePersonaDecision(
        mode: 'technical_clear_tr',
        useMeasuredFillers: false,
        preferShortSentences: true,
        preferWarmTransitions: false,
        endingContour: 'controlled_fall',
      );
    }
    if (dominantEmotion == 'sad' || dominantEmotion == 'anxious') {
      return const NovaTurkishVoicePersonaDecision(
        mode: 'calm_support_tr',
        useMeasuredFillers: false,
        preferShortSentences: true,
        preferWarmTransitions: true,
        endingContour: 'soft_fall',
      );
    }
    if (socialMode == 'casual') {
      return const NovaTurkishVoicePersonaDecision(
        mode: 'warm_daily_tr',
        useMeasuredFillers: true,
        preferShortSentences: true,
        preferWarmTransitions: true,
        endingContour: 'light_rise_fall',
      );
    }
    return const NovaTurkishVoicePersonaDecision(
      mode: 'formal_helper_tr',
      useMeasuredFillers: false,
      preferShortSentences: false,
      preferWarmTransitions: true,
      endingContour: 'steady_fall',
    );
  }
}
