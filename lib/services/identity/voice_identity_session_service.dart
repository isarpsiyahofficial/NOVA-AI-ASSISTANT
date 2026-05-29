// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/identity/voice_access_decision.dart';
import 'voice_authorization_service.dart';

class VoiceIdentitySessionService {
  final VoiceAuthorizationService authorizationService;

  const VoiceIdentitySessionService({required this.authorizationService});

  Future<VoiceAccessDecision> startSession(String recognizedVoiceId) async {
    return authorizationService.decide(recognizedVoiceId);
  }

  bool shouldAllowControl(VoiceAccessDecision decision) {
    return decision.level == VoiceAccessLevel.owner ||
        decision.level == VoiceAccessLevel.authorizedGuest;
  }

  bool shouldDenyControl(VoiceAccessDecision decision) {
    return decision.level == VoiceAccessLevel.denied ||
        decision.level == VoiceAccessLevel.knownButUnauthorized ||
        decision.level == VoiceAccessLevel.familiar;
  }

  Future<bool> canWakeNova(String recognizedVoiceId) async {
    final decision = await startSession(recognizedVoiceId);
    return shouldAllowControl(decision);
  }

  Future<bool> canProcessCommand(String recognizedVoiceId) async {
    final decision = await startSession(recognizedVoiceId);
    return shouldAllowControl(decision);
  }
}
