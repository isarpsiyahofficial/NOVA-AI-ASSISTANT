// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../learning/learning_engine.dart';
import '../../services/status/status_service.dart';

class NovaBrain {
  final LearningEngine learningEngine;
  final StatusService statusService;

  const NovaBrain({required this.learningEngine, required this.statusService});

  Future<NovaDecision> process(String input) async {
    // Legacy brain no longer produces independent behavioral speech.
    // Non-security behavior must be routed through NovaAiService/Gemma
    // and BrainDecision-style policy gates. This class remains only as a
    // compatibility shell for older constructors.
    final String? learned = await learningEngine.process(input);
    return NovaDecision(quickReply: '', fullResponse: learned?.trim() ?? '');
  }
}

class NovaDecision {
  final String quickReply;
  final String fullResponse;

  const NovaDecision({required this.quickReply, required this.fullResponse});
}
