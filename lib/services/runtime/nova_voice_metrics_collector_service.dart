// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaVoiceMetricsCollectorService {
  const NovaVoiceMetricsCollectorService();

  Map<String, dynamic> buildMetrics({
    required String primaryAct,
    required String turnType,
    required bool expectsResponse,
    required bool shouldClarify,
    required double talkRatio,
  }) {
    return <String, dynamic>{
      'voice_primary_act': primaryAct,
      'voice_turn_type': turnType,
      'voice_expects_response': expectsResponse,
      'voice_should_clarify': shouldClarify,
      'voice_talk_ratio': talkRatio,
    };
  }

  String buildPromptSection(Map<String, dynamic> metrics) {
    return 'VOICE METRİK İPUÇLARI: anaEylem=${metrics['voice_primary_act']}; tur=${metrics['voice_turn_type']}; cevapBekliyor=${metrics['voice_expects_response']}; netleştirme=${metrics['voice_should_clarify']}; konuşmaOranı=${metrics['voice_talk_ratio']}';
  }
}
