// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class BrainActionPlan {
  final String action;
  final Map<String, dynamic> arguments;
  final bool requiresPolicyApproval;

  const BrainActionPlan({
    required this.action,
    this.arguments = const <String, dynamic>{},
    this.requiresPolicyApproval = true,
  });

  bool get hasAction => action.trim().isNotEmpty && action.trim() != 'none';

  Map<String, dynamic> toMap() => <String, dynamic>{
    'action': action,
    'arguments': arguments,
    'requiresPolicyApproval': requiresPolicyApproval,
  };
}

class BrainDecision {
  final String finalText;
  final List<BrainActionPlan> actionPlans;
  final String route;
  final bool fromLocalBrain;
  final Map<String, dynamic> metadata;

  const BrainDecision({
    required this.finalText,
    this.actionPlans = const <BrainActionPlan>[],
    this.route = 'ai_chain',
    this.fromLocalBrain = true,
    this.metadata = const <String, dynamic>{},
  });

  bool get hasSpeech => finalText.trim().isNotEmpty;
  bool get hasActions => actionPlans.any((action) => action.hasAction);

  Map<String, dynamic> toMap() => <String, dynamic>{
    'finalText': finalText,
    'actionPlans': actionPlans.map((action) => action.toMap()).toList(),
    'route': route,
    'fromLocalBrain': fromLocalBrain,
    'metadata': metadata,
  };
}
