// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_API_FIRST_SECURE_SETTINGS_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/nova_secure_token_store.dart';
import '../../core/settings/nova_settings.dart';

class NovaSettingsService {
  static const _k = 'nova_settings_v2';
  const NovaSettingsService();

  Future<NovaSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_k);
      final base = raw == null || raw.trim().isEmpty
          ? const NovaSettings()
          : NovaSettings.fromMap(
              Map<String, dynamic>.from(jsonDecode(raw) as Map),
            );
      final secureKey = await const NovaSecureTokenStore().read(
        base.activeAiProvider,
      );
      return base.copyWith(
        apiKey: secureKey.trim().isNotEmpty ? secureKey : base.apiKey,
      );
    } catch (_) {
      return const NovaSettings();
    }
  }

  Future<void> save(NovaSettings settings) async {
    await const NovaSecureTokenStore().write(
      settings.activeAiProvider,
      settings.apiKey,
    );
    final prefs = await SharedPreferences.getInstance();
    final safeSettingsMap = <String, dynamic>{
      ...settings.toMap(),
      'apiKey': '',
    };
    await prefs.setString(_k, jsonEncode(safeSettingsMap));
  }
}
