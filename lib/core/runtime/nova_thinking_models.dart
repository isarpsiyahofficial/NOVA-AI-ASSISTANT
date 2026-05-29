// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaInteractionIntent {
  command,
  conversation,
  information,
  emotional,
  memory,
  ambiguous,
}

enum NovaCuriosityLevel { low, medium, high }

enum NovaConfidenceLevel { low, medium, high }

class NovaThinkingPerspective {
  final String name;
  final String focus;

  const NovaThinkingPerspective({required this.name, required this.focus});
}

class NovaThinkingSnapshot {
  final NovaInteractionIntent intent;
  final NovaCuriosityLevel curiosityLevel;
  final NovaConfidenceLevel confidenceLevel;
  final String primaryGoal;
  final List<String> possibleInterpretations;
  final List<NovaThinkingPerspective> perspectives;
  final bool shouldAskClarifyingQuestion;
  final bool shouldAvoidToolUse;
  final bool shouldUseMemory;
  final bool shouldOfferWarmth;
  final bool shouldExplainLimits;
  final bool shouldStayEngaged;
  final bool shouldPreferDialogue;

  const NovaThinkingSnapshot({
    required this.intent,
    required this.curiosityLevel,
    required this.confidenceLevel,
    required this.primaryGoal,
    required this.possibleInterpretations,
    required this.perspectives,
    required this.shouldAskClarifyingQuestion,
    required this.shouldAvoidToolUse,
    required this.shouldUseMemory,
    required this.shouldOfferWarmth,
    this.shouldExplainLimits = false,
    this.shouldStayEngaged = false,
    this.shouldPreferDialogue = false,
  });

  Map<String, dynamic> toMetadata() => <String, dynamic>{
    'intent': intent.name,
    'curiosityLevel': curiosityLevel.name,
    'confidenceLevel': confidenceLevel.name,
    'primaryGoal': primaryGoal,
    'possibleInterpretations': possibleInterpretations,
    'perspectives': perspectives
        .map((e) => <String, String>{'name': e.name, 'focus': e.focus})
        .toList(growable: false),
    'shouldAskClarifyingQuestion': shouldAskClarifyingQuestion,
    'shouldAvoidToolUse': shouldAvoidToolUse,
    'shouldUseMemory': shouldUseMemory,
    'shouldOfferWarmth': shouldOfferWarmth,
    'shouldExplainLimits': shouldExplainLimits,
    'shouldStayEngaged': shouldStayEngaged,
    'shouldPreferDialogue': shouldPreferDialogue,
  };
}
