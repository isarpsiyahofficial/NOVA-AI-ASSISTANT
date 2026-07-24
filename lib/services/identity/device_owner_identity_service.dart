// NOVA_DEVICE_OWNER_IDENTITY_V2_REAL_VOICEPRINT_ONLY
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
      if (raw == null || raw.trim().isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final profile = DeviceOwnerProfile.fromMap(
        Map<String, dynamic>.from(decoded),
      );
      if (!isVerifiedVoiceprintId(profile.ownerVoiceId)) {
        await prefs.remove(_storageKey);
        return null;
      }
      return profile;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveOwner(DeviceOwnerProfile owner) async {
    if (!isVerifiedVoiceprintId(owner.ownerVoiceId)) {
      throw StateError(
        'Sahip profili yalnız gerçek TitaNet voiceprint kimliğiyle kaydedilebilir.',
      );
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(owner.toMap()));
  }

  Future<void> registerOwner({
    required String ownerName,
    required String ownerVoiceId,
    String welcomeBackText = 'Hoş geldin patron.',
    bool proactiveChatAllowed = true,
  }) async {
    final normalizedVoiceId = ownerVoiceId.trim();
    if (!isVerifiedVoiceprintId(normalizedVoiceId)) {
      throw StateError(
        'Geçersiz sahip ses kimliği. Kurulum TitaNet kayıt ve bağımsız doğrulama adımlarından geçmelidir.',
      );
    }
    final profile = DeviceOwnerProfile(
      ownerName: ownerName.trim(),
      ownerVoiceId: normalizedVoiceId,
      welcomeBackText: welcomeBackText.trim().isEmpty
          ? 'Hoş geldin patron.'
          : welcomeBackText.trim(),
      proactiveChatAllowed: proactiveChatAllowed,
      configuredAt: DateTime.now(),
    );
    await saveOwner(profile);
  }

  bool isVerifiedVoiceprintId(String rawVoiceId) {
    final value = rawVoiceId.trim();
    if (!value.startsWith('owner_')) return false;
    if (value.startsWith('owner_manual_') ||
        value.startsWith('nova_manual_owner_')) {
      return false;
    }
    final suffix = value.substring('owner_'.length);
    return suffix.length >= 8 && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(suffix);
  }

  Future<void> clearOwner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }
}
