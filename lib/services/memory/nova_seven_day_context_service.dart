// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../runtime/nova_identity_runtime_service.dart';

class NovaSevenDayContextEntry {
  final String text;
  final DateTime createdAt;
  final bool repetitive;
  final bool addressedToNova;

  const NovaSevenDayContextEntry({
    required this.text,
    required this.createdAt,
    required this.repetitive,
    required this.addressedToNova,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'repetitive': repetitive,
    'addressedToNova': addressedToNova,
  };

  factory NovaSevenDayContextEntry.fromMap(Map<String, dynamic> map) {
    return NovaSevenDayContextEntry(
      text: (map['text'] as String? ?? '').trim(),
      createdAt:
          DateTime.tryParse((map['createdAt'] as String? ?? '').trim()) ??
          DateTime.now(),
      repetitive: map['repetitive'] as bool? ?? false,
      addressedToNova: map['addressedToNova'] as bool? ?? false,
    );
  }
}

class NovaSevenDayContextService {
  final NovaIdentityRuntimeService identityRuntimeService =
      const NovaIdentityRuntimeService();
  static const String _storageKey = 'nova_seven_day_context_v2';
  static const Duration _retention = Duration(days: 7);
  static const Duration _repetitiveRetention = Duration(days: 3);
  static const int _maxEntryCount = 1400;

  const NovaSevenDayContextService();

  Future<void> remember(String text) async {
    final normalized = _normalize(text);
    if (normalized.isEmpty) return;
    if (!_isLikelyAddressedToNova(normalized) && !_looksMemorable(normalized)) {
      return;
    }

    final items = await _load();
    final now = DateTime.now();
    final repetitive = _looksRepetitive(normalized);

    final duplicate = items.any((entry) {
      if (entry.text.toLowerCase() != normalized.toLowerCase()) return false;
      final window = repetitive
          ? const Duration(hours: 8)
          : const Duration(minutes: 20);
      return now.difference(entry.createdAt) <= window;
    });
    if (duplicate) return;

    items.add(
      NovaSevenDayContextEntry(
        text: normalized,
        createdAt: now,
        repetitive: repetitive,
        addressedToNova: _isLikelyAddressedToNova(normalized),
      ),
    );
    await _save(items);
  }

  Future<void> prune() async {
    final items = await _load();
    await _save(items);
  }

  Future<List<String>> snapshot() async {
    final items = await _load();
    return items.map((e) => e.text).toList(growable: false);
  }

  Future<List<NovaSevenDayContextEntry>> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty)
        return <NovaSevenDayContextEntry>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <NovaSevenDayContextEntry>[];
      final items = decoded
          .whereType<Map>()
          .map(
            (e) =>
                NovaSevenDayContextEntry.fromMap(Map<String, dynamic>.from(e)),
          )
          .where((e) => e.text.isNotEmpty)
          .toList(growable: true);
      return _trim(items);
    } catch (_) {
      return <NovaSevenDayContextEntry>[];
    }
  }

  Future<void> _save(List<NovaSevenDayContextEntry> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmed = _trim(items);
      await prefs.setString(
        _storageKey,
        jsonEncode(trimmed.map((e) => e.toMap()).toList(growable: false)),
      );
    } catch (_) {
      // Sessiz fallback
    }
  }

  List<NovaSevenDayContextEntry> _trim(List<NovaSevenDayContextEntry> items) {
    final now = DateTime.now();
    final cutoff = now.subtract(_retention);
    final repetitiveCutoff = now.subtract(_repetitiveRetention);
    final sorted = List<NovaSevenDayContextEntry>.from(items)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    sorted.removeWhere((entry) => entry.createdAt.isBefore(cutoff));
    sorted.removeWhere(
      (entry) => entry.repetitive && entry.createdAt.isBefore(repetitiveCutoff),
    );
    if (sorted.length > _maxEntryCount) {
      return sorted.sublist(sorted.length - _maxEntryCount);
    }
    return sorted;
  }

  String _normalize(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _looksRepetitive(String text) {
    final compact = text.toLowerCase();
    final words = compact
        .split(' ')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    return compact.length <= 24 || words.length <= 4;
  }

  bool _looksMemorable(String text) {
    final normalized = text.toLowerCase();
    return normalized.contains('hatırla') ||
        normalized.contains('hatirla') ||
        normalized.contains('öğren') ||
        normalized.contains('ogren') ||
        normalized.contains('geçen gün') ||
        normalized.contains('gecen gun') ||
        normalized.contains('çağrı') ||
        normalized.contains('cagri') ||
        normalized.contains('hatırlat') ||
        normalized.contains('hatirlat') ||
        normalized.contains('güç modu') ||
        normalized.contains('guc modu');
  }

  bool _isLikelyAddressedToNova(String text) {
    final markers = <String>{
      ...identityRuntimeService.knownAliases,
      'benim için',
      'benim icin',
      'bana',
      'beni',
      'ara',
      'hatırlat',
      'hatirlat',
      'sohbet edelim',
      'konuşalım',
      'konusalim',
      'yardım et',
      'yardim et',
      'ne düşünüyorsun',
      'ne dusunuyorsun',
      'devral',
      'devret',
    };
    for (final marker in markers) {
      if (text == marker ||
          text.startsWith('$marker ') ||
          text.contains(' $marker ')) {
        return true;
      }
    }
    return false;
  }
}
