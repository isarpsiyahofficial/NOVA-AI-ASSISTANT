// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/phone_control/phone_control_state.dart';

class PhoneControlService {
  static const String _storageKey = 'nova_phone_control_state_v1';

  PhoneControlState _state = const PhoneControlState.disabled();

  PhoneControlState get state => _state;
  bool get isEnabled => _state.enabled;

  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) {
        _state = const PhoneControlState.disabled();
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        _state = const PhoneControlState.disabled();
        return;
      }
      _state = PhoneControlState.fromMap(Map<String, dynamic>.from(decoded));
    } catch (_) {
      _state = const PhoneControlState.disabled();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_state.toMap()));
    } catch (_) {}
  }

  Future<PhoneControlState> getState() async {
    await restore();
    return _state;
  }

  Future<void> enable() async {
    _state = PhoneControlState(enabled: true, enabledAt: DateTime.now());
    await _persist();
  }

  Future<void> disable() async {
    _state = const PhoneControlState.disabled();
    await _persist();
  }

  Future<void> markReminderSent() async {
    _state = _state.copyWith(lastReminderAt: DateTime.now());
    await _persist();
  }

  Future<void> extendSession() async {
    _state = _state.copyWith(enabled: true, enabledAt: DateTime.now());
    await _persist();
  }

  Future<void> setPreferredMediaPackage(String packageName) async {
    final allowed = <String>{
      'com.spotify.music',
      'com.google.android.apps.youtube.music',
    };
    final normalized = packageName.trim();
    if (!allowed.contains(normalized)) return;
    _state = _state.copyWith(preferredMediaPackage: normalized);
    await _persist();
  }
}
