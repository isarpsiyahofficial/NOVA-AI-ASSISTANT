// ignore_for_file: unnecessary_cast, avoid_print, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/presence/nova_presence_settings.dart';

enum NovaPresenceState { idle, listening, speaking, sleeping, fullyOff }

class NovaPresenceService extends ChangeNotifier {
  static const String _storageKey = 'nova_presence_settings_v1';

  NovaPresenceSettings _settings = const NovaPresenceSettings();
  NovaPresenceState _state = NovaPresenceState.idle;

  NovaPresenceSettings get settings => _settings;
  NovaPresenceState get state => _state;

  bool get isIndicatorVisible => _settings.indicatorEnabled;
  bool get isSpeaking => _state == NovaPresenceState.speaking;

  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw == null || raw.trim().isEmpty) {
        _settings = const NovaPresenceSettings();
        notifyListeners();
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        _settings = const NovaPresenceSettings();
        notifyListeners();
        return;
      }

      _settings = NovaPresenceSettings.fromMap(
        Map<String, dynamic>.from(decoded as Map),
      );
      notifyListeners();
    } catch (_) {
      _settings = const NovaPresenceSettings();
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_settings.toMap()));
    } catch (_) {
      // Sessiz fallback
    }
  }

  Future<void> setIndicatorEnabled(bool value) async {
    _settings = _settings.copyWith(indicatorEnabled: value);
    notifyListeners();
    await _persist();
  }

  Future<void> setIndicatorSize(double value) async {
    final safeSize = value.clamp(12, 28).toDouble();
    _settings = _settings.copyWith(indicatorSize: safeSize);
    notifyListeners();
    await _persist();
  }

  void setStateSafe(NovaPresenceState next) {
    _state = next;
    notifyListeners();
  }
}
