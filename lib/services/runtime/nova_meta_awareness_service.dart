// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_RUNTIME_LEXICAL_MUTATION_DISABLED_V3
class NovaMetaAwarenessFrame {
  final String directive;
  final double score;
  final String reason;
  const NovaMetaAwarenessFrame({
    required this.directive,
    required this.score,
    required this.reason,
  });
}

class NovaMetaAwarenessService {
  const NovaMetaAwarenessService();

  String apply(String text, {required bool enabled}) {
    // Meta-awareness is not allowed to add self-referential phrases after model
    // output. It is disabled for final text mutation.
    return text.trim();
  }

  String buildPromptSection() {
    // Keep internal runtime/meta language out of model prompts.
    return '';
  }

  NovaMetaAwarenessFrame analyze(String text) {
    return const NovaMetaAwarenessFrame(
      directive: '',
      score: 0.0,
      reason: 'metadata_only_disabled_for_final_speech',
    );
  }
}
