// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NovaBehaviorObservabilityService {
  static const String _storageKey = 'nova_behavior_observability_log_v1';
  static const int _maxEntries = 40;

  const NovaBehaviorObservabilityService();

  Future<void> recordTurn({
    required String prompt,
    required String reply,
    required String route,
    required String promptKind,
    required double ownerConfidence,
    required String ownerSignal,
    required List<String> memorySources,
    required String personaMode,
    required String personaTone,
    required String responseSource,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    final entry = <String, dynamic>{
      'createdAt': DateTime.now().toIso8601String(),
      'prompt': prompt.trim(),
      'reply': reply.trim(),
      'route': route.trim(),
      'promptKind': promptKind.trim(),
      'ownerConfidence': ownerConfidence.clamp(0.0, 1.0),
      'ownerSignal': ownerSignal.trim(),
      'memorySources': memorySources
          .where((e) => e.trim().isNotEmpty)
          .toList(growable: false),
      'personaMode': personaMode.trim(),
      'personaTone': personaTone.trim(),
      'responseSource': responseSource.trim(),
      ...extra,
    };

    debugPrint(
      '[NovaBehavior] '
      'kind=${entry['promptKind']} '
      'owner=${(entry['ownerConfidence'] as double).toStringAsFixed(2)} '
      'signal=${entry['ownerSignal']} '
      'memory=${(entry['memorySources'] as List).join('|')} '
      'persona=${entry['personaMode']} '
      'route=${entry['route']} '
      'source=${entry['responseSource']} '
      'social=${entry['socialMode'] ?? ''} '
      'composite=${entry['compositeIntent'] ?? false}',
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey) ?? '[]';
      final decoded = jsonDecode(raw);
      final current = <Map<String, dynamic>>[];
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            current.add(Map<String, dynamic>.from(item));
          }
        }
      }
      current.add(entry);
      final trimmed = current.length > _maxEntries
          ? current.sublist(current.length - _maxEntries)
          : current;
      await prefs.setString(_storageKey, jsonEncode(trimmed));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> loadRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey) ?? '[]';
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <Map<String, dynamic>>[];
      final items = <Map<String, dynamic>>[];
      for (final item in decoded) {
        if (item is Map) {
          items.add(Map<String, dynamic>.from(item));
        }
      }
      return items;
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }
}
