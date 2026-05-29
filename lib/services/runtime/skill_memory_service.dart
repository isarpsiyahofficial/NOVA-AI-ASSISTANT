// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/runtime/nova_skill_card.dart';
import '../../core/runtime/nova_task_experience.dart';
import 'nova_memory_compaction_service.dart';

class NovaSkillMemoryRecommendation {
  final NovaSkillCard card;
  final double relevanceScore;
  final String reason;
  final List<String> matchedSignals;

  const NovaSkillMemoryRecommendation({
    required this.card,
    required this.relevanceScore,
    required this.reason,
    required this.matchedSignals,
  });
}

class NovaSkillMemoryHealth {
  final int totalSkills;
  final int highlyTrustedSkills;
  final int weakSkills;
  final int staleSkills;
  final double averageConfidence;
  final List<String> promotionCandidates;
  final List<String> staleSkillKeys;

  const NovaSkillMemoryHealth({
    required this.totalSkills,
    required this.highlyTrustedSkills,
    required this.weakSkills,
    required this.staleSkills,
    required this.averageConfidence,
    required this.promotionCandidates,
    required this.staleSkillKeys,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'totalSkills': totalSkills,
    'highlyTrustedSkills': highlyTrustedSkills,
    'weakSkills': weakSkills,
    'staleSkills': staleSkills,
    'averageConfidence': averageConfidence,
    'promotionCandidates': promotionCandidates,
    'staleSkillKeys': staleSkillKeys,
  };

  String buildPromptSection() {
    return [
      'SKILL HAFIZA SAĞLIĞI:',
      '- toplam skill: $totalSkills',
      '- yüksek güvenli: $highlyTrustedSkills',
      '- zayıf/kanıtsız: $weakSkills',
      '- bayatlamış skill: $staleSkills',
      '- ortalama güven: ${averageConfidence.toStringAsFixed(2)}',
      if (promotionCandidates.isNotEmpty)
        '- yükselmeye yakın: ${promotionCandidates.take(5).join(' | ')}',
      if (staleSkillKeys.isNotEmpty)
        '- gözden geçir: ${staleSkillKeys.take(5).join(' | ')}',
      'KURAL: Güven düşükse skill kör uygulanmasın; sadece hafif öncelik olsun.',
    ].join('\n');
  }
}

class SkillMemoryService {
  static const NovaMemoryCompactionService _compaction =
      NovaMemoryCompactionService();
  static const String _storageKey = 'nova_skill_cards_v1';
  static const int _maxSkillCount = 180;

  const SkillMemoryService();

  Future<Map<String, NovaSkillCard>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty)
        return const <String, NovaSkillCard>{};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const <String, NovaSkillCard>{};
      final map = <String, NovaSkillCard>{};
      decoded.forEach((key, value) {
        if (value is Map) {
          final card = NovaSkillCard.fromMap(Map<String, dynamic>.from(value));
          final normalizedKey = _normalizeKey(
            key.toString().trim().isEmpty ? card.taskKey : key.toString(),
          );
          if (normalizedKey.isNotEmpty) {
            map[normalizedKey] = _compact(card);
          }
        }
      });
      return map;
    } catch (_) {
      return const <String, NovaSkillCard>{};
    }
  }

  Future<NovaSkillCard?> getByTaskKey(String taskKey) async {
    final all = await getAll();
    return all[_normalizeKey(taskKey)];
  }

  Future<void> save(NovaSkillCard card) async {
    final all = await getAll();
    final key = _normalizeKey(card.taskKey);
    if (key.isEmpty) return;
    final incoming = _compact(card);
    final existing = all[key];
    all[key] = existing == null ? incoming : _mergeCards(existing, incoming);
    final trimmed = _trimToBudget(all);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(trimmed.map((k, v) => MapEntry(k, v.toMap()))),
    );
  }

  Future<void> remove(String taskKey) async {
    final all = await getAll();
    all.remove(_normalizeKey(taskKey));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(all.map((k, v) => MapEntry(k, v.toMap()))),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<List<NovaSkillMemoryRecommendation>> recommendForContext({
    required String taskText,
    String speakerKey = '',
    List<String> relationSignals = const <String>[],
    int limit = 5,
  }) async {
    final all = await getAll();
    final normalizedTask = _normalizeText(taskText);
    final normalizedSpeaker = _normalizeText(speakerKey);
    final normalizedRelations = relationSignals
        .map(_normalizeText)
        .where((e) => e.isNotEmpty)
        .toSet();
    final items = <NovaSkillMemoryRecommendation>[];
    for (final card in all.values) {
      final scoreData = _scoreCard(
        card,
        normalizedTask: normalizedTask,
        normalizedSpeaker: normalizedSpeaker,
        relationSignals: normalizedRelations,
      );
      if (scoreData.$1 <= 0.18) continue;
      items.add(
        NovaSkillMemoryRecommendation(
          card: card,
          relevanceScore: scoreData.$1,
          reason: scoreData.$2,
          matchedSignals: scoreData.$3,
        ),
      );
    }
    items.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return items.take(limit.clamp(1, 12) as int).toList(growable: false);
  }

  Future<String> buildPromptSectionForTask({
    required String taskText,
    String speakerKey = '',
    List<String> relationSignals = const <String>[],
    int limit = 3,
  }) async {
    final recommendations = await recommendForContext(
      taskText: taskText,
      speakerKey: speakerKey,
      relationSignals: relationSignals,
      limit: limit,
    );
    if (recommendations.isEmpty) {
      return 'SKILL HAFIZA: Bu görev için güvenli bir kısa yol bulunamadı; normal düşünme zinciriyle ilerle.';
    }
    return [
      'SKILL HAFIZA EŞLEŞMESİ:',
      for (final item in recommendations)
        '- ${item.card.title} | skor=${item.relevanceScore.toStringAsFixed(2)} | neden=${item.reason}'
            '${item.matchedSignals.isEmpty ? '' : ' | iz=${item.matchedSignals.join(', ')}'}\n'
            '  strateji=${item.card.strategy}\n'
            '${item.card.preferredSteps.isEmpty ? '' : '  adımlar=${item.card.preferredSteps.take(5).join(' → ')}'}'
            '${item.card.avoidSteps.isEmpty ? '' : '\n  kaçın=${item.card.avoidSteps.take(4).join(' | ')}'}',
      'KURAL: En yüksek skorlu kartı bağlama uygunsa kullan; ama yeni ilişki tonu veya yeni görev yapısı varsa kör bağlanma.',
    ].join('\n');
  }

  Future<NovaSkillMemoryHealth> buildHealth() async {
    final all = await getAll();
    if (all.isEmpty) {
      return const NovaSkillMemoryHealth(
        totalSkills: 0,
        highlyTrustedSkills: 0,
        weakSkills: 0,
        staleSkills: 0,
        averageConfidence: 0,
        promotionCandidates: <String>[],
        staleSkillKeys: <String>[],
      );
    }
    final now = DateTime.now();
    final values = all.values.toList(growable: false);
    final highlyTrusted = values
        .where((e) => e.validationCount >= 3 && e.confidence >= 0.78)
        .length;
    final weak = values
        .where((e) => e.validationCount <= 1 || e.confidence < 0.50)
        .length;
    final stale = values
        .where((e) => now.difference(e.updatedAt).inDays >= 45)
        .toList(growable: false);
    final average =
        values.fold<double>(0, (sum, e) => sum + e.confidence) / values.length;
    final promotions = values
        .where(
          (e) =>
              e.validationCount >= 2 &&
              e.confidence >= 0.65 &&
              now.difference(e.updatedAt).inDays <= 21,
        )
        .map((e) => e.title.trim().isEmpty ? e.taskKey : e.title)
        .take(8)
        .toList(growable: false);
    return NovaSkillMemoryHealth(
      totalSkills: values.length,
      highlyTrustedSkills: highlyTrusted,
      weakSkills: weak,
      staleSkills: stale.length,
      averageConfidence: average,
      promotionCandidates: promotions,
      staleSkillKeys: stale
          .map((e) => e.taskKey)
          .take(8)
          .toList(growable: false),
    );
  }

  Future<NovaSkillCard?> promoteFromExperiences({
    required String taskKey,
    required List<NovaTaskExperience> experiences,
    String titleHint = '',
  }) async {
    final normalizedTaskKey = _normalizeKey(taskKey);
    if (normalizedTaskKey.isEmpty || experiences.isEmpty) return null;
    final related = experiences
        .where((e) => _normalizeKey(e.taskKey) == normalizedTaskKey)
        .toList(growable: false);
    if (related.isEmpty) return null;

    final successPool = <String, int>{};
    final avoidPool = <String, int>{};
    double satisfaction = 0;
    double latency = 0;
    double duration = 0;
    int validationCount = 0;

    for (final item in related) {
      satisfaction += item.satisfactionSignal.clamp(0, 1);
      latency += item.firstResponseLatencySeconds <= 0
          ? 0
          : item.firstResponseLatencySeconds;
      duration += item.durationSeconds <= 0 ? 0 : item.durationSeconds;
      if (item.satisfactionSignal >= 0.62 && item.correctionCount <= 1) {
        validationCount += 1;
      }
      for (final step in item.successfulSteps) {
        final key = _normalizeText(step);
        if (key.isEmpty) continue;
        successPool[key] = (successPool[key] ?? 0) + 1;
      }
      for (final step in <String>[...item.wastedSteps, ...item.errorSignals]) {
        final key = _normalizeText(step);
        if (key.isEmpty) continue;
        avoidPool[key] = (avoidPool[key] ?? 0) + 1;
      }
    }

    final count = related.length.toDouble();
    final avgSatisfaction = satisfaction / count;
    final avgLatency = latency / count;
    final avgDuration = duration / count;
    final confidence =
        ((avgSatisfaction * 0.55) +
                (_inversePenalty(avgLatency, ideal: 1.6, worst: 6.5) * 0.20) +
                (_inversePenalty(avgDuration, ideal: 8, worst: 80) * 0.10) +
                ((validationCount / count).clamp(0, 1) * 0.15))
            .clamp(0.05, 0.98);

    final preferredSteps = successPool.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final avoidSteps = avoidPool.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final card = NovaSkillCard(
      skillKey:
          'skill_${_normalizeKey(titleHint.isEmpty ? normalizedTaskKey : titleHint)}',
      taskKey: normalizedTaskKey,
      title: _compactTitle(titleHint, normalizedTaskKey),
      strategy: _buildStrategySummary(related),
      preferredSteps: preferredSteps
          .map((e) => e.key)
          .take(6)
          .toList(growable: false),
      avoidSteps: avoidSteps.map((e) => e.key).take(5).toList(growable: false),
      validationCount: validationCount,
      averageDurationSeconds: avgDuration,
      confidence: confidence,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await save(card);
    return card;
  }

  Future<Map<String, dynamic>> summarize() async {
    final health = await buildHealth();
    final all = await getAll();
    final newest = all.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return <String, dynamic>{
      'health': health.toMap(),
      'newestSkillKeys': newest
          .take(8)
          .map((e) => e.taskKey)
          .toList(growable: false),
      'newestTitles': newest
          .take(8)
          .map((e) => e.title)
          .toList(growable: false),
    };
  }

  NovaSkillCard _compact(NovaSkillCard card) {
    return NovaSkillCard(
      skillKey: _compaction.compactSummary(card.skillKey, maxLength: 56),
      taskKey: _compaction.compactSummary(card.taskKey, maxLength: 56),
      title: _compaction.compactSummary(card.title, maxLength: 72),
      strategy: _compaction.compactSummary(card.strategy, maxLength: 180),
      preferredSteps: _compaction.compactStrings(
        card.preferredSteps,
        limit: 6,
        maxItemLength: 84,
      ),
      avoidSteps: _compaction.compactStrings(
        card.avoidSteps,
        limit: 5,
        maxItemLength: 84,
      ),
      validationCount: card.validationCount,
      averageDurationSeconds: card.averageDurationSeconds,
      confidence: card.confidence,
      createdAt: card.createdAt,
      updatedAt: card.updatedAt,
    );
  }

  Map<String, NovaSkillCard> _trimToBudget(Map<String, NovaSkillCard> source) {
    final entries = source.entries.toList()
      ..sort((a, b) {
        final scoreA = _retentionScore(a.value);
        final scoreB = _retentionScore(b.value);
        return scoreB.compareTo(scoreA);
      });
    return Map<String, NovaSkillCard>.fromEntries(entries.take(_maxSkillCount));
  }

  NovaSkillCard _mergeCards(NovaSkillCard base, NovaSkillCard incoming) {
    final preferred = <String>{
      ...base.preferredSteps,
      ...incoming.preferredSteps,
    }.take(6).toList(growable: false);
    final avoid = <String>{
      ...base.avoidSteps,
      ...incoming.avoidSteps,
    }.take(5).toList(growable: false);
    final totalValidations =
        math.max(base.validationCount, 0) +
        math.max(incoming.validationCount, 0);
    final weightedDuration =
        ((base.averageDurationSeconds * math.max(base.validationCount, 1)) +
            (incoming.averageDurationSeconds *
                math.max(incoming.validationCount, 1))) /
        math.max(
          math.max(base.validationCount, 1) +
              math.max(incoming.validationCount, 1),
          1,
        );
    final confidence = ((base.confidence * 0.45) + (incoming.confidence * 0.55))
        .clamp(0.05, 0.99);
    final chosenStrategy =
        incoming.strategy.trim().length >= base.strategy.trim().length
        ? incoming.strategy
        : base.strategy;
    final chosenTitle = incoming.title.trim().isNotEmpty
        ? incoming.title
        : base.title;
    return NovaSkillCard(
      skillKey: incoming.skillKey.trim().isNotEmpty
          ? incoming.skillKey
          : base.skillKey,
      taskKey: incoming.taskKey.trim().isNotEmpty
          ? incoming.taskKey
          : base.taskKey,
      title: chosenTitle,
      strategy: chosenStrategy,
      preferredSteps: preferred,
      avoidSteps: avoid,
      validationCount: totalValidations.toInt(),
      averageDurationSeconds: weightedDuration,
      confidence: confidence,
      createdAt: base.createdAt.isBefore(incoming.createdAt)
          ? base.createdAt
          : incoming.createdAt,
      updatedAt: incoming.updatedAt.isAfter(base.updatedAt)
          ? incoming.updatedAt
          : base.updatedAt,
    );
  }

  double _retentionScore(NovaSkillCard card) {
    final freshness = _inversePenalty(
      DateTime.now().difference(card.updatedAt).inDays.toDouble(),
      ideal: 2,
      worst: 120,
    );
    return (card.confidence * 0.45) +
        ((card.validationCount.clamp(0, 6) / 6) * 0.30) +
        (freshness * 0.25);
  }

  (double, String, List<String>) _scoreCard(
    NovaSkillCard card, {
    required String normalizedTask,
    required String normalizedSpeaker,
    required Set<String> relationSignals,
  }) {
    final matchedSignals = <String>[];
    double score = 0.10;
    final taskKey = _normalizeText(card.taskKey);
    final title = _normalizeText(card.title);
    final strategy = _normalizeText(card.strategy);

    if (normalizedTask.contains(taskKey) || taskKey.contains(normalizedTask)) {
      score += 0.40;
      matchedSignals.add('taskKey');
    }
    if (normalizedTask.isNotEmpty &&
        (normalizedTask.contains(title) || title.contains(normalizedTask))) {
      score += 0.22;
      matchedSignals.add('title');
    }
    final tokens = normalizedTask
        .split(' ')
        .where((e) => e.length >= 3)
        .toSet();
    final strategyTokens = strategy
        .split(' ')
        .where((e) => e.length >= 3)
        .toSet();
    final overlap = tokens.intersection(strategyTokens).length;
    if (overlap > 0) {
      score += math.min(0.18, overlap * 0.03);
      matchedSignals.add('strategyOverlap:$overlap');
    }
    if (normalizedSpeaker.isNotEmpty && strategy.contains(normalizedSpeaker)) {
      score += 0.08;
      matchedSignals.add('speaker');
    }
    for (final signal in relationSignals) {
      if (signal.isNotEmpty &&
          (taskKey.contains(signal) ||
              title.contains(signal) ||
              strategy.contains(signal))) {
        score += 0.05;
        matchedSignals.add('relation:$signal');
      }
    }

    score += (card.confidence.clamp(0, 1) * 0.20);
    score += ((card.validationCount.clamp(0, 5) / 5) * 0.12);
    score -=
        (DateTime.now().difference(card.updatedAt).inDays.clamp(0, 180) / 180) *
        0.08;
    final reason = matchedSignals.isEmpty
        ? 'genel güven ve geçmiş başarı nedeniyle zayıf eşleşme'
        : 'eşleşme ${matchedSignals.join(', ')} izleri üzerinden kuruldu';
    return (score.clamp(0, 0.99), reason, matchedSignals);
  }

  double _inversePenalty(
    double value, {
    required double ideal,
    required double worst,
  }) {
    if (value <= ideal) return 1;
    if (value >= worst) return 0;
    return 1 - ((value - ideal) / (worst - ideal));
  }

  String _buildStrategySummary(List<NovaTaskExperience> experiences) {
    final best = experiences.toList()
      ..sort((a, b) => b.satisfactionSignal.compareTo(a.satisfactionSignal));
    final top = best.take(3).toList(growable: false);
    final summaries = top
        .map((e) => e.strategySummary.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (summaries.isEmpty) {
      return 'Önce ilişki ve bağlamı oku, sonra kısa ve doğal ilk cevap ver, ardından gereksiz soru sayısını düşük tut.';
    }
    return _compaction.compactSummary(summaries.join(' | '), maxLength: 180);
  }

  String _compactTitle(String hint, String fallback) {
    final cleaned = hint.trim();
    if (cleaned.isNotEmpty)
      return _compaction.compactSummary(cleaned, maxLength: 72);
    return fallback
        .replaceAll('_', ' ')
        .split(' ')
        .where((e) => e.trim().isNotEmpty)
        .map((e) => e[0].toUpperCase() + e.substring(1))
        .join(' ')
        .trim();
  }

  String _normalizeKey(String value) {
    return _normalizeText(value).replaceAll(' ', '_');
  }

  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü\s_]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class NovaSkillDeploymentPlan {
  final NovaSkillCard? primarySkill;
  final List<NovaSkillCard> supportingSkills;
  final List<String> executionSteps;
  final List<String> cautionSteps;
  final String relationshipTone;

  const NovaSkillDeploymentPlan({
    required this.primarySkill,
    required this.supportingSkills,
    required this.executionSteps,
    required this.cautionSteps,
    required this.relationshipTone,
  });

  String buildPromptSection() {
    return <String>[
      'SKILL UYGULAMA PLANI:',
      '- ana kart: ${primarySkill?.title ?? 'yok'}',
      '- destek kartları: ${supportingSkills.map((e) => e.title).join(' | ')}',
      '- ilişki tonu: $relationshipTone',
      '- uygulama: ${executionSteps.join(' -> ')}',
      '- dikkat: ${cautionSteps.join(' | ')}',
    ].join('\n');
  }
}

class NovaSkillRelationshipProfile {
  final String speakerKey;
  final String relationshipTone;
  final int strongMatches;
  final int weakMatches;
  final List<String> matchedTitles;

  const NovaSkillRelationshipProfile({
    required this.speakerKey,
    required this.relationshipTone,
    required this.strongMatches,
    required this.weakMatches,
    required this.matchedTitles,
  });
}

extension NovaSkillMemoryServiceDeploymentExtension on SkillMemoryService {
  Future<NovaSkillRelationshipProfile> inspectRelationshipProfile({
    required String taskHint,
    required String speakerKey,
    List<String> relationSignals = const <String>[],
  }) async {
    final cards = (await getAll()).values.toList(growable: false);
    var strong = 0;
    var weak = 0;
    final titles = <String>[];
    for (final card in cards) {
      final scoreTuple = _scoreCard(
        card,
        normalizedTask: _normalizeText(taskHint),
        normalizedSpeaker: _normalizeText(speakerKey),
        relationSignals: relationSignals
            .map(_normalizeText)
            .where((e) => e.isNotEmpty)
            .toSet(),
      );
      final score = scoreTuple.$1;
      if (score >= 0.64) {
        strong++;
        titles.add(card.title);
      } else if (score >= 0.38) {
        weak++;
      }
      if (titles.length >= 6) break;
    }
    final relationshipTone =
        relationSignals.any(
          (e) => e.contains('anne') || e.contains('baba') || e.contains('eş'),
        )
        ? 'yakın ve koruyucu'
        : relationSignals.any((e) => e.contains('yetkili'))
        ? 'saygılı ve net'
        : 'nötr ama sıcak';
    return NovaSkillRelationshipProfile(
      speakerKey: speakerKey,
      relationshipTone: relationshipTone,
      strongMatches: strong,
      weakMatches: weak,
      matchedTitles: titles,
    );
  }

  Future<NovaSkillDeploymentPlan> buildDeploymentPlan({
    required String taskHint,
    required String speakerKey,
    List<String> relationSignals = const <String>[],
  }) async {
    final recommendations = await recommendForContext(
      taskText: taskHint,
      speakerKey: speakerKey,
      relationSignals: relationSignals,
      limit: 4,
    );
    final primary = recommendations.isEmpty ? null : recommendations.first.card;
    final support = recommendations
        .skip(1)
        .map((e) => e.card)
        .take(3)
        .toList(growable: false);
    final relationship = await inspectRelationshipProfile(
      taskHint: taskHint,
      speakerKey: speakerKey,
      relationSignals: relationSignals,
    );
    final executionSteps = <String>[
      if (primary != null) ...primary.preferredSteps.take(4),
      if (primary == null) 'önce niyeti netleştir',
      if (primary == null) 'kısa ilk cevap ver',
      'gerekirse ilişki tonunu koruyarak devam et',
    ];
    final cautionSteps = <String>[
      if (primary != null) ...primary.avoidSteps.take(3),
      'kör ezber çalışma; bağlam uyuşmuyorsa akışı düzelt',
      'mahrem bilgiyi uygunsuz ortamda açma',
    ];
    return NovaSkillDeploymentPlan(
      primarySkill: primary,
      supportingSkills: support,
      executionSteps: executionSteps,
      cautionSteps: cautionSteps,
      relationshipTone: relationship.relationshipTone,
    );
  }
}
