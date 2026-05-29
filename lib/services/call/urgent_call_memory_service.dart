// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UrgentCallMemoryItem {
  final String callerNumber;
  final String callerName;
  final String summary;
  final String createdAtIso;
  final String notifiedOwnerAtIso;
  final int repeatCount;

  const UrgentCallMemoryItem({
    required this.callerNumber,
    required this.callerName,
    required this.summary,
    required this.createdAtIso,
    required this.notifiedOwnerAtIso,
    this.repeatCount = 1,
  });

  UrgentCallMemoryItem copyWith({
    String? callerNumber,
    String? callerName,
    String? summary,
    String? createdAtIso,
    String? notifiedOwnerAtIso,
    int? repeatCount,
  }) => UrgentCallMemoryItem(
    callerNumber: callerNumber ?? this.callerNumber,
    callerName: callerName ?? this.callerName,
    summary: summary ?? this.summary,
    createdAtIso: createdAtIso ?? this.createdAtIso,
    notifiedOwnerAtIso: notifiedOwnerAtIso ?? this.notifiedOwnerAtIso,
    repeatCount: repeatCount ?? this.repeatCount,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'callerNumber': callerNumber,
    'callerName': callerName,
    'summary': summary,
    'createdAtIso': createdAtIso,
    'notifiedOwnerAtIso': notifiedOwnerAtIso,
    'repeatCount': repeatCount,
  };

  factory UrgentCallMemoryItem.fromMap(Map<String, dynamic> map) =>
      UrgentCallMemoryItem(
        callerNumber: (map['callerNumber'] as String? ?? '').trim(),
        callerName: (map['callerName'] as String? ?? '').trim(),
        summary: (map['summary'] as String? ?? '').trim(),
        createdAtIso: (map['createdAtIso'] as String? ?? '').trim(),
        notifiedOwnerAtIso: (map['notifiedOwnerAtIso'] as String? ?? '').trim(),
        repeatCount: map['repeatCount'] as int? ?? 1,
      );
}

class UrgentCallMemoryService {
  static const String _storageKey = 'nova_urgent_call_memory_v1';
  static const Duration _retention = Duration(hours: 4);

  const UrgentCallMemoryService();

  Future<List<UrgentCallMemoryItem>> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty)
        return const <UrgentCallMemoryItem>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <UrgentCallMemoryItem>[];
      return decoded
          .whereType<Map>()
          .map(
            (e) => UrgentCallMemoryItem.fromMap(Map<String, dynamic>.from(e)),
          )
          .where((e) => e.callerNumber.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <UrgentCallMemoryItem>[];
    }
  }

  Future<void> _save(List<UrgentCallMemoryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(items.map((e) => e.toMap()).toList(growable: false)),
    );
  }

  Future<void> cleanupExpired() async {
    final items = await _load();
    final now = DateTime.now();
    final kept = items
        .where((e) {
          final created = DateTime.tryParse(e.createdAtIso);
          return created != null && now.difference(created) < _retention;
        })
        .toList(growable: false);
    if (kept.length != items.length) await _save(kept);
  }

  Future<UrgentCallMemoryItem?> getActive(String callerNumber) async {
    await cleanupExpired();
    final key = callerNumber.trim();
    if (key.isEmpty) return null;
    final items = await _load();
    for (final item in items) {
      if (item.callerNumber == key) return item;
    }
    return null;
  }

  Future<void> markUrgent({
    required String callerNumber,
    required String callerName,
    required String summary,
  }) async {
    final key = callerNumber.trim();
    if (key.isEmpty) return;
    final items = await _load();
    final nowIso = DateTime.now().toIso8601String();
    bool updated = false;
    final next = items
        .map((e) {
          if (e.callerNumber != key) return e;
          updated = true;
          return e.copyWith(
            callerName: callerName.trim().isEmpty
                ? e.callerName
                : callerName.trim(),
            summary: summary.trim().isEmpty ? e.summary : summary.trim(),
            notifiedOwnerAtIso: nowIso,
            repeatCount: e.repeatCount + 1,
          );
        })
        .toList(growable: true);
    if (!updated) {
      next.insert(
        0,
        UrgentCallMemoryItem(
          callerNumber: key,
          callerName: callerName.trim(),
          summary: summary.trim(),
          createdAtIso: nowIso,
          notifiedOwnerAtIso: nowIso,
          repeatCount: 1,
        ),
      );
    }
    await _save(next);
  }

  Future<void> clear(String callerNumber) async {
    final key = callerNumber.trim();
    if (key.isEmpty) return;
    final items = await _load();
    await _save(
      items.where((e) => e.callerNumber != key).toList(growable: false),
    );
  }
}
