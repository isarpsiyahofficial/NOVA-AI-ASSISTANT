// NOVA_TYPED_TURN_AUTHORITY_V2_SCOPED_COMPANION
// Authority is created only from a local UI gesture, a verified owner
// voiceprint, an explicitly configured companion scope, or a reminder event.
// Model output and free-form metadata can never promote this value.

enum NovaTurnAuthorityKind {
  unverified,
  localUser,
  ownerVoice,
  companion,
  reminder,
}

class NovaTurnAuthority {
  static const Set<String> _companionCallControlActions = <String>{
    'answer_call',
    'reject_call',
    'hang_up',
    'mute_call',
    'unmute_call',
    'speaker_on',
    'speaker_off',
    'toggle_hold',
  };

  final NovaTurnAuthorityKind kind;
  final bool localUserPresence;
  final bool ownerVoiceVerified;
  final bool companionAuthorized;
  final String ownerVoiceId;
  final double ownerConfidence;
  final String nativeActionToken;
  final String evidenceId;
  final int issuedAtEpochMs;
  final int expiresAtEpochMs;

  const NovaTurnAuthority._({
    required this.kind,
    required this.localUserPresence,
    required this.ownerVoiceVerified,
    required this.companionAuthorized,
    required this.ownerVoiceId,
    required this.ownerConfidence,
    required this.nativeActionToken,
    required this.evidenceId,
    required this.issuedAtEpochMs,
    required this.expiresAtEpochMs,
  });

  const NovaTurnAuthority.unverified()
      : this._(
          kind: NovaTurnAuthorityKind.unverified,
          localUserPresence: false,
          ownerVoiceVerified: false,
          companionAuthorized: false,
          ownerVoiceId: '',
          ownerConfidence: 0,
          nativeActionToken: '',
          evidenceId: '',
          issuedAtEpochMs: 0,
          expiresAtEpochMs: 0,
        );

  factory NovaTurnAuthority.localUser({
    required String evidenceId,
    Duration lifetime = const Duration(minutes: 2),
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return NovaTurnAuthority._(
      kind: NovaTurnAuthorityKind.localUser,
      localUserPresence: true,
      ownerVoiceVerified: false,
      companionAuthorized: false,
      ownerVoiceId: '',
      ownerConfidence: 0,
      nativeActionToken: '',
      evidenceId: evidenceId.trim(),
      issuedAtEpochMs: now,
      expiresAtEpochMs: now + lifetime.inMilliseconds,
    );
  }

  factory NovaTurnAuthority.ownerVoice({
    required String ownerVoiceId,
    required double confidence,
    required String nativeActionToken,
    required String evidenceId,
    Duration lifetime = const Duration(seconds: 20),
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return NovaTurnAuthority._(
      kind: NovaTurnAuthorityKind.ownerVoice,
      localUserPresence: true,
      ownerVoiceVerified: true,
      companionAuthorized: false,
      ownerVoiceId: ownerVoiceId.trim(),
      ownerConfidence: confidence.clamp(0.0, 1.0),
      nativeActionToken: nativeActionToken.trim(),
      evidenceId: evidenceId.trim(),
      issuedAtEpochMs: now,
      expiresAtEpochMs: now + lifetime.inMilliseconds,
    );
  }

  factory NovaTurnAuthority.companion({
    required String evidenceId,
    Duration lifetime = const Duration(seconds: 30),
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return NovaTurnAuthority._(
      kind: NovaTurnAuthorityKind.companion,
      localUserPresence: false,
      ownerVoiceVerified: false,
      companionAuthorized: true,
      ownerVoiceId: '',
      ownerConfidence: 0,
      nativeActionToken: '',
      evidenceId: evidenceId.trim(),
      issuedAtEpochMs: now,
      expiresAtEpochMs: now + lifetime.inMilliseconds,
    );
  }

  factory NovaTurnAuthority.reminder({
    required String evidenceId,
    Duration lifetime = const Duration(minutes: 1),
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return NovaTurnAuthority._(
      kind: NovaTurnAuthorityKind.reminder,
      localUserPresence: false,
      ownerVoiceVerified: false,
      companionAuthorized: false,
      ownerVoiceId: '',
      ownerConfidence: 0,
      nativeActionToken: '',
      evidenceId: evidenceId.trim(),
      issuedAtEpochMs: now,
      expiresAtEpochMs: now + lifetime.inMilliseconds,
    );
  }

  bool get isExpired {
    if (expiresAtEpochMs <= 0) return true;
    return DateTime.now().millisecondsSinceEpoch >= expiresAtEpochMs;
  }

  bool get isVerified => kind != NovaTurnAuthorityKind.unverified && !isExpired;

  bool get canRequestNativeAction {
    if (!isVerified) return false;
    if (kind == NovaTurnAuthorityKind.localUser) return localUserPresence;
    if (kind == NovaTurnAuthorityKind.ownerVoice) {
      return ownerVoiceVerified &&
          ownerVoiceId.isNotEmpty &&
          ownerConfidence >= 0.64 &&
          nativeActionToken.isNotEmpty;
    }
    return false;
  }

  bool canRequestNativeActionFor(String action) {
    final normalizedAction = action.trim().toLowerCase();
    if (normalizedAction.isEmpty || !isVerified) return false;
    if (kind == NovaTurnAuthorityKind.companion) {
      return companionAuthorized &&
          _companionCallControlActions.contains(normalizedAction);
    }
    return canRequestNativeAction;
  }

  NovaTurnAuthority copyWithNativeActionToken(String token) {
    return NovaTurnAuthority._(
      kind: kind,
      localUserPresence: localUserPresence,
      ownerVoiceVerified: ownerVoiceVerified,
      companionAuthorized: companionAuthorized,
      ownerVoiceId: ownerVoiceId,
      ownerConfidence: ownerConfidence,
      nativeActionToken: token.trim(),
      evidenceId: evidenceId,
      issuedAtEpochMs: issuedAtEpochMs,
      expiresAtEpochMs: expiresAtEpochMs,
    );
  }

  Map<String, dynamic> toAuditMap() => <String, dynamic>{
        'kind': kind.name,
        'localUserPresence': localUserPresence,
        'ownerVoiceVerified': ownerVoiceVerified,
        'companionAuthorized': companionAuthorized,
        'companionNativeScope': kind == NovaTurnAuthorityKind.companion
            ? _companionCallControlActions.toList(growable: false)
            : const <String>[],
        'ownerVoiceIdPresent': ownerVoiceId.isNotEmpty,
        'ownerConfidence': ownerConfidence,
        'nativeActionTokenPresent': nativeActionToken.isNotEmpty,
        'evidenceId': evidenceId,
        'issuedAtEpochMs': issuedAtEpochMs,
        'expiresAtEpochMs': expiresAtEpochMs,
        'expired': isExpired,
      };
}
