// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaSkillCard {
  final String skillKey;
  final String taskKey;
  final String title;
  final String strategy;
  final List<String> preferredSteps;
  final List<String> avoidSteps;
  final int validationCount;
  final double averageDurationSeconds;
  final double confidence;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NovaSkillCard({
    required this.skillKey,
    required this.taskKey,
    required this.title,
    required this.strategy,
    required this.preferredSteps,
    required this.avoidSteps,
    required this.validationCount,
    required this.averageDurationSeconds,
    required this.confidence,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'skillKey': skillKey,
    'taskKey': taskKey,
    'title': title,
    'strategy': strategy,
    'preferredSteps': preferredSteps,
    'avoidSteps': avoidSteps,
    'validationCount': validationCount,
    'averageDurationSeconds': averageDurationSeconds,
    'confidence': confidence,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory NovaSkillCard.fromMap(Map<String, dynamic> map) {
    List<String> parseList(String key) =>
        (map[key] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
    return NovaSkillCard(
      skillKey: map['skillKey']?.toString() ?? '',
      taskKey: map['taskKey']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      strategy: map['strategy']?.toString() ?? '',
      preferredSteps: parseList('preferredSteps'),
      avoidSteps: parseList('avoidSteps'),
      validationCount: (map['validationCount'] as num?)?.toInt() ?? 0,
      averageDurationSeconds:
          (map['averageDurationSeconds'] as num?)?.toDouble() ?? 0.0,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  String buildPromptSection() {
    return [
      'DOĞRULANMIŞ SKILL KARTI:',
      '- görev: $taskKey',
      '- başlık: $title',
      '- strateji: $strategy',
      '- doğrulama sayısı: $validationCount',
      '- ortalama süre: ${averageDurationSeconds.toStringAsFixed(1)} sn',
      '- güven: ${confidence.toStringAsFixed(2)}',
      if (preferredSteps.isNotEmpty)
        '- tercih edilen sıra: ${preferredSteps.take(5).join(' → ')}',
      if (avoidSteps.isNotEmpty)
        '- kaçınılacaklar: ${avoidSteps.take(4).join(' | ')}',
      'KURAL: Mümkünse önce bu kısayolu kullan; ama bağlam uymuyorsa körü körüne kilitlenme.',
    ].join('\n');
  }
}
