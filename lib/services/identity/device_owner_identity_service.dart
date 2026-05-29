// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/identity/device_owner_profile.dart';

class DeviceOwnerIdentityService {
  static const String _storageKey = 'nova_device_owner_profile_v1';

  const DeviceOwnerIdentityService();

  Future<DeviceOwnerProfile?> loadOwner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw == null || raw.trim().isEmpty) {
        return null;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }

      return DeviceOwnerProfile.fromMap(
        Map<String, dynamic>.from(decoded as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveOwner(DeviceOwnerProfile owner) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(owner.toMap()));
    } catch (_) {
      // Sessiz fallback
    }
  }

  Future<void> registerOwner({
    required String ownerName,
    required String ownerVoiceId,
    String welcomeBackText = 'Hoş geldin patron.',
    bool proactiveChatAllowed = true,
  }) async {
    final profile = DeviceOwnerProfile(
      ownerName: ownerName.trim(),
      ownerVoiceId: ownerVoiceId.trim(),
      welcomeBackText: welcomeBackText.trim().isEmpty
          ? 'Hoş geldin patron.'
          : welcomeBackText.trim(),
      proactiveChatAllowed: proactiveChatAllowed,
      configuredAt: DateTime.now(),
    );

    await saveOwner(profile);
  }

  Future<void> clearOwner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {
      // Sessiz fallback
    }
  }
}
