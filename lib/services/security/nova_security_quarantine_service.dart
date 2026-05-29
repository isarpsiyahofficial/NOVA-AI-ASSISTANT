// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'nova_security_diagnostic_mode_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

class NovaSecurityQuarantineState {
  final bool quarantined;
  final int strikeCount;
  final String reason;
  final String lastTriggeredAtIso;

  const NovaSecurityQuarantineState({
    required this.quarantined,
    required this.strikeCount,
    required this.reason,
    required this.lastTriggeredAtIso,
  });

  const NovaSecurityQuarantineState.safe()
    : quarantined = false,
      strikeCount = 0,
      reason = '',
      lastTriggeredAtIso = '';

  NovaSecurityQuarantineState copyWith({
    bool? quarantined,
    int? strikeCount,
    String? reason,
    String? lastTriggeredAtIso,
  }) {
    return NovaSecurityQuarantineState(
      quarantined: quarantined ?? this.quarantined,
      strikeCount: strikeCount ?? this.strikeCount,
      reason: reason ?? this.reason,
      lastTriggeredAtIso: lastTriggeredAtIso ?? this.lastTriggeredAtIso,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'quarantined': quarantined,
      'strikeCount': strikeCount,
      'reason': reason,
      'lastTriggeredAtIso': lastTriggeredAtIso,
    };
  }

  factory NovaSecurityQuarantineState.fromMap(Map<String, dynamic> map) {
    return NovaSecurityQuarantineState(
      quarantined: map['quarantined'] as bool? ?? false,
      strikeCount: map['strikeCount'] as int? ?? 0,
      reason: (map['reason'] as String? ?? '').trim(),
      lastTriggeredAtIso: (map['lastTriggeredAtIso'] as String? ?? '').trim(),
    );
  }
}

class NovaSecurityQuarantineService {
  static const String _storageKey = 'nova_security_quarantine_v1';
  static const int _quarantineThreshold = 5;
  static const Duration _activeQuarantineTtl = Duration(minutes: 30);
  static const Duration _strikeDecayTtl = Duration(hours: 6);

  const NovaSecurityQuarantineService();

  Future<NovaSecurityQuarantineState> load() async {
    if (await const NovaSecurityDiagnosticModeService().isPassive()) {
      return const NovaSecurityQuarantineState.safe();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) {
        return const NovaSecurityQuarantineState.safe();
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const NovaSecurityQuarantineState.safe();
      }

      final state = NovaSecurityQuarantineState.fromMap(
        Map<String, dynamic>.from(decoded as Map),
      );
      final normalized = _decayIfExpired(state);
      if (normalized != state) {
        await _save(normalized);
      }
      return normalized;
    } catch (_) {
      return const NovaSecurityQuarantineState.safe();
    }
  }

  Future<void> _save(NovaSecurityQuarantineState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(state.toMap()));
    } catch (_) {
      // sessiz fallback
    }
  }

  Future<NovaSecurityQuarantineState> registerStrike({
    required String reason,
  }) async {
    if (await const NovaSecurityDiagnosticModeService().isPassive()) {
      print(
        'NOVA_SECURITY_DIAGNOSTIC_PASSIVE_QUARANTINE_STRIKE_IGNORED reason=$reason',
      );
      return const NovaSecurityQuarantineState.safe();
    }
    final current = await load();
    final nextCount = current.strikeCount + 1;
    final now = DateTime.now().toIso8601String();

    final next = current.copyWith(
      strikeCount: nextCount,
      reason: reason.trim(),
      lastTriggeredAtIso: now,
      quarantined: nextCount >= _quarantineThreshold,
    );

    await _save(next);
    return next;
  }

  Future<void> reset() async {
    await _save(const NovaSecurityQuarantineState.safe());
  }

  Future<bool> isQuarantined() async {
    if (await const NovaSecurityDiagnosticModeService().isPassive())
      return false;
    final state = await load();
    return state.quarantined;
  }

  NovaSecurityQuarantineState _decayIfExpired(
    NovaSecurityQuarantineState state,
  ) {
    final at = DateTime.tryParse(state.lastTriggeredAtIso);
    if (at == null) return state;
    final age = DateTime.now().difference(at);
    if (state.quarantined && age >= _activeQuarantineTtl) {
      return const NovaSecurityQuarantineState.safe();
    }
    if (!state.quarantined && state.strikeCount > 0 && age >= _strikeDecayTtl) {
      return const NovaSecurityQuarantineState.safe();
    }
    return state;
  }
}
