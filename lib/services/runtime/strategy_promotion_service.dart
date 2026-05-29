// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/runtime/nova_post_task_reflection.dart';
import '../../core/runtime/nova_skill_card.dart';
import '../../core/runtime/nova_task_experience.dart';

class StrategyPromotionService {
  const StrategyPromotionService();

  static const List<String> _successNotes = <String>[
    'ana sonucu erken vermek',
    'gereksiz soruyu azaltmak',
    'ilişki tonunu korumak',
    'hızlı ilk tepki',
  ];
  static const List<String> _avoidNotes = <String>[
    'uzun giriş',
    'gereksiz özür',
    'tekrar eden açıklama',
    'yanlış kişiye hitap',
  ];
  static const List<String> _weightsNotes = <String>[
    'speed',
    'clarity',
    'satisfaction',
    'repair',
  ];

  NovaSkillCard? promote({
    required String taskKey,
    required List<NovaTaskExperience> existingExperiences,
    required NovaTaskExperience latestExperience,
    required NovaPostTaskReflection reflection,
    NovaSkillCard? currentCard,
  }) {
    final all = <NovaTaskExperience>[latestExperience, ...existingExperiences]
        .where(
          (e) => e.taskKey.trim().toLowerCase() == taskKey.trim().toLowerCase(),
        )
        .toList(growable: false);
    if (all.length < 2 && !reflection.shouldPromoteSkill) return null;
    final now = DateTime.now();
    final averageDuration = _avg(all.map((e) => e.durationSeconds));
    final avgSatisfaction = _avg(all.map((e) => e.satisfactionSignal));
    final avgLatency = _avg(all.map((e) => e.firstResponseLatencySeconds));
    final validationCount =
        (currentCard?.validationCount ?? 0) +
        (reflection.shouldPromoteSkill ? 1 : 0) +
        (all.length >= 3 ? 1 : 0);
    final confidence = _confidence(
      averageDuration: averageDuration,
      avgSatisfaction: avgSatisfaction,
      avgLatency: avgLatency,
      latest: latestExperience,
      validationCount: validationCount,
    );
    final preferredSteps = _rankSteps(
      all.expand((e) => e.successfulSteps).toList(growable: false),
    );
    final avoidSteps = _rankAvoids(
      all
          .expand((e) => e.wastedSteps.followedBy(e.errorSignals))
          .toList(growable: false),
    );
    final strategy = _strategySummary(
      reflection,
      latestExperience,
      preferredSteps,
      avoidSteps,
    );
    return NovaSkillCard(
      skillKey: currentCard?.skillKey ?? '${taskKey}_skill',
      taskKey: taskKey,
      title: currentCard?.title ?? 'Hızlı rota: $taskKey',
      strategy: strategy,
      preferredSteps: preferredSteps,
      avoidSteps: avoidSteps,
      validationCount: validationCount,
      averageDurationSeconds: averageDuration,
      confidence: confidence,
      createdAt: currentCard?.createdAt ?? now,
      updatedAt: now,
    );
  }

  String _strategySummary(
    NovaPostTaskReflection reflection,
    NovaTaskExperience latest,
    List<String> preferred,
    List<String> avoids,
  ) {
    final parts = <String>[reflection.summary.trim()];
    if (latest.correctionCount == 0 && latest.unnecessaryQuestionCount == 0)
      parts.add('az sürtünme');
    if (latest.firstResponseLatencySeconds <= 1.4) parts.add('erken ilk tepki');
    if (preferred.isNotEmpty)
      parts.add('tercih edilen sıra: ${preferred.take(4).join(' → ')}');
    if (avoids.isNotEmpty) parts.add('kaçın: ${avoids.take(3).join(' | ')}');
    return parts.where((e) => e.trim().isNotEmpty).join(' • ');
  }

  double _confidence({
    required double averageDuration,
    required double avgSatisfaction,
    required double avgLatency,
    required NovaTaskExperience latest,
    required int validationCount,
  }) {
    final durationScore = (1.0 - (averageDuration / 60.0)).clamp(0.0, 1.0);
    final latencyScore = (1.0 - (avgLatency / 8.0)).clamp(0.0, 1.0);
    final frictionScore =
        (1.0 -
                ((latest.correctionCount + latest.unnecessaryQuestionCount) /
                    6.0))
            .clamp(0.0, 1.0);
    final validationScore = (validationCount / 8.0).clamp(0.0, 1.0);
    return ((avgSatisfaction * 0.38) +
            (durationScore * 0.16) +
            (latencyScore * 0.16) +
            (frictionScore * 0.16) +
            (validationScore * 0.14))
        .clamp(0.0, 0.98);
  }

  List<String> _rankSteps(List<String> items) {
    final counts = <String, int>{};
    for (final item in items) {
      final clean = item.trim();
      if (clean.isEmpty) continue;
      counts[clean] = (counts[clean] ?? 0) + 1;
    }
    final list = counts.entries.toList()
      ..sort((a, b) {
        final c = b.value.compareTo(a.value);
        return c != 0 ? c : a.key.length.compareTo(b.key.length);
      });
    return list.map((e) => e.key).take(8).toList(growable: false);
  }

  List<String> _rankAvoids(List<String> items) {
    final counts = <String, int>{};
    for (final item in items) {
      final clean = item.trim();
      if (clean.isEmpty) continue;
      counts[clean] = (counts[clean] ?? 0) + 1;
    }
    final list = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.map((e) => e.key).take(8).toList(growable: false);
  }

  double _avg(Iterable<double> values) {
    final list = values.toList(growable: false);
    if (list.isEmpty) return 0.0;
    return list.reduce((a, b) => a + b) / list.length;
  }
}
