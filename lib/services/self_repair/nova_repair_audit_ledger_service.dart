// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// GEMMA95952_SAFE_SELF_REPAIR_KERNEL
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/self_repair/nova_repair_audit_entry.dart';
import '../../core/self_repair/nova_repair_manifest.dart';

class NovaRepairAuditLedgerService {
  static const String _storageKey = 'nova_repair_audit_ledger_v1';
  static const int _maxEntries = 180;

  const NovaRepairAuditLedgerService();

  Future<List<NovaRepairAuditEntry>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) {
        return const <NovaRepairAuditEntry>[];
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <NovaRepairAuditEntry>[];
      }
      final items =
          decoded
              .whereType<Map>()
              .map(
                (e) =>
                    NovaRepairAuditEntry.fromMap(Map<String, dynamic>.from(e)),
              )
              .toList(growable: false)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items.take(_maxEntries).toList(growable: false);
    } catch (_) {
      return const <NovaRepairAuditEntry>[];
    }
  }

  Future<void> record({
    required String category,
    required String title,
    required String detail,
    NovaRepairManifest? manifest,
    String securityDecision = '',
    String validationResult = '',
    bool aiAuthored = false,
    bool userApproved = false,
  }) async {
    final now = DateTime.now();
    final entry = NovaRepairAuditEntry(
      id: now.microsecondsSinceEpoch.toString(),
      category: _redact(category),
      title: _redact(title),
      detail: _redact(detail),
      manifestId: _redact(manifest?.id ?? ''),
      targetPolicy: _redact(manifest?.targetPolicy.key ?? ''),
      riskLevel: _redact(manifest?.riskLevel.key ?? ''),
      oldValue: _redact(manifest?.oldValue ?? ''),
      newValue: _redact(manifest?.newValue ?? ''),
      securityDecision: _redact(securityDecision),
      validationResult: _redact(validationResult),
      rollbackKey: _redact(manifest?.rollbackKey ?? ''),
      aiAuthored: aiAuthored,
      userApproved: userApproved,
      createdAt: now,
    );
    final current = await getAll();
    final next = <NovaRepairAuditEntry>[
      entry,
      ...current,
    ].take(_maxEntries).toList(growable: false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(next.map((e) => e.toMap()).toList(growable: false)),
      );
    } catch (_) {}
  }

  String _redact(String raw) {
    var text = raw.trim();
    if (text.length > 1200) {
      text = '${text.substring(0, 1200)} [kısaltıldı]';
    }
    final lowered = text.toLowerCase();
    const blockedDetails = <String>[
      'token=',
      'api_key',
      'secret',
      'owner_secret',
      'password=',
      'private_key',
      'exploit',
      'bypass detail',
    ];
    if (blockedDetails.any(lowered.contains)) {
      return '[güvenlik nedeniyle maskelendi]';
    }
    return text;
  }
}
