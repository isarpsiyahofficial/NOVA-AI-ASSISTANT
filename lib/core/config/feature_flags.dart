// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class FeatureFlags {
  final bool localModelEnabled;
  final bool apiEnabled;
  final bool callHandlingEnabled;
  final bool phoneControlEnabled;
  final bool teachingModeEnabled;
  final bool voiceProfilesEnabled;
  final bool reminderCleanupEnabled;

  const FeatureFlags({
    this.localModelEnabled = false,
    this.apiEnabled = true,
    this.callHandlingEnabled = true,
    this.phoneControlEnabled = false,
    this.teachingModeEnabled = true,
    this.voiceProfilesEnabled = true,
    this.reminderCleanupEnabled = true,
  });

  FeatureFlags copyWith({
    bool? localModelEnabled,
    bool? apiEnabled,
    bool? callHandlingEnabled,
    bool? phoneControlEnabled,
    bool? teachingModeEnabled,
    bool? voiceProfilesEnabled,
    bool? reminderCleanupEnabled,
  }) {
    return FeatureFlags(
      localModelEnabled: localModelEnabled ?? this.localModelEnabled,
      apiEnabled: apiEnabled ?? this.apiEnabled,
      callHandlingEnabled: callHandlingEnabled ?? this.callHandlingEnabled,
      phoneControlEnabled: phoneControlEnabled ?? this.phoneControlEnabled,
      teachingModeEnabled: teachingModeEnabled ?? this.teachingModeEnabled,
      voiceProfilesEnabled: voiceProfilesEnabled ?? this.voiceProfilesEnabled,
      reminderCleanupEnabled:
          reminderCleanupEnabled ?? this.reminderCleanupEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'localModelEnabled': localModelEnabled,
      'apiEnabled': apiEnabled,
      'callHandlingEnabled': callHandlingEnabled,
      'phoneControlEnabled': phoneControlEnabled,
      'teachingModeEnabled': teachingModeEnabled,
      'voiceProfilesEnabled': voiceProfilesEnabled,
      'reminderCleanupEnabled': reminderCleanupEnabled,
    };
  }

  factory FeatureFlags.fromMap(Map<String, dynamic> map) {
    return FeatureFlags(
      localModelEnabled: map['localModelEnabled'] as bool? ?? false,
      apiEnabled: map['apiEnabled'] as bool? ?? true,
      callHandlingEnabled: map['callHandlingEnabled'] as bool? ?? true,
      phoneControlEnabled: map['phoneControlEnabled'] as bool? ?? false,
      teachingModeEnabled: map['teachingModeEnabled'] as bool? ?? true,
      voiceProfilesEnabled: map['voiceProfilesEnabled'] as bool? ?? true,
      reminderCleanupEnabled: map['reminderCleanupEnabled'] as bool? ?? true,
    );
  }
}
