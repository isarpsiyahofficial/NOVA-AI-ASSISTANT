// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/behavior_control/behavior_keys.dart';
import '../../core/behavior_control/behavior_override.dart';

class BehaviorOverrideService {
  static const String _storageKey = 'nova_behavior_overrides_v2';
  static const int _maxInstructionLength = 500;
  static const int _maxSourceLength = 40;
  static const int _maxOverrideCount = 100;

  const BehaviorOverrideService();

  Future<List<BehaviorOverride>> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw == null || raw.trim().isEmpty) {
        return const <BehaviorOverride>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <BehaviorOverride>[];
      }

      final List<BehaviorOverride> items = decoded
          .whereType<Map>()
          .map(
            (dynamic e) =>
                BehaviorOverride.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .where(
            (BehaviorOverride e) =>
                e.key.isNotEmpty && BehaviorKeys.isValid(e.key),
          )
          .toList(growable: false);

      return _deduplicateAndTrim(items);
    } catch (_) {
      return const <BehaviorOverride>[];
    }
  }

  Future<void> _save(List<BehaviorOverride> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final safeItems = _deduplicateAndTrim(items);
      final encoded = jsonEncode(
        safeItems
            .map((BehaviorOverride e) => e.toMap())
            .toList(growable: false),
      );
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }

  List<BehaviorOverride> _deduplicateAndTrim(List<BehaviorOverride> items) {
    final Map<String, BehaviorOverride> latestByKey =
        <String, BehaviorOverride>{};

    for (final item in items) {
      if (!BehaviorKeys.isValid(item.key)) continue;

      final current = latestByKey[item.key];
      if (current == null || item.updatedAt.isAfter(current.updatedAt)) {
        latestByKey[item.key] = item;
      }
    }

    final sorted = latestByKey.values.toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (sorted.length <= _maxOverrideCount) {
      return sorted;
    }

    return sorted.take(_maxOverrideCount).toList(growable: false);
  }

  String _sanitizeInstruction(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.length <= _maxInstructionLength) {
      return cleaned;
    }
    return cleaned.substring(0, _maxInstructionLength).trim();
  }

  String _sanitizeSource(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'\s+'), '_');
    if (cleaned.isEmpty) return 'user';
    if (cleaned.length <= _maxSourceLength) return cleaned;
    return cleaned.substring(0, _maxSourceLength).trim();
  }

  Future<List<BehaviorOverride>> getAll() async {
    return _load();
  }

  Future<BehaviorOverride?> findByKey(String key) async {
    if (!BehaviorKeys.isValid(key)) return null;

    final items = await _load();
    for (final item in items) {
      if (item.key == key) return item;
    }
    return null;
  }

  Future<void> setOverride({
    required String key,
    required String instruction,
    String source = 'user',
  }) async {
    if (!BehaviorKeys.isValid(key)) return;

    final sanitizedInstruction = _sanitizeInstruction(instruction);
    final sanitizedSource = _sanitizeSource(source);

    if (sanitizedInstruction.isEmpty) return;
    if (_looksLikeSoftwareOrCodingScope(sanitizedInstruction)) return;

    final items = await _load();
    final now = DateTime.now();

    bool updated = false;
    final next = items
        .map((BehaviorOverride item) {
          if (item.key == key) {
            updated = true;
            return item.copyWith(
              instruction: sanitizedInstruction,
              isEnabled: true,
              source: sanitizedSource,
              updatedAt: now,
            );
          }
          return item;
        })
        .toList(growable: true);

    if (!updated) {
      next.add(
        BehaviorOverride(
          key: key,
          instruction: sanitizedInstruction,
          isEnabled: true,
          source: sanitizedSource,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    await _save(next);
  }

  Future<void> disableOverride(String key) async {
    if (!BehaviorKeys.isValid(key)) return;

    final items = await _load();
    final now = DateTime.now();

    final next = items
        .map(
          (BehaviorOverride item) => item.key == key
              ? item.copyWith(isEnabled: false, updatedAt: now)
              : item,
        )
        .toList(growable: false);

    await _save(next);
  }

  Future<void> resetOverrideToDefault(String key) async {
    if (!BehaviorKeys.isValid(key)) return;

    final items = await _load();
    final next = items
        .where((BehaviorOverride item) => item.key != key)
        .toList(growable: false);

    await _save(next);
  }

  Future<void> resetAllToDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }

  Future<String?> resolveInstruction(String key) async {
    if (!BehaviorKeys.isValid(key)) return null;

    final item = await findByKey(key);
    if (item == null) return null;
    if (!item.isEnabled) return null;
    if (!item.hasUsableInstruction) return null;

    return item.instruction.trim();
  }

  Future<String> resolveOrDefault({
    required String key,
    required String defaultInstruction,
  }) async {
    final resolved = await resolveInstruction(key);
    if (resolved == null || resolved.trim().isEmpty) {
      return defaultInstruction;
    }
    return resolved;
  }

  bool _looksLikeSoftwareOrCodingScope(String input) {
    final text = input.trim().toLowerCase();
    if (text.isEmpty) return false;

    const patterns = <String>[
      'kod',
      'kodlama',
      'yazılım',
      'software',
      'flutter',
      'dart',
      'kotlin',
      'java',
      'adb',
      'root',
      'exploit',
      'script',
      'payload',
    ];

    for (final pattern in patterns) {
      if (text.contains(pattern)) return true;
    }

    return false;
  }
}
