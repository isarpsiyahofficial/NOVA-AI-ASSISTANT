// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'voice_profile.dart';

class VoiceProfileService {
  const VoiceProfileService();

  Future<List<VoiceProfile>> getAllProfiles() async => const <VoiceProfile>[];

  List<VoiceProfile> replaceProfiles({
    required List<VoiceProfile> existing,
    required List<VoiceProfile> incoming,
  }) {
    final byId = <String, VoiceProfile>{
      for (final item in existing)
        if (item.id.trim().isNotEmpty) item.id: item,
    };

    for (final item in incoming) {
      if (item.id.trim().isEmpty) continue;
      byId[item.id] = item;
    }

    final merged = byId.values.toList(growable: false);
    final hasSelected = merged.any((e) => e.isSelected);
    if (!hasSelected && merged.isNotEmpty) {
      return <VoiceProfile>[
        merged.first.copyWith(isSelected: true),
        ...merged.skip(1).map((e) => e.copyWith(isSelected: false)),
      ];
    }
    return merged;
  }

  List<VoiceProfile> selectProfile({
    required List<VoiceProfile> profiles,
    required String profileId,
  }) {
    final id = profileId.trim();
    return profiles
        .map((e) => e.copyWith(isSelected: e.id == id))
        .toList(growable: false);
  }

  List<VoiceProfile> approveProfile({
    required List<VoiceProfile> profiles,
    required String profileId,
  }) {
    final id = profileId.trim();
    return profiles
        .map((e) => e.id == id ? e.copyWith(isApproved: true) : e)
        .toList(growable: false);
  }

  List<VoiceProfile> rejectProfile({
    required List<VoiceProfile> profiles,
    required String profileId,
  }) {
    final id = profileId.trim();
    return profiles
        .map((e) => e.id == id ? e.copyWith(isApproved: false) : e)
        .toList(growable: false);
  }

  VoiceProfile? getSelectedProfile(List<VoiceProfile> profiles) {
    for (final profile in profiles) {
      if (profile.isSelected) return profile;
    }
    return profiles.isEmpty ? null : profiles.first;
  }
}
