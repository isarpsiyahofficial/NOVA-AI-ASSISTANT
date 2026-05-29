// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/call_learning/learned_call_response.dart' as core;

class LearnedCallResponseService {
  static const String _storageKey = 'nova_learned_call_responses_v1';

  const LearnedCallResponseService();

  Future<List<core.LearnedCallResponse>> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty)
        return const <core.LearnedCallResponse>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <core.LearnedCallResponse>[];
      return decoded
          .whereType<Map>()
          .map(
            (e) =>
                core.LearnedCallResponse.fromMap(Map<String, dynamic>.from(e)),
          )
          .where(
            (e) => e.id.trim().isNotEmpty && e.responseText.trim().isNotEmpty,
          )
          .toList(growable: false);
    } catch (_) {
      return const <core.LearnedCallResponse>[];
    }
  }

  Future<void> _save(List<core.LearnedCallResponse> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(items.map((e) => e.toMap()).toList(growable: false)),
      );
    } catch (_) {}
  }

  Future<List<core.LearnedCallResponse>> getAll() async {
    final items = await _load();
    final sorted = [...items]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }

  Future<core.LearnedCallResponse> upsert({
    required String trigger,
    required String responseText,
    String category = 'general',
  }) async {
    final normalizedTrigger = _normalize(trigger);
    final cleanedResponse = responseText.trim();
    final cleanedCategory = _normalizeCategory(category);
    if (normalizedTrigger.isEmpty || cleanedResponse.isEmpty) {
      throw ArgumentError(
        'Öğrenilmiş çağrı cevabı için tetik ve cevap zorunludur.',
      );
    }

    final items = await _load();
    final now = DateTime.now();
    core.LearnedCallResponse? updated;

    final next = items
        .map((item) {
          if (_normalize(item.trigger) == normalizedTrigger &&
              item.category == cleanedCategory) {
            updated = item.copyWith(
              trigger: trigger.trim(),
              responseText: cleanedResponse,
              category: cleanedCategory,
              updatedAt: now,
            );
            return updated!;
          }
          return item;
        })
        .toList(growable: true);

    if (updated == null) {
      updated = core.LearnedCallResponse(
        id: 'learned_call_${now.microsecondsSinceEpoch}',
        trigger: trigger.trim(),
        responseText: cleanedResponse,
        category: cleanedCategory,
        createdAt: now,
        updatedAt: now,
      );
      next.insert(0, updated!);
    }

    await _save(next);
    return updated!;
  }

  Future<int> removeById(String id) async {
    final target = id.trim();
    if (target.isEmpty) return 0;
    final items = await _load();
    final kept = items.where((e) => e.id != target).toList(growable: false);
    await _save(kept);
    return items.length - kept.length;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<core.LearnedCallResponse?> resolve({
    String? callerName,
    String? statusLabel,
    String? rawTrigger,
  }) async {
    final items = await _load();
    if (items.isEmpty) return null;

    final normalizedCaller = _normalize(callerName ?? '');
    final normalizedStatus = _normalize(statusLabel ?? '');
    final normalizedTrigger = _normalize(rawTrigger ?? '');

    core.LearnedCallResponse? best;
    double bestScore = 0;

    for (final item in items) {
      final score = _score(
        item: item,
        normalizedCaller: normalizedCaller,
        normalizedStatus: normalizedStatus,
        normalizedTrigger: normalizedTrigger,
      );
      if (score > bestScore) {
        bestScore = score;
        best = item;
      }
    }

    if (bestScore < 0.74) return null;
    return best;
  }

  double _score({
    required core.LearnedCallResponse item,
    required String normalizedCaller,
    required String normalizedStatus,
    required String normalizedTrigger,
  }) {
    final trigger = _normalize(item.trigger);
    final category = _normalizeCategory(item.category);
    if (trigger.isEmpty) return 0;

    double score = 0;

    if (normalizedTrigger.isNotEmpty) {
      if (normalizedTrigger == trigger) {
        score = 1.0;
      } else if (normalizedTrigger.contains(trigger) ||
          trigger.contains(normalizedTrigger)) {
        score = 0.92;
      } else {
        final overlap = _tokenOverlap(normalizedTrigger, trigger);
        if (overlap >= 0.70) score = 0.82;
      }
    }

    if (normalizedCaller.isNotEmpty) {
      if (trigger == normalizedCaller ||
          trigger.contains(normalizedCaller) ||
          normalizedCaller.contains(trigger)) {
        score = score < 0.9 ? 0.9 : score;
      } else {
        final overlap = _tokenOverlap(normalizedCaller, trigger);
        if (overlap >= 0.60) score = score < 0.80 ? 0.80 : score;
      }
    }

    if (normalizedStatus.isNotEmpty && category == normalizedStatus) {
      score = score < 0.88 ? 0.88 : score;
    }

    if (category == 'general' && score > 0) {
      score -= 0.03;
    }

    return score.clamp(0, 1).toDouble();
  }

  double _tokenOverlap(String a, String b) {
    final aa = a.split(' ').where((e) => e.trim().isNotEmpty).toSet();
    final bb = b.split(' ').where((e) => e.trim().isNotEmpty).toSet();
    if (aa.isEmpty || bb.isEmpty) return 0;
    final common = aa.intersection(bb).length;
    final denom = aa.length > bb.length ? aa.length : bb.length;
    return common / denom;
  }

  String _normalizeCategory(String raw) {
    final value = _normalize(raw);
    if (value.isEmpty) return 'general';
    if (value.contains('sleep')) return 'sleeping';
    if (value.contains('drive') ||
        value.contains('surus') ||
        value.contains('suruş') ||
        value.contains('arac'))
      return 'driving';
    if (value.contains('shower') ||
        value.contains('dus') ||
        value.contains('duş'))
      return 'showering';
    if (value.contains('busy') ||
        value.contains('mesgul') ||
        value.contains('meşgul'))
      return 'busy';
    return value;
  }

  String _normalize(String raw) => raw
      .toLowerCase()
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('û', 'u')
      .replaceAll(RegExp(r'[^a-z0-9çğıöşü ]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
