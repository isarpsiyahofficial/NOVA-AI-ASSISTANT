// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/identity/voice_access_decision.dart';
import '../../core/runtime/nova_runtime_signal.dart';
import '../audio_runtime/nova_playback_echo_filter_service.dart';
import '../runtime/nova_runtime_signal_service.dart';
import 'nova_daily_voice_session_service.dart';
import 'nova_recent_speaker_service.dart';
import 'nova_voice_identity_runtime_service.dart';
import 'device_owner_identity_service.dart';
import 'voice_authorization_service.dart';
import 'nova_multi_speaker_authority_service.dart';

class VoiceAuthorizationRuntimeInspectionResult {
  final VoiceAccessDecision decision;
  final String recognizedVoiceId;
  final String recognizedDisplayName;
  final double similarity;
  final bool captureSucceeded;

  const VoiceAuthorizationRuntimeInspectionResult({
    required this.decision,
    this.recognizedVoiceId = '',
    this.recognizedDisplayName = '',
    this.similarity = 0,
    this.captureSucceeded = false,
  });
}

class VoiceAuthorizationRuntimeService {
  final NovaVoiceIdentityRuntimeService voiceIdentityRuntimeService;
  final VoiceAuthorizationService authorizationService;
  final NovaPlaybackEchoFilterService playbackGuardService;
  final NovaDailyVoiceSessionService dailyVoiceSessionService;
  final NovaRecentSpeakerService recentSpeakerService;
  final DeviceOwnerIdentityService ownerService;
  final NovaMultiSpeakerAuthorityService multiSpeakerAuthorityService =
      const NovaMultiSpeakerAuthorityService();

  VoiceAuthorizationRuntimeService({
    required this.voiceIdentityRuntimeService,
    required this.authorizationService,
    this.playbackGuardService =
        const NovaPlaybackEchoFilterService(),
    NovaDailyVoiceSessionService? dailyVoiceSessionService,
    NovaRecentSpeakerService? recentSpeakerService,
    DeviceOwnerIdentityService? ownerService,
  }) : dailyVoiceSessionService =
           dailyVoiceSessionService ?? const NovaDailyVoiceSessionService(),
       recentSpeakerService =
           recentSpeakerService ?? const NovaRecentSpeakerService(),
       ownerService = ownerService ?? const DeviceOwnerIdentityService();

  Future<VoiceAuthorizationRuntimeInspectionResult> inspectFreshExternalSample({
    int maxDurationSeconds = 4,
    String outputName = 'nova_runtime_auth',
    double minSimilarity = 0.64,
  }) async {
    final blockedBySyntheticPlayback = await playbackGuardService
        .isPlaybackActiveNow();

    if (blockedBySyntheticPlayback) {
      final released = await playbackGuardService.waitUntilPlaybackInactive(
        timeout: const Duration(milliseconds: 3200),
      );

      if (!released) {
        await NovaRuntimeSignalService.instance.record(
          kind: NovaRuntimeSignalKind.authorization,
          level: NovaRuntimeSignalLevel.warning,
          code: 'authorization_blocked_during_synthetic_playback',
          message:
              'Yetki doğrulaması sentetik konuşma oynarken engellendi. Ses teyidi yalnız doğrulama için kullanılabilir.',
          technicalDetails: 'outputName=$outputName',
          diagnosticCandidate: false,
        );

        return const VoiceAuthorizationRuntimeInspectionResult(
          decision: VoiceAccessDecision(
            level: VoiceAccessLevel.denied,
            message:
                'Yetki doğrulaması için kısa bir an bekliyorum efendim. Tekrar deneyin.',
          ),
          captureSucceeded: false,
        );
      }
    }

    final identify = await voiceIdentityRuntimeService
        .identifyFromFreshExternalSample(
          maxDurationSeconds: maxDurationSeconds,
          outputName: outputName,
          minSimilarity: minSimilarity,
        );

    if (!identify.success) {
      await NovaRuntimeSignalService.instance.record(
        kind: NovaRuntimeSignalKind.voiceIdentity,
        level: NovaRuntimeSignalLevel.error,
        code: 'voice_identity_capture_failed',
        message: identify.message.trim().isEmpty
            ? 'Ses doğrulaması yapılamadı efendim.'
            : identify.message.trim(),
        technicalDetails: 'identifyFromFreshExternalSample failed',
        diagnosticCandidate: false,
      );

      return VoiceAuthorizationRuntimeInspectionResult(
        decision: VoiceAccessDecision(
          level: VoiceAccessLevel.denied,
          message: identify.message.trim().isEmpty
              ? 'Ses doğrulaması yapılamadı efendim.'
              : identify.message.trim(),
        ),
        captureSucceeded: false,
      );
    }

    final String voiceId = identify.voiceId.trim();

    if (!identify.matched || voiceId.isEmpty) {
      await NovaRuntimeSignalService.instance.record(
        kind: NovaRuntimeSignalKind.authorization,
        level: NovaRuntimeSignalLevel.warning,
        code: 'voice_identity_no_match',
        message:
            'Ses net gelmedi ya da kayıtlı ses havuzunda eşleşme bulamadım efendim. Sohbete nötr modda devam edebilirim.',
        technicalDetails: 'matched=${identify.matched}, voiceId=$voiceId',
        diagnosticCandidate: false,
      );

      return VoiceAuthorizationRuntimeInspectionResult(
        decision: const VoiceAccessDecision(
          level: VoiceAccessLevel.denied,
          message: '',
          suppressStatusBroadcast: true,
        ),
        recognizedVoiceId: voiceId,
        recognizedDisplayName: identify.displayName.trim(),
        similarity: identify.similarity,
        captureSucceeded: true,
      );
    }

    final decision = await authorizationService.decide(voiceId);
    return VoiceAuthorizationRuntimeInspectionResult(
      decision: decision,
      recognizedVoiceId: voiceId,
      recognizedDisplayName: identify.displayName.trim(),
      similarity: identify.similarity,
      captureSucceeded: true,
    );
  }

  Map<String, dynamic> buildAuthorityHints({
    required VoiceAccessLevel? level,
    required String speakerName,
    required bool addressedNova,
    required bool containsCommand,
  }) {
    final decision = multiSpeakerAuthorityService.decide(
      speakers: <NovaSpeakerFrame>[
        NovaSpeakerFrame(
          voiceId: speakerName.trim().toLowerCase(),
          displayName: speakerName,
          band: multiSpeakerAuthorityService.bandForLevel(level),
          similarity: 0.92,
          addressedNova: addressedNova,
          containsCommand: containsCommand,
          observedAt: DateTime.now(),
        ),
      ],
      transcript: speakerName,
    );
    return <String, dynamic>{
      'chosenBand': decision.chosenBand.name,
      'allowCommand': decision.allowCommand,
      'allowConversation': decision.allowConversation,
      'ownerDominated': decision.ownerDominated,
      'spokenResponse': decision.spokenResponse,
    };
  }

  Future<VoiceAuthorizationRuntimeInspectionResult?> _inspectOwnerContinuity({
    required DateTime now,
    required String preferredVoiceId,
    Duration trustedDailyWindow = const Duration(hours: 24),
    Duration trustedRecentWindow = const Duration(hours: 20),
    Duration conversationWindow = const Duration(hours: 8),
  }) async {
    final owner = await ownerService.loadOwner();
    final ownerVoiceId = owner?.ownerVoiceId.trim() ?? '';
    if (ownerVoiceId.isEmpty) return null;
    if (preferredVoiceId.isNotEmpty && preferredVoiceId != ownerVoiceId) {
      // owner sesi biliniyorsa ama başka bir tercih varsa yine de owner önceliğini koru.
    }

    final dailyTrustedSessions = await dailyVoiceSessionService
        .loadActiveTrustedSessions();
    for (final session in dailyTrustedSessions) {
      if (session.voiceId != ownerVoiceId) continue;
      if (!session.isTrusted) continue;
      if (now.difference(session.updatedAt) > trustedDailyWindow) continue;
      return VoiceAuthorizationRuntimeInspectionResult(
        decision: VoiceAccessDecision(
          level: VoiceAccessLevel.owner,
          message: owner == null
              ? 'Cihaz sahibi için günlük güven devamlılığı kullanılıyor.'
              : '${owner.ownerName} için günlük owner devamlılığı kullanılıyor.',
          recognizedName: owner?.ownerName ?? session.recognizedName,
          relationshipLabel: 'Cihaz sahibi',
          suppressStatusBroadcast: true,
        ),
        recognizedVoiceId: ownerVoiceId,
        recognizedDisplayName: owner?.ownerName ?? session.recognizedName,
        similarity: 1,
        captureSucceeded: false,
      );
    }

    final recentOwner = await recentSpeakerService.findByVoiceId(ownerVoiceId);
    if (recentOwner != null &&
        now.difference(recentOwner.observedAt) <= trustedRecentWindow &&
        (recentOwner.level == VoiceAccessLevel.owner ||
            recentOwner.level == VoiceAccessLevel.authorizedGuest ||
            recentOwner.level == VoiceAccessLevel.familiar)) {
      return VoiceAuthorizationRuntimeInspectionResult(
        decision: VoiceAccessDecision(
          level: VoiceAccessLevel.owner,
          message: owner == null
              ? 'Cihaz sahibi için yakın ses devamlılığı kullanılıyor.'
              : '${owner.ownerName} için yakın owner ses devamlılığı kullanılıyor.',
          recognizedName: owner?.ownerName ?? recentOwner.speakerName,
          relationshipLabel: 'Cihaz sahibi',
          suppressStatusBroadcast: true,
        ),
        recognizedVoiceId: ownerVoiceId,
        recognizedDisplayName: owner?.ownerName ?? recentOwner.speakerName,
        similarity: 0.97,
        captureSucceeded: false,
      );
    }

    final recentConversationSpeaker = await recentSpeakerService
        .bestConversationCandidate(
          trustedWindow: trustedRecentWindow,
          familiarWindow: conversationWindow,
        );
    if (recentConversationSpeaker != null &&
        recentConversationSpeaker.voiceId == ownerVoiceId &&
        now.difference(recentConversationSpeaker.observedAt) <=
            conversationWindow) {
      return VoiceAuthorizationRuntimeInspectionResult(
        decision: VoiceAccessDecision(
          level: VoiceAccessLevel.owner,
          message: owner == null
              ? 'Cihaz sahibi konuşma devamlılığı korunuyor.'
              : '${owner.ownerName} için owner konuşma devamlılığı korunuyor.',
          recognizedName:
              owner?.ownerName ?? recentConversationSpeaker.speakerName,
          relationshipLabel: 'Cihaz sahibi',
          suppressStatusBroadcast: true,
        ),
        recognizedVoiceId: ownerVoiceId,
        recognizedDisplayName:
            owner?.ownerName ?? recentConversationSpeaker.speakerName,
        similarity: 0.93,
        captureSucceeded: false,
      );
    }
    return null;
  }

  Future<VoiceAuthorizationRuntimeInspectionResult?> inspectUsingContinuity({
    Duration trustedDailyWindow = const Duration(hours: 24),
    Duration trustedRecentWindow = const Duration(hours: 20),
    Duration conversationWindow = const Duration(hours: 8),
    String preferredVoiceId = '',
  }) async {
    final now = DateTime.now();
    final dailyTrustedSessions = await dailyVoiceSessionService
        .loadActiveTrustedSessions();
    final preferredVoice = preferredVoiceId.trim();

    final ownerContinuity = await _inspectOwnerContinuity(
      now: now,
      preferredVoiceId: preferredVoice,
      trustedDailyWindow: trustedDailyWindow,
      trustedRecentWindow: trustedRecentWindow,
      conversationWindow: conversationWindow,
    );
    if (ownerContinuity != null) {
      return ownerContinuity;
    }

    Iterable<NovaDailyVoiceSessionSnapshot> orderedDailySessions =
        dailyTrustedSessions;
    if (preferredVoice.isNotEmpty) {
      orderedDailySessions = [
        ...dailyTrustedSessions.where((e) => e.voiceId == preferredVoice),
        ...dailyTrustedSessions.where((e) => e.voiceId != preferredVoice),
      ];
    }

    for (final session in orderedDailySessions) {
      final withinWindow =
          now.difference(session.updatedAt) <= trustedDailyWindow;
      if (!session.isTrusted || !withinWindow) {
        continue;
      }
      return VoiceAuthorizationRuntimeInspectionResult(
        decision: VoiceAccessDecision(
          level: session.level,
          message: session.recognizedName.trim().isEmpty
              ? 'Günlük güvenilen konuşmacı devamlılığı kullanılıyor.'
              : '${session.recognizedName.trim()} için günlük güvenilen konuşmacı devamlılığı kullanılıyor.',
          suppressStatusBroadcast: true,
        ),
        recognizedVoiceId: session.voiceId,
        recognizedDisplayName: session.recognizedName,
        similarity: 1,
        captureSucceeded: false,
      );
    }

    final recentTrusted = preferredVoice.isNotEmpty
        ? await recentSpeakerService.findByVoiceId(preferredVoice) ??
              await recentSpeakerService.bestTrustedSpeaker()
        : await recentSpeakerService.bestTrustedSpeaker();
    if (recentTrusted != null &&
        now.difference(recentTrusted.observedAt) <= trustedRecentWindow &&
        (recentTrusted.level == VoiceAccessLevel.owner ||
            recentTrusted.level == VoiceAccessLevel.authorizedGuest)) {
      return VoiceAuthorizationRuntimeInspectionResult(
        decision: VoiceAccessDecision(
          level: recentTrusted.level,
          relationshipLabel: recentTrusted.relationshipLabel,
          message: recentTrusted.speakerName.trim().isEmpty
              ? 'Yakın güvenilen konuşmacı devamlılığı kullanılıyor.'
              : '${recentTrusted.speakerName.trim()} için yakın güvenilen konuşmacı devamlılığı kullanılıyor.',
          suppressStatusBroadcast: true,
        ),
        recognizedVoiceId: recentTrusted.voiceId,
        recognizedDisplayName: recentTrusted.speakerName,
        similarity: 0.92,
        captureSucceeded: false,
      );
    }

    final recentConversationSpeaker = preferredVoice.isNotEmpty
        ? await recentSpeakerService.findByVoiceId(preferredVoice) ??
              await recentSpeakerService.bestConversationCandidate()
        : await recentSpeakerService.bestConversationCandidate();
    if (recentConversationSpeaker != null &&
        now.difference(recentConversationSpeaker.observedAt) <=
            conversationWindow &&
        (recentConversationSpeaker.level == VoiceAccessLevel.owner ||
            recentConversationSpeaker.level ==
                VoiceAccessLevel.authorizedGuest ||
            recentConversationSpeaker.level == VoiceAccessLevel.familiar ||
            recentConversationSpeaker.level ==
                VoiceAccessLevel.knownButUnauthorized)) {
      return VoiceAuthorizationRuntimeInspectionResult(
        decision: VoiceAccessDecision(
          level: recentConversationSpeaker.level,
          relationshipLabel: recentConversationSpeaker.relationshipLabel,
          message: recentConversationSpeaker.speakerName.trim().isEmpty
              ? 'Yakın konuşma akışı konuşmacısı korunuyor.'
              : '${recentConversationSpeaker.speakerName.trim()} için yakın konuşma akışı korunuyor.',
          suppressStatusBroadcast: true,
        ),
        recognizedVoiceId: recentConversationSpeaker.voiceId,
        recognizedDisplayName: recentConversationSpeaker.speakerName,
        similarity: 0.86,
        captureSucceeded: false,
      );
    }

    return null;
  }

  Future<VoiceAuthorizationRuntimeInspectionResult>
  inspectPreferContinuityThenFresh({
    int maxDurationSeconds = 4,
    String outputName = 'nova_runtime_auth',
    double minSimilarity = 0.64,
    Duration trustedDailyWindow = const Duration(hours: 24),
    Duration trustedRecentWindow = const Duration(hours: 20),
    Duration conversationWindow = const Duration(hours: 8),
    bool allowContinuityReuse = true,
    String preferredVoiceId = '',
  }) async {
    if (allowContinuityReuse) {
      final continuity = await inspectUsingContinuity(
        trustedDailyWindow: trustedDailyWindow,
        trustedRecentWindow: trustedRecentWindow,
        conversationWindow: conversationWindow,
        preferredVoiceId: preferredVoiceId,
      );
      if (continuity != null) {
        return continuity;
      }
    }

    return inspectFreshExternalSample(
      maxDurationSeconds: maxDurationSeconds,
      outputName: outputName,
      minSimilarity: minSimilarity,
    );
  }

  Future<VoiceAccessDecision> decideFromFreshExternalSample({
    int maxDurationSeconds = 4,
    String outputName = 'nova_runtime_auth',
    double minSimilarity = 0.64,
    bool allowContinuityReuse = true,
    String preferredVoiceId = '',
  }) async {
    final inspection = await inspectPreferContinuityThenFresh(
      maxDurationSeconds: maxDurationSeconds,
      outputName: outputName,
      minSimilarity: minSimilarity,
      allowContinuityReuse: allowContinuityReuse,
      preferredVoiceId: preferredVoiceId,
    );
    return inspection.decision;
  }

  Future<bool> canWakeFromFreshExternalSample({
    int maxDurationSeconds = 4,
    String outputName = 'nova_runtime_wake_auth',
    double minSimilarity = 0.64,
  }) async {
    final decision = await decideFromFreshExternalSample(
      maxDurationSeconds: maxDurationSeconds,
      outputName: outputName,
      minSimilarity: minSimilarity,
    );

    return decision.level == VoiceAccessLevel.owner ||
        decision.level == VoiceAccessLevel.authorizedGuest;
  }

  Future<bool> canControlFromFreshExternalSample({
    int maxDurationSeconds = 4,
    String outputName = 'nova_runtime_control_auth',
    double minSimilarity = 0.64,
  }) async {
    final decision = await decideFromFreshExternalSample(
      maxDurationSeconds: maxDurationSeconds,
      outputName: outputName,
      minSimilarity: minSimilarity,
    );

    return decision.level == VoiceAccessLevel.owner ||
        decision.level == VoiceAccessLevel.authorizedGuest;
  }

  Map<String, dynamic> buildAuthorizationSnapshot(
    VoiceAccessDecision decision,
  ) {
    return <String, dynamic>{
      'level': decision.level.name,
      'recognizedName': decision.recognizedName,
      'relationshipLabel': decision.relationshipLabel,
      'suppressStatusBroadcast': decision.suppressStatusBroadcast,
      'message': decision.message,
      'allowsCommand':
          decision.level == VoiceAccessLevel.owner ||
          decision.level == VoiceAccessLevel.authorizedGuest,
      'allowsConversation': decision.level != VoiceAccessLevel.denied,
    };
  }

  List<String> buildAuthorityRules() {
    return const <String>[
      'Cihaz sahibi en yüksek önceliktedir.',
      'Yetkili kişi komut verebilir ama owner ile çakışırsa owner seçilir.',
      'Tanışılmış kişiler sohbet edebilir, komut veremez.',
      'Yabancı kişiler için tanışma/izin akışı gerekir.',
      'Sürekli yeniden kimlik doğrulaması yerine devamlılık kullanılır; riskte tazelenir.',
    ];
  }

  bool shouldReuseContinuity({
    required VoiceAccessLevel level,
    required DateTime? lastSeenAt,
    Duration familiarWindow = const Duration(hours: 8),
    Duration trustedWindow = const Duration(hours: 20),
  }) {
    if (lastSeenAt == null) return false;
    final age = DateTime.now().difference(lastSeenAt);
    if (level == VoiceAccessLevel.owner ||
        level == VoiceAccessLevel.authorizedGuest)
      return age <= trustedWindow;
    if (level == VoiceAccessLevel.familiar) return age <= familiarWindow;
    return false;
  }

  String buildConflictResolutionHint({
    required bool ownerPresent,
    required bool authorizedPresent,
    required bool commandRequested,
  }) {
    if (ownerPresent && authorizedPresent && commandRequested)
      return 'Aynı anda komut geldi; cihaz sahibinin önceliği korunmalı.';
    if (authorizedPresent && commandRequested)
      return 'Yetkili kişi komut verebilir; owner yoksa akış devam eder.';
    if (commandRequested) return 'Komut istendi ama yetki yeterli görünmüyor.';
    return 'Sohbet akışı için yumuşak yetki devamlılığı yeterli.';
  }
}
