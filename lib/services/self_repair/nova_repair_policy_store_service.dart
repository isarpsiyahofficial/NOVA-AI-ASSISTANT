// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals_to_create_immutables
// GEMMA95952_SELF_REPAIR_SAFE_KERNEL_V4
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/self_repair/nova_repair_manifest.dart';

class NovaRepairPolicySnapshot {
  final String targetPolicy;
  final String activeValue;
  final String previousValue;
  final String rollbackKey;
  final String manifestId;
  final DateTime updatedAt;

  const NovaRepairPolicySnapshot({
    required this.targetPolicy,
    required this.activeValue,
    required this.previousValue,
    required this.rollbackKey,
    required this.manifestId,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'targetPolicy': targetPolicy,
    'activeValue': activeValue,
    'previousValue': previousValue,
    'rollbackKey': rollbackKey,
    'manifestId': manifestId,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory NovaRepairPolicySnapshot.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return NovaRepairPolicySnapshot(
      targetPolicy: (map['targetPolicy'] as String? ?? '').trim(),
      activeValue: (map['activeValue'] as String? ?? '').trim(),
      previousValue: (map['previousValue'] as String? ?? '').trim(),
      rollbackKey: (map['rollbackKey'] as String? ?? '').trim(),
      manifestId: (map['manifestId'] as String? ?? '').trim(),
      updatedAt:
          DateTime.tryParse((map['updatedAt'] as String? ?? '').trim()) ?? now,
    );
  }
}

class NovaRepairPolicyStoreService {
  static const String _storageKey = 'nova_safe_repair_policy_store_v4';
  static const String rejectedSecurityValue =
      '[rejected_for_security_redaction]';

  const NovaRepairPolicyStoreService();

  Future<Map<String, NovaRepairPolicySnapshot>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) {
        return const <String, NovaRepairPolicySnapshot>{};
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const <String, NovaRepairPolicySnapshot>{};
      }
      final result = <String, NovaRepairPolicySnapshot>{};
      for (final entry in decoded.entries) {
        final key = entry.key.toString().trim();
        final value = entry.value;
        if (key.isEmpty || value is! Map) continue;
        if (!_isAllowedKey(key)) continue;
        result[key] = NovaRepairPolicySnapshot.fromMap(
          Map<String, dynamic>.from(value),
        );
      }
      return result;
    } catch (_) {
      return const <String, NovaRepairPolicySnapshot>{};
    }
  }

  Future<NovaRepairPolicySnapshot?> getPolicy(
    NovaRepairTargetPolicy target,
  ) async {
    final all = await loadAll();
    return all[target.key];
  }

  Future<bool> isPolicyActive(
    NovaRepairTargetPolicy target, {
    String containsValue = '',
  }) async {
    final snapshot = await getPolicy(target);
    if (snapshot == null) return false;
    final active = snapshot.activeValue.trim().toLowerCase();
    if (active.isEmpty || active == rejectedSecurityValue) return false;
    final expected = containsValue.trim().toLowerCase();
    return expected.isEmpty || active.contains(expected);
  }

  Future<NovaRepairPolicySnapshot> applyManifest(
    NovaRepairManifest manifest,
  ) async {
    final target = manifest.targetPolicy;
    if (!_isAllowedTarget(target)) {
      throw StateError('Repair policy target allowlist dışında: ${target.key}');
    }

    final sanitizedNewValue = _sanitizePolicyValue(manifest.newValue);
    final sanitizedOldValue = _sanitizePolicyValue(manifest.oldValue);
    final sanitizedRollbackKey = _sanitizePolicyValue(manifest.rollbackKey);
    final sanitizedManifestId = _sanitizePolicyValue(manifest.id);
    if (sanitizedNewValue == rejectedSecurityValue ||
        sanitizedOldValue == rejectedSecurityValue ||
        sanitizedRollbackKey == rejectedSecurityValue ||
        sanitizedManifestId == rejectedSecurityValue) {
      throw StateError('Repair policy değeri güvenlik nedeniyle reddedildi.');
    }

    final all = Map<String, NovaRepairPolicySnapshot>.from(await loadAll());
    final previous = all[target.key];
    final snapshot = NovaRepairPolicySnapshot(
      targetPolicy: target.key,
      activeValue: sanitizedNewValue,
      previousValue: previous?.activeValue ?? sanitizedOldValue,
      rollbackKey: sanitizedRollbackKey,
      manifestId: sanitizedManifestId,
      updatedAt: DateTime.now(),
    );
    all[target.key] = snapshot;
    await _save(all);
    return snapshot;
  }

  Future<bool> rollback(NovaRepairManifest manifest) async {
    final target = manifest.targetPolicy;
    if (!_isAllowedTarget(target)) return false;
    final all = Map<String, NovaRepairPolicySnapshot>.from(await loadAll());
    final current = all[target.key];
    if (current == null) return false;
    all[target.key] = NovaRepairPolicySnapshot(
      targetPolicy: target.key,
      activeValue: current.previousValue,
      previousValue: current.activeValue,
      rollbackKey: current.rollbackKey,
      manifestId: current.manifestId,
      updatedAt: DateTime.now(),
    );
    await _save(all);
    return true;
  }

  Future<void> _save(Map<String, NovaRepairPolicySnapshot> values) async {
    final safe = <String, dynamic>{};
    for (final entry in values.entries) {
      if (!_isAllowedKey(entry.key)) continue;
      safe[entry.key] = entry.value.toMap();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(safe));
  }

  bool _isAllowedTarget(NovaRepairTargetPolicy target) {
    return target != NovaRepairTargetPolicy.none &&
        (target.isGreen || target.isYellow);
  }

  bool _isAllowedKey(String key) {
    return NovaRepairTargetPolicyX.fromKey(key) != NovaRepairTargetPolicy.none;
  }

  String _sanitizePolicyValue(String raw) {
    final value = raw.trim();
    final lowered = value.toLowerCase();
    const forbidden = <String>[
      'android/',
      'android\\',
      'androidmanifest',
      'manifest.xml',
      'kotlin',
      '.kt',
      '.java',
      'native',
      'methodchannel',
      'permission',
      'assets/',
      'assets\\',
      'model_loader',
      'model loader',
      'lib/security',
      'security shield',
      'security_shield',
      'security root',
      'security_root',
      'disable_security',
      'owner root',
      'owner_root',
      'new file',
      'create file',
      'delete file',
      'rewrite file',
      'full rewrite',
      'script',
      'process.run',
      'process.start',
      'shell',
      'python',
      'dart:io',
      'file(',
      'directory(',
      'writeas',
      'exec',
      'download code',
      'external code',
      'targetpath',
      'path=',
      'patch ',
      'eval(',
      'spawn',
      'chmod',
      'lib/services/security',
      'lib/core/security',
    ];
    if (forbidden.any(lowered.contains)) {
      return rejectedSecurityValue;
    }
    return value.length > 400 ? '${value.substring(0, 400)} [trimmed]' : value;
  }
}
