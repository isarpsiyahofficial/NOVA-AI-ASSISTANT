// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/self_repair/nova_repair_trace_entry.dart';

class NovaRepairTraceService {
  static const String _storageKey = 'nova_repair_trace_v1';

  const NovaRepairTraceService();

  Future<List<NovaRepairTraceEntry>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) {
        return const <NovaRepairTraceEntry>[];
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <NovaRepairTraceEntry>[];
      }
      final items =
          decoded
              .whereType<Map>()
              .map(
                (e) =>
                    NovaRepairTraceEntry.fromMap(Map<String, dynamic>.from(e)),
              )
              .toList(growable: false)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return _trim(items);
    } catch (_) {
      return const <NovaRepairTraceEntry>[];
    }
  }

  Future<void> add({
    required String issueCode,
    required String solutionSummary,
    required String decisionLevel,
  }) async {
    final items = await getAll();
    final now = DateTime.now();
    final entry = NovaRepairTraceEntry(
      id: now.microsecondsSinceEpoch.toString(),
      issueCode: issueCode.trim(),
      solutionSummary: solutionSummary.trim(),
      decisionLevel: decisionLevel.trim(),
      createdAt: now,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(
        _trim(<NovaRepairTraceEntry>[
          entry,
          ...items,
        ]).map((e) => e.toMap()).toList(growable: false),
      ),
    );
  }

  Future<void> cleanupRetention() async {
    final items = await getAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_trim(items).map((e) => e.toMap()).toList(growable: false)),
    );
  }

  List<NovaRepairTraceEntry> _trim(List<NovaRepairTraceEntry> items) {
    final now = DateTime.now();
    return items
        .where((e) {
          final age = now.difference(e.createdAt);
          final lowered = e.decisionLevel.trim().toLowerCase();
          final resolved =
              lowered == 'self_healed' || lowered == 'owner_patch_applied';
          if (resolved) {
            return age.inHours < 24;
          }
          return age.inDays < 7;
        })
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
