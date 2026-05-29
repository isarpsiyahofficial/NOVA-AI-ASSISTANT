// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/automation/automation_workflow.dart';

class AutomationWorkflowService {
  static const String _storageKey = 'nova_automation_workflows_v1';
  static const int _maxWorkflowCount = 200;

  const AutomationWorkflowService();

  Future<List<AutomationWorkflow>> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw == null || raw.trim().isEmpty) {
        return const <AutomationWorkflow>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <AutomationWorkflow>[];
      }

      final items = decoded
          .whereType<Map>()
          .map(
            (e) =>
                AutomationWorkflow.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .where((e) => e.id.isNotEmpty && e.hasUsableTrigger && e.hasCommands)
          .toList(growable: false);

      return _dedupeAndTrim(items);
    } catch (_) {
      return const <AutomationWorkflow>[];
    }
  }

  Future<void> _save(List<AutomationWorkflow> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final safe = _dedupeAndTrim(items);
      await prefs.setString(
        _storageKey,
        jsonEncode(safe.map((e) => e.toMap()).toList(growable: false)),
      );
    } catch (_) {
      // Sessiz fallback
    }
  }

  List<AutomationWorkflow> _dedupeAndTrim(List<AutomationWorkflow> items) {
    final latest = <String, AutomationWorkflow>{};

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

  Future<List<AutomationWorkflow>> getAll() async {
    return _load();
  }

  Future<AutomationWorkflow?> findByTrigger(String input) async {
    final text = input.toLowerCase().trim();
    if (text.isEmpty) return null;

    final items = await _load();
    for (final item in items) {
      if (!item.enabled) continue;
      if (text.contains(item.triggerPhrase.toLowerCase())) {
        return item;
      }
    }
    return null;
  }

  Future<void> addOrUpdate(AutomationWorkflow workflow) async {
    final items = await _load();
    bool updated = false;

    final next = items
        .map((item) {
          if (item.id == workflow.id) {
            updated = true;
            return workflow;
          }
          return item;
        })
        .toList(growable: true);

    if (!updated) {
      next.add(workflow);
    }

    await _save(next);
  }

  Future<void> remove(String id) async {
    final items = await _load();
    final next = items.where((e) => e.id != id).toList(growable: false);
    await _save(next);
  }
}
