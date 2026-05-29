// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class VoiceCloneSettings {
  final bool externalCloneEnabled;
  final bool internalCloneEnabled;

  /// 0 = nötr, 1 = sıcak, 2 = duygulu, 3 = resmi
  final int expressionLevel;

  /// 0 = düşük, 1 = orta, 2 = yüksek
  final int emotionStrength;

  const VoiceCloneSettings({
    this.externalCloneEnabled = false,
    this.internalCloneEnabled = false,
    this.expressionLevel = 0,
    this.emotionStrength = 1,
  });

  VoiceCloneSettings copyWith({
    bool? externalCloneEnabled,
    bool? internalCloneEnabled,
    int? expressionLevel,
    int? emotionStrength,
  }) {
    return VoiceCloneSettings(
      externalCloneEnabled: externalCloneEnabled ?? this.externalCloneEnabled,
      internalCloneEnabled: internalCloneEnabled ?? this.internalCloneEnabled,
      expressionLevel: expressionLevel ?? this.expressionLevel,
      emotionStrength: emotionStrength ?? this.emotionStrength,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'externalCloneEnabled': externalCloneEnabled,
      'internalCloneEnabled': internalCloneEnabled,
      'expressionLevel': expressionLevel,
      'emotionStrength': emotionStrength,
    };
  }

  factory VoiceCloneSettings.fromMap(Map<String, dynamic> map) {
    return VoiceCloneSettings(
      externalCloneEnabled: map['externalCloneEnabled'] as bool? ?? false,
      internalCloneEnabled: map['internalCloneEnabled'] as bool? ?? false,
      expressionLevel: map['expressionLevel'] as int? ?? 0,
      emotionStrength: map['emotionStrength'] as int? ?? 1,
    );
  }
}
