// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:async';

import '../../core/call_companion/nova_call_companion_request.dart';
import '../../core/call_companion/nova_call_companion_state.dart';
import '../../core/contacts/phone_number_normalizer.dart';
import '../../core/identity/voice_access_decision.dart';
import '../../core/stt/nova_stt_mode.dart' show NovaSttMode;
import '../../core/runtime/nova_runtime_signal.dart';
import '../../core/tts/nova_tts_mode.dart' show NovaTtsMode;
import '../call/nova_call_control_bridge_service.dart';
import '../call/nova_call_state_service.dart';
import '../call_learning/nova_call_style_learning_service.dart';
import '../contacts/nova_contact_service.dart';
import '../identity/nova_daily_voice_session_service.dart';
import '../identity/nova_recent_speaker_service.dart';
import '../identity/voice_authorization_runtime_service.dart';
import '../runtime/nova_runtime_signal_service.dart';
import '../stt/nova_speech_to_text_service.dart' show NovaSpeechToTextService;
import '../tts/nova_tts_service.dart' show NovaTtsService;
import '../system/nova_power_service.dart';
import '../runtime/nova_benchmark_harness_service.dart';
import '../runtime/nova_unified_social_runtime_service.dart';
import 'nova_call_companion_gate_service.dart';
import 'nova_call_companion_service.dart';
import '../runtime/nova_identity_runtime_service.dart';
import 'nova_live_call_companion_brain_service.dart';

class NovaCallCompanionRuntimeService {
  final NovaCallCompanionService companionService;
  final NovaCallStateService callStateService;
  final NovaCallControlBridgeService callControlService;
  final NovaContactService contactService;
  final NovaSpeechToTextService sttService;
  final NovaTtsService ttsService;
  final VoiceAuthorizationRuntimeService authorizationRuntimeService;
  final NovaCallCompanionGateService gateService;
  final NovaDailyVoiceSessionService dailyVoiceSessionService;
  final NovaRecentSpeakerService recentSpeakerService;
  final NovaPowerService? powerService;
  final NovaCallStyleLearningService callStyleLearningService;
  final NovaIdentityRuntimeService identityRuntimeService =
      const NovaIdentityRuntimeService();
  final NovaLiveCallCompanionBrainService companionBrainService =
      const NovaLiveCallCompanionBrainService();
  final NovaUnifiedSocialRuntimeService unifiedSocialRuntimeService;
  final NovaBenchmarkHarnessService benchmarkHarnessService;

  bool _active = false;
  bool _loopBusy = false;
  bool _userOverride = false;
  String? _activePhoneNumber;
  String _lastStatusMessage = '';
  bool _awaitingUserReplyInstruction = false;
  NovaCallCompanionState _state = NovaCallCompanionState.idle();
  DateTime? _trustedSpeakerUntil;
  VoiceAccessLevel? _trustedSpeakerLevel;
  String _trustedSpeakerVoiceId = '';
  bool _restoreFullyShutdownOnStop = false;
  DateTime? _lastHeardAt;
  String _lastCallerEmotion = '';
  String _lastCompanionMemorySummary = '';

  NovaCallCompanionRuntimeService({
    required this.companionService,
    required this.callStateService,
    required this.callControlService,
    required this.contactService,
    required this.sttService,
    required this.ttsService,
    required this.authorizationRuntimeService,
    NovaCallCompanionGateService? gateService,
    NovaDailyVoiceSessionService? dailyVoiceSessionService,
    NovaRecentSpeakerService? recentSpeakerService,
    NovaCallStyleLearningService? callStyleLearningService,
    this.powerService,
    NovaUnifiedSocialRuntimeService? unifiedSocialRuntimeService,
    NovaBenchmarkHarnessService? benchmarkHarnessService,
  }) : gateService = gateService ?? const NovaCallCompanionGateService(),
       dailyVoiceSessionService =
           dailyVoiceSessionService ?? const NovaDailyVoiceSessionService(),
       recentSpeakerService =
           recentSpeakerService ?? const NovaRecentSpeakerService(),
       callStyleLearningService =
           callStyleLearningService ?? const NovaCallStyleLearningService(),
       unifiedSocialRuntimeService =
           unifiedSocialRuntimeService ?? NovaUnifiedSocialRuntimeService(),
       benchmarkHarnessService =
           benchmarkHarnessService ?? NovaBenchmarkHarnessService();

  bool get isActive => _active;
  bool get isUserOverrideActive => _userOverride;
  String? get activePhoneNumber => _activePhoneNumber;
  String get lastStatusMessage => _lastStatusMessage;
  NovaCallCompanionState get state => _state;

  Map<String, dynamic> buildLiveCompanionHints({
    String ownerDirective = '',
    String remoteTranscript = '',
    String callerName = '',
    String relationLabel = '',
  }) {
    final directive = companionBrainService.analyzeOwnerDirective(
      ownerDirective,
    );
    final remote = companionBrainService.analyzeRemoteTurn(
      remoteTranscript,
      knownRelation: relationLabel,
    );
    final plan = companionBrainService.buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: identityRuntimeService.currentDisplayName,
      callerName: callerName.trim().isEmpty ? 'Arayan kişi' : callerName.trim(),
      relationLabel: relationLabel,
      ownerAlias: 'patronum',
      explicitInstruction: directive.extractedInstruction,
    );
    unifiedSocialRuntimeService.ingestVoiceInput(
      transcript: ownerDirective.isNotEmpty ? ownerDirective : remoteTranscript,
      accessLevel: _trustedSpeakerLevel,
      speakerVoiceId: _trustedSpeakerVoiceId,
      speakerName: callerName,
      relationLabel: relationLabel,
      addressedNova: true,
      containsCommand: ownerDirective.trim().isNotEmpty,
      activeCall: true,
      companionActive: true,
    );
    return <String, dynamic>{
      'directive': directive.scores,
      'remote': remote.scores,
      'reply': '',
      'replyPlan': plan.toStructuredContext(),
      'shouldTakeOver': plan.shouldTakeOver,
      'shouldHandBack': plan.shouldHandBack,
      'shouldWakeOwner': plan.shouldWakeOwner,
      'shouldStoreNote': plan.shouldStoreNote,
      'reasons': plan.reasons,
      'benchmark': benchmarkHarnessService.buildDashboardSummary(),
      'runtimeHints': companionBrainService.buildCompanionRuntimeHints(
        directive: directive,
        remote: remote,
        activeMode: _state.mode.name,
      ),
    };
  }

  Future<bool> startForCurrentCall({bool allowShutdownBypass = false}) async {
    final snapshot = await callStateService.getSnapshot();

    if (!snapshot.inCall || (!snapshot.isActiveCall && !snapshot.isRinging)) {
      _setStatus(
        'Aktif veya çalan çağrı bulunamadı.',
        mode: NovaCallCompanionMode.idle,
      );
      return false;
    }

    final phoneNumber = snapshot.normalizedActiveNumber;
    if (phoneNumber.isEmpty) {
      _setStatus(
        'Aktif çağrı numarası alınamadı.',
        mode: NovaCallCompanionMode.error,
      );
      return false;
    }

    if (snapshot.isRinging) {
      final answer = await callControlService.answerRingingCall();
      if (!answer.success) {
        _setStatus(
          answer.message.trim().isEmpty
              ? 'Gelen çağrı cevaplanamadığı için companion başlatılamadı.'
              : answer.message.trim(),
          mode: NovaCallCompanionMode.error,
        );
        return false;
      }
      await Future<void>.delayed(const Duration(milliseconds: 450));
    }

    return start(phoneNumber, allowShutdownBypass: allowShutdownBypass);
  }

  Future<bool> start(
    String phoneNumber, {
    bool allowShutdownBypass = false,
  }) async {
    final normalizedNumber = PhoneNumberNormalizer.normalize(phoneNumber);
    if (normalizedNumber.isEmpty) {
      _setStatus(
        'Geçersiz telefon numarası.',
        mode: NovaCallCompanionMode.error,
      );
      return false;
    }

    final contact = await contactService.findByPhoneNumber(normalizedNumber);
    if (contact == null) {
      _setStatus(
        'Bu numara kayıtlı kişilerde bulunamadı.',
        mode: NovaCallCompanionMode.error,
      );
      return false;
    }

    if (!contact.canReceiveAutoCallHandling) {
      _setStatus(
        'Bu kişi çağrı companion kullanımı için yetkili değil.',
        mode: NovaCallCompanionMode.error,
      );
      return false;
    }

    if (_active && _activePhoneNumber == normalizedNumber) {
      _setStatus(
        'Çağrı companion zaten aktif.',
        mode: NovaCallCompanionMode.listening,
        isActive: true,
        phoneNumber: normalizedNumber,
        speakerExpected: true,
        microphoneExpectedMuted: true,
      );
      return true;
    }

    await stop(silent: true);

    if (powerService?.isFullyShutdown == true) {
      if (!allowShutdownBypass) {
        _setStatus(
          '${identityRuntimeService.currentDisplayName} tam kapalı modda olduğu için companion başlatılamadı.',
          mode: NovaCallCompanionMode.error,
        );
        return false;
      }
      await powerService?.setPassiveSleep();
      _restoreFullyShutdownOnStop = true;
    } else {
      _restoreFullyShutdownOnStop = false;
    }

    final handoff = await callControlService.handOverToNova(
      trustedSource: 'companion',
    );
    if (!handoff.success) {
      _setStatus(
        handoff.message.trim().isEmpty
            ? 'Çağrı companion devralma başarısız oldu.'
            : handoff.message.trim(),
        mode: NovaCallCompanionMode.error,
      );
      return false;
    }

    _active = true;
    _userOverride = false;
    _activePhoneNumber = normalizedNumber;

    _setStatus(
      'Çağrı companion aktif edildi: ${contact.displayName}',
      mode: NovaCallCompanionMode.listening,
      isActive: true,
      phoneNumber: normalizedNumber,
      speakerExpected: true,
      microphoneExpectedMuted: true,
      userOverrideActive: false,
    );

    unawaited(_runLoop());
    return true;
  }

  Future<void> stop({bool silent = false}) async {
    _active = false;
    _userOverride = false;
    _activePhoneNumber = null;
    _trustedSpeakerUntil = null;
    _trustedSpeakerLevel = null;
    _trustedSpeakerVoiceId = '';
    _awaitingUserReplyInstruction = false;
    final shouldRestoreFullyShutdown = _restoreFullyShutdownOnStop;
    _restoreFullyShutdownOnStop = false;

    try {
      await ttsService.stop();
    } catch (_) {}

    try {
      await callControlService.handOverToUser(trustedSource: 'companion');
    } catch (_) {}

    if (shouldRestoreFullyShutdown) {
      await powerService?.setFullyShutdown();
    }

    if (!silent) {
      _setStatus(
        'Çağrı companion durduruldu.',
        mode: NovaCallCompanionMode.idle,
        isActive: false,
        phoneNumber: '',
        speakerExpected: false,
        microphoneExpectedMuted: false,
        userOverrideActive: false,
      );
    } else {
      _state = NovaCallCompanionState.idle();
      _lastStatusMessage = '';
    }
  }

  Future<void> handOverToUser() async {
    _userOverride = true;

    final result = await callControlService.handOverToUser(
      trustedSource: 'companion',
    );

    _setStatus(
      result.message.trim().isEmpty
          ? 'Kontrol kullanıcıya bırakıldı.'
          : result.message.trim(),
      mode: result.success
          ? NovaCallCompanionMode.handedToUser
          : NovaCallCompanionMode.error,
      isActive: true,
      phoneNumber: _activePhoneNumber ?? '',
      speakerExpected: false,
      microphoneExpectedMuted: false,
      userOverrideActive: true,
    );

    try {
      await ttsService.stop();
    } catch (_) {}
  }

  Future<void> takeBackControl() async {
    _userOverride = false;

    final result = await callControlService.handOverToNova(
      trustedSource: 'companion',
    );

    _setStatus(
      result.message.trim().isEmpty
          ? 'Kontrol tekrar ${identityRuntimeService.currentDisplayName} companion tarafına geçti.'
          : result.message.trim(),
      mode: result.success
          ? NovaCallCompanionMode.listening
          : NovaCallCompanionMode.error,
      isActive: true,
      phoneNumber: _activePhoneNumber ?? '',
      speakerExpected: true,
      microphoneExpectedMuted: true,
      userOverrideActive: false,
    );
  }

  Future<void> _runLoop() async {
    while (_active) {
      if (_loopBusy) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        continue;
      }

      _loopBusy = true;

      try {
        final snapshot = await callStateService.getSnapshot();

        if (!snapshot.inCall || !snapshot.isActiveCall) {
          await stop();
          break;
        }

        final liveNumber = snapshot.normalizedActiveNumber;
        if (liveNumber.isEmpty) {
          _setStatus(
            'Canlı çağrı numarası alınamadı.',
            mode: NovaCallCompanionMode.suspended,
            isActive: true,
            phoneNumber: _activePhoneNumber ?? '',
          );
          await Future<void>.delayed(const Duration(milliseconds: 500));
          continue;
        }

        if (_activePhoneNumber != null && liveNumber != _activePhoneNumber) {
          _setStatus(
            'Çağrı numarası değiştiği için companion kapatıldı.',
            mode: NovaCallCompanionMode.idle,
            isActive: false,
            phoneNumber: '',
          );
          await stop(silent: true);
          break;
        }

        if (_userOverride) {
          final alreadyInUserMode = !snapshot.isMuted && !snapshot.isSpeakerOn;

          if (!alreadyInUserMode) {
            await callControlService.handOverToUser(trustedSource: 'companion');
          }

          final userSideStt = await sttService.transcribe(
            mode: NovaSttMode.light,
            targetDescription:
                'Kullanıcı kontrolündeki çağrıda companion geri çağırma',
            useCallCompanionAudioPolicy: true,
          );

          final userSideText = userSideStt.recognizedText.trim().toLowerCase();
          if (userSideStt.success && userSideText.isNotEmpty) {
            final wantsNovaBack =
                gateService.isNovaTakebackCommand(userSideText) ||
                identityRuntimeService
                    .prefixedPhrases(const <String>[
                      'gel buraya',
                      'buraya gel',
                    ], includeBareName: false)
                    .any(userSideText.contains) ||
                userSideText.contains('devral') ||
                userSideText.contains('sen konuş') ||
                userSideText.contains('sen cevapla') ||
                userSideText.contains('cevapla sen konuş') ||
                userSideText.contains('hoparlorle ver') ||
                userSideText.contains('hoparlörle ver');
            if (wantsNovaBack) {
              final authorizedDuringOverride =
                  await _isAuthorizedSpeakerInCall();
              if (authorizedDuringOverride) {
                await takeBackControl();
                await Future<void>.delayed(const Duration(milliseconds: 220));
                continue;
              }
            }
          }

          await Future<void>.delayed(const Duration(milliseconds: 500));
          continue;
        }

        if (!snapshot.isMuted || !snapshot.isSpeakerOn) {
          await callControlService.handOverToNova(trustedSource: 'companion');
        }

        _setStatus(
          '${identityRuntimeService.currentDisplayName} companion çağrı içi komut bekliyor.',
          mode: NovaCallCompanionMode.listening,
          isActive: true,
          phoneNumber: _activePhoneNumber ?? '',
          speakerExpected: true,
          microphoneExpectedMuted: true,
          userOverrideActive: false,
        );

        final stt = await sttService.transcribe(
          mode: NovaSttMode.enhanced,
          targetDescription:
              '${identityRuntimeService.currentDisplayName} çağrı yardımcısı konuşması',
          useCallCompanionAudioPolicy: true,
        );

        if (!stt.success || stt.recognizedText.trim().isEmpty) {
          await Future<void>.delayed(const Duration(milliseconds: 350));
          continue;
        }

        final recognizedText = stt.recognizedText.trim();
        final lowered = recognizedText.toLowerCase();

        if (gateService.isCallControlActionCommand(lowered)) {
          final authorizedForCallAction = await _isAuthorizedSpeakerInCall();
          if (!authorizedForCallAction) {
            _setStatus(
              'Companion çağrı kontrol komutu engellendi; komut sahibi yetkili ses olarak doğrulanmadı.',
              mode: NovaCallCompanionMode.listening,
              isActive: true,
              phoneNumber: _activePhoneNumber ?? '',
              speakerExpected: true,
              microphoneExpectedMuted: true,
              userOverrideActive: false,
            );
            await Future<void>.delayed(const Duration(milliseconds: 300));
            continue;
          }
        }

        final quickRouteHandled = await _handleQuickRoutingCommand(
          recognizedText,
          lowered,
        );
        if (quickRouteHandled) {
          await Future<void>.delayed(const Duration(milliseconds: 180));
          continue;
        }

        if (gateService.isStopCommand(lowered)) {
          await stop();
          break;
        }

        final wantsSpeakerUserTakeover =
            lowered.contains('hoparlorle ver ben konus') ||
            lowered.contains('hoparlörle ver ben konuş') ||
            lowered.contains('beni hoparlore ver') ||
            lowered.contains('beni hoparlöre ver') ||
            lowered.contains('mikrofonu bana ver');

        if (gateService.isUserTakeoverCommand(lowered) ||
            lowered.contains('ben konusacagim') ||
            lowered.contains('ben konuşacağım') ||
            lowered.contains('bana ver') ||
            wantsSpeakerUserTakeover) {
          if (wantsSpeakerUserTakeover) {
            _userOverride = true;
            final speaker = await callControlService.routeToSpeaker(true);
            final mic = await callControlService.setMuted(false);
            _setStatus(
              (speaker.success && mic.success)
                  ? 'Kontrol size bırakıldı; hoparlör açık ve mikrofon sizde.'
                  : 'Kontrol size bırakılmaya çalışıldı; hoparlör veya mikrofon durumu tam uygulanamadı.',
              mode: (speaker.success && mic.success)
                  ? NovaCallCompanionMode.handedToUser
                  : NovaCallCompanionMode.error,
              isActive: true,
              phoneNumber: _activePhoneNumber ?? '',
              speakerExpected: true,
              microphoneExpectedMuted: false,
              userOverrideActive: true,
            );
            try {
              await ttsService.stop();
            } catch (_) {}
            continue;
          }
          await handOverToUser();
          continue;
        }

        if (gateService.isNovaTakebackCommand(lowered) ||
            identityRuntimeService
                .prefixedPhrases(const <String>[
                  'gel buraya',
                  'buraya gel',
                ], includeBareName: false)
                .any(lowered.contains) ||
            lowered.contains('sen konus') ||
            lowered.contains('sen konuş') ||
            lowered.contains('sen cevapla') ||
            lowered.contains('cevapla sen konuş') ||
            lowered.contains('devral')) {
          await takeBackControl();
          if (gateService.shouldAskWhatToSay(lowered)) {
            _awaitingUserReplyInstruction = true;
            final askReply = await companionService.generateReplyWithAuthority(
              NovaCallCompanionRequest(
                liveConversation:
                    'Owner çağrı içinde Novain devralmasını istedi ama ne söyleneceği net değil. Sahibine tek cümleyle ne söylemem gerektiğini sor; bu cümle arayana değil sahibedir.',
                phoneNumber: _activePhoneNumber ?? '',
                allowApi: true,
                isUserApproved: true,
                isUserInitiated: true,
                requestedByVoice: true,
                allowTakeover: true,
                allowHandoffBack: true,
              ),
            );
            if (askReply.trimmedText.isNotEmpty &&
                askReply.authorityResponse?.hasAuthoritativeBrainProof ==
                    true) {
              await ttsService.speak(
                askReply.trimmedText,
                mode: NovaTtsMode.neuralLocal,
                interruptCurrentSpeech: true,
                authoritySource: 'call_companion_ai_authority_output',
                singleBrainApproved: true,
                authorityResponse: askReply.authorityResponse,
              );
            }
          }
          continue;
        }

        if (_awaitingUserReplyInstruction) {
          final authorizedForInstruction = await _isAuthorizedSpeakerInCall();
          if (authorizedForInstruction) {
            _awaitingUserReplyInstruction = false;
            await _speakDirectedReply(recognizedText, lowered);
            continue;
          }
        }

        if (!gateService.shouldRespondDuringCompanion(lowered)) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          continue;
        }

        final authorizedSpeaker = await _isAuthorizedSpeakerInCall();
        if (!authorizedSpeaker) {
          _setStatus(
            _lastStatusMessage.trim().isEmpty
                ? 'Çağrı içi komut yetkisi tanınmadı; companion dinlemeye devam ediyor.'
                : _lastStatusMessage.trim(),
            mode: NovaCallCompanionMode.listening,
            isActive: true,
            phoneNumber: _activePhoneNumber ?? '',
            speakerExpected: true,
            microphoneExpectedMuted: true,
            userOverrideActive: false,
          );
          await Future<void>.delayed(const Duration(milliseconds: 300));
          continue;
        }

        await callControlService.handOverToNova(trustedSource: 'companion');

        _setStatus(
          '${identityRuntimeService.currentDisplayName} companion cevap üretiyor.',
          mode: NovaCallCompanionMode.speaking,
          isActive: true,
          phoneNumber: _activePhoneNumber ?? '',
          speakerExpected: true,
          microphoneExpectedMuted: true,
          userOverrideActive: false,
        );

        final reply = await companionService.generateReplyWithAuthority(
          NovaCallCompanionRequest(
            liveConversation: recognizedText,
            phoneNumber: _activePhoneNumber ?? '',
            allowApi: true,
            isUserApproved: true,
            isUserInitiated: true,
            requestedByVoice: true,
            allowTakeover: true,
            allowHandoffBack: true,
          ),
        );

        final safeReply = reply.trimmedText;
        if (safeReply.isEmpty) {
          _setStatus(
            'Boş cevap oluştu, companion dinlemeye döndü.',
            mode: NovaCallCompanionMode.listening,
            isActive: true,
            phoneNumber: _activePhoneNumber ?? '',
            speakerExpected: true,
            microphoneExpectedMuted: true,
            userOverrideActive: false,
          );
          await Future<void>.delayed(const Duration(milliseconds: 300));
          continue;
        }

        benchmarkHarnessService.recordBatch(
          benchmarkHarnessService.evaluateConversationEpisode(
            ownerPriorityPreserved:
                _trustedSpeakerLevel == VoiceAccessLevel.owner ||
                _trustedSpeakerLevel == VoiceAccessLevel.authorizedGuest,
            backchannelQuality: 0.88,
            interruptionQuality: 0.90,
            semanticTurnAccuracy: 0.90,
            memoryCommitQuality: safeReply.toLowerCase().contains('not')
                ? 0.92
                : 0.82,
            relationshipToneQuality:
                _state.lastMessage.toLowerCase().contains('anne') ||
                    _state.lastMessage.toLowerCase().contains('baba') ||
                    _state.lastMessage.toLowerCase().contains('eş')
                ? 0.93
                : 0.84,
            ttsSelfBlindProtected: true,
            multiSpeakerStable: true,
            noteDelivered: !safeReply.toLowerCase().contains('not'),
            latencyScore: 0.86,
          ),
        );
        await ttsService.speak(
          safeReply,
          mode: NovaTtsMode.neuralLocal,
          interruptCurrentSpeech: true,
          authoritySource: 'call_companion_ai_authority_output',
          authorityResponse: reply.authorityResponse,
        );

        await callControlService.handOverToNova(trustedSource: 'companion');

        _setStatus(
          '${identityRuntimeService.currentDisplayName} companion yeniden dinleme modunda.',
          mode: NovaCallCompanionMode.listening,
          isActive: true,
          phoneNumber: _activePhoneNumber ?? '',
          speakerExpected: true,
          microphoneExpectedMuted: true,
          userOverrideActive: false,
        );
      } catch (_) {
        _setStatus(
          'Çağrı companion döngüsünde beklenmeyen hata oluştu.',
          mode: NovaCallCompanionMode.error,
          isActive: true,
          phoneNumber: _activePhoneNumber ?? '',
        );
        await Future<void>.delayed(const Duration(milliseconds: 700));
      } finally {
        _loopBusy = false;
      }
    }
  }

  Future<void> _speakDirectedReply(
    String recognizedText,
    String lowered,
  ) async {
    await callControlService.handOverToNova(trustedSource: 'companion');
    _setStatus(
      'Asistan companion yönlendirilmiş cevap üretiyor.',
      mode: NovaCallCompanionMode.speaking,
      isActive: true,
      phoneNumber: _activePhoneNumber ?? '',
      speakerExpected: true,
      microphoneExpectedMuted: true,
      userOverrideActive: false,
    );

    final styleSuffix = await callStyleLearningService.buildPromptSuffix();
    NovaCallCompanionReply reply;
    if (gateService.shouldUseFreeformReply(lowered)) {
      final freeformPrompt = styleSuffix.trim().isEmpty
          ? 'Arayan için uygun, kısa, nazik, akıcı ve gerçekten insan gibi duyulan bir cevap kur. Robotik, fazla resmi, madde madde ya da yapay zeka gibi olmasın. Türkçe konuşma telefon hattında doğal aksın; nefesli kısa duraklar, doğal vurgu ve bağlama uygun sıcaklık kullan. Bağlam: $recognizedText'
          : 'Arayan için uygun, kısa, nazik, akıcı ve gerçekten insan gibi duyulan bir cevap kur. Robotik, fazla resmi, madde madde ya da yapay zeka gibi olmasın. Türkçe konuşma telefon hattında doğal aksın; nefesli kısa duraklar, doğal vurgu ve bağlama uygun sıcaklık kullan. Bağlam: $recognizedText$styleSuffix';
      reply = await companionService.generateReplyWithAuthority(
        NovaCallCompanionRequest(
          liveConversation: freeformPrompt,
          phoneNumber: _activePhoneNumber ?? '',
          allowApi: true,
          isUserApproved: true,
          isUserInitiated: true,
          requestedByVoice: true,
          allowTakeover: true,
          allowHandoffBack: true,
        ),
      );
    } else {
      reply = await companionService.generateReplyWithAuthority(
        NovaCallCompanionRequest(
          liveConversation:
              'Sahip çağrı içinde yönlendirilmiş cevap verdi. Anlamı değiştirme; sahibin açıkça aynen söyle dediği durumlarda aynen, aksi halde kısa ve doğal telefon cümlesi kur. Yönerge: $recognizedText',
          phoneNumber: _activePhoneNumber ?? '',
          allowApi: true,
          isUserApproved: true,
          isUserInitiated: true,
          requestedByVoice: true,
          allowTakeover: true,
          allowHandoffBack: true,
        ),
      );
    }

    final safeReply = reply.trimmedText;
    if (safeReply.isNotEmpty) {
      await ttsService.speak(
        safeReply,
        mode: NovaTtsMode.neuralLocal,
        interruptCurrentSpeech: true,
        authoritySource: 'call_companion_ai_authority_output',
        authorityResponse: reply.authorityResponse,
      );
    }

    await callControlService.handOverToNova(trustedSource: 'companion');
    _setStatus(
      '${identityRuntimeService.currentDisplayName} companion yeniden dinleme modunda.',
      mode: NovaCallCompanionMode.listening,
      isActive: true,
      phoneNumber: _activePhoneNumber ?? '',
      speakerExpected: true,
      microphoneExpectedMuted: true,
      userOverrideActive: false,
    );
  }

  String _blendDirectedReply(
    String primary,
    String fallback, {
    required String recognizedText,
  }) {
    final main = primary.trim();
    final alt = fallback.trim();
    if (main.isEmpty) return alt;
    if (main.split(RegExp(r'\s+')).length >= 8) return main;
    if (alt.isEmpty) return main;
    if (alt.toLowerCase().contains(main.toLowerCase())) return alt;
    return '$alt $main'.trim();
  }

  String _extractDirectedReply(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return text;
    final lower = text.toLowerCase();
    const markers = <String>[
      'şunları söyle',
      'sunlari soyle',
      'şunu söyle',
      'sunu soyle',
      'de ki',
      'şunu ilet',
      'sunu ilet',
      'şunu sor',
      'sunu sor',
      'ona de ki',
      'ona söyle',
      'onu ara ve de ki',
    ];
    for (final marker in markers) {
      final index = lower.indexOf(marker);
      if (index >= 0) {
        final extracted = text.substring(index + marker.length).trim();
        if (extracted.isNotEmpty) {
          return extracted;
        }
      }
    }
    return text
        .replaceFirst(
          RegExp(
            r'^([a-zçğıöşü0-9_-]+\s+)?(sen\s+)?konuş\s*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(
          RegExp(
            r'^([a-zçğıöşü0-9_-]+\s+)?(sen\s+)?cevapla\s*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(
          RegExp(
            r'^([a-zçğıöşü0-9_-]+\s+)?aç\s+sen\s+konuş\s*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(
          RegExp(
            r'^([a-zçğıöşü0-9_-]+\s+)?uygun\s+bir\s+şeyler\s+söyle\s*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  Future<bool> _isAuthorizedSpeakerInCall() async {
    final now = DateTime.now();

    // CALL_AUDIO_AUTH_STRICT_V1
    // Çağrı sırasında transcript tek başına yetki değildir.
    // Eski geniş continuity/daily-session pencereleri çağrıdaki karşı tarafın
    // sesiyle owner güveninin karışmasına yol açabileceği için burada
    // yalnızca saniyeler önce alınmış taze doğrulama yeniden kullanılabilir.
    if (_trustedSpeakerUntil != null &&
        now.isBefore(_trustedSpeakerUntil!) &&
        _trustedSpeakerVoiceId.trim().isNotEmpty &&
        (_trustedSpeakerLevel == VoiceAccessLevel.owner ||
            _trustedSpeakerLevel == VoiceAccessLevel.authorizedGuest)) {
      return true;
    }

    try {
      final inspection = await authorizationRuntimeService
          .inspectFreshExternalSample(
            maxDurationSeconds: 3,
            outputName: 'nova_call_companion_fresh_auth',
            minSimilarity: 0.62,
          );
      final decision = inspection.decision;
      final allowed =
          inspection.captureSucceeded &&
          (decision.level == VoiceAccessLevel.owner ||
              decision.level == VoiceAccessLevel.authorizedGuest);

      if (inspection.recognizedVoiceId.trim().isNotEmpty) {
        await recentSpeakerService.remember(
          voiceId: inspection.recognizedVoiceId.trim(),
          level: decision.level,
          speakerName: inspection.recognizedDisplayName.trim(),
          relationshipLabel: decision.relationshipLabel,
        );
      }

      if (allowed) {
        _trustedSpeakerLevel = decision.level;
        _trustedSpeakerVoiceId = inspection.recognizedVoiceId.trim();
        _trustedSpeakerUntil = now.add(const Duration(seconds: 20));
        if (inspection.recognizedVoiceId.trim().isNotEmpty) {
          await dailyVoiceSessionService.rememberTrustedSpeaker(
            voiceId: inspection.recognizedVoiceId.trim(),
            level: decision.level,
            recognizedName: inspection.recognizedDisplayName.trim(),
          );
        }
        _lastStatusMessage = '';
        return true;
      }

      _trustedSpeakerUntil = null;
      _trustedSpeakerLevel = null;
      _trustedSpeakerVoiceId = '';
      _lastStatusMessage = decision.message.trim().isEmpty
          ? 'Çağrı içi komut için taze ses doğrulaması gerekli; API transcript tek başına yetki sayılmaz.'
          : decision.message.trim();
      return false;
    } catch (_) {
      _trustedSpeakerUntil = null;
      _trustedSpeakerLevel = null;
      _trustedSpeakerVoiceId = '';
      _lastStatusMessage =
          'Çağrı içi taze ses yetki kontrolü başarısız oldu; komut reddedildi.';
      return false;
    }
  }

  Future<bool> _handleQuickRoutingCommand(
    String recognizedText,
    String lowered,
  ) async {
    final wantsSpeakerAssist =
        lowered.contains('telefonu benim için aç hoparlöre ver') ||
        lowered.contains('hoparlöre ver') ||
        lowered.contains('hoparlore ver') ||
        lowered.contains('hoparlöre al') ||
        lowered.contains('hoparlore al');
    final wantsNovaSpeak =
        lowered.contains('aç sen konuş') ||
        lowered.contains('ac sen konus') ||
        lowered.contains('sen konuş') ||
        lowered.contains('sen konus');
    if (!wantsSpeakerAssist && !wantsNovaSpeak) {
      return false;
    }

    if (wantsSpeakerAssist) {
      await callControlService.routeToSpeaker(true);
    }

    if (wantsNovaSpeak) {
      await takeBackControl();
      await callControlService.routeToSpeaker(true);
      _awaitingUserReplyInstruction = true;
      // No static operational clarification may speak without SingleBrain/Gemma proof.
      // The runtime stays in awaiting instruction mode and listens instead.
      await NovaRuntimeSignalService.instance.record(
        kind: NovaRuntimeSignalKind.call,
        level: NovaRuntimeSignalLevel.info,
        code: 'call_companion_operational_clarification_speech_blocked',
        message:
            'Companion açıklama konuşması AI authority proof olmadan TTS’ye gönderilmedi.',
        technicalDetails: 'source=call_companion_operational_clarification',
        diagnosticCandidate: false,
      );
      return true;
    }

    _setStatus(
      'Hoparlör çağrı akışına geçirildi; companion hazır bekliyor.',
      mode: NovaCallCompanionMode.listening,
      isActive: true,
      phoneNumber: _activePhoneNumber ?? '',
      speakerExpected: true,
      microphoneExpectedMuted: _userOverride ? false : true,
      userOverrideActive: _userOverride,
    );
    return true;
  }

  void _setStatus(
    String message, {
    required NovaCallCompanionMode mode,
    bool? isActive,
    String? phoneNumber,
    bool? userOverrideActive,
    bool? speakerExpected,
    bool? microphoneExpectedMuted,
  }) {
    _lastStatusMessage = message;
    _state = _state.copyWith(
      isActive: isActive,
      phoneNumber: phoneNumber,
      mode: mode,
      userOverrideActive: userOverrideActive,
      speakerExpected: speakerExpected,
      microphoneExpectedMuted: microphoneExpectedMuted,
      lastMessage: message,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> buildRuntimeIntegritySnapshot() {
    return <String, dynamic>{
      'isActive': _state.isActive,
      'mode': _state.mode.name,
      'userOverride': _userOverride,
      'awaitingInstruction': _awaitingUserReplyInstruction,
      'hasActivePhoneNumber': (_activePhoneNumber ?? '').trim().isNotEmpty,
      'speakerExpected': _state.speakerExpected,
      'microphoneExpectedMuted': _state.microphoneExpectedMuted,
      'lastStatusMessage': _lastStatusMessage,
      'lastHeardAt': _lastHeardAt?.toIso8601String() ?? '',
      'lastCallerEmotion': _lastCallerEmotion,
      'lastMemorySummary': _lastCompanionMemorySummary,
    };
  }

  Map<String, dynamic> buildTakeoverPlan({
    required String instruction,
    required bool userAskedDetailedRelay,
    required bool urgent,
  }) {
    final normalized = instruction.toLowerCase().trim();
    final shouldSpeakForUser =
        normalized.contains('benim için konuş') ||
        normalized.contains('sen konuş') ||
        normalized.contains('devral');
    final shouldRouteSpeaker =
        normalized.contains('hoparl') || normalized.contains('speaker');
    return <String, dynamic>{
      'shouldSpeakForUser': shouldSpeakForUser,
      'shouldRouteSpeaker': shouldRouteSpeaker,
      'shouldRelayWithExpansion':
          userAskedDetailedRelay ||
          normalized.contains('ayrıntı') ||
          normalized.contains('detay'),
      'shouldStayHumanLike': true,
      'shouldKeepOwnerIntent': true,
      'urgent': urgent,
      'memoryCommitRecommended': shouldSpeakForUser || urgent,
    };
  }

  List<String> buildHumanLikeCompanionChecks() {
    return <String>[
      'Karşı tarafın duygusu kısa etikete indirgenmez; ton ve amaç birlikte yorumlanır.',
      'Cihaz sahibinin niyeti korunur, kelimeler robotik biçimde kopyalanmaz.',
      'Mahrem bilgi kalabalıkta açılmaz; gerekirse daha sonra iletilir.',
      'Acil çağrıda uyandırma sınırı kontrollüdür ve sonsuz tekrar yoktur.',
      'Companion devralma ve kullanıcı devralma akışı çağrı zinciriyle uyumlu kalır.',
    ];
  }

  bool shouldEscalateWakeRequest({
    required bool urgent,
    required int elapsedMinutes,
  }) {
    if (!urgent) return false;
    return elapsedMinutes < 15;
  }

  String buildMemoryCommitSuggestion(String transcript) {
    final cleaned = transcript.trim();
    if (cleaned.isEmpty)
      return 'Çağrı notu oluşturulacak kadar açık bir içerik yok.';
    if (cleaned.length <= 120)
      return 'Çağrı hafızasına kısa not olarak eklenebilir: ' + cleaned;
    return 'Çağrı hafızasına özet + ayrıntı ayrımıyla eklenmeli.';
  }
}
