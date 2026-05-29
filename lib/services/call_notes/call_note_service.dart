// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CallNoteItem {
  final String id;
  final String callerName;
  final String callerNumber;
  final String content;
  final DateTime createdAt;
  final bool delivered;
  final DateTime? deliveredAt;

  const CallNoteItem({
    required this.id,
    required this.callerName,
    required this.callerNumber,
    required this.content,
    required this.createdAt,
    this.delivered = false,
    this.deliveredAt,
  });

  CallNoteItem copyWith({
    String? id,
    String? callerName,
    String? callerNumber,
    String? content,
    DateTime? createdAt,
    bool? delivered,
    DateTime? deliveredAt,
  }) => CallNoteItem(
    id: id ?? this.id,
    callerName: callerName ?? this.callerName,
    callerNumber: callerNumber ?? this.callerNumber,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
    delivered: delivered ?? this.delivered,
    deliveredAt: deliveredAt ?? this.deliveredAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'callerName': callerName,
    'callerNumber': callerNumber,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'delivered': delivered,
    'deliveredAt': deliveredAt?.toIso8601String(),
  };

  factory CallNoteItem.fromMap(Map<String, dynamic> map) => CallNoteItem(
    id: (map['id'] as String? ?? '').trim(),
    callerName: (map['callerName'] as String? ?? '').trim(),
    callerNumber: (map['callerNumber'] as String? ?? '').trim(),
    content: (map['content'] as String? ?? '').trim(),
    createdAt:
        DateTime.tryParse((map['createdAt'] as String? ?? '').trim()) ??
        DateTime.fromMillisecondsSinceEpoch(0),
    delivered: map['delivered'] as bool? ?? false,
    deliveredAt: DateTime.tryParse(
      (map['deliveredAt'] as String? ?? '').trim(),
    ),
  );
}

class CallNoteService {
  static const String _storageKey = 'nova_call_notes_v1';
  static const Duration _maxRetention = Duration(hours: 48);

  const CallNoteService();

  Future<List<CallNoteItem>> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) return const <CallNoteItem>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <CallNoteItem>[];
      return decoded
          .whereType<Map>()
          .map((e) => CallNoteItem.fromMap(Map<String, dynamic>.from(e)))
          .where((e) => e.id.isNotEmpty && e.content.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <CallNoteItem>[];
    }
  }

  Future<void> _save(List<CallNoteItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(items.map((e) => e.toMap()).toList(growable: false)),
    );
  }

  Future<List<CallNoteItem>> getAll() async {
    await cleanupExpired();
    return _load();
  }

  Future<void> add({
    String callerName = '',
    String callerNumber = '',
    String content = '',
  }) async {
    final cleaned = content.trim();
    if (cleaned.isEmpty) return;
    final items = await _load();
    final item = CallNoteItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      callerName: callerName.trim(),
      callerNumber: callerNumber.trim(),
      content: cleaned,
      createdAt: DateTime.now(),
    );
    await _save(<CallNoteItem>[item, ...items]);
    await cleanupExpired();
  }

  Future<void> remove(String id) async {
    final items = await _load();
    await _save(items.where((e) => e.id != id).toList(growable: false));
  }

  Future<bool> markDelivered(String id) async {
    final target = id.trim();
    if (target.isEmpty) return false;
    final items = await _load();
    bool changed = false;
    final next = items
        .map((e) {
          if (e.id != target) return e;
          changed = true;
          return e.copyWith(delivered: true, deliveredAt: DateTime.now());
        })
        .toList(growable: false);
    if (changed) await _save(next);
    return changed;
  }

  Future<int> removeMatching(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return 0;
    final items = await _load();
    final kept = items
        .where((e) {
          final hay = '${e.callerName} ${e.callerNumber} ${e.content}'
              .toLowerCase();
          return !hay.contains(q);
        })
        .toList(growable: false);
    await _save(kept);
    return items.length - kept.length;
  }

  Future<int> cleanupExpired() async {
    final items = await _load();
    final now = DateTime.now();
    final filtered = items
        .where((e) {
          return now.difference(e.createdAt) < _maxRetention;
        })
        .toList(growable: false);
    if (filtered.length != items.length) await _save(filtered);
    return items.length - filtered.length;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
