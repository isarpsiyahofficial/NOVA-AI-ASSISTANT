// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/voice/voice_profile.dart';
import '../settings/nova_settings_service.dart';
import '../../services/voice_clone/cloned_voice_library_service.dart';
import '../voice/voice_profile_storage_service.dart';

class VoiceProfileRuntimeService {
  final VoiceProfileStorageService storageService;
  final ClonedVoiceLibraryService clonedVoiceLibraryService;
  final NovaSettingsService settingsService;

  const VoiceProfileRuntimeService({
    required this.storageService,
    required this.clonedVoiceLibraryService,
    required this.settingsService,
  });

  Future<VoiceProfile?> getSelectedProfile() async {
    try {
      return await storageService.getSelectedProfile();
    } catch (_) {
      return null;
    }
  }

  Future<String> resolveActiveVoiceProfileId({
    String requestedVoiceProfileId = '',
  }) async {
    final requested = requestedVoiceProfileId.trim();
    if (requested.isNotEmpty) {
      return requested;
    }

    try {
      final activeCloned = await clonedVoiceLibraryService.getActiveVoice();
      if (activeCloned != null && activeCloned.id.trim().isNotEmpty) {
        return activeCloned.id.trim();
      }
    } catch (_) {}

    try {
      final settings = await settingsService.load();
      if (settings.activeVoiceProfileId.trim().isNotEmpty) {
        return settings.activeVoiceProfileId.trim();
      }
    } catch (_) {}

    final selected = await getSelectedProfile();
    if (selected != null && selected.id.trim().isNotEmpty) {
      return selected.id.trim();
    }

    return 'nova_tr_prime';
  }

  Future<String> resolveActiveSpeakerPath({
    String requestedVoiceProfileId = '',
  }) async {
    final activeId = await resolveActiveVoiceProfileId(
      requestedVoiceProfileId: requestedVoiceProfileId,
    );

    try {
      final activeCloned = await clonedVoiceLibraryService.getActiveVoice();
      if (activeCloned != null &&
          activeCloned.id == activeId &&
          activeCloned.sourceReference.trim().isNotEmpty) {
        return activeCloned.sourceReference.trim();
      }
    } catch (_) {}

    try {
      final profiles = await storageService.loadProfiles();
      for (final profile in profiles) {
        if (profile.id == activeId && profile.filePath.trim().isNotEmpty) {
          return profile.filePath.trim();
        }
      }
    } catch (_) {}

    return '';
  }

  Future<String> resolveStyleHint({String requestedVoiceProfileId = ''}) async {
    final activeId = await resolveActiveVoiceProfileId(
      requestedVoiceProfileId: requestedVoiceProfileId,
    );

    try {
      final activeCloned = await clonedVoiceLibraryService.getActiveVoice();
      if (activeCloned != null && activeCloned.id == activeId) {
        return activeCloned.styleInstruction.trim().isEmpty
            ? _defaultNovaStyleHint()
            : activeCloned.styleInstruction.trim();
      }
    } catch (_) {}

    try {
      final profiles = await storageService.loadProfiles();
      for (final profile in profiles) {
        if (profile.id == activeId) {
          return profile.styleHint.trim().isEmpty
              ? _defaultNovaStyleHint()
              : profile.styleHint.trim();
        }
      }
    } catch (_) {}

    return _defaultNovaStyleHint();
  }

  String _defaultNovaStyleHint() {
    return 'Doğal, akıcı, insan gibi konuşan Türkçe kadın sesi. '
        'Robotik olmamalı. Kontrollü ama sıcak. '
        'Kelime vurguları doğal, duraklamalar gerçekçi. '
        'Efendim hitabı nazik ve akıcı olmalı.';
  }
}
