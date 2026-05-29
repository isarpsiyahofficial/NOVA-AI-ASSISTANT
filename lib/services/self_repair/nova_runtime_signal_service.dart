// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/runtime/nova_runtime_signal.dart';

class NovaRuntimeSignalService {
  static const String _storageKey = 'nova_runtime_signals_v1';
  static const int _maxSignalCount = 250;

  static final NovaRuntimeSignalService instance =
      NovaRuntimeSignalService._internal();

  NovaRuntimeSignalService._internal();

  Future<List<NovaRuntimeSignal>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw == null || raw.trim().isEmpty) {
        return const <NovaRuntimeSignal>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <NovaRuntimeSignal>[];
      }

      final items = decoded
          .whereType<Map>()
          .map(
            (dynamic e) =>
                NovaRuntimeSignal.fromMap(Map<String, dynamic>.from(e as Map)),
          )
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

    if (normalizedCode.isEmpty || normalizedMessage.isEmpty) {
      return;
    }

    final current = await getAll();
    final now = DateTime.now();
    final healthy = _isHealthySignal(
      level: level,
      code: normalizedCode,
      message: normalizedMessage,
    );

    final base = healthy
        ? current
              .where((e) => !_isSameArea(e, kind, normalizedCode))
              .toList(growable: false)
        : current;

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
      ...base,
    ];

    await _save(_dedupe(next));
  }

  Future<void> clearResolvedOlderThan({required Duration maxAge}) async {
    final current = await getAll();
    final threshold = DateTime.now().subtract(maxAge);

    final next = current
        .where((NovaRuntimeSignal e) => e.createdAt.isAfter(threshold))
        .toList(growable: false);

    await _save(next);
  }

  Future<void> clearByIds(Set<String> signalIds) async {
    final normalized = signalIds
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toSet();

    if (normalized.isEmpty) return;

    final current = await getAll();
    final next = current
        .where((NovaRuntimeSignal e) => !normalized.contains(e.id))
        .toList(growable: false);

    await _save(next);
  }

  Future<void> clearByCodes(Set<String> codes) async {
    final normalized = codes
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toSet();

    if (normalized.isEmpty) return;

    final current = await getAll();
    final next = current
        .where((NovaRuntimeSignal e) => !normalized.contains(e.code))
        .toList(growable: false);

    await _save(next);
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }

  bool _isHealthySignal({
    required NovaRuntimeSignalLevel level,
    required String code,
    required String message,
  }) {
    if (level != NovaRuntimeSignalLevel.info) return false;
    final value = '${code.toLowerCase()} ${message.toLowerCase()}';
    const healthyTokens = <String>[
      'healthy',
      'ready',
      'verified',
      'ok',
      'running',
      'available',
      'success',
      'resolved',
      'çalışıyor',
      'calisiyor',
      'hazır',
      'hazir',
      'doğrulandı',
      'dogrulandi',
      'uygun',
      'aktif',
    ];
    return healthyTokens.any(value.contains);
  }

  bool _isSameArea(
    NovaRuntimeSignal existing,
    NovaRuntimeSignalKind kind,
    String code,
  ) {
    if (existing.kind != kind) return false;
    final a = existing.code.toLowerCase();
    final b = code.toLowerCase();
    String root(String value) {
      final parts = value
          .split('_')
          .where((e) => e.trim().isNotEmpty)
          .toList(growable: false);
      if (parts.length <= 2) return value;
      return parts.take(2).join('_');
    }

    return root(a) == root(b) || a == b;
  }

  List<NovaRuntimeSignal> _dedupe(List<NovaRuntimeSignal> items) {
    final Map<String, NovaRuntimeSignal> latest = <String, NovaRuntimeSignal>{};

    for (final item in items) {
      final key = '${item.kind.name}:${item.code}:${item.message}';
      final existing = latest[key];

      if (existing == null || item.createdAt.isAfter(existing.createdAt)) {
        latest[key] = item;
      }
    }

    final list = latest.values.toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (list.length <= _maxSignalCount) {
      return list;
    }

    return list.take(_maxSignalCount).toList(growable: false);
  }

  Future<void> _save(List<NovaRuntimeSignal> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(
          items.map((NovaRuntimeSignal e) => e.toMap()).toList(growable: false),
        ),
      );
    } catch (_) {}
  }
}
