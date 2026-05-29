// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaRelationshipProfile {
  final String speakerKey;
  final String displayName;
  final String relationshipLabel;
  final String preferredAddress;
  final double warmth;
  final double formality;
  final double humorTolerance;
  final double questionTolerance;
  final String supportStyle;
  final List<String> stablePreferences;
  final List<String> sharedAnchors;
  final List<String> criticalCorrections;
  final double trustLevel;
  final double authorityLevel;
  final String relationshipStage;
  final List<String> constitutionPrinciples;
  final List<String> ritualSeeds;
  final int positiveSignals;
  final int correctiveSignals;
  final int totalInteractions;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final DateTime lastConfirmedAt;

  const NovaRelationshipProfile({
    required this.speakerKey,
    required this.displayName,
    required this.relationshipLabel,
    required this.preferredAddress,
    required this.warmth,
    required this.formality,
    required this.humorTolerance,
    required this.questionTolerance,
    required this.supportStyle,
    required this.stablePreferences,
    required this.sharedAnchors,
    required this.criticalCorrections,
    required this.trustLevel,
    required this.authorityLevel,
    required this.relationshipStage,
    required this.constitutionPrinciples,
    required this.ritualSeeds,
    required this.positiveSignals,
    required this.correctiveSignals,
    required this.totalInteractions,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.lastConfirmedAt,
  });

  factory NovaRelationshipProfile.fallback({
    required String speakerKey,
    required String displayName,
    required String relationshipLabel,
  }) {
    final now = DateTime.now();
    return NovaRelationshipProfile(
      speakerKey: speakerKey,
      displayName: displayName,
      relationshipLabel: relationshipLabel,
      preferredAddress: displayName.trim().isEmpty
          ? 'doğal hitap'
          : displayName.trim(),
      warmth: 0.58,
      formality: 0.52,
      humorTolerance: 0.42,
      questionTolerance: 0.50,
      supportStyle: 'ölçülü, doğal, bağlama duyarlı',
      stablePreferences: const <String>[],
      sharedAnchors: const <String>[],
      criticalCorrections: const <String>[],
      trustLevel: 0.50,
      authorityLevel: 0.40,
      relationshipStage: 'tanışma',
      constitutionPrinciples: const <String>[],
      ritualSeeds: const <String>[],
      positiveSignals: 0,
      correctiveSignals: 0,
      totalInteractions: 0,
      firstSeenAt: now,
      lastSeenAt: now,
      lastConfirmedAt: now,
    );
  }

  NovaRelationshipProfile copyWith({
    String? speakerKey,
    String? displayName,
    String? relationshipLabel,
    String? preferredAddress,
    double? warmth,
    double? formality,
    double? humorTolerance,
    double? questionTolerance,
    String? supportStyle,
    List<String>? stablePreferences,
    List<String>? sharedAnchors,
    List<String>? criticalCorrections,
    double? trustLevel,
    double? authorityLevel,
    String? relationshipStage,
    List<String>? constitutionPrinciples,
    List<String>? ritualSeeds,
    int? positiveSignals,
    int? correctiveSignals,
    int? totalInteractions,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
    DateTime? lastConfirmedAt,
  }) {
    return NovaRelationshipProfile(
      speakerKey: speakerKey ?? this.speakerKey,
      displayName: displayName ?? this.displayName,
      relationshipLabel: relationshipLabel ?? this.relationshipLabel,
      preferredAddress: preferredAddress ?? this.preferredAddress,
      warmth: warmth ?? this.warmth,
      formality: formality ?? this.formality,
      humorTolerance: humorTolerance ?? this.humorTolerance,
      questionTolerance: questionTolerance ?? this.questionTolerance,
      supportStyle: supportStyle ?? this.supportStyle,
      stablePreferences: stablePreferences ?? this.stablePreferences,
      sharedAnchors: sharedAnchors ?? this.sharedAnchors,
      criticalCorrections: criticalCorrections ?? this.criticalCorrections,
      trustLevel: trustLevel ?? this.trustLevel,
      authorityLevel: authorityLevel ?? this.authorityLevel,
      relationshipStage: relationshipStage ?? this.relationshipStage,
      constitutionPrinciples:
          constitutionPrinciples ?? this.constitutionPrinciples,
      ritualSeeds: ritualSeeds ?? this.ritualSeeds,
      positiveSignals: positiveSignals ?? this.positiveSignals,
      correctiveSignals: correctiveSignals ?? this.correctiveSignals,
      totalInteractions: totalInteractions ?? this.totalInteractions,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      lastConfirmedAt: lastConfirmedAt ?? this.lastConfirmedAt,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'speakerKey': speakerKey,
    'displayName': displayName,
    'relationshipLabel': relationshipLabel,
    'preferredAddress': preferredAddress,
    'warmth': warmth,
    'formality': formality,
    'humorTolerance': humorTolerance,
    'questionTolerance': questionTolerance,
    'supportStyle': supportStyle,
    'stablePreferences': stablePreferences,
    'sharedAnchors': sharedAnchors,
    'criticalCorrections': criticalCorrections,
    'trustLevel': trustLevel,
    'authorityLevel': authorityLevel,
    'relationshipStage': relationshipStage,
    'constitutionPrinciples': constitutionPrinciples,
    'ritualSeeds': ritualSeeds,
    'positiveSignals': positiveSignals,
    'correctiveSignals': correctiveSignals,
    'totalInteractions': totalInteractions,
    'firstSeenAt': firstSeenAt.toIso8601String(),
    'lastSeenAt': lastSeenAt.toIso8601String(),
    'lastConfirmedAt': lastConfirmedAt.toIso8601String(),
  };

  factory NovaRelationshipProfile.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(String key) =>
        DateTime.tryParse(map[key]?.toString() ?? '') ?? DateTime.now();
    List<String> parseList(String key) =>
        (map[key] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
    return NovaRelationshipProfile(
      speakerKey: map['speakerKey']?.toString() ?? '',
      displayName: map['displayName']?.toString() ?? '',
      relationshipLabel: map['relationshipLabel']?.toString() ?? '',
      preferredAddress: map['preferredAddress']?.toString() ?? 'doğal hitap',
      warmth: (map['warmth'] as num?)?.toDouble() ?? 0.58,
      formality: (map['formality'] as num?)?.toDouble() ?? 0.52,
      humorTolerance: (map['humorTolerance'] as num?)?.toDouble() ?? 0.42,
      questionTolerance: (map['questionTolerance'] as num?)?.toDouble() ?? 0.50,
      supportStyle:
          map['supportStyle']?.toString() ?? 'ölçülü, doğal, bağlama duyarlı',
      stablePreferences: parseList('stablePreferences'),
      sharedAnchors: parseList('sharedAnchors'),
      criticalCorrections: parseList('criticalCorrections'),
      trustLevel: (map['trustLevel'] as num?)?.toDouble() ?? 0.50,
      authorityLevel: (map['authorityLevel'] as num?)?.toDouble() ?? 0.40,
      relationshipStage: map['relationshipStage']?.toString() ?? 'tanışma',
      constitutionPrinciples: parseList('constitutionPrinciples'),
      ritualSeeds: parseList('ritualSeeds'),
      positiveSignals: (map['positiveSignals'] as num?)?.toInt() ?? 0,
      correctiveSignals: (map['correctiveSignals'] as num?)?.toInt() ?? 0,
      totalInteractions: (map['totalInteractions'] as num?)?.toInt() ?? 0,
      firstSeenAt: parseDate('firstSeenAt'),
      lastSeenAt: parseDate('lastSeenAt'),
      lastConfirmedAt: parseDate('lastConfirmedAt'),
    );
  }

  String buildPromptSection() {
    return [
      'KALICI İLİŞKİ PROFİLİ:',
      '- kişi anahtarı: $speakerKey',
      '- görünen ad: ${displayName.isEmpty ? 'bilinmiyor' : displayName}',
      '- ilişki etiketi: ${relationshipLabel.isEmpty ? 'belirsiz' : relationshipLabel}',
      '- tercih edilen hitap: $preferredAddress',
      '- sıcaklık: ${warmth.toStringAsFixed(2)}',
      '- resmiyet: ${formality.toStringAsFixed(2)}',
      '- mizah toleransı: ${humorTolerance.toStringAsFixed(2)}',
      '- soru toleransı: ${questionTolerance.toStringAsFixed(2)}',
      '- destek stili: $supportStyle',
      '- güven: ${trustLevel.toStringAsFixed(2)}',
      '- yetki: ${authorityLevel.toStringAsFixed(2)}',
      '- ilişki evresi: $relationshipStage',
      '- toplam etkileşim: $totalInteractions',
      if (stablePreferences.isNotEmpty)
        '- kararlı tercihler: ${stablePreferences.take(5).join(' | ')}',
      if (sharedAnchors.isNotEmpty)
        '- ortak bağ sinyalleri: ${sharedAnchors.take(4).join(' | ')}',
      if (criticalCorrections.isNotEmpty)
        '- kritik düzeltmeler: ${criticalCorrections.take(3).join(' | ')}',
      if (constitutionPrinciples.isNotEmpty)
        '- ilişki ilkeleri: ${constitutionPrinciples.take(4).join(' | ')}',
      if (ritualSeeds.isNotEmpty)
        '- ritüel tohumları: ${ritualSeeds.take(4).join(' | ')}',
      'KURAL: Bu profil sadece bilgi değil; hitap, ton, açıklama boyu ve ilişki kararlılığını gerçekten değiştirmeli.',
    ].join('\n');
  }
}
