// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_RUNTIME_LEXICAL_MUTATION_DISABLED_V4
import '../../core/conversation/nova_turn_decision.dart';
import '../../core/runtime/nova_internal_state.dart';
import '../../core/runtime/nova_style_profile.dart';
import '../../core/runtime/nova_thinking_models.dart';

class NovaSpokenResponsePlannerService {
  const NovaSpokenResponsePlannerService();

  String plan(
    String rawText, {
    required NovaThinkingSnapshot thinking,
    required NovaInternalState internalState,
    required NovaTurnDecision turnDecision,
    required NovaStyleProfile styleProfile,
  }) {
    // Speech planning is metadata-only. It must not rewrite, prepend, shorten,
    // soften, humanize, or otherwise mutate model output after generation.
    return rawText.trim();
  }
}
