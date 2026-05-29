// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaSelfRepairSettings {
  final bool commandRepairEnabled;
  final bool manualRepairEnabled;
  final bool voiceNarrationEnabled;
  final bool autoRepairSafeIssues;
  final bool autoReportProblems;

  const NovaSelfRepairSettings({
    this.commandRepairEnabled = true,
    this.manualRepairEnabled = true,
    this.voiceNarrationEnabled = true,
    this.autoRepairSafeIssues = false,
    this.autoReportProblems = true,
  });

  NovaSelfRepairSettings copyWith({
    bool? commandRepairEnabled,
    bool? manualRepairEnabled,
    bool? voiceNarrationEnabled,
    bool? autoRepairSafeIssues,
    bool? autoReportProblems,
  }) {
    return NovaSelfRepairSettings(
      commandRepairEnabled: commandRepairEnabled ?? this.commandRepairEnabled,
      manualRepairEnabled: manualRepairEnabled ?? this.manualRepairEnabled,
      voiceNarrationEnabled:
          voiceNarrationEnabled ?? this.voiceNarrationEnabled,
      autoRepairSafeIssues: autoRepairSafeIssues ?? this.autoRepairSafeIssues,
      autoReportProblems: autoReportProblems ?? this.autoReportProblems,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'commandRepairEnabled': commandRepairEnabled,
    'manualRepairEnabled': manualRepairEnabled,
    'voiceNarrationEnabled': voiceNarrationEnabled,
    'autoRepairSafeIssues': autoRepairSafeIssues,
    'autoReportProblems': autoReportProblems,
  };

  factory NovaSelfRepairSettings.fromMap(Map<String, dynamic> map) {
    return NovaSelfRepairSettings(
      commandRepairEnabled: map['commandRepairEnabled'] as bool? ?? true,
      manualRepairEnabled: map['manualRepairEnabled'] as bool? ?? true,
      voiceNarrationEnabled: map['voiceNarrationEnabled'] as bool? ?? true,
      autoRepairSafeIssues: map['autoRepairSafeIssues'] as bool? ?? false,
      autoReportProblems: map['autoReportProblems'] as bool? ?? true,
    );
  }
}
