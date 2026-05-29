// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/voice_clone/voice_clone_source_type.dart';
import 'voice_clone_settings_service.dart';

enum VoiceClonePermissionDecision {
  allow,
  askEnableExternal,
  askEnableInternal,
  deny,
}

class VoiceClonePermissionGateService {
  final VoiceCloneSettingsService settingsService;

  const VoiceClonePermissionGateService({required this.settingsService});

  VoiceClonePermissionDecision decide(VoiceCloneSourceType sourceType) {
    final settings = settingsService.settings;

    switch (sourceType) {
      case VoiceCloneSourceType.file:
        return VoiceClonePermissionDecision.allow;
      case VoiceCloneSourceType.externalMic:
        return settings.externalCloneEnabled
            ? VoiceClonePermissionDecision.allow
            : VoiceClonePermissionDecision.askEnableExternal;
      case VoiceCloneSourceType.internalPhoneAudio:
        return settings.internalCloneEnabled
            ? VoiceClonePermissionDecision.allow
            : VoiceClonePermissionDecision.askEnableInternal;
    }
  }

  String buildQuestion(VoiceCloneSourceType sourceType) {
    switch (sourceType) {
      case VoiceCloneSourceType.file:
        return 'Dosyadan klonlama hazır efendim.';
      case VoiceCloneSourceType.externalMic:
        return 'Efendim dış sesten klonlama kapalı. Açmak ister misiniz?';
      case VoiceCloneSourceType.internalPhoneAudio:
        return 'Efendim telefon içi sesten klonlama kapalı. Açmak ister misiniz?';
    }
  }
}
