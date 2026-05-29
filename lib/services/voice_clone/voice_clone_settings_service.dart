// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/voice_clone/voice_clone_settings.dart';

class VoiceCloneSettingsService {
  static const String _storageKey = 'nova_voice_clone_settings_v1';
  final VoiceCloneSettings _defaults;
  static VoiceCloneSettings _cache = const VoiceCloneSettings(
    externalCloneEnabled: true,
    internalCloneEnabled: true,
    expressionLevel: 1,
    emotionStrength: 1,
  );

  const VoiceCloneSettingsService({
    VoiceCloneSettings settings = const VoiceCloneSettings(
      externalCloneEnabled: true,
      internalCloneEnabled: true,
      expressionLevel: 1,
      emotionStrength: 1,
    ),
  }) : _defaults = settings;

  VoiceCloneSettings get settings => _cache;

  Future<VoiceCloneSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) {
        _cache = _defaults;
        return _cache;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        _cache = _defaults;
        return _cache;
      }
      _cache = VoiceCloneSettings.fromMap(Map<String, dynamic>.from(decoded));
      return _cache;
    } catch (_) {
      _cache = _defaults;
      return _cache;
    }
  }

  Future<void> save(VoiceCloneSettings settings) async {
    _cache = settings;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(settings.toMap()));
    } catch (_) {}
  }

  Future<void> reset() async {
    _cache = _defaults;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }
}
