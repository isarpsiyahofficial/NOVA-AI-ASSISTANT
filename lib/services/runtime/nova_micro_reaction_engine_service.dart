// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_RUNTIME_LEXICAL_MUTATION_DISABLED_V3
import '../../core/runtime/nova_behavior_decision.dart';
import '../../core/runtime/nova_thinking_models.dart';

class NovaMicroReactionFrame {
  final String phrase;
  final double weight;
  final String reason;
  final String posture;
  const NovaMicroReactionFrame({
    required this.phrase,
    required this.weight,
    required this.reason,
    this.posture = 'neutral',
  });
}

class NovaMicroReactionAudit {
  final String selectedPhrase;
  final String reason;
  final double confidence;
  final List<String> alternatives;
  const NovaMicroReactionAudit({
    required this.selectedPhrase,
    required this.reason,
    required this.confidence,
    required this.alternatives,
  });
  Map<String, dynamic> toMap() => <String, dynamic>{
    'selectedPhrase': selectedPhrase,
    'reason': reason,
    'confidence': confidence,
    'alternatives': alternatives,
  };
}

class NovaMicroReactionEngineService {
  const NovaMicroReactionEngineService();

  String apply(
    String text, {
    required NovaBehaviorDecision decision,
    required NovaThinkingSnapshot thinking,
  }) {
    // Micro reactions are banned from post-model lexical mutation.
    return text.trim();
  }

  List<NovaMicroReactionFrame> buildFrames({
    required NovaBehaviorDecision decision,
    required NovaThinkingSnapshot thinking,
    required String rawText,
  }) {
    return const <NovaMicroReactionFrame>[];
  }

  NovaMicroReactionFrame chooseFrame(
    List<NovaMicroReactionFrame> frames,
    String lower,
  ) {
    return const NovaMicroReactionFrame(
      phrase: '',
      weight: 0.0,
      reason: 'metadata_only_disabled_for_final_speech',
    );
  }

  NovaMicroReactionAudit audit(
    String text, {
    required NovaBehaviorDecision decision,
    required NovaThinkingSnapshot thinking,
  }) {
    return const NovaMicroReactionAudit(
      selectedPhrase: '',
      reason: 'metadata_only_disabled_for_final_speech',
      confidence: 0.0,
      alternatives: <String>[],
    );
  }
}
