// NOVA_TYPED_REQUEST_AUTHORITY_AND_LEASE_V1
import '../turn/nova_turn_authority.dart';
import '../turn/nova_turn_lease.dart';
import 'ai_mode.dart';

class AiRequest {
  final String prompt;
  final String originalUserText;
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
  final NovaTurnAuthority authority;
  final NovaTurnLease? lease;
  final Map<String, dynamic> metadata;

  const AiRequest({
    required this.prompt,
    required this.mode,
    this.originalUserText = '',
    this.internetAllowed = true,
    this.isResearchRequest = false,
    this.isSelfLearningRequest = false,
    this.isFastResponsePriority = true,
    this.isUserApprovedApiUsage = true,
    this.isBehaviorTeachingRequest = false,
    this.isScreenLocked = false,
    this.requestedByVoice = false,
    this.learningModeHint = 'none',
    this.requestOrigin = 'unknown',
    this.userInitiated = false,
    this.userConfirmedThisAction = false,
    this.activeProviderKey = '',
    this.activeModelId = '',
    this.authority = const NovaTurnAuthority.unverified(),
    this.lease,
    this.metadata = const <String, dynamic>{},
  });

  String get canonicalUserText {
    final original = originalUserText.trim();
    return original.isNotEmpty ? original : prompt.trim();
  }

  bool get hasCurrentLease {
    final current = lease;
    return current != null && NovaTurnLeaseController.instance.isCurrent(current);
  }

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
    const userOrigins = <String>{
      'user_voice',
      'user_ui',
      'dashboard_stt',
      'dashboard_text',
      'dashboard_manual_voice_entry',
      'setup_voice',
      'setup_ui',
      'setup_panel',
    };
    const systemOrigins = <String>{
      'background_authorized_voice',
      'call_companion_authorized_voice',
      'reminder_runtime_event',
      'main_tts_router',
      'reminder_ai_speech_rewriter',
      'call_instruction_runtime_ai_speech_rewriter',
    };
    if (userOrigins.contains(normalized)) {
      return userInitiated || authority.localUserPresence ||
          authority.ownerVoiceVerified;
    }
    if (systemOrigins.contains(normalized)) {
      return authority.companionAuthorized ||
          authority.kind == NovaTurnAuthorityKind.reminder ||
          authority.ownerVoiceVerified;
    }
    return false;
  }

  AiRequest copyWith({
    String? prompt,
    String? originalUserText,
    AiMode? mode,
    bool? internetAllowed,
    bool? isResearchRequest,
    bool? isSelfLearningRequest,
    bool? isFastResponsePriority,
    bool? isUserApprovedApiUsage,
    bool? isBehaviorTeachingRequest,
    bool? isScreenLocked,
    bool? requestedByVoice,
    String? learningModeHint,
    String? requestOrigin,
    bool? userInitiated,
    bool? userConfirmedThisAction,
    String? activeProviderKey,
    String? activeModelId,
    NovaTurnAuthority? authority,
    NovaTurnLease? lease,
    Map<String, dynamic>? metadata,
  }) {
    return AiRequest(
      prompt: prompt ?? this.prompt,
      originalUserText: originalUserText ?? this.originalUserText,
      mode: mode ?? this.mode,
      internetAllowed: internetAllowed ?? this.internetAllowed,
      isResearchRequest: isResearchRequest ?? this.isResearchRequest,
      isSelfLearningRequest:
          isSelfLearningRequest ?? this.isSelfLearningRequest,
      isFastResponsePriority:
          isFastResponsePriority ?? this.isFastResponsePriority,
      isUserApprovedApiUsage:
          isUserApprovedApiUsage ?? this.isUserApprovedApiUsage,
      isBehaviorTeachingRequest:
          isBehaviorTeachingRequest ?? this.isBehaviorTeachingRequest,
      isScreenLocked: isScreenLocked ?? this.isScreenLocked,
      requestedByVoice: requestedByVoice ?? this.requestedByVoice,
      learningModeHint: learningModeHint ?? this.learningModeHint,
      requestOrigin: requestOrigin ?? this.requestOrigin,
      userInitiated: userInitiated ?? this.userInitiated,
      userConfirmedThisAction:
          userConfirmedThisAction ?? this.userConfirmedThisAction,
      activeProviderKey: activeProviderKey ?? this.activeProviderKey,
      activeModelId: activeModelId ?? this.activeModelId,
      authority: authority ?? this.authority,
      lease: lease ?? this.lease,
      metadata: metadata ?? this.metadata,
    );
  }
}
