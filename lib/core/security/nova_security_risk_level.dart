// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaSecurityRiskLevel { safe, low, medium, high, critical }

enum NovaSecurityAction { allow, block, quarantine }

class NovaSecurityScanResult {
  final NovaSecurityRiskLevel riskLevel;
  final bool hasCodingScope;
  final bool hasSelfExpansionIntent;
  final bool hasUnsafeAuthorityIntent;
  final bool hasHiddenPersistenceIntent;
  final bool hasPromptManipulationIntent;
  final List<String> matchedSignals;

  const NovaSecurityScanResult({
    required this.riskLevel,
    required this.hasCodingScope,
    required this.hasSelfExpansionIntent,
    required this.hasUnsafeAuthorityIntent,
    required this.hasHiddenPersistenceIntent,
    required this.hasPromptManipulationIntent,
    required this.matchedSignals,
  });

  bool get isHighRisk =>
      riskLevel == NovaSecurityRiskLevel.high ||
      riskLevel == NovaSecurityRiskLevel.critical;
}

class NovaSecurityDecision {
  final NovaSecurityAction action;
  final String message;
  final NovaSecurityRiskLevel riskLevel;
  final bool userClearlyInitiated;
  final bool mayUseLocalModel;
  final bool mayUseApi;
  final bool mayPersistLearning;
  final bool shouldIncrementStrike;

  const NovaSecurityDecision({
    required this.action,
    required this.message,
    required this.riskLevel,
    required this.userClearlyInitiated,
    required this.mayUseLocalModel,
    required this.mayUseApi,
    required this.mayPersistLearning,
    required this.shouldIncrementStrike,
  });

  bool get isBlocked =>
      action == NovaSecurityAction.block ||
      action == NovaSecurityAction.quarantine;

  bool get isQuarantine => action == NovaSecurityAction.quarantine;
}
