// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/self_repair/nova_capability_manifest_entry.dart';

class NovaCapabilityRuntimeRegistryService {
  static const String _storageKey = 'nova_capability_runtime_registry_v1';

  const NovaCapabilityRuntimeRegistryService();

  Future<List<NovaCapabilityManifestEntry>> loadRegisteredCapabilities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) {
        return const <NovaCapabilityManifestEntry>[];
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <NovaCapabilityManifestEntry>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (dynamic e) => NovaCapabilityManifestEntry.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .where((e) => e.capabilityId.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <NovaCapabilityManifestEntry>[];
    }
  }

  Future<void> registerCapabilities(
    List<NovaCapabilityManifestEntry> entries,
  ) async {
    try {
      final merged = <String, NovaCapabilityManifestEntry>{
        for (final item in await loadRegisteredCapabilities())
          item.capabilityId: item,
        for (final item in entries) item.capabilityId: item,
      };
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(merged.values.map((e) => e.toMap()).toList(growable: false)),
      );
    } catch (_) {
      // sessiz fallback
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {
      // sessiz fallback
    }
  }
}
