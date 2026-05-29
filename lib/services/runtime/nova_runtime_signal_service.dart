import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/runtime/nova_runtime_signal.dart';

class NovaRuntimeSignalService {
  static const String _storageKey = 'nova_runtime_signals_v2';
  static const int _maxSignalCount = 250;

  static final NovaRuntimeSignalService instance =
      NovaRuntimeSignalService._internal();

  NovaRuntimeSignalService._internal();

  Future<List<NovaRuntimeSignal>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) return const <NovaRuntimeSignal>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <NovaRuntimeSignal>[];
      final items = decoded
          .whereType<Map>()
          .map((e) => NovaRuntimeSignal.fromMap(Map<String, dynamic>.from(e)))
          .toList(growable: false);
      return _dedupe(items);
    } catch (_) {
      return const <NovaRuntimeSignal>[];
    }
  }

  Future<void> record({
    required NovaRuntimeSignalKind kind,
    required NovaRuntimeSignalLevel level,
    required String code,
    required String message,
    String technicalDetails = '',
    bool diagnosticCandidate = false,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final normalizedCode = code.trim();
    final normalizedMessage = message.trim();
    if (normalizedCode.isEmpty || normalizedMessage.isEmpty) return;

    final now = DateTime.now();
    final current = await getAll();
    final next = <NovaRuntimeSignal>[
      NovaRuntimeSignal(
        id: '${now.microsecondsSinceEpoch}_$normalizedCode',
        kind: kind,
        level: level,
        code: normalizedCode,
        message: normalizedMessage,
        technicalDetails: technicalDetails.trim(),
        diagnosticCandidate: diagnosticCandidate,
        createdAt: now,
        metadata: metadata,
      ),
      ...current,
    ];
    await _save(_dedupe(next));
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      await prefs.remove('nova_runtime_signals_v1');
    } catch (_) {}
  }

  List<NovaRuntimeSignal> _dedupe(List<NovaRuntimeSignal> items) {
    final latest = <String, NovaRuntimeSignal>{};
    for (final item in items) {
      final key = '${item.kind.name}:${item.code}:${item.message}';
      final existing = latest[key];
      if (existing == null || item.createdAt.isAfter(existing.createdAt)) {
        latest[key] = item;
      }
    }
    final list = latest.values.toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.length <= _maxSignalCount
        ? list
        : list.take(_maxSignalCount).toList(growable: false);
  }

  Future<void> _save(List<NovaRuntimeSignal> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(items.map((e) => e.toMap()).toList(growable: false)),
      );
    } catch (_) {}
  }
}
