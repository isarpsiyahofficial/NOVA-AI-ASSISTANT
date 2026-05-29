// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaPartialResponsePlannerService {
  const NovaPartialResponsePlannerService();

  Map<String, dynamic> plan({
    required String thinkingMode,
    required bool shouldClarify,
    required bool urgent,
    required bool voiceFirst,
  }) {
    final deep = thinkingMode == 'deepThink' || thinkingMode == 'deep_think';
    return <String, dynamic>{
      'strategy': urgent
          ? 'ack_then_answer'
          : (deep ? 'frame_then_detail' : 'single_breath_response'),
      'shouldClarify': shouldClarify,
      'useShortOpening': voiceFirst,
      'useStepDownExpansion': deep && !urgent,
    };
  }

  String buildPromptSection({
    required String thinkingMode,
    required bool shouldClarify,
    bool urgent = false,
    bool voiceFirst = true,
  }) {
    final planMap = plan(
      thinkingMode: thinkingMode,
      shouldClarify: shouldClarify,
      urgent: urgent,
      voiceFirst: voiceFirst,
    );
    return [
      'PARTIAL RESPONSE PLANNER:',
      '- strateji: ${planMap['strategy']}',
      '- netleştirme ihtiyacı: ${planMap['shouldClarify']}',
      '- kısa açılış: ${planMap['useShortOpening']}',
      '- kademeli genişletme: ${planMap['useStepDownExpansion']}',
      'KURAL: Çok karmaşık durumda önce kısa yön, sonra genişletme uygula; boş bekleyiş hissi oluşturma.',
    ].join('\n');
  }
}
