// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/teaching/taught_workflow.dart';

class TaughtWorkflowService {
  static const String _storageKey = 'nova_taught_workflows_v1';
  static const int _maxWorkflowCount = 200;
  static const int _maxStepCount = 30;
  static const int _maxTextLength = 300;

  const TaughtWorkflowService();

  Future<List<TaughtWorkflow>> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw == null || raw.trim().isEmpty) {
        return const <TaughtWorkflow>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <TaughtWorkflow>[];
      }

      final items = decoded
          .whereType<Map>()
          .map(
            (e) => TaughtWorkflow.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .where((e) => e.id.isNotEmpty && e.hasUsableTrigger)
          .toList(growable: false);

      return _dedupeAndTrim(items);
    } catch (_) {
      return const <TaughtWorkflow>[];
    }
  }

  Future<void> _save(List<TaughtWorkflow> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final safe = _dedupeAndTrim(items);
      final encoded = jsonEncode(
        safe.map((e) => e.toMap()).toList(growable: false),
      );
      await prefs.setString(_storageKey, encoded);
    } catch (_) {
      // Sessiz fallback
    }
  }

  List<TaughtWorkflow> _dedupeAndTrim(List<TaughtWorkflow> items) {
    final Map<String, TaughtWorkflow> latest = <String, TaughtWorkflow>{};

    for (final item in items) {
      final existing = latest[item.id];
      if (existing == null || item.updatedAt.isAfter(existing.updatedAt)) {
        latest[item.id] = item;
      }
    }

    final list = latest.values.toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (list.length <= _maxWorkflowCount) {
      return list;
    }

    return list.take(_maxWorkflowCount).toList(growable: false);
  }

  String _sanitizeText(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.length <= _maxTextLength) return cleaned;
    return cleaned.substring(0, _maxTextLength).trim();
  }

  List<String> _sanitizeSteps(List<String> rawSteps) {
    final cleaned = rawSteps
        .map(_sanitizeText)
        .where((e) => e.isNotEmpty)
        .take(_maxStepCount)
        .toList(growable: false);

    return cleaned;
  }

  Future<List<TaughtWorkflow>> getAll() async {
    return _load();
  }

  Future<TaughtWorkflow?> findByTrigger(String input) async {
    final text = input.toLowerCase().trim();
    if (text.isEmpty) return null;

    final items = await _load();

    for (final item in items) {
      if (!item.isEnabled) continue;
      if (text.contains(item.triggerPhrase.toLowerCase())) {
        return item;
      }
    }

    return null;
  }

  Future<void> addOrUpdate({
    required String id,
    required String title,
    required String triggerPhrase,
    required String description,
    required List<String> steps,
    required String teachingSource,
    bool isEnabled = true,
  }) async {
    final now = DateTime.now();
    final safeTitle = _sanitizeText(title);
    final safeTrigger = _sanitizeText(triggerPhrase);
    final safeDescription = _sanitizeText(description);
    final safeSteps = _sanitizeSteps(steps);

    if (safeTitle.isEmpty || safeTrigger.isEmpty || safeSteps.isEmpty) {
      return;
    }

    final items = await _load();
    bool updated = false;

    final next = items
        .map((item) {
          if (item.id == id) {
            updated = true;
            return item.copyWith(
              title: safeTitle,
              triggerPhrase: safeTrigger,
              description: safeDescription,
              steps: safeSteps,
              teachingSource: _sanitizeText(teachingSource).isEmpty
                  ? 'manual'
                  : _sanitizeText(teachingSource),
              isEnabled: isEnabled,
              updatedAt: now,
            );
          }
          return item;
        })
        .toList(growable: true);

    if (!updated) {
      next.add(
        TaughtWorkflow(
          id: id,
          title: safeTitle,
          triggerPhrase: safeTrigger,
          description: safeDescription,
          steps: safeSteps,
          teachingSource: _sanitizeText(teachingSource).isEmpty
              ? 'manual'
              : _sanitizeText(teachingSource),
          isEnabled: isEnabled,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    await _save(next);
  }

  Future<void> disable(String id) async {
    final items = await _load();
    final now = DateTime.now();

    final next = items
        .map(
          (item) => item.id == id
              ? item.copyWith(isEnabled: false, updatedAt: now)
              : item,
        )
        .toList(growable: false);

    await _save(next);
  }

  Future<void> remove(String id) async {
    final items = await _load();
    final next = items.where((item) => item.id != id).toList(growable: false);
    await _save(next);
  }
}
