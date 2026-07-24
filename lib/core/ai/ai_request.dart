// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals_to_create_immutables
// NOVA_API_FIRST_REQUEST_AUTHORITY_V2_REAL_ACTION_ORIGINS
import 'ai_mode.dart';

class AiRequest {
  final String prompt;
  final AiMode mode;
  final bool internetAllowed;
  final bool isResearchRequest;
  final bool isSelfLearningRequest;
  final bool isFastResponsePriority;
  final bool isUserApprovedApiUsage;
  final bool isBehaviorTeachingRequest;
  final bool isScreenLocked;
  final bool requestedByVoice;
  final String learningModeHint;
  final String requestOrigin;
  final bool userInitiated;
  final bool userConfirmedThisAction;
  final String activeProviderKey;
  final String activeModelId;
  final Map<String, dynamic> metadata;

  const AiRequest({
    required this.prompt,
    required this.mode,
    this.internetAllowed = true,
    this.isResearchRequest = false,
    this.isSelfLearningRequest = false,
    this.isFastResponsePriority = true,
    this.isUserApprovedApiUsage = true,
    this.isBehaviorTeachingRequest = false,
    this.isScreenLocked = false,
    this.requestedByVoice = true,
    this.learningModeHint = 'none',
    this.requestOrigin = 'user_voice',
    this.userInitiated = true,
    this.userConfirmedThisAction = true,
    this.activeProviderKey = '',
    this.activeModelId = '',
    this.metadata = const <String, dynamic>{},
  });

  bool get shouldUseApi {
    if (!mode.canUseApi) return false;
    if (!internetAllowed) return false;
    if (!isUserApprovedApiUsage) return false;
    if (!isSafeUserOrigin) return false;
    return true;
  }

  bool get shouldUseLocalModel => mode.usesLocalModel;

  bool get isSafeUserOrigin {
    final normalized = requestOrigin.trim();
    const allowed = <String>{
      'user_voice',
      'user_ui',
      'background_authorized_voice',
      'setup_voice',
      'setup_ui',
      'setup_panel',
      'dashboard_stt',
      'dashboard_text',
      'dashboard_manual_voice_entry',
      'call_companion_authorized_voice',
      'reminder_runtime_event',
      'main_tts_router',
      'reminder_ai_speech_rewriter',
      'call_instruction_runtime_ai_speech_rewriter',
    };
    final localCompanionProof =
        normalized == 'call_companion_authorized_voice' &&
        metadata['localCompanionAuthorityProof'] == true;
    final trustedSystemOrigin =
        normalized == 'background_authorized_voice' ||
        normalized == 'main_tts_router' ||
        normalized == 'reminder_runtime_event' ||
        normalized == 'reminder_ai_speech_rewriter' ||
        normalized == 'call_instruction_runtime_ai_speech_rewriter' ||
        localCompanionProof ||
        normalized.startsWith('setup');
    if (!userInitiated && !trustedSystemOrigin) return false;
    return allowed.contains(normalized) || normalized.startsWith('setup');
  }
}
