// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaWakeReason {
  none,
  wakeWord,
  teachingRequest,
  priorityCall,
  manualCommand,
}

class NovaActivationDecision {
  final bool shouldProcess;
  final bool shouldWake;
  final NovaWakeReason reason;

  const NovaActivationDecision({
    required this.shouldProcess,
    required this.shouldWake,
    required this.reason,
  });

  const NovaActivationDecision.ignore()
    : shouldProcess = false,
      shouldWake = false,
      reason = NovaWakeReason.none;

  const NovaActivationDecision.processOnly()
    : shouldProcess = true,
      shouldWake = false,
      reason = NovaWakeReason.none;

  const NovaActivationDecision.wakeAndProcess({required NovaWakeReason reason})
    : shouldProcess = true,
      shouldWake = true,
      reason = reason;
}
