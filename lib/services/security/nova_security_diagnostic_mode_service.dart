// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_V38_SECURITY_DIAGNOSTIC_PASSIVE_MODE
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NovaSecurityDiagnosticModeState {
  final bool passiveShields;
  final bool hiddenFromAiRuntime;
  final String updatedBy;
  final String updatedAtIso;

  const NovaSecurityDiagnosticModeState({
    required this.passiveShields,
    required this.hiddenFromAiRuntime,
    required this.updatedBy,
    required this.updatedAtIso,
  });

  const NovaSecurityDiagnosticModeState.defaultPassive()
    : passiveShields = true,
      hiddenFromAiRuntime = true,
      updatedBy = 'default_v38_first_install',
      updatedAtIso = '';

  String get modeCode =>
      passiveShields ? 'passive_observe_only' : 'enforced_blocking';

  Map<String, dynamic> toMap() => <String, dynamic>{
    'passiveShields': passiveShields,
    'hiddenFromAiRuntime': hiddenFromAiRuntime,
    'updatedBy': updatedBy,
    'updatedAtIso': updatedAtIso,
  };

  factory NovaSecurityDiagnosticModeState.fromMap(Map<String, dynamic> map) {
    return NovaSecurityDiagnosticModeState(
      passiveShields: map['passiveShields'] as bool? ?? true,
      hiddenFromAiRuntime: map['hiddenFromAiRuntime'] as bool? ?? true,
      updatedBy: (map['updatedBy'] as String? ?? 'unknown').trim(),
      updatedAtIso: (map['updatedAtIso'] as String? ?? '').trim(),
    );
  }
}

class NovaSecurityDiagnosticModeService {
  static const String storageKey =
      'nova_security_diagnostic_mode_v38_private_ui_only';
  static const String passiveMarker = 'NOVA_SECURITY_SHIELDS_PASSIVE_V38';
  static const Set<String> _allowedUiWriters = <String>{
    'setup_ui',
    'dashboard_ui',
    'manual_owner_ui',
  };

  const NovaSecurityDiagnosticModeService();

  Future<NovaSecurityDiagnosticModeState> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.trim().isEmpty) {
        return const NovaSecurityDiagnosticModeState.defaultPassive();
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map)
        return const NovaSecurityDiagnosticModeState.defaultPassive();
      return NovaSecurityDiagnosticModeState.fromMap(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return const NovaSecurityDiagnosticModeState.defaultPassive();
    }
  }

  Future<bool> isPassive() async => (await load()).passiveShields;

  Future<void> setPassive({
    required bool passive,
    required String updatedBy,
  }) async {
    final writer = updatedBy.trim();
    if (!_allowedUiWriters.contains(writer)) {
      print('NOVA_SECURITY_DIAGNOSTIC_MODE_WRITE_REJECTED writer=$writer');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final next = NovaSecurityDiagnosticModeState(
      passiveShields: passive,
      hiddenFromAiRuntime: true,
      updatedBy: writer,
      updatedAtIso: DateTime.now().toUtc().toIso8601String(),
    );
    await prefs.setString(storageKey, jsonEncode(next.toMap()));
    print(
      'NOVA_SECURITY_DIAGNOSTIC_MODE_UPDATED mode=${next.modeCode} hiddenFromAi=true writer=$writer',
    );
  }

  Future<void> forceDefaultPassiveIfMissing() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      await prefs.setString(
        storageKey,
        jsonEncode(
          const NovaSecurityDiagnosticModeState.defaultPassive().toMap(),
        ),
      );
      print('$passiveMarker default=true hiddenFromAi=true');
    }
  }
}
