// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/self_repair/nova_self_repair_settings.dart';

class NovaSelfRepairSettingsService {
  static const String _storageKey = 'nova_self_repair_settings_v2';

  const NovaSelfRepairSettingsService();

  Future<NovaSelfRepairSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) {
        return const NovaSelfRepairSettings();
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const NovaSelfRepairSettings();
      }
      return NovaSelfRepairSettings.fromMap(
        Map<String, dynamic>.from(decoded as Map),
      );
    } catch (_) {
      return const NovaSelfRepairSettings();
    }
  }

  Future<void> save(NovaSelfRepairSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(settings.toMap()));
    } catch (_) {}
  }
}
