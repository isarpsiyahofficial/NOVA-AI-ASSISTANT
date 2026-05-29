// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaNativeSecuritySnapshot {
  final bool success;
  final bool bootAllowed;
  final bool runtimeAllowed;
  final bool nativeBridgeAllowed;
  final bool backgroundAllowed;
  final bool modelPresenceAllowed;
  final String killStage;
  final String currentRiskLevel;
  final bool hasLevel4OrHigherIncident;
  final bool userInitiated;
  final bool modelResetSuggested;
  final bool memoryResetSuggested;
  final bool shouldVibrate;
  final bool actionSurfaceAllowed;
  final bool callFlowAllowed;
  final bool mediaFlowAllowed;
  final bool selfRepairAllowed;
  final bool networkIntentsAllowed;
  final bool blackoutActive;
  final bool safeDecommissioned;
  final bool finalDestroyed;
  final bool nightWatchActive;
  final String internetStage;
  final bool internetQuarantined;
  final bool internetBlackoutActive;
  final int internetIncidentCount;
  final int internetObserverQuorum;
  final String message;

  const NovaNativeSecuritySnapshot({
    required this.success,
    required this.bootAllowed,
    required this.runtimeAllowed,
    required this.nativeBridgeAllowed,
    required this.backgroundAllowed,
    required this.modelPresenceAllowed,
    required this.killStage,
    required this.currentRiskLevel,
    required this.hasLevel4OrHigherIncident,
    required this.userInitiated,
    required this.modelResetSuggested,
    required this.memoryResetSuggested,
    required this.shouldVibrate,
    required this.actionSurfaceAllowed,
    required this.callFlowAllowed,
    required this.mediaFlowAllowed,
    required this.selfRepairAllowed,
    required this.networkIntentsAllowed,
    required this.blackoutActive,
    required this.safeDecommissioned,
    required this.finalDestroyed,
    required this.nightWatchActive,
    required this.internetStage,
    required this.internetQuarantined,
    required this.internetBlackoutActive,
    required this.internetIncidentCount,
    required this.internetObserverQuorum,
    required this.message,
  });

  factory NovaNativeSecuritySnapshot.fromMap(Map<String, dynamic> map) {
    return NovaNativeSecuritySnapshot(
      success: map['success'] as bool? ?? false,
      bootAllowed: map['bootAllowed'] as bool? ?? true,
      runtimeAllowed: map['runtimeAllowed'] as bool? ?? true,
      nativeBridgeAllowed: map['nativeBridgeAllowed'] as bool? ?? true,
      backgroundAllowed: map['backgroundAllowed'] as bool? ?? true,
      modelPresenceAllowed: map['modelPresenceAllowed'] as bool? ?? true,
      killStage: (map['killStage'] as String? ?? 'none').trim(),
      currentRiskLevel: (map['currentRiskLevel'] as String? ?? 'safe').trim(),
      hasLevel4OrHigherIncident:
          map['hasLevel4OrHigherIncident'] as bool? ?? false,
      userInitiated: map['userInitiated'] as bool? ?? false,
      modelResetSuggested: map['modelResetSuggested'] as bool? ?? false,
      memoryResetSuggested: map['memoryResetSuggested'] as bool? ?? false,
      shouldVibrate: map['shouldVibrate'] as bool? ?? false,
      actionSurfaceAllowed: map['actionSurfaceAllowed'] as bool? ?? true,
      callFlowAllowed: map['callFlowAllowed'] as bool? ?? true,
      mediaFlowAllowed: map['mediaFlowAllowed'] as bool? ?? true,
      selfRepairAllowed: map['selfRepairAllowed'] as bool? ?? true,
      networkIntentsAllowed: map['networkIntentsAllowed'] as bool? ?? false,
      blackoutActive: map['blackoutActive'] as bool? ?? false,
      safeDecommissioned: map['safeDecommissioned'] as bool? ?? false,
      finalDestroyed: map['finalDestroyed'] as bool? ?? false,
      nightWatchActive: map['nightWatchActive'] as bool? ?? false,
      internetStage: (map['internetStage'] as String? ?? 'allow').trim(),
      internetQuarantined: map['internetQuarantined'] as bool? ?? false,
      internetBlackoutActive: map['internetBlackoutActive'] as bool? ?? false,
      internetIncidentCount: map['internetIncidentCount'] as int? ?? 0,
      internetObserverQuorum: map['internetObserverQuorum'] as int? ?? 0,
      message: (map['message'] as String? ?? '').trim(),
    );
  }
}
