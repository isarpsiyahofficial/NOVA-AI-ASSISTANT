// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1

import '../../core/runtime/nova_behavior_decision.dart';
import '../../core/runtime/nova_thinking_models.dart';

class NovaThinkingModeClassifierService {
  const NovaThinkingModeClassifierService();

  NovaThinkingMode classify({
    required String prompt,
    required NovaThinkingSnapshot thinking,
    required Map<String, dynamic> understanding,
    required double empathyNeed,
  }) {
    final tokenCount = prompt
        .split(RegExp(r'\s+'))
        .where((e) => e.trim().isNotEmpty)
        .length;
    final shouldClarify = understanding['shouldClarify'] as bool? ?? false;
    final explicitQuestion =
        understanding['explicitQuestion'] as bool? ?? false;
    if (shouldClarify || thinking.intent == NovaInteractionIntent.ambiguous) {
      return NovaThinkingMode.shortThink;
    }
    if (tokenCount >= 28 ||
        empathyNeed >= 0.56 ||
        (explicitQuestion && tokenCount >= 16)) {
      return NovaThinkingMode.deepThink;
    }
    if (tokenCount >= 10 ||
        thinking.intent == NovaInteractionIntent.information) {
      return NovaThinkingMode.shortThink;
    }
    return NovaThinkingMode.instant;
  }
}
