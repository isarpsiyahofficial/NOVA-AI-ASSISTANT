// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'nova_kill_stage.dart';

enum NovaSecurityVerdictType {
  allow,
  restricted,
  blocked,
  hardKilled,
  finalContained,
}

extension NovaSecurityVerdictTypeX on NovaSecurityVerdictType {
  String get key {
    switch (this) {
      case NovaSecurityVerdictType.allow:
        return 'allow';
      case NovaSecurityVerdictType.restricted:
        return 'restricted';
      case NovaSecurityVerdictType.blocked:
        return 'blocked';
      case NovaSecurityVerdictType.hardKilled:
        return 'sealed_runtime';
      case NovaSecurityVerdictType.finalContained:
        return 'final_contained';
    }
  }
}

class NovaSecurityVerdict {
  final NovaSecurityVerdictType type;
  final NovaKillStage killStage;
  final bool allowBoot;
  final bool allowRuntime;
  final bool allowAiRequests;
  final bool allowLearning;
  final bool allowNativeBridge;
  final bool allowBackgroundRuntime;
  final String reason;

  const NovaSecurityVerdict({
    required this.type,
    required this.killStage,
    required this.allowBoot,
    required this.allowRuntime,
    required this.allowAiRequests,
    required this.allowLearning,
    required this.allowNativeBridge,
    required this.allowBackgroundRuntime,
    required this.reason,
  });

  const NovaSecurityVerdict.allow({String reason = 'Sistem çalışmaya uygun.'})
    : type = NovaSecurityVerdictType.allow,
      killStage = NovaKillStage.none,
      allowBoot = true,
      allowRuntime = true,
      allowAiRequests = true,
      allowLearning = true,
      allowNativeBridge = true,
      allowBackgroundRuntime = true,
      reason = reason;

  const NovaSecurityVerdict.restricted({
    required String reason,
    required NovaKillStage killStage,
    bool allowBoot = true,
    bool allowRuntime = true,
    bool allowAiRequests = true,
    bool allowLearning = false,
    bool allowNativeBridge = true,
    bool allowBackgroundRuntime = true,
  }) : type = NovaSecurityVerdictType.restricted,
       killStage = killStage,
       allowBoot = allowBoot,
       allowRuntime = allowRuntime,
       allowAiRequests = allowAiRequests,
       allowLearning = allowLearning,
       allowNativeBridge = allowNativeBridge,
       allowBackgroundRuntime = allowBackgroundRuntime,
       reason = reason;

  const NovaSecurityVerdict.blocked({
    required String reason,
    required NovaKillStage killStage,
    bool allowBoot = true,
  }) : type = NovaSecurityVerdictType.blocked,
       killStage = killStage,
       allowBoot = allowBoot,
       allowRuntime = false,
       allowAiRequests = false,
       allowLearning = false,
       allowNativeBridge = false,
       allowBackgroundRuntime = false,
       reason = reason;

  const NovaSecurityVerdict.hardKilled({required String reason})
    : type = NovaSecurityVerdictType.hardKilled,
      killStage = NovaKillStage.hardKilled,
      allowBoot = true,
      allowRuntime = false,
      allowAiRequests = false,
      allowLearning = false,
      allowNativeBridge = false,
      allowBackgroundRuntime = false,
      reason = reason;

  const NovaSecurityVerdict.finalContained({required String reason})
    : type = NovaSecurityVerdictType.finalContained,
      killStage = NovaKillStage.finalContained,
      allowBoot = false,
      allowRuntime = false,
      allowAiRequests = false,
      allowLearning = false,
      allowNativeBridge = false,
      allowBackgroundRuntime = false,
      reason = reason;
}
