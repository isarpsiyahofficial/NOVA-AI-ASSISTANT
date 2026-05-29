// ignore_for_file: prefer_initializing_formals, avoid_print, unnecessary_cast, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum CallHandlingAction {
  ignore,
  askUserFirst,
  autoHandleByNova,
  letUserTakeOver,
}

class CallHandlingDecision {
  final CallHandlingAction action;
  final bool wokeNovaForThisCall;
  final String openingLine;
  final bool shouldOfferNote;
  final bool shouldAskUrgency;

  const CallHandlingDecision({
    required this.action,
    this.wokeNovaForThisCall = false,
    this.openingLine = '',
    this.shouldOfferNote = false,
    this.shouldAskUrgency = false,
  });

  const CallHandlingDecision.ignore()
    : action = CallHandlingAction.ignore,
      wokeNovaForThisCall = false,
      openingLine = '',
      shouldOfferNote = false,
      shouldAskUrgency = false;

  const CallHandlingDecision.askUserFirst({
    required String openingLine,
    bool wokeNovaForThisCall = false,
  }) : action = CallHandlingAction.askUserFirst,
       wokeNovaForThisCall = wokeNovaForThisCall,
       openingLine = openingLine,
       shouldOfferNote = false,
       shouldAskUrgency = false;

  const CallHandlingDecision.autoHandleByNova({
    required String openingLine,
    required bool wokeNovaForThisCall,
    bool shouldOfferNote = true,
    bool shouldAskUrgency = true,
  }) : action = CallHandlingAction.autoHandleByNova,
       wokeNovaForThisCall = wokeNovaForThisCall,
       openingLine = openingLine,
       shouldOfferNote = shouldOfferNote,
       shouldAskUrgency = shouldAskUrgency;

  const CallHandlingDecision.letUserTakeOver({required String openingLine})
    : action = CallHandlingAction.letUserTakeOver,
      wokeNovaForThisCall = false,
      openingLine = openingLine,
      shouldOfferNote = false,
      shouldAskUrgency = false;
}
