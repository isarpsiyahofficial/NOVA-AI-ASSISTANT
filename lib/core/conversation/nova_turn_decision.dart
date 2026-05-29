// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaTurnAction {
  answer,
  askClarifyingQuestion,
  askFollowUpQuestion,
  actSilently,
  acknowledgeAndAct,
  explainLimitation,
}

class NovaTurnDecision {
  final NovaTurnAction action;
  final bool shouldKeepItShort;
  final bool shouldExpand;
  final bool shouldActFirst;
  final bool shouldReturnToPreviousTopic;
  final bool shouldStayQuietAfterAction;
  final bool shouldLeadWithEmpathy;
  final bool shouldConfirmActionOutcome;
  final bool shouldTreatAsInterruption;
  final String reason;

  const NovaTurnDecision({
    required this.action,
    required this.shouldKeepItShort,
    required this.shouldExpand,
    required this.shouldActFirst,
    required this.shouldReturnToPreviousTopic,
    required this.shouldStayQuietAfterAction,
    this.shouldLeadWithEmpathy = false,
    this.shouldConfirmActionOutcome = false,
    this.shouldTreatAsInterruption = false,
    required this.reason,
  });
}
