// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/phone_control/phone_control_task.dart';

class PhoneControlTaskService {
  static const String _storageKey = 'nova_phone_control_tasks_v1';

  const PhoneControlTaskService();

  Future<List<PhoneControlTask>> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) return const <PhoneControlTask>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <PhoneControlTask>[];
      return decoded
          .whereType<Map>()
          .map((e) => PhoneControlTask.fromMap(Map<String, dynamic>.from(e)))
          .where((e) => e.id.isNotEmpty && e.title.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <PhoneControlTask>[];
    }
  }

  Future<void> _save(List<PhoneControlTask> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(items.map((e) => e.toMap()).toList(growable: false)),
      );
    } catch (_) {}
  }

  Future<List<PhoneControlTask>> getAll() async => _load();

  Future<void> addTask({
    required String title,
    required String description,
    required List<String> steps,
  }) async {
    final items = await _load();
    final now = DateTime.now();
    final task = PhoneControlTask(
      id: now.microsecondsSinceEpoch.toString(),
      title: title.trim(),
      description: description.trim(),
      steps: steps
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false),
      status: PhoneControlTaskStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    await _save(<PhoneControlTask>[task, ...items]);
  }

  Future<void> removeTask(String id) async {
    final items = await _load();
    await _save(items.where((e) => e.id != id).toList(growable: false));
  }

  Future<void> updateStatus(String id, PhoneControlTaskStatus status) async {
    final items = await _load();
    final updated = items
        .map(
          (e) => e.id == id
              ? e.copyWith(status: status, updatedAt: DateTime.now())
              : e,
        )
        .toList(growable: false);
    await _save(updated);
  }
}
