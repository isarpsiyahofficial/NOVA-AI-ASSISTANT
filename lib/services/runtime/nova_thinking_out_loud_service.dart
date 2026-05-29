// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_RUNTIME_LEXICAL_MUTATION_DISABLED_V3
import '../../core/runtime/nova_behavior_decision.dart';

class NovaThinkingOutLoudService {
  const NovaThinkingOutLoudService();

  String apply(String text, NovaBehaviorDecision decision) {
    // Thinking-out-loud is a pre-generation planning signal only.
    // It must never prepend/append words to model output after generation.
    return text.trim();
  }
}
