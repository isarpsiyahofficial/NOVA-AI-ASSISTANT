// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NovaRepairResolutionMemoryEntry {
  final String key;
  final String issueCode;
  final String capabilityId;
  final String resolutionSummary;
  final String decisionLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NovaRepairResolutionMemoryEntry({
    required this.key,
    required this.issueCode,
    required this.capabilityId,
    required this.resolutionSummary,
    required this.decisionLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'key': key,
      'issueCode': issueCode,
      'capabilityId': capabilityId,
      'resolutionSummary': resolutionSummary,
      'decisionLevel': decisionLevel,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NovaRepairResolutionMemoryEntry.fromMap(Map<String, dynamic> map) {
    return NovaRepairResolutionMemoryEntry(
      key: (map['key'] as String? ?? '').trim(),
      issueCode: (map['issueCode'] as String? ?? '').trim(),
      capabilityId: (map['capabilityId'] as String? ?? '').trim(),
      resolutionSummary: (map['resolutionSummary'] as String? ?? '').trim(),
      decisionLevel: (map['decisionLevel'] as String? ?? '').trim(),
      createdAt:
          DateTime.tryParse((map['createdAt'] as String? ?? '').trim()) ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse((map['updatedAt'] as String? ?? '').trim()) ??
          DateTime.now(),
    );
  }
}

class NovaRepairResolutionMemoryService {
  static const String _storageKey = 'nova_repair_resolution_memory_v1';
  static const Duration _keepDuration = Duration(days: 30);

  const NovaRepairResolutionMemoryService();

  Future<List<NovaRepairResolutionMemoryEntry>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) {
        return const <NovaRepairResolutionMemoryEntry>[];
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <NovaRepairResolutionMemoryEntry>[];
      }
      final items = decoded
          .whereType<Map>()
          .map(
            (dynamic e) => NovaRepairResolutionMemoryEntry.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .where((e) => e.key.isNotEmpty)
          .toList(growable: false);
      return _trim(items);
    } catch (_) {
      return const <NovaRepairResolutionMemoryEntry>[];
    }
  }

  Future<NovaRepairResolutionMemoryEntry?> findFor({
    required String issueCode,
    required String capabilityId,
  }) async {
    final normalizedIssue = issueCode.trim().toLowerCase();
    final normalizedCapability = capabilityId.trim().toLowerCase();
    final items = await getAll();
    for (final item in items) {
      if (item.issueCode.toLowerCase() == normalizedIssue ||
          item.capabilityId.toLowerCase() == normalizedCapability) {
        return item;
      }
    }
    return null;
  }

  Future<void> remember({
    required String issueCode,
    required String capabilityId,
    required String resolutionSummary,
    required String decisionLevel,
  }) async {
    final current = await getAll();
    final now = DateTime.now();
    final key =
        '${capabilityId.trim().toLowerCase()}::${issueCode.trim().toLowerCase()}';
    bool updated = false;
    final next = current
        .map((item) {
          if (item.key == key) {
            updated = true;
            return NovaRepairResolutionMemoryEntry(
              key: key,
              issueCode: issueCode.trim(),
              capabilityId: capabilityId.trim(),
              resolutionSummary: resolutionSummary.trim(),
              decisionLevel: decisionLevel.trim(),
              createdAt: item.createdAt,
              updatedAt: now,
            );
          }
          return item;
        })
        .toList(growable: true);

    if (!updated) {
      next.add(
        NovaRepairResolutionMemoryEntry(
          key: key,
          issueCode: issueCode.trim(),
          capabilityId: capabilityId.trim(),
          resolutionSummary: resolutionSummary.trim(),
          decisionLevel: decisionLevel.trim(),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    await _save(next);
  }

  Future<void> _save(List<NovaRepairResolutionMemoryEntry> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(_trim(items).map((e) => e.toMap()).toList(growable: false)),
      );
    } catch (_) {
      // sessiz fallback
    }
  }

  List<NovaRepairResolutionMemoryEntry> _trim(
    List<NovaRepairResolutionMemoryEntry> items,
  ) {
    final now = DateTime.now();
    final trimmed =
        items
            .where((e) => now.difference(e.updatedAt) <= _keepDuration)
            .toList(growable: false)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return trimmed;
  }
}
