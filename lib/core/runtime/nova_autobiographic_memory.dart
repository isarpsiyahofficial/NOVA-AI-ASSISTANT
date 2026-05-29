// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaAutobiographicMemory {
  final String speakerKey;
  final String relationshipStage;
  final List<String> turningPoints;
  final List<String> repairedMisunderstandings;
  final List<String> unresolvedThreads;
  final List<String> sharedHabits;
  final List<String> trustMoments;
  final String storyPhase;
  final String continuitySummary;
  final DateTime updatedAt;

  const NovaAutobiographicMemory({
    required this.speakerKey,
    required this.relationshipStage,
    required this.turningPoints,
    required this.repairedMisunderstandings,
    required this.unresolvedThreads,
    required this.sharedHabits,
    required this.trustMoments,
    required this.storyPhase,
    required this.continuitySummary,
    required this.updatedAt,
  });

  factory NovaAutobiographicMemory.empty(String speakerKey) {
    return NovaAutobiographicMemory(
      speakerKey: speakerKey,
      relationshipStage: 'tanışma',
      turningPoints: const <String>[],
      repairedMisunderstandings: const <String>[],
      unresolvedThreads: const <String>[],
      sharedHabits: const <String>[],
      trustMoments: const <String>[],
      storyPhase: 'başlangıç',
      continuitySummary:
          'Henüz ortak tarih ince ve yeni; konuşmalar sıfırdan başlamasın ama aşırı tarih yükü de kurulmasın.',
      updatedAt: DateTime.now(),
    );
  }

  NovaAutobiographicMemory copyWith({
    String? speakerKey,
    String? relationshipStage,
    List<String>? turningPoints,
    List<String>? repairedMisunderstandings,
    List<String>? unresolvedThreads,
    List<String>? sharedHabits,
    List<String>? trustMoments,
    String? storyPhase,
    String? continuitySummary,
    DateTime? updatedAt,
  }) {
    return NovaAutobiographicMemory(
      speakerKey: speakerKey ?? this.speakerKey,
      relationshipStage: relationshipStage ?? this.relationshipStage,
      turningPoints: turningPoints ?? this.turningPoints,
      repairedMisunderstandings:
          repairedMisunderstandings ?? this.repairedMisunderstandings,
      unresolvedThreads: unresolvedThreads ?? this.unresolvedThreads,
      sharedHabits: sharedHabits ?? this.sharedHabits,
      trustMoments: trustMoments ?? this.trustMoments,
      storyPhase: storyPhase ?? this.storyPhase,
      continuitySummary: continuitySummary ?? this.continuitySummary,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'speakerKey': speakerKey,
    'relationshipStage': relationshipStage,
    'turningPoints': turningPoints,
    'repairedMisunderstandings': repairedMisunderstandings,
    'unresolvedThreads': unresolvedThreads,
    'sharedHabits': sharedHabits,
    'trustMoments': trustMoments,
    'storyPhase': storyPhase,
    'continuitySummary': continuitySummary,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory NovaAutobiographicMemory.fromMap(Map<String, dynamic> map) {
    List<String> parse(String key) =>
        (map[key] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
    return NovaAutobiographicMemory(
      speakerKey: map['speakerKey']?.toString() ?? '',
      relationshipStage: map['relationshipStage']?.toString() ?? 'tanışma',
      turningPoints: parse('turningPoints'),
      repairedMisunderstandings: parse('repairedMisunderstandings'),
      unresolvedThreads: parse('unresolvedThreads'),
      sharedHabits: parse('sharedHabits'),
      trustMoments: parse('trustMoments'),
      storyPhase: map['storyPhase']?.toString() ?? 'başlangıç',
      continuitySummary: map['continuitySummary']?.toString() ?? '',
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  String buildPromptSection() {
    return [
      'OTOBİYOGRAFİK BENLİK ÇEKİRDEĞİ:',
      '- konuşan anahtarı: $speakerKey',
      '- ilişki evresi: $relationshipStage',
      '- hikâye fazı: $storyPhase',
      '- süreklilik özeti: $continuitySummary',
      if (turningPoints.isNotEmpty)
        '- dönüm noktaları: ${turningPoints.take(4).join(' | ')}',
      if (repairedMisunderstandings.isNotEmpty)
        '- aşılmış yanlış anlamalar: ${repairedMisunderstandings.take(3).join(' | ')}',
      if (unresolvedThreads.isNotEmpty)
        '- yarım kalan başlıklar: ${unresolvedThreads.take(3).join(' | ')}',
      if (sharedHabits.isNotEmpty)
        '- ortak alışkanlıklar: ${sharedHabits.take(4).join(' | ')}',
      if (trustMoments.isNotEmpty)
        '- güven anları: ${trustMoments.take(3).join(' | ')}',
      'KURAL: Bu bellek sadece bilgi değil; her oturumu önceki ilişkinin ve ortak geçmişin devamı gibi hissettirmeli.',
    ].join('\n');
  }
}
