// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaEmotionToProsodyMapping {
  final String speakingTemperature;
  final String cadence;
  final String landing;
  const NovaEmotionToProsodyMapping({
    required this.speakingTemperature,
    required this.cadence,
    required this.landing,
  });
  String buildPromptSection() =>
      'DUYGU→PROSODİ: sıcaklık=$speakingTemperature; kadans=$cadence; iniş=$landing';
  String get emotionalTone => speakingTemperature;
  String get contourHint => landing;
}

class NovaEmotionToProsodyMapperService {
  const NovaEmotionToProsodyMapperService();

  NovaEmotionToProsodyMapping map(String? emotion, {String prompt = ''}) {
    final resolvedEmotion = (emotion ?? 'neutral').trim();
    switch (resolvedEmotion) {
      case 'sad':
      case 'tired':
        return const NovaEmotionToProsodyMapping(
          speakingTemperature: 'warm_low',
          cadence: 'slow_even',
          landing: 'soft',
        );
      case 'happy':
      case 'relieved':
        return const NovaEmotionToProsodyMapping(
          speakingTemperature: 'warm_bright',
          cadence: 'light_flowing',
          landing: 'up_then_soft',
        );
      case 'angry':
      case 'tense':
        return const NovaEmotionToProsodyMapping(
          speakingTemperature: 'calming_neutral',
          cadence: 'measured',
          landing: 'firm_softened',
        );
      default:
        return const NovaEmotionToProsodyMapping(
          speakingTemperature: 'balanced',
          cadence: 'natural',
          landing: 'gentle_decline',
        );
    }
  }
}
