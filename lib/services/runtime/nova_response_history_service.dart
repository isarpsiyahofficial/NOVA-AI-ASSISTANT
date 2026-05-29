// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NovaResponseHistoryItem {
  final String text;
  final int timestampMs;
  final String mode;
  final double similarityHint;

  const NovaResponseHistoryItem({
    required this.text,
    required this.timestampMs,
    required this.mode,
    required this.similarityHint,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'text': text,
    'timestampMs': timestampMs,
    'mode': mode,
    'similarityHint': similarityHint,
  };

  factory NovaResponseHistoryItem.fromJson(Map<String, dynamic> json) {
    return NovaResponseHistoryItem(
      text: (json['text'] as String? ?? '').trim(),
      timestampMs: (json['timestampMs'] as num?)?.toInt() ?? 0,
      mode: (json['mode'] as String? ?? 'default').trim(),
      similarityHint: (json['similarityHint'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class NovaResponseHistoryService {
  static const String _storageKey = 'nova_recent_response_history_v2';
  static const int _maxItems = 24;

  const NovaResponseHistoryService();

  Future<List<String>> loadRecent() async {
    final rich = await loadRecentItems();
    return rich.map((e) => e.text).toList(growable: false);
  }

  Future<List<NovaResponseHistoryItem>> loadRecentItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty)
        return const <NovaResponseHistoryItem>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <NovaResponseHistoryItem>[];
      return decoded
          .whereType<Map>()
          .map(
            (e) =>
                NovaResponseHistoryItem.fromJson(Map<String, dynamic>.from(e)),
          )
          .where((e) => e.text.isNotEmpty)
          .take(_maxItems)
          .toList(growable: false);
    } catch (_) {
      return const <NovaResponseHistoryItem>[];
    }
  }

  Future<void> remember(String text, {String mode = 'default'}) async {
    final normalized = text.trim().toLowerCase();
    if (normalized.isEmpty) return;
    final existing = await loadRecentItems();
    final nextItem = NovaResponseHistoryItem(
      text: normalized,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      mode: mode,
      similarityHint: _roughSimilarityHint(normalized),
    );
    final next = <NovaResponseHistoryItem>[
      nextItem,
      ...existing.where((e) => e.text != normalized),
    ].take(_maxItems).toList(growable: false);
    await _save(next);
  }

  Future<List<String>> findNearMatches(
    String text, {
    double threshold = 0.72,
  }) async {
    final normalized = text.trim().toLowerCase();
    if (normalized.isEmpty) return const <String>[];
    final items = await loadRecentItems();
    final matches = <String>[];
    for (final item in items) {
      final score = _jaccard(normalized, item.text);
      if (score >= threshold) {
        matches.add(item.text);
      }
    }
    return matches.toSet().toList(growable: false);
  }

  Future<void> prune({int maxAgeHours = 72}) async {
    final items = await loadRecentItems();
    final cutoff = DateTime.now()
        .subtract(Duration(hours: maxAgeHours))
        .millisecondsSinceEpoch;
    final kept = items
        .where((e) => e.timestampMs >= cutoff)
        .take(_maxItems)
        .toList(growable: false);
    await _save(kept);
  }

  Future<void> _save(List<NovaResponseHistoryItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(items.map((e) => e.toJson()).toList(growable: false)),
      );
    } catch (_) {}
  }

  double _roughSimilarityHint(String text) {
    final words = text
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return 0.0;
    final unique = words.toSet().length;
    return 1.0 - (unique / words.length).clamp(0.0, 1.0);
  }

  double _jaccard(String a, String b) {
    final sa = a.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toSet();
    final sb = b.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toSet();
    if (sa.isEmpty || sb.isEmpty) return 0.0;
    final intersection = sa.intersection(sb).length.toDouble();
    final union = sa.union(sb).length.toDouble();
    return union == 0 ? 0.0 : intersection / union;
  }
}
