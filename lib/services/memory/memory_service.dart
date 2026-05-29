// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/memory/memory_item.dart';
import '../../core/memory/memory_types.dart';

class MemoryService {
  static const String _storageKey = 'nova_memory_items_v1';

  const MemoryService();

  Future<List<MemoryItem>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) return const <MemoryItem>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <MemoryItem>[];
      final items = decoded
          .whereType<Map>()
          .map((e) => MemoryItem.fromMap(Map<String, dynamic>.from(e)))
          .where((e) => e.id.isNotEmpty && e.content.isNotEmpty)
          .toList(growable: true);
      final active = items.where((e) => !e.isExpired).toList(growable: false);
      final trusted = active
          .where((e) => _canUseInPrompt(e.source) && e.trustScore > 0)
          .toList(growable: false);
      if (active.length != items.length) {
        await _save(active);
      }
      return trusted;
    } catch (_) {
      return const <MemoryItem>[];
    }
  }

  Future<void> _save(List<MemoryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(items.map((e) => e.toMap()).toList(growable: false)),
    );
  }

  Future<void> add({
    required MemoryType type,
    required String content,
    MemorySource source = MemorySource.userInput,
    double trustScore = 1.0,
    Map<String, dynamic> metadata = const <String, dynamic>{},
    Duration? ttl,
  }) async {
    final cleaned = content.trim();
    if (cleaned.isEmpty) return;
    if (!_canPersistLongTerm(source)) return;
    final items = await getAll();
    final now = DateTime.now();
    final next = <MemoryItem>[
      MemoryItem(
        id: now.microsecondsSinceEpoch.toString(),
        type: type,
        source: source,
        content: cleaned,
        trustScore: trustScore.clamp(0.0, 1.0).toDouble(),
        metadata: metadata,
        createdAt: now,
        expiresAt: ttl == null ? null : now.add(ttl),
      ),
      ...items,
    ];
    await _save(next);
  }

  Future<void> addTemporary48Hours(String content) async {
    await add(
      type: MemoryType.temporary,
      content: content,
      source: MemorySource.userInput,
      ttl: const Duration(hours: 48),
    );
  }

  bool _canPersistLongTerm(MemorySource source) {
    return source == MemorySource.userInput ||
        source == MemorySource.aiCleanResponse ||
        source == MemorySource.actionResult;
  }

  bool _canUseInPrompt(MemorySource source) {
    return _canPersistLongTerm(source);
  }

  Future<int> deleteById(String id) async {
    final target = id.trim();
    if (target.isEmpty) return 0;
    final items = await getAll();
    final kept = items.where((e) => e.id != target).toList(growable: false);
    await _save(kept);
    return items.length - kept.length;
  }

  Future<void> deleteAllPermanent() async {
    final items = await getAll();
    final kept = items
        .where((e) => e.type != MemoryType.permanent)
        .toList(growable: false);
    await _save(kept);
  }

  Future<int> deleteMatching(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return 0;
    final items = await getAll();
    final kept = items
        .where((e) => !e.content.toLowerCase().contains(q))
        .toList(growable: false);
    await _save(kept);
    return items.length - kept.length;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
