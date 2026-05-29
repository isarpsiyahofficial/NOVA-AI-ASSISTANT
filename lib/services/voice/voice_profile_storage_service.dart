// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/voice/voice_profile.dart';
import '../../core/voice/voice_profile_service.dart';

class VoiceProfileStorageService {
  static const String _profilesKey = 'nova_voice_profiles_v1';

  final VoiceProfileService voiceProfileService;

  const VoiceProfileStorageService({required this.voiceProfileService});

  Future<List<VoiceProfile>> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profilesKey);

    if (raw == null || raw.trim().isEmpty) {
      return _defaultProfiles;
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final profiles = decoded
          .map(
            (dynamic e) =>
                VoiceProfile.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList(growable: false);

      if (profiles.isEmpty) {
        return _defaultProfiles;
      }

      return profiles;
    } catch (_) {
      return _defaultProfiles;
    }
  }

  Future<void> saveProfiles(List<VoiceProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      profiles.map((VoiceProfile e) => e.toMap()).toList(growable: false),
    );
    await prefs.setString(_profilesKey, encoded);
  }

  Future<List<VoiceProfile>> replaceProfiles(
    List<VoiceProfile> incoming,
  ) async {
    final current = await loadProfiles();
    final merged = voiceProfileService.replaceProfiles(
      existing: current,
      incoming: incoming,
    );
    await saveProfiles(merged);
    return merged;
  }

  Future<List<VoiceProfile>> selectProfile(String profileId) async {
    final current = await loadProfiles();
    final updated = voiceProfileService.selectProfile(
      profiles: current,
      profileId: profileId,
    );
    await saveProfiles(updated);
    return updated;
  }

  Future<List<VoiceProfile>> approveProfile(String profileId) async {
    final current = await loadProfiles();
    final updated = voiceProfileService.approveProfile(
      profiles: current,
      profileId: profileId,
    );
    await saveProfiles(updated);
    return updated;
  }

  Future<List<VoiceProfile>> rejectProfile(String profileId) async {
    final current = await loadProfiles();
    final updated = voiceProfileService.rejectProfile(
      profiles: current,
      profileId: profileId,
    );
    await saveProfiles(updated);
    return updated;
  }

  Future<VoiceProfile?> getSelectedProfile() async {
    final current = await loadProfiles();
    return voiceProfileService.getSelectedProfile(current);
  }

  List<VoiceProfile> get _defaultProfiles => const <VoiceProfile>[
    VoiceProfile(
      id: 'default_tr_1',
      name: 'Varsayılan Türkçe 1',
      filePath: 'assets/voice_profiles/default_tr_1.json',
      isSelected: true,
      isApproved: true,
      description: 'Dengeli, sakin ve net konuşma profili.',
      styleHint: 'Sakin, temiz diksiyon, kısa ve net vurgu.',
      isReferenceSample: true,
    ),
    VoiceProfile(
      id: 'default_tr_2',
      name: 'Varsayılan Türkçe 2',
      filePath: 'assets/voice_profiles/default_tr_2.json',
      isSelected: false,
      isApproved: true,
      description: 'Biraz daha sıcak ve yumuşak ton.',
      styleHint: 'Sıcak, nazik, akıcı ve hafif yumuşak ton.',
      isReferenceSample: true,
    ),
  ];
}
