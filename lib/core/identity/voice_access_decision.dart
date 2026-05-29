// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum VoiceAccessLevel {
  denied,
  owner,
  authorizedGuest,
  familiar,
  knownButUnauthorized,
}

class VoiceAccessDecision {
  final VoiceAccessLevel level;
  final String message;
  final String recognizedName;
  final String relationshipLabel;
  final bool suppressStatusBroadcast;

  const VoiceAccessDecision({
    required this.level,
    required this.message,
    this.recognizedName = '',
    this.relationshipLabel = '',
    this.suppressStatusBroadcast = false,
  });

  bool get canUseCommands =>
      level == VoiceAccessLevel.owner ||
      level == VoiceAccessLevel.authorizedGuest;

  bool get canContinueNeutralConversation =>
      canUseCommands ||
      level == VoiceAccessLevel.familiar ||
      level == VoiceAccessLevel.knownButUnauthorized ||
      suppressStatusBroadcast;

  int get priorityScore {
    switch (level) {
      case VoiceAccessLevel.owner:
        return 500;
      case VoiceAccessLevel.authorizedGuest:
        return 400;
      case VoiceAccessLevel.familiar:
        return 300;
      case VoiceAccessLevel.knownButUnauthorized:
        return 200;
      case VoiceAccessLevel.denied:
        return 100;
    }
  }

  String get authoritySummary {
    switch (level) {
      case VoiceAccessLevel.owner:
        return 'cihaz sahibi';
      case VoiceAccessLevel.authorizedGuest:
        return 'yetkili kişi';
      case VoiceAccessLevel.familiar:
        return 'tanıştırılmış kişi';
      case VoiceAccessLevel.knownButUnauthorized:
        return 'tanınan ama komut yetkisi olmayan kişi';
      case VoiceAccessLevel.denied:
        return 'tanınmayan kişi';
    }
  }
}
