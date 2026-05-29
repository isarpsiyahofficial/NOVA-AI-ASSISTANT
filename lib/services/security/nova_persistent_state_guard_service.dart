// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/security/nova_security_state.dart';

class NovaPersistentStateGuardService {
  static const String _stateKey = 'nova_security_state_v1';
  static const String _shadowStateKey = 'nova_security_state_shadow_v1';
  static const String _counterKey = 'nova_security_monotonic_counter_v1';

  const NovaPersistentStateGuardService();

  Future<NovaSecurityState> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String? primaryRaw = prefs.getString(_stateKey);
      final String? shadowRaw = prefs.getString(_shadowStateKey);

      final primary = _decode(primaryRaw);
      final shadow = _decode(shadowRaw);

      if (primary == null && shadow == null) {
        return NovaSecurityState.initial();
      }

      if (primary != null && shadow == null) {
        await save(primary);
        return primary;
      }

      if (primary == null && shadow != null) {
        await save(shadow);
        return shadow;
      }

      if (primary != null && shadow != null) {
        final chosen = _chooseSafer(primary, shadow);
        await save(chosen);
        return chosen;
      }

      return NovaSecurityState.initial();
    } catch (_) {
      return NovaSecurityState.initial();
    }
  }

  Future<void> save(NovaSecurityState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(state.toMap());

      await prefs.setString(_stateKey, encoded);
      await prefs.setString(_shadowStateKey, encoded);

      final int currentCounter = prefs.getInt(_counterKey) ?? 0;
      await prefs.setInt(_counterKey, currentCounter + 1);
    } catch (_) {
      // Sessiz fallback
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_stateKey);
      await prefs.remove(_shadowStateKey);
      await prefs.remove(_counterKey);
    } catch (_) {
      // Sessiz fallback
    }
  }

  NovaSecurityState? _decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return NovaSecurityState.fromMap(
        Map<String, dynamic>.from(decoded as Map),
      );
    } catch (_) {
      return null;
    }
  }

  NovaSecurityState _chooseSafer(NovaSecurityState a, NovaSecurityState b) {
    if (a.killStage.index > b.killStage.index) {
      return a;
    }

    if (b.killStage.index > a.killStage.index) {
      return b;
    }

    if (a.escalationScore > b.escalationScore) {
      return a;
    }

    if (b.escalationScore > a.escalationScore) {
      return b;
    }

    return a.updatedAt.isAfter(b.updatedAt) ? a : b;
  }
}
