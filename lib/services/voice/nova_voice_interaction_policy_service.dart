// NOVA_CANONICAL_TYPED_VOICE_INTERACTION_POLICY_V2
import '../../core/ai/ai_request.dart';
import '../../core/turn/nova_turn_authority.dart';

class NovaVoicePolicyDecision {
  final bool allow;
  final String reason;
  final String interactionBand;
  final double voicePriority;
  final List<String> notes;

  const NovaVoicePolicyDecision({
    required this.allow,
    required this.reason,
    required this.interactionBand,
    required this.voicePriority,
    required this.notes,
  });
}

class NovaVoiceInteractionPolicyService {
  const NovaVoiceInteractionPolicyService();

  bool shouldAllowProcessing(AiRequest request) => evaluate(request).allow;

  NovaVoicePolicyDecision evaluate(AiRequest request) {
    final authority = request.authority;
    final safeOrigin = request.isSafeUserOrigin;
    final liveLease = request.hasCurrentLease;
    final requestedByVoice = request.requestedByVoice;
    final callMode = request.metadata['inCall'] == true ||
        request.metadata['callMode']?.toString().trim().isNotEmpty == true;
    final companionMode =
        authority.kind == NovaTurnAuthorityKind.companion;

    final allowedAuthority = authority.localUserPresence ||
        authority.ownerVoiceVerified ||
        authority.companionAuthorized ||
        authority.kind == NovaTurnAuthorityKind.reminder;
    final allow = safeOrigin && liveLease && allowedAuthority;

    var priority = requestedByVoice ? 0.72 : 0.34;
    if (authority.ownerVoiceVerified) priority += 0.20;
    if (authority.companionAuthorized) priority += 0.08;
    if (callMode) priority += 0.04;
    priority += authority.ownerConfidence.clamp(0.0, 1.0) * 0.06;

    return NovaVoicePolicyDecision(
      allow: allow,
      reason: allow
          ? 'typed authority and current turn lease verified'
          : _denialReason(
              safeOrigin: safeOrigin,
              liveLease: liveLease,
              allowedAuthority: allowedAuthority,
            ),
      interactionBand: _interactionBand(
        requestedByVoice: requestedByVoice,
        callMode: callMode,
        companionMode: companionMode,
      ),
      voicePriority: priority.clamp(0.0, 1.0),
      notes: <String>[
        'authority=${authority.kind.name}',
        'lease=${liveLease ? 'current' : 'stale_or_missing'}',
        if (authority.ownerVoiceVerified) 'owner_voice_verified',
        if (authority.companionAuthorized) 'companion_scope_verified',
      ],
    );
  }

  String _denialReason({
    required bool safeOrigin,
    required bool liveLease,
    required bool allowedAuthority,
  }) {
    if (!liveLease) return 'turn lease is stale or missing';
    if (!safeOrigin) return 'request origin is not authorized';
    if (!allowedAuthority) return 'typed authority is unverified';
    return 'voice interaction policy denied the turn';
  }

  String _interactionBand({
    required bool requestedByVoice,
    required bool callMode,
    required bool companionMode,
  }) {
    if (callMode && companionMode) return 'live_call_companion';
    if (callMode) return 'live_call';
    if (requestedByVoice) return 'voice_first';
    return 'typed_auxiliary_channel';
  }
}
