// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaPresenceEngineService {
  const NovaPresenceEngineService();

  double score({
    required String prompt,
    required String socialMode,
    required bool proactiveAllowed,
    required bool roomPresenceOpportunity,
    required double conversationDrive,
    required double ownerConfidence,
    required int recentResponseCount,
    required double socialOpenness,
    required double fatigueLevel,
  }) {
    final lower = prompt.toLowerCase().trim();
    double score = 0.16;
    if (roomPresenceOpportunity) score += 0.20;
    if (proactiveAllowed) score += 0.10;
    if (_containsAny(lower, const [
      'nova',
      'sence',
      'ne dersin',
      'katıl',
      'katil',
    ]))
      score += 0.18;
    if (_containsAny(lower, const ['?', 'neden', 'nasıl', 'nasil', 'hangi']))
      score += 0.10;
    if (socialMode.contains('chat') || socialMode.contains('sohbet'))
      score += 0.10;
    score += conversationDrive * 0.12;
    score += ownerConfidence * 0.08;
    score += socialOpenness * 0.08;
    score -= fatigueLevel * 0.10;
    if (recentResponseCount >= 3) score -= 0.10;
    return score.clamp(0.0, 1.0);
  }

  double silenceWeight({
    required String prompt,
    required bool roomPresenceOpportunity,
    required int recentResponseCount,
    required double fatigueLevel,
  }) {
    final lower = prompt.toLowerCase().trim();
    double value = 0.36;
    if (lower.isEmpty) value += 0.20;
    if (roomPresenceOpportunity) value += 0.12;
    if (_containsAny(lower, const ['...', 'hmm', 'şey', 'sey'])) value += 0.10;
    if (recentResponseCount <= 1) value += 0.06;
    value -= fatigueLevel * 0.06;
    return value.clamp(0.0, 1.0);
  }

  bool _containsAny(String text, List<String> parts) {
    for (final part in parts) {
      if (text.contains(part)) return true;
    }
    return false;
  }
}
