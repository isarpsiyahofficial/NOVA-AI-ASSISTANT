// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'status_service.dart';

class StatusStorageService {
  static const String _statusStateKey = 'nova_status_state_v1';

  const StatusStorageService();

  Future<void> save(StatusService statusService) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(statusService.exportState());
    await prefs.setString(_statusStateKey, encoded);
  }

  Future<void> restore(StatusService statusService) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statusStateKey);

    if (raw == null || raw.trim().isEmpty) {
      return;
    }

    try {
      final Map<String, dynamic> map = Map<String, dynamic>.from(
        jsonDecode(raw) as Map,
      );
      statusService.restoreState(map);
    } catch (_) {
      // Sessiz fallback: bozuk state varsa default ile devam.
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_statusStateKey);
  }
}
