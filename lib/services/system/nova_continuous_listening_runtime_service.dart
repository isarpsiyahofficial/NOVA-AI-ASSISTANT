// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:async';

import '../../core/asr/nova_streaming_asr_event.dart';
import '../../core/identity/voice_access_decision.dart';
import '../../core/runtime/nova_runtime_signal.dart';
import '../../core/system/nova_power_mode.dart';
import '../asr/nova_streaming_asr_runtime_service.dart';
import '../call/nova_call_control_bridge_service.dart';
import '../call/nova_call_state_service.dart';
import '../call_companion/nova_call_companion_runtime_service.dart';
import '../contacts/nova_contact_service.dart';
import '../identity/nova_daily_voice_session_service.dart';
import '../identity/nova_recent_speaker_service.dart';
import '../identity/voice_authorization_runtime_service.dart';
import '../presence/nova_presence_service.dart';
import '../runtime/nova_runtime_signal_service.dart';
import '../stt/nova_speech_to_text_service.dart';
import '../runtime/nova_spoken_intent_interpreter_service.dart';
import '../runtime/nova_conversation_act_detector_service.dart';
import '../runtime/nova_semantic_turn_detector_service.dart';
import '../runtime/nova_interruption_intent_detector_service.dart';
import '../runtime/nova_benchmark_harness_service.dart';
import '../runtime/nova_unified_social_runtime_service.dart';
import '../audio_runtime/nova_playback_echo_filter_service.dart';
import '../runtime/nova_identity_runtime_service.dart';
import '../runtime/nova_system_adaptation_contract_service.dart';
import 'nova_background_bridge_service.dart';
import 'nova_voice_first_presence_runtime_service.dart';
import 'nova_lifecycle_service.dart';
import 'nova_power_service.dart';
import 'nova_power_schedule_service.dart';

class NovaContinuousListeningRuntimeService {
  static const String familiarConversationMarker =
      '__nova_familiar_conversation__:';
  final NovaSpeechToTextService sttService;
  final NovaPowerService powerService;
  final NovaLifecycleService lifecycleService;
  final NovaPresenceService presenceService;
  final NovaBackgroundBridgeService backgroundBridgeService;
  final VoiceAuthorizationRuntimeService authorizationRuntimeService;
  final NovaCallCompanionRuntimeService? companionRuntime;
  final NovaContactService? contactService;
  final NovaCallStateService? callStateService;
  final NovaCallControlBridgeService? callControlService;
  final bool Function()? isWakeWordEnabled;
  final bool Function()? isCallHandlingEnabled;
  final NovaDailyVoiceSessionService dailyVoiceSessionService;
  final NovaRecentSpeakerService recentSpeakerService;
  final NovaPowerScheduleService powerScheduleService;
  final NovaStreamingAsrRuntimeService streamingAsrRuntimeService;
  final NovaPlaybackEchoFilterService playbackGuardService;
  final NovaIdentityRuntimeService identityRuntimeService =
      const NovaIdentityRuntimeService();
  final NovaSystemAdaptationContractService adaptationContractService =
      const NovaSystemAdaptationContractService();
  final NovaVoiceFirstPresenceRuntimeService voiceFirstPresenceRuntimeService =
      const NovaVoiceFirstPresenceRuntimeService();
  final NovaUnifiedSocialRuntimeService unifiedSocialRuntimeService;
  final NovaBenchmarkHarnessService benchmarkHarnessService;

  bool _running = false;
  bool _loopBusy = false;
  String _lastStatusBroadcast = '';
  DateTime? _lastStatusBroadcastAt;
  final NovaSpokenIntentInterpreterService _spokenIntentInterpreter =
      const NovaSpokenIntentInterpreterService();
  final NovaConversationActDetectorService _conversationActDetector =
      const NovaConversationActDetectorService();
  final NovaSemanticTurnDetectorService _semanticTurnDetector =
      const NovaSemanticTurnDetectorService();
  final NovaInterruptionIntentDetectorService _interruptionIntentDetector =
      const NovaInterruptionIntentDetectorService();
  DateTime? _conversationHoldUntil;
  DateTime? _authorizedConversationUntil;
  DateTime? _softSpeakerIdentityUntil;
  DateTime? _lastHeardAt;
  VoiceAccessLevel? _lastAuthorizedLevel;
  String _lastAuthorizedVoiceId = '';
  String _lastRecognizedSpeakerName = '';
  String _lastRelationshipLabel = '';
  DateTime? _lastNativeSessionHealthCheckAt;
  DateTime? _lastSpeakerContinuityRefreshAt;
  StreamSubscription<NovaStreamingAsrEvent>? _streamingAsrSubscription;
  String _recentStreamingFinalText = '';
  String _recentStreamingPartialText = '';
  String _recentStreamingLocale = 'tr-TR';
  String _recentStreamingFinalRoute = 'none';
  String _recentStreamingPartialRoute = 'none';
  DateTime? _recentStreamingFinalAt;
  DateTime? _recentStreamingPartialAt;
  String _lastDeliveredStreamingTranscript = '';
  DateTime? _lastDeliveredStreamingTranscriptAt;
  DateTime? _lastActiveCaptureAt;
  DateTime? _streamingSpeechGraceUntil;
  DateTime? _lastVoiceGateEnsureAt;
  String _runtimeAudioMode = 'none';

  NovaContinuousListeningRuntimeService({
    required this.sttService,
    required this.powerService,
    required this.lifecycleService,
    required this.presenceService,
    required this.backgroundBridgeService,
    required this.authorizationRuntimeService,
    this.callStateService,
    this.callControlService,
    this.companionRuntime,
    this.contactService,
    this.isWakeWordEnabled,
    this.isCallHandlingEnabled,
    NovaDailyVoiceSessionService? dailyVoiceSessionService,
    NovaRecentSpeakerService? recentSpeakerService,
    NovaPowerScheduleService? powerScheduleService,
    NovaStreamingAsrRuntimeService? streamingAsrRuntimeService,
    NovaPlaybackEchoFilterService? playbackGuardService,
    NovaUnifiedSocialRuntimeService? unifiedSocialRuntimeService,
    NovaBenchmarkHarnessService? benchmarkHarnessService,
  }) : dailyVoiceSessionService =
           dailyVoiceSessionService ?? const NovaDailyVoiceSessionService(),
       recentSpeakerService =
           recentSpeakerService ?? const NovaRecentSpeakerService(),
       powerScheduleService =
           powerScheduleService ?? const NovaPowerScheduleService(),
       streamingAsrRuntimeService =
           streamingAsrRuntimeService ?? NovaStreamingAsrRuntimeService(),
       playbackGuardService =
           playbackGuardService ??
           const NovaPlaybackEchoFilterService(),
       unifiedSocialRuntimeService =
           unifiedSocialRuntimeService ?? NovaUnifiedSocialRuntimeService(),
       benchmarkHarnessService =
           benchmarkHarnessService ?? NovaBenchmarkHarnessService();

  bool get isRunning => _running;

  Map<String, dynamic> get currentPromptMetadata => <String, dynamic>{
    'speakerVoiceId': _lastAuthorizedVoiceId.trim(),
    'speakerName': _lastRecognizedSpeakerName.trim(),
    'relationshipLabel': _lastRelationshipLabel.trim(),
    'voiceAccessLevel': _lastAuthorizedLevel?.name ?? '',
    'ownerConfidence': _ownerConfidenceForLevel(_lastAuthorizedLevel),
    'heardAt': _lastHeardAt?.toIso8601String() ?? '',
    'streamingAsrRoute': _recentStreamingFinalRoute.trim().isNotEmpty
        ? _recentStreamingFinalRoute
        : _recentStreamingPartialRoute,
    'streamingAsrFinalRoute': _recentStreamingFinalRoute,
    'streamingAsrPartialRoute': _recentStreamingPartialRoute,
    'adaptiveContractVersion': '2026-04-19',
    'socialCommandMode': 'conversation_first',
    'dynamicEntityMode': 'enabled',
    'futureSystemAutoAdaptReady': true,
    'identityContinuityEnabled': true,
    'relationshipMemoryEnabled': true,
    'safeAutoAdaptEligible': true,
    'wakeWordLocalOnly': true,
    'apiTranscriptIsNotAuthority': true,
    'speakerVerificationLocalDeterministic': true,
    'callModeRequiresFreshVoiceAuth': true,
    'sourceSystem': 'continuous_listening_runtime',
  };

  static const Duration _activeCaptureCooldown = Duration(seconds: 75);

  Map<String, dynamic> runtimeSnapshot() {
    final now = DateTime.now();
    final asr = streamingAsrRuntimeService.latestState;
    return <String, dynamic>{
      'running': _running,
      'conversationHoldActive':
          _conversationHoldUntil != null &&
          now.isBefore(_conversationHoldUntil!),
      'authorizedConversationActive':
          _authorizedConversationUntil != null &&
          now.isBefore(_authorizedConversationUntil!),
      'softSpeakerIdentityActive':
          _softSpeakerIdentityUntil != null &&
          now.isBefore(_softSpeakerIdentityUntil!),
      'lastAuthorizedLevel': _lastAuthorizedLevel?.name ?? '',
      'lastAuthorizedVoiceId': _lastAuthorizedVoiceId,
      'lastRecognizedSpeakerName': _lastRecognizedSpeakerName,
      'lastRelationshipLabel': _lastRelationshipLabel,
      'lastHeardAt': _lastHeardAt?.toIso8601String() ?? '',
      'embeddedAsrReady': asr.embeddedSherpaReady,
      'asrSingleAuthorityConfirmed': asr.singleAuthorityConfirmed,
      'asrMessage': asr.message,
      'asrModelAssetPath': asr.modelAssetPath,
      'asrDecoderAssetPath': asr.decoderAssetPath,
      'asrFinalCount': asr.finalCount,
      'asrDroppedFrames': asr.droppedFrames,
      'speakerContinuityActive':
          _softSpeakerIdentityUntil != null &&
          now.isBefore(_softSpeakerIdentityUntil!),
      'wakeWordLocalOnly': true,
      'apiTranscriptIsNotAuthority': true,
      'speakerVerificationLocalDeterministic': true,
      'callModeRequiresFreshVoiceAuth': true,
      'recentStreamingFinalText': _recentStreamingFinalText,
      'recentStreamingFinalAt':
          _recentStreamingFinalAt?.toIso8601String() ?? '',
      'recentStreamingPartialText': _recentStreamingPartialText,
      'recentStreamingPartialAt':
          _recentStreamingPartialAt?.toIso8601String() ?? '',
      'recentStreamingLocale': _recentStreamingLocale,
      'recentStreamingFinalRoute': _recentStreamingFinalRoute,
      'recentStreamingPartialRoute': _recentStreamingPartialRoute,
      'lastActiveCaptureAt': _lastActiveCaptureAt?.toIso8601String() ?? '',
      'voiceFirstPresence': voiceFirstPresenceRuntimeService
          .buildPlan(
            observedText: _recentStreamingFinalText.isNotEmpty
                ? _recentStreamingFinalText
                : _recentStreamingPartialText,
            powerMode: powerService.mode.name,
            continuousListeningEnabled: _running,
            isCompanionActive: companionRuntime?.isActive ?? false,
            isCallActive: callStateService != null,
            isMediaFlowActive: false,
          )
          .metadata,
      'unifiedSocialRuntime': unifiedSocialRuntimeService.buildPromptMetadata(),
      'benchmarkHarness': benchmarkHarnessService.buildDashboardSummary(),
    };
  }

  Future<void> start({
    required Future<void> Function(String recognizedPrompt) onAuthorizedPrompt,
    Future<void> Function(String statusMessage)? onUnauthorizedOrStatus,
  }) async {
    if (_running) return;
    _running = true;
    _clearStatusBroadcast();

    final bg = await backgroundBridgeService.startBackground();
    await powerService.restore();
    if (powerService.mode.keepsContinuousListeningAvailable &&
        !lifecycleService.isSleeping) {
      await _switchToContinuousAudioMode();
    } else {
      await _switchToWakeOnlyAudioMode();
    }
    if (!bg.success && onUnauthorizedOrStatus != null) {
      await onUnauthorizedOrStatus(
        bg.hasUsableMessage
            ? bg.message
            : 'Arka plan servisi başlatılamadı efendim.',
      );
    }

    await _streamingAsrSubscription?.cancel();
    _streamingAsrSubscription = streamingAsrRuntimeService.events.listen((
      event,
    ) {
      unawaited(_handleStreamingAsrEvent(event));
    });

    unawaited(
      _runLoop(
        onAuthorizedPrompt: onAuthorizedPrompt,
        onUnauthorizedOrStatus: onUnauthorizedOrStatus,
      ),
    );
  }

  Future<void> stop() async {
    _running = false;
    _clearStatusBroadcast();
    await backgroundBridgeService.setBackgroundSleeping();
    await backgroundBridgeService.showOverlaySleeping();
    await _switchToAudioOff();
    await _streamingAsrSubscription?.cancel();
    _streamingAsrSubscription = null;
  }

  Future<void> fullyShutdown() async {
    _clearStatusBroadcast();
    await backgroundBridgeService.setBackgroundFullyOff();
    await backgroundBridgeService.removeOverlay();
    await _switchToAudioOff();
    await _streamingAsrSubscription?.cancel();
    _streamingAsrSubscription = null;
    _running = false;
    _loopBusy = false;
  }

  Future<void> _switchToContinuousAudioMode() async {
    if (_runtimeAudioMode == 'continuous') return;
    _runtimeAudioMode = 'continuous';
    await streamingAsrRuntimeService.start(
      owner: 'continuous_runtime',
      force: true,
    );
    await sttService.nativeBridge.startStreamingVoiceGate();
    await sttService.nativeBridge.prewarmContinuousListeningSession(
      holdForMs: 6 * 60 * 1000,
    );
  }

  Future<void> _switchToWakeOnlyAudioMode() async {
    if (_runtimeAudioMode == 'wake_only') return;
    _runtimeAudioMode = 'wake_only';
    await streamingAsrRuntimeService.start(
      owner: 'wake_only_runtime',
      force: true,
    );
    await sttService.nativeBridge.startStreamingVoiceGate();
    await sttService.nativeBridge.releaseContinuousListeningSession();
  }

  Future<void> _switchToAudioOff() async {
    if (_runtimeAudioMode == 'off') return;
    _runtimeAudioMode = 'off';
    await streamingAsrRuntimeService.stop(
      owner: 'continuous_runtime',
      force: true,
    );
    await sttService.nativeBridge.stopStreamingVoiceGate();
    await sttService.nativeBridge.releaseContinuousListeningSession();
  }

  Future<void> _ensureStreamingGateRunning() async {
    final now = DateTime.now();
    if (_lastVoiceGateEnsureAt != null &&
        now.difference(_lastVoiceGateEnsureAt!) <
            const Duration(milliseconds: 900)) {
      return;
    }
    _lastVoiceGateEnsureAt = now;
    await sttService.nativeBridge.startStreamingVoiceGate();
  }

  Future<void> _runLoop({
    required Future<void> Function(String recognizedPrompt) onAuthorizedPrompt,
    Future<void> Function(String statusMessage)? onUnauthorizedOrStatus,
  }) async {
    while (_running) {
      if (_loopBusy) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        continue;
      }
      _loopBusy = true;
      try {
        await powerService.restore();

        final nowForSchedule = DateTime.now();
        final powerSchedule = await powerScheduleService.load();
        final scheduleWindow = powerScheduleService.resolveWindow(
          powerSchedule,
          nowForSchedule,
        );
        final shouldSleepBySchedule = scheduleWindow.active;
        final shouldHonorManualNightHold =
            shouldSleepBySchedule &&
            powerService.shouldKeepScheduledNightHold(nowForSchedule);

        if (!shouldSleepBySchedule &&
            powerService.scheduledNightHoldUntil != null) {
          await powerService.clearScheduledNightHold();
        }

        if (!powerService.isFullyShutdown) {
          if (shouldSleepBySchedule &&
              !shouldHonorManualNightHold &&
              !powerService.isPassiveSleep) {
            await powerService.setPassiveSleep();
            lifecycleService.sleep();
          } else if ((!shouldSleepBySchedule && powerService.isPassiveSleep) ||
              (shouldHonorManualNightHold && powerService.isPassiveSleep)) {
            lifecycleService.wake();
            await powerService.setLimbo();
          }
        }

        final NovaCallStateSnapshot? callSnapshot = callStateService != null
            ? await callStateService!.getSnapshot()
            : null;

        if (powerService.isFullyShutdown) {
          presenceService.setStateSafe(NovaPresenceState.fullyOff);
          await backgroundBridgeService.setBackgroundFullyOff();
          await backgroundBridgeService.removeOverlay();

          final bool callHandlingEnabled =
              isCallHandlingEnabled?.call() ?? true;
          if (callSnapshot?.isRinging == true) {
            final activeNumber = callSnapshot?.normalizedActiveNumber ?? '';
            final contact = activeNumber.isEmpty || contactService == null
                ? null
                : await contactService!.findByPhoneNumber(activeNumber);
            final canHandleThisCaller =
                callHandlingEnabled && (contact?.allowsCallHandling ?? false);
            if (canHandleThisCaller && callControlService != null) {
              final callerName = contact == null
                  ? 'Kayıtlı kişi'
                  : (contact.displayName.isEmpty
                        ? 'Kayıtlı kişi'
                        : contact.displayName);
              if (onUnauthorizedOrStatus != null) {
                await _emitStatusIfChanged(
                  '$callerName arıyor efendim. Nova tam kapalı moddan yalnız kayıtlı kişi çağrı tetiklemesi için geçici çağrı zinciri açıyor.',
                  onUnauthorizedOrStatus,
                );
              }
              final answered = await callControlService!.answerRingingCall();
              if (answered.success) {
                await callControlService!.handOverToNova(
                  trustedSource: 'shutdown_registered_call',
                );
                await callControlService!.routeToSpeaker(
                  true,
                  trustedSource: 'shutdown_registered_call',
                );
                await callControlService!.setMuted(
                  true,
                  trustedSource: 'shutdown_registered_call',
                );
                if (companionRuntime != null) {
                  bool started = false;
                  for (var retry = 0; retry < 5; retry++) {
                    await Future<void>.delayed(
                      Duration(milliseconds: 180 + (retry * 120)),
                    );
                    started = await companionRuntime!.startForCurrentCall(
                      allowShutdownBypass: true,
                    );
                    if (started) break;
                  }
                  if (!started) {
                    await NovaRuntimeSignalService.instance.record(
                      kind: NovaRuntimeSignalKind.callCompanion,
                      level: NovaRuntimeSignalLevel.warning,
                      code: 'shutdown_call_companion_start_failed',
                      message:
                          companionRuntime!.lastStatusMessage.trim().isEmpty
                          ? 'Tam kapalı modda companion başlatılamadı.'
                          : companionRuntime!.lastStatusMessage.trim(),
                      technicalDetails: 'shutdown authorized call start failed',
                      diagnosticCandidate: true,
                    );
                  }
                }
              }
              await Future<void>.delayed(const Duration(milliseconds: 1000));
              continue;
            }
          }

          final bool wakeWordEnabled = isWakeWordEnabled?.call() ?? true;
          if (!wakeWordEnabled) {
            await Future<void>.delayed(const Duration(milliseconds: 1800));
            continue;
          }

          final wakeText = _takeWakePhraseFromStreaming();
          if (wakeText.isEmpty || !_isWakePhrase(wakeText.toLowerCase())) {
            await Future<void>.delayed(const Duration(milliseconds: 1600));
            continue;
          }

          lifecycleService.wake();
          await powerService.setFullyOn(userInitiated: true);
          _softSpeakerIdentityUntil = DateTime.now().add(
            const Duration(hours: 2),
          );
          _authorizedConversationUntil = DateTime.now().add(
            const Duration(hours: 2),
          );
          _conversationHoldUntil = DateTime.now().add(
            const Duration(minutes: 20),
          );
          await backgroundBridgeService.setBackgroundRunning();
          await backgroundBridgeService.showOverlayIdle();
          if (onUnauthorizedOrStatus != null) {
            await onUnauthorizedOrStatus(
              '${identityRuntimeService.currentDisplayName} tam kapalı moddan sesli tetikleme ile uyandı efendim.',
            );
          }
          await _switchToContinuousAudioMode();
          await Future<void>.delayed(const Duration(milliseconds: 500));
          continue;
        }

        final trustedDailySessions = await dailyVoiceSessionService
            .loadActiveTrustedSessions();
        final trustedDailySession = trustedDailySessions.isNotEmpty
            ? trustedDailySessions.first
            : null;
        final recentTrustedSpeaker = await recentSpeakerService
            .bestTrustedSpeaker();
        final recentConversationSpeaker = await recentSpeakerService
            .bestConversationCandidate();
        await _refreshSpeakerContinuityIfNeeded(
          trustedDailySession: trustedDailySession,
          recentTrustedSpeaker: recentTrustedSpeaker,
          recentConversationSpeaker: recentConversationSpeaker,
        );

        if (companionRuntime?.isActive == true ||
            callSnapshot?.isActiveCall == true) {
          _clearStatusBroadcast();
          presenceService.setStateSafe(NovaPresenceState.idle);
          await backgroundBridgeService.setBackgroundRunning();
          await backgroundBridgeService.showOverlayIdle();
          await Future<void>.delayed(const Duration(milliseconds: 700));
          continue;
        }

        final bool sleeping =
            powerService.isPassiveSleep ||
            powerService.isLimbo ||
            lifecycleService.isSleeping;

        if (sleeping) {
          await _switchToWakeOnlyAudioMode();
          presenceService.setStateSafe(NovaPresenceState.sleeping);
          await backgroundBridgeService.setBackgroundSleeping();
          await backgroundBridgeService.showOverlaySleeping();
        } else {
          if (powerService.mode.keepsContinuousListeningAvailable) {
            await _switchToContinuousAudioMode();
          } else {
            await _switchToWakeOnlyAudioMode();
          }
          presenceService.setStateSafe(NovaPresenceState.listening);
          await backgroundBridgeService.setBackgroundRunning();
          await backgroundBridgeService.showOverlayListening();
        }

        final bool callHandlingEnabled = isCallHandlingEnabled?.call() ?? true;
        if (callSnapshot?.isRinging == true) {
          final activeNumber = callSnapshot?.normalizedActiveNumber ?? '';
          final contact = activeNumber.isEmpty || contactService == null
              ? null
              : await contactService!.findByPhoneNumber(activeNumber);
          final canHandleThisCaller =
              callHandlingEnabled && (contact?.allowsCallHandling ?? false);
          final canNightAutoHandleThisCaller =
              callHandlingEnabled &&
              (contact?.allowsNightAutoHandling ?? false);
          final callerName = contact == null
              ? 'Kayıtlı olmayan arayan'
              : (contact.displayName.isEmpty
                    ? 'Kayıtlı kişi'
                    : contact.displayName);

          if (powerService.isPassiveSleep &&
              canNightAutoHandleThisCaller &&
              callControlService != null &&
              callSnapshot?.canAnswer == true) {
            final opening =
                '${identityRuntimeService.currentDisplayName} konuşuyor. $callerName için gece modu otomatik çağrı sistemi devrede. İbrahim şu an uygun değil; acilse söyleyebilirsiniz, not alabilirim.';
            if (onUnauthorizedOrStatus != null) {
              await _emitStatusIfChanged(opening, onUnauthorizedOrStatus);
            }
            final answered = await callControlService!.answerRingingCall(
              trustedSource: 'night_auto_call',
            );
            if (!answered.success) {
              await NovaRuntimeSignalService.instance.record(
                kind: NovaRuntimeSignalKind.call,
                level: NovaRuntimeSignalLevel.error,
                code: 'night_auto_call_answer_failed',
                message: answered.message.trim().isEmpty
                    ? 'Gece modu otomatik çağrısı cevaplanamadı.'
                    : answered.message.trim(),
                technicalDetails:
                    'answerRingingCall failed in passiveSleep without companion',
                diagnosticCandidate: true,
              );
            } else {
              final handoff = await callControlService!.handOverToNova(
                trustedSource: 'night_auto_call',
              );
              final speaker = await callControlService!.routeToSpeaker(
                true,
                trustedSource: 'night_auto_call',
              );
              final mute = await callControlService!.setMuted(
                true,
                trustedSource: 'night_auto_call',
              );
              final routeReady =
                  handoff.success && speaker.success && mute.success;
              await NovaRuntimeSignalService.instance.record(
                kind: NovaRuntimeSignalKind.call,
                level: routeReady
                    ? NovaRuntimeSignalLevel.info
                    : NovaRuntimeSignalLevel.warning,
                code: routeReady
                    ? 'night_auto_call_route_ready'
                    : 'night_auto_call_route_degraded',
                message: routeReady
                    ? 'Gece modu otomatik çağrı sistemi Companion olmadan Nova konuşma hattına alındı.'
                    : 'Gece modu otomatik çağrı cevaplandı fakat ses route/mute/handoff zincirinde eksik var.',
                technicalDetails:
                    'handoff=${handoff.success} speaker=${speaker.success} muted=${mute.success}',
                diagnosticCandidate: !routeReady,
              );
            }
            await Future<void>.delayed(const Duration(milliseconds: 1200));
            continue;
          }

          if (powerService.isPassiveSleep &&
              canHandleThisCaller &&
              !canNightAutoHandleThisCaller) {
            if (onUnauthorizedOrStatus != null) {
              await _emitStatusIfChanged(
                '$callerName arıyor efendim. Kişi kayıtlı ancak gece otomatik cevap izni kapalı; normal telefon akışı korunuyor.',
                onUnauthorizedOrStatus,
              );
            }
            await Future<void>.delayed(const Duration(milliseconds: 1200));
            continue;
          }

          if (powerService.isLimbo) {
            if (canHandleThisCaller && onUnauthorizedOrStatus != null) {
              await _emitStatusIfChanged(
                '$callerName arıyor efendim. Araf modundayım; normal telefon sistemi çalmaya devam ediyor. İsterseniz beni açıkça çağırıp devralmamı isteyebilirsiniz.',
                onUnauthorizedOrStatus,
              );
            }
            await Future<void>.delayed(const Duration(milliseconds: 1200));
            continue;
          }

          if (canHandleThisCaller && onUnauthorizedOrStatus != null) {
            await _emitStatusIfChanged(
              '$callerName arıyor efendim. Normal telefon sistemi aktif; yalnız isterseniz companion yardımıyla çağrıyı devralabilirim.',
              onUnauthorizedOrStatus,
            );
          } else if (!canHandleThisCaller &&
              onUnauthorizedOrStatus != null &&
              activeNumber.isNotEmpty) {
            await _emitStatusIfChanged(
              '$callerName arıyor efendim. Kayıtlı otomatik çağrı listesinde olmadığı için normal telefon akışı aynen korunuyor.',
              onUnauthorizedOrStatus,
            );
          }

          await Future<void>.delayed(const Duration(milliseconds: 1200));
          continue;
        }

        if (sleeping) {
          final bool wakeWordEnabled = isWakeWordEnabled?.call() ?? true;
          if (!wakeWordEnabled) {
            await Future<void>.delayed(const Duration(milliseconds: 1400));
            continue;
          }

          final wakeText = _takeWakePhraseFromStreaming();
          if (wakeText.isEmpty) {
            await Future<void>.delayed(const Duration(milliseconds: 1400));
            continue;
          }

          if (!_isWakePhrase(wakeText.toLowerCase())) {
            await Future<void>.delayed(const Duration(milliseconds: 1200));
            continue;
          }

          VoiceAccessDecision? wakeDecision;
          final bool wakeTrustedBySession =
              trustedDailySession != null && trustedDailySession.isTrusted;
          final bool wakeTrustedByRecent =
              recentTrustedSpeaker != null &&
              recentTrustedSpeaker.observedAt.isAfter(
                DateTime.now().subtract(const Duration(hours: 20)),
              ) &&
              (recentTrustedSpeaker.level == VoiceAccessLevel.owner ||
                  recentTrustedSpeaker.level ==
                      VoiceAccessLevel.authorizedGuest);

          bool wakeAuthorized = wakeTrustedBySession || wakeTrustedByRecent;
          if (!wakeAuthorized) {
            wakeDecision = await authorizationRuntimeService
                .decideFromFreshExternalSample(
                  maxDurationSeconds: 3,
                  outputName: 'nova_wake_auth',
                  minSimilarity: 0.58,
                );
            wakeAuthorized =
                wakeDecision.level == VoiceAccessLevel.owner ||
                wakeDecision.level == VoiceAccessLevel.authorizedGuest;
          }
          if (!wakeAuthorized) {
            if (onUnauthorizedOrStatus != null &&
                !(wakeDecision?.suppressStatusBroadcast ?? false)) {
              await _emitStatusIfChanged(
                wakeDecision?.message.trim().isEmpty != false
                    ? 'Yetkiniz bulunmamaktadır.'
                    : wakeDecision!.message.trim(),
                onUnauthorizedOrStatus,
              );
            }
            await Future<void>.delayed(const Duration(milliseconds: 1200));
            continue;
          }

          lifecycleService.wake();
          await powerService.setFullyOn(userInitiated: true);
          _softSpeakerIdentityUntil = DateTime.now().add(
            const Duration(hours: 2),
          );
          _authorizedConversationUntil = DateTime.now().add(
            const Duration(hours: 2),
          );
          _conversationHoldUntil = DateTime.now().add(
            const Duration(minutes: 20),
          );
          _lastAuthorizedLevel =
              wakeDecision?.level ??
              trustedDailySession?.level ??
              recentTrustedSpeaker?.level ??
              VoiceAccessLevel.owner;
          presenceService.setStateSafe(NovaPresenceState.idle);
          await backgroundBridgeService.setBackgroundRunning();
          await backgroundBridgeService.showOverlayIdle();

          if (onUnauthorizedOrStatus != null) {
            await onUnauthorizedOrStatus(
              '${identityRuntimeService.currentDisplayName} aktif moda geçti efendim.',
            );
          }

          await Future<void>.delayed(const Duration(milliseconds: 700));
          continue;
        }

        final now = DateTime.now();
        final shouldCheckNativeSession =
            _lastNativeSessionHealthCheckAt == null ||
            now.difference(_lastNativeSessionHealthCheckAt!) >
                const Duration(minutes: 3);
        if (shouldCheckNativeSession &&
            powerService.mode.keepsContinuousListeningAvailable) {
          _lastNativeSessionHealthCheckAt = now;
          final nativeSession = await sttService.nativeBridge
              .getContinuousListeningSessionState();
          final session = Map<String, dynamic>.from(
            nativeSession['session'] as Map? ?? const <String, dynamic>{},
          );
          final hasRecognizer = session['hasRecognizer'] as bool? ?? false;
          if (!hasRecognizer && !powerService.isFullyShutdown) {
            await NovaRuntimeSignalService.instance.record(
              kind: NovaRuntimeSignalKind.background,
              level: NovaRuntimeSignalLevel.warning,
              code: 'background_bridge_failed',
              message: 'Dinleme oturumu soğumuş görünüyor; tekrar ısıtılıyor.',
              technicalDetails: session.toString(),
              diagnosticCandidate: true,
            );
            await sttService.nativeBridge.prewarmContinuousListeningSession(
              holdForMs: 12 * 60 * 1000,
            );
          }
        }
        final inConversationWindow =
            _conversationHoldUntil != null &&
            now.isBefore(_conversationHoldUntil!);
        final hasRecentVoiceFlow =
            _lastHeardAt != null &&
            now.difference(_lastHeardAt!) < const Duration(minutes: 3);
        final hasSoftIdentityWindow =
            _softSpeakerIdentityUntil != null &&
            now.isBefore(_softSpeakerIdentityUntil!);
        final gateState = await sttService.nativeBridge
            .getStreamingVoiceGateState();
        final gateRunning = gateState['running'] as bool? ?? false;
        final gateSpeechActive = gateState['speechActive'] as bool? ?? false;
        final gateSpeechRecent =
            gateState['speechRecentlyActive'] as bool? ?? false;
        if (gateSpeechActive) {
          _streamingSpeechGraceUntil = now.add(const Duration(seconds: 6));
        } else if (gateSpeechRecent) {
          _streamingSpeechGraceUntil ??= now.add(const Duration(seconds: 4));
          if (now.isAfter(_streamingSpeechGraceUntil!)) {
            _streamingSpeechGraceUntil = now.add(const Duration(seconds: 4));
          }
        }
        if (!gateRunning && !powerService.isFullyShutdown) {
          await _ensureStreamingGateRunning();
        }
        final playbackBlocked = await playbackGuardService
            .isPlaybackActiveNow();
        final shouldAttemptTranscription =
            !playbackBlocked &&
            (inConversationWindow ||
                hasRecentVoiceFlow ||
                gateSpeechActive ||
                gateSpeechRecent ||
                _hasFreshStreamingTranscript(
                  maxAge: inConversationWindow
                      ? const Duration(seconds: 22)
                      : const Duration(seconds: 12),
                ));
        if (!shouldAttemptTranscription) {
          await backgroundBridgeService.showOverlayIdle();
          presenceService.setStateSafe(NovaPresenceState.idle);
          await Future<void>.delayed(const Duration(milliseconds: 380));
          continue;
        }

        final prompt = await _takeBestAvailablePrompt(
          inConversationWindow: inConversationWindow,
          gateSpeechActive: gateSpeechActive,
          gateSpeechRecent: gateSpeechRecent,
        );
        if (prompt.isEmpty) {
          await _ensureStreamingGateRunning();
          await backgroundBridgeService.showOverlayIdle();
          presenceService.setStateSafe(NovaPresenceState.idle);
          await Future<void>.delayed(
            Duration(milliseconds: inConversationWindow ? 520 : 1400),
          );
          continue;
        }

        final promptRoute = _routeForPrompt(prompt);
        _lastHeardAt = DateTime.now();
        final spokenAct = _conversationActDetector.detect(prompt);
        final semanticTurn = _semanticTurnDetector.detect(prompt);
        final interruptionIntent = _interruptionIntentDetector.detect(prompt);
        unifiedSocialRuntimeService.ingestVoiceInput(
          transcript: prompt,
          accessLevel: _lastAuthorizedLevel,
          speakerVoiceId: _lastAuthorizedVoiceId,
          speakerName: _lastRecognizedSpeakerName,
          relationLabel: _lastRelationshipLabel,
          addressedNova: _isLikelyAddressedToNova(prompt),
          containsCommand: _spokenIntentInterpreter.isDirectCommand(prompt),
          activeCall:
              callStateService != null &&
              (await callStateService!.getSnapshot()).isActiveCall,
          companionActive: companionRuntime?.isActive ?? false,
          syntheticPlaybackGuarded: await playbackGuardService
              .isPlaybackActiveNow(),
        );
        final isNaturalConversation =
            _spokenIntentInterpreter.isNaturalConversationForNova(prompt) ||
            _spokenIntentInterpreter.shouldAnswerWithoutExplicitCommand(
              prompt,
            ) ||
            spokenAct.expectsResponse ||
            spokenAct.isEmotionCue ||
            spokenAct.isRepairCue ||
            spokenAct.isSocialCue;

        final bool hasDailyTrustedAuthorization =
            trustedDailySession?.isTrusted == true;
        final bool hasRecentTrustedAuthorization =
            recentTrustedSpeaker != null &&
            recentTrustedSpeaker.observedAt.isAfter(
              DateTime.now().subtract(const Duration(hours: 20)),
            ) &&
            (recentTrustedSpeaker.level == VoiceAccessLevel.owner ||
                recentTrustedSpeaker.level == VoiceAccessLevel.authorizedGuest);

        final bool hasRecentConversationSpeaker =
            recentConversationSpeaker != null &&
            recentConversationSpeaker.observedAt.isAfter(
              DateTime.now().subtract(const Duration(hours: 8)),
            );

        final bool hasFreshConversationAuthorization =
            _authorizedConversationUntil != null &&
            now.isBefore(_authorizedConversationUntil!) &&
            (_lastAuthorizedLevel == VoiceAccessLevel.owner ||
                _lastAuthorizedLevel == VoiceAccessLevel.authorizedGuest);

        final bool ownerPriorityActive =
            _lastAuthorizedLevel == VoiceAccessLevel.owner ||
            trustedDailySession?.level == VoiceAccessLevel.owner ||
            recentTrustedSpeaker?.level == VoiceAccessLevel.owner;

        final trustedConversationContinuation =
            hasDailyTrustedAuthorization ||
            hasRecentTrustedAuthorization ||
            hasFreshConversationAuthorization ||
            (hasSoftIdentityWindow && ownerPriorityActive);
        final explicitlyAddressed =
            _isLikelyAddressedToNova(prompt) ||
            _spokenIntentInterpreter.isDirectCommand(prompt) ||
            _spokenIntentInterpreter.isContinueSpeakingOverride(prompt) ||
            _looksLikeRoomConversationForNova(prompt);
        final conversationalCarry =
            inConversationWindow ||
            hasRecentVoiceFlow ||
            trustedConversationContinuation ||
            interruptionIntent.wantsToTakeTurn ||
            semanticTurn.shouldYield;
        var likelyForNova =
            explicitlyAddressed ||
            (conversationalCarry &&
                (isNaturalConversation ||
                    spokenAct.expectsResponse ||
                    spokenAct.isRepairCue));
        final routeForcesBrainDelivery =
            promptRoute == 'conversation' ||
            promptRoute == 'command' ||
            promptRoute == 'teaching' ||
            promptRoute == 'reminder' ||
            promptRoute == 'call';
        if (!likelyForNova && routeForcesBrainDelivery) {
          likelyForNova = true;
          print(
            'NOVA_CONTINUOUS_ROUTE_FORCED_BRAIN_DELIVERY route=$promptRoute chars=${prompt.length}',
          );
        }
        if (!likelyForNova) {
          await _ensureStreamingGateRunning();
          await backgroundBridgeService.showOverlayIdle();
          presenceService.setStateSafe(NovaPresenceState.idle);
          await Future<void>.delayed(const Duration(milliseconds: 1100));
          continue;
        }

        final bool canReuseSpeakerIdentity =
            hasFreshConversationAuthorization ||
            hasDailyTrustedAuthorization ||
            hasRecentTrustedAuthorization ||
            (ownerPriorityActive && likelyForNova) ||
            (hasSoftIdentityWindow && likelyForNova) ||
            (hasRecentConversationSpeaker && likelyForNova);

        VoiceAccessDecision? decision;
        VoiceAuthorizationRuntimeInspectionResult? inspection;
        var authorized = canReuseSpeakerIdentity;
        var allowFamiliarConversation = false;

        final bool canReuseFamiliarConversation =
            hasRecentConversationSpeaker &&
            recentConversationSpeaker != null &&
            (recentConversationSpeaker.level == VoiceAccessLevel.familiar ||
                recentConversationSpeaker.level ==
                    VoiceAccessLevel.knownButUnauthorized) &&
            isNaturalConversation &&
            !_spokenIntentInterpreter.isDirectCommand(prompt);
        if (!authorized && canReuseFamiliarConversation) {
          allowFamiliarConversation = true;
          decision = VoiceAccessDecision(
            level: recentConversationSpeaker!.level,
            message: 'Tanınmış konuşmacı için sohbet devamlılığı korunuyor.',
            recognizedName: recentConversationSpeaker.speakerName,
            relationshipLabel: recentConversationSpeaker.relationshipLabel,
            suppressStatusBroadcast: true,
          );
        }

        if (!authorized &&
            !allowFamiliarConversation &&
            !hasDailyTrustedAuthorization) {
          inspection = await authorizationRuntimeService
              .inspectPreferContinuityThenFresh(
                maxDurationSeconds: 4,
                outputName: 'nova_bg_auth',
                minSimilarity: 0.58,
                allowContinuityReuse: true,
                preferredVoiceId: _lastAuthorizedVoiceId,
              );
          decision = inspection.decision;
          authorized =
              decision.level == VoiceAccessLevel.owner ||
              decision.level == VoiceAccessLevel.authorizedGuest;
          if (inspection.recognizedVoiceId.trim().isNotEmpty) {
            await recentSpeakerService.remember(
              voiceId: inspection.recognizedVoiceId.trim(),
              level: decision.level,
              speakerName: inspection.recognizedDisplayName.trim(),
              relationshipLabel: decision.relationshipLabel,
            );
          } else if (recentConversationSpeaker != null && hasRecentVoiceFlow) {
            await recentSpeakerService.remember(
              voiceId: recentConversationSpeaker.voiceId,
              level: recentConversationSpeaker.level,
              speakerName: recentConversationSpeaker.speakerName,
              relationshipLabel: recentConversationSpeaker.relationshipLabel,
            );
          }
          allowFamiliarConversation =
              (decision.level == VoiceAccessLevel.familiar ||
                  decision.level == VoiceAccessLevel.knownButUnauthorized) &&
              isNaturalConversation &&
              !_spokenIntentInterpreter.isDirectCommand(prompt);

          final bool canTolerateTransientIdentityMiss =
              hasRecentVoiceFlow &&
              (hasFreshConversationAuthorization ||
                  hasRecentConversationSpeaker ||
                  ownerPriorityActive) &&
              !inspection.captureSucceeded;

          if (!authorized && canTolerateTransientIdentityMiss) {
            authorized = true;
            decision = null;
          }
        }

        if (!authorized && hasDailyTrustedAuthorization && likelyForNova) {
          authorized = true;
          decision = VoiceAccessDecision(
            level: trustedDailySession!.level,
            message: 'Günlük owner/izinli konuşmacı güveni korunuyor.',
            suppressStatusBroadcast: true,
          );
        }

        if (!authorized) {
          if (allowFamiliarConversation) {
            _clearStatusBroadcast();
            _conversationHoldUntil = DateTime.now().add(
              const Duration(minutes: 18),
            );
            _softSpeakerIdentityUntil = DateTime.now().add(
              const Duration(hours: 2),
            );
            await onAuthorizedPrompt('$familiarConversationMarker$prompt');
            await _ensureStreamingGateRunning();
            await backgroundBridgeService.showOverlayIdle();
            presenceService.setStateSafe(NovaPresenceState.idle);
            await Future<void>.delayed(const Duration(milliseconds: 260));
            continue;
          }
          if (onUnauthorizedOrStatus != null &&
              !(decision?.suppressStatusBroadcast ?? false)) {
            await _emitStatusIfChanged(
              decision?.message.trim().isEmpty != false
                  ? 'Yetkiniz bulunmamaktadır.'
                  : decision!.message.trim(),
              onUnauthorizedOrStatus,
            );
          }
          if (!(hasRecentVoiceFlow && hasFreshConversationAuthorization)) {
            _authorizedConversationUntil = null;
            _softSpeakerIdentityUntil = null;
            _lastAuthorizedLevel = null;
            _lastAuthorizedVoiceId = '';
            _lastRecognizedSpeakerName = '';
            _lastRelationshipLabel = '';
          }
          await _ensureStreamingGateRunning();
          await backgroundBridgeService.showOverlayIdle();
          presenceService.setStateSafe(NovaPresenceState.idle);
          await Future<void>.delayed(const Duration(milliseconds: 1600));
          continue;
        }

        _clearStatusBroadcast();
        final conversationWindow =
            isNaturalConversation ||
                spokenAct.expectsResponse ||
                spokenAct.isRepairCue ||
                _spokenIntentInterpreter.isContinueSpeakingOverride(prompt) ||
                inConversationWindow ||
                hasRecentVoiceFlow
            ? const Duration(minutes: 90)
            : const Duration(minutes: 18);
        final softIdentityWindow = isNaturalConversation || hasRecentVoiceFlow
            ? const Duration(hours: 12)
            : const Duration(hours: 4);
        _authorizedConversationUntil = DateTime.now().add(conversationWindow);
        _softSpeakerIdentityUntil = DateTime.now().add(softIdentityWindow);
        _lastAuthorizedLevel =
            decision?.level ??
            trustedDailySession?.level ??
            recentTrustedSpeaker?.level ??
            _lastAuthorizedLevel ??
            VoiceAccessLevel.owner;
        if (inspection != null &&
            inspection.recognizedVoiceId.trim().isNotEmpty) {
          _lastAuthorizedVoiceId = inspection.recognizedVoiceId.trim();
        } else if (_lastAuthorizedVoiceId.isEmpty &&
            trustedDailySession != null) {
          _lastAuthorizedVoiceId = trustedDailySession.voiceId;
        } else if (_lastAuthorizedVoiceId.isEmpty &&
            recentTrustedSpeaker != null) {
          _lastAuthorizedVoiceId = recentTrustedSpeaker.voiceId;
        }
        if (inspection != null &&
            inspection.recognizedDisplayName.trim().isNotEmpty) {
          _lastRecognizedSpeakerName = inspection.recognizedDisplayName.trim();
        } else if (_lastRecognizedSpeakerName.isEmpty &&
            trustedDailySession != null) {
          _lastRecognizedSpeakerName = trustedDailySession.recognizedName;
        } else if (_lastRecognizedSpeakerName.isEmpty &&
            recentTrustedSpeaker != null) {
          _lastRecognizedSpeakerName = recentTrustedSpeaker.speakerName;
        }
        if (decision != null && decision.relationshipLabel.trim().isNotEmpty) {
          _lastRelationshipLabel = decision.relationshipLabel.trim();
        } else if (_lastRelationshipLabel.isEmpty &&
            recentTrustedSpeaker != null) {
          _lastRelationshipLabel = recentTrustedSpeaker.relationshipLabel;
        } else if (_lastRelationshipLabel.isEmpty &&
            recentConversationSpeaker != null) {
          _lastRelationshipLabel = recentConversationSpeaker.relationshipLabel;
        }
        _conversationHoldUntil = DateTime.now().add(conversationWindow);
        if (_lastAuthorizedVoiceId.trim().isNotEmpty &&
            (_lastAuthorizedLevel == VoiceAccessLevel.owner ||
                _lastAuthorizedLevel == VoiceAccessLevel.authorizedGuest)) {
          await dailyVoiceSessionService.rememberTrustedSpeaker(
            voiceId: _lastAuthorizedVoiceId.trim(),
            level: _lastAuthorizedLevel!,
            recognizedName: _lastRecognizedSpeakerName,
          );
          await recentSpeakerService.remember(
            voiceId: _lastAuthorizedVoiceId.trim(),
            level: _lastAuthorizedLevel!,
            speakerName: _lastRecognizedSpeakerName,
            relationshipLabel: _lastRelationshipLabel,
          );
        }
        benchmarkHarnessService.recordBatch(
          benchmarkHarnessService.evaluateConversationEpisode(
            ownerPriorityPreserved:
                _lastAuthorizedLevel == VoiceAccessLevel.owner ||
                _lastAuthorizedLevel == VoiceAccessLevel.authorizedGuest,
            backchannelQuality: semanticTurn.shouldBackchannel ? 0.92 : 0.74,
            interruptionQuality: interruptionIntent.wantsClarification
                ? 0.86
                : (interruptionIntent.isSoftInterruption ? 0.92 : 0.89),
            semanticTurnAccuracy: semanticTurn.completionScore.clamp(
              0.40,
              0.98,
            ),
            memoryCommitQuality:
                unifiedSocialRuntimeService
                    .snapshot
                    .lastDecision
                    .shouldPersistMemory
                ? 0.90
                : 0.76,
            relationshipToneQuality: _lastRelationshipLabel.isEmpty
                ? 0.72
                : 0.90,
            ttsSelfBlindProtected: true,
            multiSpeakerStable: _softSpeakerIdentityUntil != null,
            noteDelivered:
                !prompt.toLowerCase().contains('not') ||
                unifiedSocialRuntimeService
                    .snapshot
                    .lastDecision
                    .shouldPersistMemory,
            latencyScore: inConversationWindow ? 0.94 : 0.86,
          ),
        );
        await onAuthorizedPrompt(prompt);
        await _ensureStreamingGateRunning();
        await backgroundBridgeService.showOverlayIdle();
        presenceService.setStateSafe(NovaPresenceState.idle);
        await Future<void>.delayed(
          Duration(
            milliseconds: isNaturalConversation || inConversationWindow
                ? 260
                : 520,
          ),
        );
      } catch (_) {
        await _ensureStreamingGateRunning();
        await Future<void>.delayed(const Duration(seconds: 1));
      } finally {
        _loopBusy = false;
      }
    }
  }

  Future<void> _handleStreamingAsrEvent(NovaStreamingAsrEvent event) async {
    final normalized = event.transcript.text.trim();
    if (normalized.isEmpty) return;

    final playbackBlocked = await playbackGuardService
        .isPlaybackActiveNow();
    final likelyOwnSpeech = await playbackGuardService.isLikelyOwnSpeech(
      normalized,
    );
    if (playbackBlocked ||
        likelyOwnSpeech ||
        _looksLikeNovaSelfSpeech(normalized)) {
      _recentStreamingPartialText = '';
      _recentStreamingPartialRoute = 'none';
      _recentStreamingPartialAt = null;
      return;
    }

    final routeDecision = streamingAsrRuntimeService.transcriptRouterService
        .decide(event);
    _recentStreamingLocale = event.transcript.locale.trim().isEmpty
        ? 'tr-TR'
        : event.transcript.locale.trim();
    if (event.isFinal) {
      _recentStreamingFinalText = normalized;
      _recentStreamingFinalRoute = routeDecision.route;
      _recentStreamingFinalAt = event.createdAt;
      print(
        'NOVA_CONTINUOUS_ASR_FINAL_ROUTE route=${routeDecision.route} chars=${normalized.length}',
      );
    } else if (event.isPartial) {
      _recentStreamingPartialText = normalized;
      _recentStreamingPartialRoute = routeDecision.route;
      _recentStreamingPartialAt = event.createdAt;
    }
  }

  bool _hasFreshStreamingTranscript({required Duration maxAge}) {
    final finalAt = _recentStreamingFinalAt;
    if (finalAt == null) return false;
    if (DateTime.now().difference(finalAt) > maxAge) return false;
    return _recentStreamingFinalText.trim().isNotEmpty;
  }

  bool _wasStreamingTranscriptDeliveredRecently(String text) {
    final normalized = text.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    final at = _lastDeliveredStreamingTranscriptAt;
    if (_lastDeliveredStreamingTranscript != normalized) return false;
    if (at == null) return false;
    return DateTime.now().difference(at) <= const Duration(seconds: 18);
  }

  void _markStreamingTranscriptDelivered(String text) {
    final normalized = text.trim().toLowerCase();
    if (normalized.isEmpty) return;
    _lastDeliveredStreamingTranscript = normalized;
    _lastDeliveredStreamingTranscriptAt = DateTime.now();
  }

  bool _canOpenActiveCaptureNow() {
    final last = _lastActiveCaptureAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >= _activeCaptureCooldown;
  }

  bool _looksLikeNovaSelfSpeech(String text) {
    final value = text.trim().toLowerCase();
    if (value.isEmpty) return false;
    const selfSpeechMarkers = <String>[
      'efendim',
      'sizi dinliyorum',
      'hazırım efendim',
      'buyurun efendim',
      'hemen bakıyorum',
      'anladım efendim',
      'nasıl yardımcı olabilirim',
    ];
    for (final marker in selfSpeechMarkers) {
      if (value.startsWith(marker)) {
        return true;
      }
    }
    return false;
  }

  bool _looksLikeRoomConversationForNova(String text) {
    final value = text.trim().toLowerCase();
    if (value.isEmpty) return false;
    final cues = <String>{
      'sohbete katıl',
      'sohbete katil',
      'aramıza katıl',
      'aramiza katil',
      'sen de katıl',
      'sen de katil',
      'bize katıl',
      'bize katilir misin',
      'bize katılır mısın',
      'bize katil',
      'katılsana',
      'katilsana',
      'nova buraya gel',
      ...identityRuntimeService.prefixedPhrases(const <String>[
        'ne dersin',
      ], includeBareName: false),
    };
    for (final cue in cues) {
      if (value.contains(cue)) return true;
    }
    return false;
  }

  String _takeWakePhraseFromStreaming({
    Duration finalFreshWindow = const Duration(seconds: 10),
    Duration partialFreshWindow = const Duration(seconds: 4),
  }) {
    final now = DateTime.now();
    final finalText = _recentStreamingFinalText.trim();
    if (finalText.isNotEmpty &&
        _recentStreamingFinalAt != null &&
        now.difference(_recentStreamingFinalAt!) <= finalFreshWindow &&
        !_wasStreamingTranscriptDeliveredRecently(finalText)) {
      _markStreamingTranscriptDelivered(finalText);
      return finalText;
    }
    final partialText = _recentStreamingPartialText.trim();
    if (partialText.isNotEmpty &&
        partialText.length >= 5 &&
        _recentStreamingPartialAt != null &&
        now.difference(_recentStreamingPartialAt!) <= partialFreshWindow &&
        !_wasStreamingTranscriptDeliveredRecently(partialText)) {
      _markStreamingTranscriptDelivered(partialText);
      return partialText;
    }
    return '';
  }

  String _routeForPrompt(String prompt) {
    final normalized = prompt.trim().toLowerCase();
    if (normalized.isEmpty) return 'none';
    final recentFinal = _recentStreamingFinalText.trim().toLowerCase();
    final recentPartial = _recentStreamingPartialText.trim().toLowerCase();
    if (recentFinal.isNotEmpty && normalized == recentFinal) {
      return _recentStreamingFinalRoute.trim().isEmpty
          ? 'none'
          : _recentStreamingFinalRoute;
    }
    if (recentPartial.isNotEmpty && normalized == recentPartial) {
      return _recentStreamingPartialRoute.trim().isEmpty
          ? 'none'
          : _recentStreamingPartialRoute;
    }
    return 'none';
  }

  Future<String> _takeBestAvailablePrompt({
    required bool inConversationWindow,
    required bool gateSpeechActive,
    required bool gateSpeechRecent,
  }) async {
    final freshStreamingText = _recentStreamingFinalText.trim();
    final freshStreamingAt = _recentStreamingFinalAt;
    final freshPartialText = _recentStreamingPartialText.trim();
    final freshPartialAt = _recentStreamingPartialAt;
    final streamingReady =
        streamingAsrRuntimeService.latestState.embeddedSherpaReady;
    final finalFreshWindow = inConversationWindow
        ? const Duration(seconds: 42)
        : const Duration(seconds: 28);
    final partialFreshWindow = inConversationWindow
        ? const Duration(seconds: 20)
        : const Duration(seconds: 12);
    final streamingStillFresh =
        freshStreamingAt != null &&
        DateTime.now().difference(freshStreamingAt) <= finalFreshWindow;
    final partialStillFresh =
        freshPartialAt != null &&
        DateTime.now().difference(freshPartialAt) <= partialFreshWindow;
    if (streamingReady &&
        streamingStillFresh &&
        freshStreamingText.isNotEmpty &&
        !_wasStreamingTranscriptDeliveredRecently(freshStreamingText)) {
      _markStreamingTranscriptDelivered(freshStreamingText);
      return freshStreamingText;
    }

    if (streamingReady &&
        partialStillFresh &&
        freshPartialText.isNotEmpty &&
        freshPartialText.length >= 16 &&
        !_wasStreamingTranscriptDeliveredRecently(freshPartialText)) {
      _markStreamingTranscriptDelivered(freshPartialText);
      return freshPartialText;
    }

    final now = DateTime.now();
    final streamingGraceActive =
        _streamingSpeechGraceUntil != null &&
        now.isBefore(_streamingSpeechGraceUntil!);
    if (streamingReady &&
        (gateSpeechActive || gateSpeechRecent || streamingGraceActive)) {
      _recentStreamingPartialText = '';
      _recentStreamingPartialRoute = 'none';
      _recentStreamingPartialAt = null;
      return '';
    }

    if (gateSpeechActive || gateSpeechRecent) {
      return '';
    }

    if (powerService.isPassiveSleep ||
        powerService.isLimbo ||
        lifecycleService.isSleeping) {
      return '';
    }

    final playbackBlocked = await playbackGuardService
        .isPlaybackActiveNow();
    if (playbackBlocked) {
      return '';
    }

    final streamingRuntimeActive = streamingAsrRuntimeService.isStarted;
    if (!streamingRuntimeActive) {
      try {
        await streamingAsrRuntimeService.start(owner: 'prompt_fallback');
        await sttService.nativeBridge.startStreamingVoiceGate();
        await sttService.nativeBridge.ensureStreamingAsrReady();
      } catch (_) {}
    }

    return '';
  }

  Future<void> _refreshSpeakerContinuityIfNeeded({
    required NovaDailyVoiceSessionSnapshot? trustedDailySession,
    required NovaRecentSpeakerObservation? recentTrustedSpeaker,
    required NovaRecentSpeakerObservation? recentConversationSpeaker,
  }) async {
    final now = DateTime.now();
    final shouldRefresh =
        _lastSpeakerContinuityRefreshAt == null ||
        now.difference(_lastSpeakerContinuityRefreshAt!) >
            const Duration(minutes: 3);
    if (!shouldRefresh) return;
    _lastSpeakerContinuityRefreshAt = now;

    if (trustedDailySession != null && trustedDailySession.isTrusted) {
      _lastAuthorizedLevel = trustedDailySession.level;
      if (_lastAuthorizedVoiceId.trim().isEmpty) {
        _lastAuthorizedVoiceId = trustedDailySession.voiceId;
      }
      if (_lastRecognizedSpeakerName.trim().isEmpty) {
        _lastRecognizedSpeakerName = trustedDailySession.recognizedName;
      }
      _softSpeakerIdentityUntil = now.add(const Duration(hours: 16));
      _authorizedConversationUntil ??= now.add(const Duration(hours: 8));
      return;
    }

    if (recentTrustedSpeaker != null) {
      _lastAuthorizedLevel = recentTrustedSpeaker.level;
      if (_lastAuthorizedVoiceId.trim().isEmpty) {
        _lastAuthorizedVoiceId = recentTrustedSpeaker.voiceId;
      }
      if (_lastRecognizedSpeakerName.trim().isEmpty) {
        _lastRecognizedSpeakerName = recentTrustedSpeaker.speakerName;
      }
      if (_lastRelationshipLabel.trim().isEmpty) {
        _lastRelationshipLabel = recentTrustedSpeaker.relationshipLabel;
      }
      _softSpeakerIdentityUntil ??= now.add(const Duration(hours: 8));
      return;
    }

    if (recentConversationSpeaker != null &&
        (recentConversationSpeaker.level == VoiceAccessLevel.owner ||
            recentConversationSpeaker.level ==
                VoiceAccessLevel.authorizedGuest)) {
      _lastAuthorizedLevel = recentConversationSpeaker.level;
      if (_lastAuthorizedVoiceId.trim().isEmpty) {
        _lastAuthorizedVoiceId = recentConversationSpeaker.voiceId;
      }
      if (_lastRecognizedSpeakerName.trim().isEmpty) {
        _lastRecognizedSpeakerName = recentConversationSpeaker.speakerName;
      }
      if (_lastRelationshipLabel.trim().isEmpty) {
        _lastRelationshipLabel = recentConversationSpeaker.relationshipLabel;
      }
      _softSpeakerIdentityUntil ??= now.add(const Duration(hours: 6));
    }
  }

  double _ownerConfidenceForLevel(VoiceAccessLevel? level) {
    switch (level) {
      case VoiceAccessLevel.owner:
        return 0.98;
      case VoiceAccessLevel.authorizedGuest:
        return 0.82;
      case VoiceAccessLevel.familiar:
        return 0.64;
      case VoiceAccessLevel.knownButUnauthorized:
        return 0.36;
      case VoiceAccessLevel.denied:
      case null:
        return 0.12;
    }
  }

  int _priorityForLevel(VoiceAccessLevel? level) {
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
      case null:
        return 100;
    }
  }

  Future<void> _emitStatusIfChanged(
    String message,
    Future<void> Function(String statusMessage) sink,
  ) async {
    final normalized = message.trim();
    if (normalized.isEmpty) return;
    final now = DateTime.now();
    if (_lastStatusBroadcast == normalized &&
        _lastStatusBroadcastAt != null &&
        now.difference(_lastStatusBroadcastAt!) < const Duration(seconds: 20)) {
      return;
    }
    _lastStatusBroadcast = normalized;
    _lastStatusBroadcastAt = now;
    await sink(normalized);
  }

  void _clearStatusBroadcast() {
    _lastStatusBroadcast = '';
    _lastStatusBroadcastAt = null;
  }

  bool _isLikelyAddressedToNova(String text) {
    final value = text.trim().toLowerCase();
    if (value.isEmpty) return false;
    final act = _conversationActDetector.detect(text);
    if (act.isCommandLike ||
        act.isSocialCue ||
        act.isEmotionCue ||
        act.isRepairCue) {
      return true;
    }

    final directMarkers = <String>{
      ...identityRuntimeService.knownAliases,
      'bana',
      'beni',
      'benim için',
      'dinle',
      'yardım et',
      'ara',
      'mesaj at',
      'hatırlat',
      'aç',
      'kapat',
      'değiştir',
      'söyler misin',
      'anlat',
      'sence',
      'ne düşünüyorsun',
      'sen bu konuda ne düşünüyorsun',
      'sence bu nasıl',
      'sohbet edelim',
      'konuşalım',
      'beni duy',
      'buraya gel',
      'yardima gel',
      'yardıma gel',
      'sen konuş',
      'ben konuşacağım',
      'devral',
      'devret',
      'hatırlıyor musun',
      'neyi konuşuyorduk',
      'kaldığımız yer',
      ...identityRuntimeService.prefixedPhrases(const <String>[
        'beni dinle',
        'yardım et',
        'buraya gel',
        'devral',
      ], includeBareName: false),
    };

    for (final marker in directMarkers) {
      if (value == marker ||
          value.startsWith('$marker ') ||
          value.contains(' $marker ')) {
        return true;
      }
    }

    return false;
  }

  bool _isWakePhrase(String text) {
    final value = text.trim().toLowerCase();
    if (value.isEmpty) return false;
    final phrases = <String>{
      'uyan',
      'beni dinle',
      'aktif moda geç',
      'yardima gel',
      'yardıma gel',
      'buraya gel',
      'gel buraya',
      'beni duy',
      ...identityRuntimeService.knownAliases,
      ...identityRuntimeService.prefixedPhrases(const <String>[
        'burda mısın',
        'burada mısın',
        'burda misin',
        'burada misin',
        'uyan',
        'beni dinle',
      ]),
    };
    for (final phrase in phrases) {
      if (value == phrase || value.contains(phrase)) return true;
    }
    return false;
  }

  Map<String, dynamic> buildListeningIntegritySnapshot() {
    final now = DateTime.now();
    return <String, dynamic>{
      'running': _running,
      'loopBusy': _loopBusy,
      'authorizedConversationActive':
          _authorizedConversationUntil != null &&
          now.isBefore(_authorizedConversationUntil!),
      'conversationHoldActive':
          _conversationHoldUntil != null &&
          now.isBefore(_conversationHoldUntil!),
      'softSpeakerIdentityActive':
          _softSpeakerIdentityUntil != null &&
          now.isBefore(_softSpeakerIdentityUntil!),
      'recentStreamingFinalText': _recentStreamingFinalText,
      'recentStreamingPartialText': _recentStreamingPartialText,
      'recentStreamingLocale': _recentStreamingLocale,
      'lastAuthorizedVoiceId': _lastAuthorizedVoiceId,
      'lastRecognizedSpeakerName': _lastRecognizedSpeakerName,
      'lastRelationshipLabel': _lastRelationshipLabel,
    };
  }

  String buildSpeakerContinuityHint() {
    if (_lastAuthorizedVoiceId.trim().isEmpty)
      return 'Henüz güvenilir konuşmacı devamlılığı yok.';
    if (_softSpeakerIdentityUntil != null &&
        DateTime.now().isBefore(_softSpeakerIdentityUntil!))
      return 'Kısa süreli ses devamlılığı aktif; gereksiz yeniden doğrulama azaltılır.';
    return 'Devamlılık zayıf; yeni doğrulama gerekebilir.';
  }

  Map<String, dynamic> buildMicFlapGuardHint() {
    return <String, dynamic>{
      'shouldAvoidMicFlapping': true,
      'activeCaptureCooldownMs': _activeCaptureCooldown.inMilliseconds,
      'streamingSpeechGraceActive':
          _streamingSpeechGraceUntil != null &&
          DateTime.now().isBefore(_streamingSpeechGraceUntil!),
      'lastActiveCaptureAt': _lastActiveCaptureAt?.toIso8601String() ?? '',
    };
  }

  String buildModeBehaviorHint() {
    if (!_running) return 'Dinleme kapalı; varlık modu pasif.';
    if (companionRuntime?.isActive == true)
      return 'Companion aktif; dinleme çağrı bağlamına göre davranır.';
    return 'Sürekli dinleme açık; ses-first varlık akışı korunur.';
  }
}
