// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaRuntimeIntent {
  generalConversation,
  statusReport,
  startListening,
  stopListening,
  sleepMode,
  wakeMode,
  shutdownMode,
  batterySaverMode,
  limboMode,
  answerCall,
  rejectCall,
  handOverCallToNova,
  handOverCallToUser,
  startSelfRepair,
  openSelfRepair,
  debugSystems,
  reminderAction,
}

enum NovaIntentRiskLevel { low, medium, high }

enum NovaAllowedContext {
  general,
  voiceOnly,
  activeCall,
  ownerConfirmed,
  unlockedDevice,
  selfRepairWindow,
}

class NovaRuntimeIntentMatch {
  final NovaRuntimeIntent intent;
  final double confidence;
  final String normalizedCommand;
  final String reason;
  final String target;
  final NovaIntentRiskLevel riskLevel;
  final bool needsConfirmation;
  final List<NovaAllowedContext> allowedContexts;

  const NovaRuntimeIntentMatch({
    required this.intent,
    required this.confidence,
    required this.normalizedCommand,
    required this.reason,
    this.target = '',
    this.riskLevel = NovaIntentRiskLevel.low,
    this.needsConfirmation = false,
    this.allowedContexts = const <NovaAllowedContext>[
      NovaAllowedContext.general,
    ],
  });
}
