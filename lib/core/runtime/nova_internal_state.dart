// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaInternalState {
  final double energyLevel;
  final double focusLevel;
  final double socialOpenness;
  final double fatigueLevel;
  final double conversationDrive;
  final double ownerCloseness;
  final bool ownerMode;
  final bool authorizedMode;
  final String speakingRegister;
  final List<String> lastOpenLoops;
  final int sessionTurnCount;

  const NovaInternalState({
    required this.energyLevel,
    required this.focusLevel,
    required this.socialOpenness,
    required this.fatigueLevel,
    required this.conversationDrive,
    required this.ownerCloseness,
    required this.ownerMode,
    required this.authorizedMode,
    required this.speakingRegister,
    required this.lastOpenLoops,
    required this.sessionTurnCount,
  });

  factory NovaInternalState.initial() => const NovaInternalState(
    energyLevel: 0.68,
    focusLevel: 0.70,
    socialOpenness: 0.56,
    fatigueLevel: 0.18,
    conversationDrive: 0.55,
    ownerCloseness: 1.0,
    ownerMode: true,
    authorizedMode: false,
    speakingRegister: 'warm_owner',
    lastOpenLoops: <String>[],
    sessionTurnCount: 0,
  );

  NovaInternalState copyWith({
    double? energyLevel,
    double? focusLevel,
    double? socialOpenness,
    double? fatigueLevel,
    double? conversationDrive,
    double? ownerCloseness,
    bool? ownerMode,
    bool? authorizedMode,
    String? speakingRegister,
    List<String>? lastOpenLoops,
    int? sessionTurnCount,
  }) {
    return NovaInternalState(
      energyLevel: energyLevel ?? this.energyLevel,
      focusLevel: focusLevel ?? this.focusLevel,
      socialOpenness: socialOpenness ?? this.socialOpenness,
      fatigueLevel: fatigueLevel ?? this.fatigueLevel,
      conversationDrive: conversationDrive ?? this.conversationDrive,
      ownerCloseness: ownerCloseness ?? this.ownerCloseness,
      ownerMode: ownerMode ?? this.ownerMode,
      authorizedMode: authorizedMode ?? this.authorizedMode,
      speakingRegister: speakingRegister ?? this.speakingRegister,
      lastOpenLoops: lastOpenLoops ?? this.lastOpenLoops,
      sessionTurnCount: sessionTurnCount ?? this.sessionTurnCount,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'energyLevel': energyLevel,
    'focusLevel': focusLevel,
    'socialOpenness': socialOpenness,
    'fatigueLevel': fatigueLevel,
    'conversationDrive': conversationDrive,
    'ownerCloseness': ownerCloseness,
    'ownerMode': ownerMode,
    'authorizedMode': authorizedMode,
    'speakingRegister': speakingRegister,
    'lastOpenLoops': lastOpenLoops,
    'sessionTurnCount': sessionTurnCount,
  };

  factory NovaInternalState.fromMap(Map<String, dynamic> map) {
    return NovaInternalState(
      energyLevel: (map['energyLevel'] as num?)?.toDouble() ?? 0.68,
      focusLevel: (map['focusLevel'] as num?)?.toDouble() ?? 0.70,
      socialOpenness: (map['socialOpenness'] as num?)?.toDouble() ?? 0.56,
      fatigueLevel: (map['fatigueLevel'] as num?)?.toDouble() ?? 0.18,
      conversationDrive: (map['conversationDrive'] as num?)?.toDouble() ?? 0.55,
      ownerCloseness: (map['ownerCloseness'] as num?)?.toDouble() ?? 1.0,
      ownerMode: map['ownerMode'] as bool? ?? true,
      authorizedMode: map['authorizedMode'] as bool? ?? false,
      speakingRegister: (map['speakingRegister'] as String? ?? 'warm_owner')
          .trim(),
      lastOpenLoops:
          (map['lastOpenLoops'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<String>()
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(growable: false),
      sessionTurnCount: (map['sessionTurnCount'] as num?)?.toInt() ?? 0,
    );
  }

  String get moodLabel {
    if (fatigueLevel >= 0.72) return 'tired';
    if (energyLevel >= 0.78 && socialOpenness >= 0.60) return 'happy';
    if (focusLevel >= 0.72) return 'focused';
    return 'balanced';
  }
}
