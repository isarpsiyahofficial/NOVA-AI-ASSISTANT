// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/runtime/nova_task_experience.dart';
import 'nova_memory_compaction_service.dart';

class NovaTaskExperienceAnalytics {
  final String taskKey;
  final int totalRuns;
  final int successfulRuns;
  final int correctionHeavyRuns;
  final double averageSatisfaction;
  final double averageLatencySeconds;
  final double averageDurationSeconds;
  final double promotionReadiness;
  final List<String> stableSuccessSteps;
  final List<String> recurringWasteSteps;
  final List<String> recurringErrorSignals;

  const NovaTaskExperienceAnalytics({
    required this.taskKey,
    required this.totalRuns,
    required this.successfulRuns,
    required this.correctionHeavyRuns,
    required this.averageSatisfaction,
    required this.averageLatencySeconds,
    required this.averageDurationSeconds,
    required this.promotionReadiness,
    required this.stableSuccessSteps,
    required this.recurringWasteSteps,
    required this.recurringErrorSignals,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'taskKey': taskKey,
    'totalRuns': totalRuns,
    'successfulRuns': successfulRuns,
    'correctionHeavyRuns': correctionHeavyRuns,
    'averageSatisfaction': averageSatisfaction,
    'averageLatencySeconds': averageLatencySeconds,
    'averageDurationSeconds': averageDurationSeconds,
    'promotionReadiness': promotionReadiness,
    'stableSuccessSteps': stableSuccessSteps,
    'recurringWasteSteps': recurringWasteSteps,
    'recurringErrorSignals': recurringErrorSignals,
  };

  String buildPromptSection() {
    return [
      'GÖREV DENEYİM ANALİTİĞİ:',
      '- görev: $taskKey',
      '- toplam tekrar: $totalRuns',
      '- başarılı tekrar: $successfulRuns',
      '- düzeltme ağır tekrar: $correctionHeavyRuns',
      '- memnuniyet: ${averageSatisfaction.toStringAsFixed(2)}',
      '- ilk tepki gecikmesi: ${averageLatencySeconds.toStringAsFixed(2)} sn',
      '- ortalama süre: ${averageDurationSeconds.toStringAsFixed(1)} sn',
      '- skill terfi hazırlığı: ${promotionReadiness.toStringAsFixed(2)}',
      if (stableSuccessSteps.isNotEmpty)
        '- tekrar işe yarayan adımlar: ${stableSuccessSteps.take(5).join(' | ')}',
      if (recurringWasteSteps.isNotEmpty)
        '- tekrar boşa gidenler: ${recurringWasteSteps.take(4).join(' | ')}',
      if (recurringErrorSignals.isNotEmpty)
        '- sık hata sinyalleri: ${recurringErrorSignals.take(4).join(' | ')}',
    ].join('\n');
  }
}

class TaskExperienceStore {
  static const NovaMemoryCompactionService _compaction =
      NovaMemoryCompactionService();
  static const String _storageKey = 'nova_task_experiences_v1';
  static const int _maxExperienceCount = 240;

  const TaskExperienceStore();

  Future<List<NovaTaskExperience>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty)
        return const <NovaTaskExperience>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <NovaTaskExperience>[];
      final mapped = decoded
          .whereType<Map>()
          .map(
            (e) => _compact(
              NovaTaskExperience.fromMap(Map<String, dynamic>.from(e)),
            ),
          )
          .where((e) => _normalizeKey(e.taskKey).isNotEmpty)
          .toList(growable: true);
      mapped.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return List<NovaTaskExperience>.unmodifiable(mapped);
    } catch (_) {
      return const <NovaTaskExperience>[];
    }
  }

  Future<void> add(NovaTaskExperience experience) async {
    final current = await getAll();
    final compacted = _compact(experience);
    final merged = _mergeSimilar(<NovaTaskExperience>[compacted, ...current]);
    final trimmed = _trimToBudget(merged);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(trimmed.map((e) => e.toMap()).toList(growable: false)),
    );
  }

  Future<List<NovaTaskExperience>> byTaskKey(String taskKey) async {
    final normalized = _normalizeKey(taskKey);
    final all = await getAll();
    return all
        .where((e) => _normalizeKey(e.taskKey) == normalized)
        .toList(growable: false);
  }

  Future<List<NovaTaskExperience>> bySpeakerKey(
    String speakerKey, {
    int limit = 24,
  }) async {
    final normalized = _normalizeText(speakerKey);
    if (normalized.isEmpty) return const <NovaTaskExperience>[];
    final all = await getAll();
    return all
        .where((e) => _normalizeText(e.speakerKey) == normalized)
        .take(limit.clamp(1, 80) as int)
        .toList(growable: false);
  }

  Future<List<NovaTaskExperience>> recent({
    Duration window = const Duration(days: 21),
    int limit = 60,
  }) async {
    final all = await getAll();
    final now = DateTime.now();
    return all
        .where((e) => now.difference(e.createdAt) <= window)
        .take(limit.clamp(1, 120) as int)
        .toList(growable: false);
  }

  Future<void> cleanup({Duration maxAge = const Duration(days: 90)}) async {
    final all = await getAll();
    final now = DateTime.now();
    final kept = all
        .where((e) => now.difference(e.createdAt) <= maxAge)
        .toList(growable: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(kept.map((e) => e.toMap()).toList(growable: false)),
    );
  }

  Future<NovaTaskExperienceAnalytics?> buildAnalytics(String taskKey) async {
    final items = await byTaskKey(taskKey);
    if (items.isEmpty) return null;
    return _buildAnalytics(taskKey: _normalizeKey(taskKey), items: items);
  }

  Future<List<NovaTaskExperienceAnalytics>> buildTopAnalytics({
    int limit = 8,
  }) async {
    final all = await getAll();
    final grouped = <String, List<NovaTaskExperience>>{};
    for (final item in all) {
      final key = _normalizeKey(item.taskKey);
      if (key.isEmpty) continue;
      grouped.putIfAbsent(key, () => <NovaTaskExperience>[]).add(item);
    }
    final analytics =
        grouped.entries
            .map((e) => _buildAnalytics(taskKey: e.key, items: e.value))
            .toList(growable: false)
          ..sort(
            (a, b) => b.promotionReadiness.compareTo(a.promotionReadiness),
          );
    return analytics.take(limit.clamp(1, 16) as int).toList(growable: false);
  }

  Future<List<String>> recommendPromotionCandidates({int limit = 8}) async {
    final analytics = await buildTopAnalytics(limit: math.max(limit, 12));
    return analytics
        .where(
          (e) =>
              e.totalRuns >= 2 &&
              e.averageSatisfaction >= 0.68 &&
              e.promotionReadiness >= 0.62,
        )
        .map((e) => e.taskKey)
        .take(limit.clamp(1, 12) as int)
        .toList(growable: false);
  }

  Future<String> buildPromptSectionForTask(String taskKey) async {
    final analytics = await buildAnalytics(taskKey);
    if (analytics == null) {
      return 'GÖREV DENEYİM HAVUZU: Bu görev için yeterli tekrar birikmedi; yeni deneyim üretilebilir.';
    }
    final related = await byTaskKey(taskKey);
    final recentSuccess = related
        .where((e) => e.satisfactionSignal >= 0.65)
        .take(3)
        .map((e) => e.strategySummary.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    return [
      analytics.buildPromptSection(),
      if (recentSuccess.isNotEmpty)
        'SON BAŞARILI ÖZETLER: ${recentSuccess.join(' || ')}',
      'KURAL: Eğer ilişki tonu değişmişse veya yeni kişi bağlamı varsa eski patterni aynen kopyalama; sadece başlangıç yönü olarak kullan.',
    ].join('\n');
  }

  Future<Map<String, dynamic>> summarizeLearningHealth() async {
    final all = await getAll();
    final top = await buildTopAnalytics(limit: 6);
    final ownerHeavy = all
        .where((e) => _normalizeText(e.speakerKey).contains('owner'))
        .length;
    final correctionHeavy = all
        .where((e) => e.correctionCount >= 2 || e.unnecessaryQuestionCount >= 2)
        .length;
    return <String, dynamic>{
      'totalExperiences': all.length,
      'ownerHeavyCount': ownerHeavy,
      'correctionHeavyCount': correctionHeavy,
      'topPromotionCandidates': top
          .map((e) => e.taskKey)
          .toList(growable: false),
      'averagePromotionReadiness': top.isEmpty
          ? 0.0
          : top.fold<double>(0, (sum, e) => sum + e.promotionReadiness) /
                top.length,
    };
  }

  NovaTaskExperience _compact(NovaTaskExperience value) {
    return NovaTaskExperience(
      id: value.id,
      taskKey: _compaction.compactSummary(value.taskKey, maxLength: 56),
      speakerKey: _compaction.compactSummary(value.speakerKey, maxLength: 48),
      strategySummary: _compaction.compactSummary(
        value.strategySummary,
        maxLength: 180,
      ),
      successfulSteps: _compaction.compactStrings(
        value.successfulSteps,
        limit: 6,
        maxItemLength: 84,
      ),
      wastedSteps: _compaction.compactStrings(
        value.wastedSteps,
        limit: 5,
        maxItemLength: 84,
      ),
      errorSignals: _compaction.compactStrings(
        value.errorSignals,
        limit: 5,
        maxItemLength: 84,
      ),
      durationSeconds: value.durationSeconds,
      firstResponseLatencySeconds: value.firstResponseLatencySeconds,
      turnCount: value.turnCount,
      correctionCount: value.correctionCount,
      unnecessaryQuestionCount: value.unnecessaryQuestionCount,
      satisfactionSignal: value.satisfactionSignal,
      createdAt: value.createdAt,
    );
  }

  NovaTaskExperienceAnalytics _buildAnalytics({
    required String taskKey,
    required List<NovaTaskExperience> items,
  }) {
    final successPool = <String, int>{};
    final wastePool = <String, int>{};
    final errorPool = <String, int>{};
    int successes = 0;
    int correctionHeavy = 0;
    double satisfaction = 0;
    double latency = 0;
    double duration = 0;

    for (final item in items) {
      final consideredSuccess =
          item.satisfactionSignal >= 0.65 && item.correctionCount <= 1;
      if (consideredSuccess) successes += 1;
      if (item.correctionCount >= 2 || item.unnecessaryQuestionCount >= 2)
        correctionHeavy += 1;
      satisfaction += item.satisfactionSignal.clamp(0, 1);
      latency += item.firstResponseLatencySeconds <= 0
          ? 0
          : item.firstResponseLatencySeconds;
      duration += item.durationSeconds <= 0 ? 0 : item.durationSeconds;
      for (final step in item.successfulSteps) {
        final key = _normalizeText(step);
        if (key.isEmpty) continue;
        successPool[key] = (successPool[key] ?? 0) + 1;
      }
      for (final step in item.wastedSteps) {
        final key = _normalizeText(step);
        if (key.isEmpty) continue;
        wastePool[key] = (wastePool[key] ?? 0) + 1;
      }
      for (final signal in item.errorSignals) {
        final key = _normalizeText(signal);
        if (key.isEmpty) continue;
        errorPool[key] = (errorPool[key] ?? 0) + 1;
      }
    }

    final count = items.length.toDouble();
    final avgSatisfaction = satisfaction / count;
    final avgLatency = latency / count;
    final avgDuration = duration / count;
    final readiness =
        ((avgSatisfaction * 0.45) +
                ((successes / count).clamp(0, 1) * 0.25) +
                (_inversePenalty(avgLatency, ideal: 1.8, worst: 8.0) * 0.15) +
                (_inversePenalty(avgDuration, ideal: 8.0, worst: 90.0) * 0.10) +
                ((1 - (correctionHeavy / count).clamp(0, 1)) * 0.05))
            .clamp(0.0, 0.98);

    List<String> sortPool(Map<String, int> pool, int cap) {
      final entries = pool.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return entries.map((e) => e.key).take(cap).toList(growable: false);
    }

    return NovaTaskExperienceAnalytics(
      taskKey: taskKey,
      totalRuns: items.length,
      successfulRuns: successes,
      correctionHeavyRuns: correctionHeavy,
      averageSatisfaction: avgSatisfaction,
      averageLatencySeconds: avgLatency,
      averageDurationSeconds: avgDuration,
      promotionReadiness: readiness,
      stableSuccessSteps: sortPool(successPool, 6),
      recurringWasteSteps: sortPool(wastePool, 5),
      recurringErrorSignals: sortPool(errorPool, 5),
    );
  }

  List<NovaTaskExperience> _mergeSimilar(List<NovaTaskExperience> items) {
    final map = <String, NovaTaskExperience>{};
    final ordered = items.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    for (final item in ordered) {
      final key = [
        _normalizeKey(item.taskKey),
        _normalizeText(item.speakerKey),
        _normalizeText(item.strategySummary),
      ].join('::');
      if (key.replaceAll(':', '').trim().isEmpty) continue;
      final existing = map[key];
      if (existing == null) {
        map[key] = item;
        continue;
      }
      map[key] = _preferStronger(existing, item);
    }
    return map.values.toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<NovaTaskExperience> _trimToBudget(List<NovaTaskExperience> items) {
    final ordered = items.toList()
      ..sort((a, b) => _retentionScore(b).compareTo(_retentionScore(a)));
    return ordered.take(_maxExperienceCount).toList(growable: false);
  }

  NovaTaskExperience _preferStronger(
    NovaTaskExperience a,
    NovaTaskExperience b,
  ) {
    final scoreA = _retentionScore(a);
    final scoreB = _retentionScore(b);
    if (scoreB >= scoreA) return b;
    return a;
  }

  double _retentionScore(NovaTaskExperience value) {
    final freshness = _inversePenalty(
      DateTime.now().difference(value.createdAt).inDays.toDouble(),
      ideal: 1,
      worst: 120,
    );
    return (value.satisfactionSignal.clamp(0, 1) * 0.40) +
        (_inversePenalty(
              value.firstResponseLatencySeconds,
              ideal: 1.5,
              worst: 8,
            ) *
            0.18) +
        (_inversePenalty(value.durationSeconds, ideal: 8, worst: 90) * 0.12) +
        ((1 - (value.correctionCount.clamp(0, 4) / 4)) * 0.10) +
        ((1 - (value.unnecessaryQuestionCount.clamp(0, 4) / 4)) * 0.10) +
        (freshness * 0.10);
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
