// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
// NOVA_V34_SETUP_AIREQUEST_COMPILE_GATE_FIX
// NOVA_ASR_STT_AUTHORITY_MARKER: speakerVoiceId ownerConfidence relationshipLabel routed_to_SingleBrainAuthority deterministic_bridge_dto_only.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/asr/nova_streaming_asr_event.dart';
import '../../core/audio_runtime/audio_capture_request.dart';
import '../../core/audio_runtime/nova_listening_mode.dart';
import '../../core/ai/ai_response.dart';
import '../../core/ai/nova_ai_service.dart';
import '../../core/ai/ai_request.dart';
import '../../core/ai/ai_mode.dart';
import '../../core/behavior/nova_persona.dart';
import '../../core/behavior/response_style.dart';
import '../../core/memory/memory_types.dart';
import '../../core/runtime/nova_runtime_signal.dart';
import '../../core/speech/nova_final_text_contract.dart';
import '../../core/runtime/nova_identity_rollout_models.dart';
import '../../services/api/api_service.dart';
import '../../services/identity/device_owner_identity_service.dart';
import '../../services/identity/nova_first_run_service.dart';
import '../../services/identity/nova_voice_identity_runtime_service.dart';
import '../../services/conversation/nova_conversation_focus_service.dart';
import '../../services/memory/memory_service.dart';
import '../../services/runtime/nova_identity_rollout_service.dart';
import '../../services/runtime/nova_identity_runtime_service.dart';
import '../../services/asr/nova_streaming_asr_runtime_service.dart';
import '../../services/runtime/nova_spoken_intent_interpreter_service.dart';
import '../../services/runtime/nova_single_brain_authority_service.dart';
import '../../services/runtime/nova_runtime_graph_service.dart';
import '../../services/local_model/local_model_service.dart';
import '../../services/settings/nova_settings_service.dart';
import '../../services/security/nova_security_quarantine_service.dart';
import '../../services/security/nova_security_diagnostic_mode_service.dart';
import '../../services/runtime/nova_runtime_signal_service.dart';
import '../../services/self_repair/nova_runtime_signal_service.dart' as self_repair_signal;
import '../../services/stt/nova_speech_to_text_service.dart'
    show NovaSpeechToTextService, NovaSttMode;
import '../../services/tts/nova_tts_service.dart' show NovaTtsMode;
import '../../services/tts/nova_tts_service.dart' show NovaTtsService;
import '../../presentation/self_repair/self_repair_control_page.dart';
import '../../services/self_repair/nova_self_diagnostic_service.dart';
import '../../services/self_repair/nova_self_recognition_service.dart';
import '../../services/self_repair/nova_self_repair_coordinator_service.dart';
import '../../services/self_repair/nova_self_repair_orchestrator_service.dart';
import '../../services/self_repair/nova_repair_trace_service.dart';
import '../../services/self_repair/nova_self_repair_report_service.dart';
import '../../services/self_repair/nova_self_repair_security_service.dart';
import '../../services/self_repair/nova_self_repair_settings_service.dart';
import '../../services/self_repair/nova_self_repair_command_service.dart';
import '../../services/self_repair/nova_capability_runtime_registry_service.dart';
import '../../services/self_repair/nova_capability_manifest_service.dart';
import '../../services/self_repair/nova_capability_probe_service.dart';
import '../../services/self_repair/nova_capability_catalog_service.dart';
import '../../services/self_repair/nova_repair_validation_service.dart';
import '../../services/self_repair/nova_repair_resolution_memory_service.dart';
import '../../services/system/nova_background_bridge_service.dart';
import '../../services/self_repair/nova_controlled_restart_service.dart';
import '../widgets/nova_core_orb.dart';

class NovaFirstRunSetupPage extends StatefulWidget {
  final NovaSpeechToTextService sttService;
  final NovaTtsService ttsService;
  final DeviceOwnerIdentityService ownerService;
  final NovaFirstRunService firstRunService;
  final NovaVoiceIdentityRuntimeService voiceIdentityRuntimeService;
  final NovaPersona persona;
  final ResponseStyle responseStyle;
  final LocalModelService localModelService;
  final ApiService apiService;
  final VoidCallback onCompleted;

  const NovaFirstRunSetupPage({
    super.key,
    required this.sttService,
    required this.ttsService,
    required this.ownerService,
    required this.firstRunService,
    required this.voiceIdentityRuntimeService,
    required this.persona,
    required this.responseStyle,
    required this.localModelService,
    required this.apiService,
    required this.onCompleted,
  });

  @override
  State<NovaFirstRunSetupPage> createState() => _NovaFirstRunSetupPageState();
}

enum _SetupStep {
  welcome,
  askAssistantName,
  confirmAssistantName,
  rolloutIdentity,
  askOwnerName,
  confirmOwnerName,
  askWelcomeText,
  confirmWelcomeText,
  askVoiceConsent,
  saving,
  done,
}

class _NovaFirstRunSetupPageState extends State<NovaFirstRunSetupPage> {
  _SetupStep _step = _SetupStep.welcome;
  NovaOrbState _orbState = NovaOrbState.idle;

  bool _busy = false;
  bool _completionTriggered = false;
  bool _flowBootStarted = false;
  bool _primaryActionRunning = false;

  String _assistantName = 'Nova';
  String _pendingAssistantName = 'Nova';
  String _ownerName = '';
  String _pendingOwnerName = '';
  String _ownerVoiceId = '';
  String _welcomeText = 'Hoş geldin patron.';
  String _pendingWelcomeText = '';
  String _statusText = 'İlk kurulum hazırlanıyor...';
  String _lastHeardText = '';

  int _setupStepMismatchCount = 0;
  int _ownerNameAttempts = 0;
  int _voiceConsentAttempts = 0;
  Timer? _autoStepTimer;
  final NovaSpokenIntentInterpreterService _spokenIntentInterpreter =
      const NovaSpokenIntentInterpreterService();
  final NovaIdentityRuntimeService _identityRuntimeService =
      const NovaIdentityRuntimeService();
  final NovaIdentityRolloutService _identityRolloutService =
      const NovaIdentityRolloutService();
  final NovaConversationFocusService _conversationFocusService =
      const NovaConversationFocusService();
  final NovaSecurityDiagnosticModeService _securityDiagnosticModeService =
      const NovaSecurityDiagnosticModeService();
  late final NovaAiService _setupAiService;
  NovaStreamingAsrRuntimeService get _setupStreamingAsrRuntimeService =>
      widget.sttService.streamingAsrRuntimeService;

  StreamSubscription<NovaStreamingAsrEvent>? _setupStreamingSubscription;
  StreamSubscription<LocalModelBootProgress>? _localModelBootSubscription;
  int _setupOpeningAttempts = 0;
  int? _lastSpokenModelPercent;
  String _lastSpokenModelPhase = '';
  LocalModelBootProgress? _lastBootProgress;
  DateTime? _lastBootNarrationAt;
  Timer? _bootNarrationTimer;
  bool _brainKernelVerified = false;
  bool _brainKernelVerifiedNarrated = false;
  bool _setupSpeechActive = false;
  DateTime? _lastSetupSpeechEndedAt;
  bool _suppressSetupAsrWhileSpeaking = false;
  bool _setupOpeningMicroInFlight = false;
  bool _setupSpeechRenderInFlight = false;
  AiResponse? _lastSetupSpeechAuthorityResponse;
  bool _setupAsrListening = false;
  String _setupAsrStatus = 'Setup streaming ASR henüz doğrulanmadı.';
  DateTime? _lastBootQuestionAnswerAt;
  String _recentSetupStreamingFinal = '';
  String _recentSetupStreamingPartial = '';
  DateTime? _recentSetupStreamingFinalAt;
  bool _securityDiagnosticPassive = true;
  bool _securityDiagnosticSaving = false;
  DateTime? _recentSetupStreamingPartialAt;

  Future<void> _recoverBrokenSetupState() async {
    try {
      final shouldBootstrap = await widget.firstRunService
          .shouldOpenFirstRunSetup();
      if (shouldBootstrap) {
        await const NovaSecurityQuarantineService().reset();
      }
    } catch (_) {}

    // Kurulum onarımı model/corpus silmemeli. Önceki sürüm ilk kurulumda
    // eski yerel model ve offline_corpus_json temizliği yüzünden yerel model,
    // tek zihin ve corpus hattı setup sırasında kendi kendine devre dışı
    // kalabiliyordu. Bu yüzden kurtarma artık yalnızca güvenlik karantinasını
    // temizler; insan mimarisi, yerel model ve corpus zinciri korunur.
  }

  @override
  void initState() {
    super.initState();
    _setupAiService = NovaRuntimeGraphService.instance.resolveSharedAi(
      requester: 'setup_voice',
      factory: () => NovaRuntimeGraphService.buildAiService(
        localModelService: widget.localModelService,
        apiService: widget.apiService,
        persona: widget.persona,
        responseStyle: widget.responseStyle,
      ),
    );
    NovaRuntimeGraphService.instance.registerDelegate(
      'setup_voice',
      'setup_page_wrapper',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _withSetupTimeout<void>(
        _recoverBrokenSetupState(),
        const Duration(milliseconds: 1800),
      ).catchError((_) {});
      await _withSetupTimeout<void>(
        _identityRuntimeService.ensureLoaded(),
        const Duration(milliseconds: 1800),
      ).catchError((_) {});
      final securityDiagnosticMode = await _securityDiagnosticModeService
          .load();
      if (mounted) {
        setState(() {
          _securityDiagnosticPassive = securityDiagnosticMode.passiveShields;
        });
      }
      _assistantName = _identityRuntimeService.currentDisplayName;
      _pendingAssistantName = _assistantName;

      await _localModelBootSubscription?.cancel();
      _localModelBootSubscription = widget.localModelService.bootProgressEvents
          .listen(_handleLocalModelBootProgress);
      // Gerçek hazırlık yüzdesi localModelService bootProgressEvents ile ekranda gösterilir.
      // Sistem setup konuşması yapmaz; AI hazır olduğunda konuşma yetkisi AI decision'a geçer.

      await _ensureSetupSingleAsrListening(reason: 'setup_init');
      try {
        await _startFlow();
      } catch (error, stackTrace) {
        await _handleSetupStartFlowError(error, stackTrace);
      }
    });
  }

  String get _displayAssistantName {
    final current = _assistantName.trim();
    return current.isEmpty ? 'Nova' : current;
  }

  void _startBootNarrationLoop() {
    _bootNarrationTimer?.cancel();
    // GEMMA6644: sistem setup'ı sesle ilerletmez. Bu döngü eski static
    // boot narration için vardı; artık yalnız gerçek progress state'i UI'da kalır.
  }

  Future<bool> _ensureSetupSingleAsrListening({required String reason}) async {
    if (!mounted) return false;

    try {
      await _setupStreamingSubscription?.cancel();
      _setupStreamingSubscription = _setupStreamingAsrRuntimeService.events
          .listen(_handleSetupStreamingEvent);

      final started = await _withSetupTimeout<bool>(
        _setupStreamingAsrRuntimeService.start(),
        const Duration(milliseconds: 4200),
        fallback: false,
      );

      Map<String, dynamic> gateState =
          await _withSetupTimeout<Map<String, dynamic>>(
            widget.sttService.nativeBridge.getStreamingVoiceGateState(),
            const Duration(milliseconds: 1600),
            fallback: const <String, dynamic>{
              'success': false,
              'running': false,
              'message': 'VoiceGate durumu alınamadı.',
            },
          );

      if (gateState['running'] != true) {
        gateState = await _withSetupTimeout<Map<String, dynamic>>(
          widget.sttService.nativeBridge.startStreamingVoiceGate(),
          const Duration(milliseconds: 2600),
          fallback: const <String, dynamic>{
            'success': false,
            'running': false,
            'message': 'VoiceGate başlatılamadı.',
          },
        );
      }

      final ready = await _withSetupTimeout<bool>(
        widget.sttService.nativeBridge.ensureStreamingAsrReady(),
        const Duration(milliseconds: 2600),
        fallback: false,
      );

      await _withSetupTimeout<Map<String, dynamic>>(
        widget.sttService.nativeBridge.prewarmContinuousListeningSession(
          holdForMs: 12 * 60 * 1000,
        ),
        const Duration(milliseconds: 2600),
        fallback: const <String, dynamic>{
          'success': false,
          'message': 'Setup ASR prewarm tamamlanamadı.',
        },
      );

      final gateRunning =
          gateState['running'] == true || gateState['success'] == true;
      final ok = started && ready && gateRunning;
      debugPrint(
        'NOVA_SETUP_ASR_READY reason=$reason started=$started ready=$ready gateRunning=$gateRunning gateState=$gateState ok=$ok',
      );
      _setupAsrListening = ok;
      _setupAsrStatus = ok
          ? 'Setup tek ASR/mikrofon zinciri aktif. reason=$reason'
          : 'Setup tek ASR/mikrofon zinciri doğrulanamadı. started=$started ready=$ready gate=$gateState';

      if (!mounted) return ok;
      setState(() {
        if (ok) {
          _orbState = NovaOrbState.listening;
          _statusText =
              'Setup mikrofonu ve dinleme zinciri aktif. API beyin doğrulaması başlıyor.';
        } else {
          _orbState = NovaOrbState.idle;
          _statusText = _setupAsrStatus;
        }
      });
      return ok;
    } catch (e, stackTrace) {
      debugPrint(
        'NOVA_SETUP_ASR_ERROR reason=$reason type=${e.runtimeType} error=$e',
      );
      debugPrint(stackTrace.toString());
      _setupAsrListening = false;
      _setupAsrStatus = 'Setup tek ASR/mikrofon zinciri başlatılamadı: $e';
      if (mounted) {
        setState(() {
          _orbState = NovaOrbState.idle;
          _statusText = _setupAsrStatus;
        });
      }
      return false;
    }
  }

  void _speakSetupBootNarration(String text, {required String reason}) {
    if (!mounted) return;
    final visible = _normalizeSetupPercentSpeech(text);
    _lastBootNarrationAt = DateTime.now();
    debugPrint(
      'NOVA_SETUP_BOOT_NARRATION_BLOCKED_SYSTEM_SPEECH reason=$reason chars=${visible.length}',
    );
    if (visible.trim().isNotEmpty) {
      setState(() {
        _statusText = visible;
      });
    }
  }

  Future<void> _startFlow() async {
    if (!mounted || _flowBootStarted) return;
    _flowBootStarted = true;
    _setupOpeningAttempts += 1;

    if (!mounted) return;
    setState(() {
      _busy = true;
      _orbState = NovaOrbState.idle;
      _statusText =
          'API beyin hattı hazırlanıyor. Setup ASR ve TTS tek beyin otoritesiyle ilerleyecek.';
    });
    final prepare = await _withSetupTimeout<LocalModelBootProgress>(
      widget.localModelService.prepareForBoot(),
      const Duration(minutes: 20),
      fallback: LocalModelBootProgress(
        phase: 'model_prepare_timeout',
        percent: null,
        message: 'API beyin hazırlığı zamanında tamamlanmadı.',
        critical: true,
        receivedAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    if (prepare.critical) {
      setState(() {
        _busy = false;
        _orbState = _setupAsrListening
            ? NovaOrbState.listening
            : NovaOrbState.idle;
        _statusText = prepare.message.trim().isEmpty
            ? 'API beyin hazırlığı başarısız.'
            : prepare.message.trim();
      });
      return;
    }

    final memoryReady = await _conversationFocusService.verifyWritableForBoot();
    if (!mounted) return;
    if (!memoryReady) {
      setState(() {
        _busy = false;
        _orbState = NovaOrbState.idle;
        _statusText =
            'Memory/focus yazılabilirlik doğrulanamadı. AI setup devamı engellendi.';
      });
      return;
    }

    final ttsReady = await _withSetupTimeout<bool>(
      widget.ttsService.ttsService.prewarmPreferredTurkishVoice(),
      const Duration(seconds: 12),
      fallback: false,
    );
    if (!mounted) return;
    if (!ttsReady) {
      setState(() {
        _busy = false;
        _orbState = NovaOrbState.idle;
        _statusText =
            'Türkçe TTS sesi doğrulanamadı. AI setup konuşması engellendi.';
      });
      return;
    }

    final kernel = await _withSetupTimeout<LocalModelBootProgress>(
      widget.localModelService.verifyBrainKernelForBoot(),
      const Duration(minutes: 20),
      fallback: LocalModelBootProgress(
        phase: 'brain_kernel_timeout',
        percent: null,
        message:
            'Brain Kernel first-token proof 20 dakika içinde tamamlanmadı.',
        critical: true,
        receivedAt: DateTime.now(),
      ),
    );

    if (!mounted) return;
    if (kernel.critical) {
      setState(() {
        _busy = false;
        _orbState = _setupAsrListening
            ? NovaOrbState.listening
            : NovaOrbState.idle;
        _statusText = kernel.message.trim().isEmpty
            ? 'Brain Kernel first-token proof başarısız oldu.'
            : kernel.message.trim();
      });
      return;
    }

    _brainKernelVerified = true;
    debugPrint(
      'NOVA_SETUP_BOOT brain_kernel_verified_then_micro_setup_opening',
    );
    setState(() {
      _busy = true;
      _orbState = NovaOrbState.speaking;
      _statusText =
          'API beyin hattı doğrulandı. Setup açılışı SingleBrain otoritesinden başlatılıyor.';
    });

    debugPrint('NOVA_SETUP_BOOT generative_setup_opening_single_brain_start');
    _setupOpeningMicroInFlight = false;
    await _speakAndAdvance(
      text: _setupOpeningQuestion(),
      nextStep: _SetupStep.askAssistantName,
      status: 'İlk kurulum başladı. Asistan adı bekleniyor.',
      mode: NovaTtsMode.neuralLocal,
      textAlreadyFromHotpath: false,
    );
    await _ensureSetupSingleAsrListening(reason: 'after_brain_kernel_opening');
  }

  Future<void> _handleSetupStartFlowError(
    Object error,
    StackTrace stackTrace,
  ) async {
    debugPrint(
      'NOVA_SETUP_STARTFLOW_ERROR type=${error.runtimeType} error=$error',
    );
    debugPrint(stackTrace.toString());
    if (!mounted) return;

    setState(() {
      _busy = false;
      _orbState = _setupAsrListening
          ? NovaOrbState.listening
          : NovaOrbState.idle;
      _statusText =
          'Setup yerel AI cevabı olmadan ilerletilmedi. TTS/STT/ASR hazır tutuluyor; Brain Kernel tekrar denenmeli.';
    });
  }

  String _setupOpeningFallbackText() {
    return _setupOpeningQuestion();
  }

  String _setupOpeningQuestion() {
    return 'Bana hangi isimle seslenmemi istersin?';
  }

  // Deterministic setup voice plan was removed from spoken output.
  // Setup narration requires SingleBrainAuthority + authoritative API/native brain proof.

  bool _looksLikeModelBootFailure(String text) {
    final lower = text.toLowerCase();
    return lower.contains('zaman aşım') ||
        lower.contains('belleğe alınırken') ||
        lower.contains('modelbridge') ||
        lower.contains('native_model_timeout') ||
        lower.contains('yerel model') && lower.contains('cevap dönmedi');
  }

  bool _looksLikeStaticSetupLeak(String text) {
    final lower = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (lower.isEmpty) return true;
    const blocked = <String>[
      'merhaba! ilk kurulum tamamlandı',
      'ilk kurulum tamamlandı',
      'nasıl yardımcı olabilirim',
      'ne yapmamı istersin',
      'ok_real_local_model',
      'setup_boot_status',
      'blocked_non_ai_speech',
      'setup açılış mikro gemma cevabı',
      'singlebrainauthority zamanında dönmedi',
      'yerel model hazır değil',
      'modelbridge',
      'native_model_timeout',
      'debug',
      'system prompt',
      'nova human runtime capsule',
      'kullanıcı girdisi:',
      'yanıt biçimi:',
    ];
    return blocked.any(lower.contains);
  }

  bool _looksLikeBrokenSetupTurkish(String text) {
    final lower = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (lower.isEmpty) return true;
    if (lower.contains('beni seslensin')) return true;
    if (lower.contains('beni seslenmesini')) return true;
    if (lower.contains('sen beni') && lower.contains('seslen')) return true;
    if (lower.contains('şimdi sen beni')) return true;
    if (lower.contains('simdi sen beni')) return true;
    if (lower.contains('hangi isimle sesleneceğini') &&
        !lower.contains('istediğinizi') &&
        !lower.contains('istersin')) {
      return true;
    }
    return false;
  }

  String _sanitizeSetupSpokenText(String input) {
    try {
      debugPrint('NOVA_SETUP_SANITIZE_START chars=${input.length}');
      var text = input.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isEmpty) return '';
      text = text
          .replaceAll(
            RegExp(
              r'debug|log|kod|katman listesi|system prompt|prompt',
              caseSensitive: false,
              unicode: true,
            ),
            '',
          )
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final pieces = RegExp(r'[^.!?…]+[.!?…]?')
          .allMatches(text)
          .map((m) => m.group(0)?.trim() ?? '')
          .where((e) => e.isNotEmpty)
          .take(2)
          .toList(growable: false);
      text = pieces.isEmpty ? text : pieces.join(' ');
      return _limitSetupSpeechText(text, maxChars: 240, minLastSpace: 140);
    } catch (error, stackTrace) {
      debugPrint(
        'NOVA_SETUP_SANITIZE_ERROR type=${error.runtimeType} error=$error',
      );
      debugPrint(stackTrace.toString());
      return _limitSetupSpeechText(
        input.replaceAll(RegExp(r'\s+'), ' ').trim(),
        maxChars: 240,
        minLastSpace: 140,
      );
    }
  }

  String _limitSetupSpeechText(
    String input, {
    required int maxChars,
    required int minLastSpace,
  }) {
    var text = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length > maxChars) {
      text = text.substring(0, maxChars).trimRight();
      final lastSpace = text.lastIndexOf(' ');
      if (lastSpace > minLastSpace)
        text = text.substring(0, lastSpace).trimRight();
      if (!text.endsWith('.') && !text.endsWith('!') && !text.endsWith('?'))
        text = '$text.';
    }
    return text;
  }

  void _advanceSetupByVerifiedAiDecision(
    _SetupStep nextStep, {
    required String reason,
  }) {
    if (!_brainKernelVerified) {
      debugPrint(
        'NOVA_SETUP_ADVANCE_BLOCKED reason=$reason nextStep=$nextStep brainKernelVerified=false',
      );
      return;
    }
    if (_step != nextStep) {
      _setupStepMismatchCount = 0;
    }
    _step = nextStep;
    debugPrint(
      'NOVA_SETUP_ADVANCED_BY_AI_DECISION reason=$reason nextStep=$nextStep',
    );
  }

  Future<void> _speakAndAdvance({
    required String text,
    required _SetupStep nextStep,
    required String status,
    NovaTtsMode mode = NovaTtsMode.neuralLocal,
    bool textAlreadyFromHotpath = false,
    AiResponse? authorityResponse,
  }) async {
    if (!mounted) return;

    setState(() {
      _busy = true;
      _orbState = NovaOrbState.speaking;
      _statusText = status;
    });

    AiResponse? speechAuthorityResponse = authorityResponse;
    final spoken = _normalizeSetupPercentSpeech(
      textAlreadyFromHotpath ? text.trim() : await _safeRenderSetupSpeech(text),
    );
    if (!textAlreadyFromHotpath) {
      speechAuthorityResponse = _lastSetupSpeechAuthorityResponse;
    }
    debugPrint(
      'NOVA_SETUP_TTS_SPEAK_START nextStep=$nextStep mode=$mode '
      'source=${textAlreadyFromHotpath ? 'setup_hotpath_ai_output' : 'setup_single_brain_authority'} '
      'tts_source=${textAlreadyFromHotpath ? 'brain_decision_ai_output' : NovaSingleBrainAuthorityService.brainTtsSource} '
      'textChars=${spoken.length}',
    );
    if (spoken.trim().isEmpty) {
      debugPrint(
        'NOVA_SETUP_TTS_BLOCKED_EMPTY_SINGLE_BRAIN nextStep=$nextStep',
      );
      if (mounted) {
        setState(() {
          _busy = false;
          _orbState = _setupAsrListening
              ? NovaOrbState.listening
              : NovaOrbState.idle;
          _statusText =
              'API beyin cevabı gelmeden setup ilerletilmedi. TTS/STT/ASR açık tutuluyor.';
        });
      }
      return;
    }
    if (!_hasSetupSpeechAuthorityProof(speechAuthorityResponse)) {
      debugPrint(
        'NOVA_SETUP_TTS_BLOCKED_NO_AUTHORITY_PROOF nextStep=$nextStep',
      );
      if (mounted) {
        setState(() {
          _busy = false;
          _orbState = _setupAsrListening
              ? NovaOrbState.listening
              : NovaOrbState.idle;
          _statusText =
              'SingleBrain/API beyin konuşma kanıtı gelmeden setup ilerletilmedi.';
        });
      }
      return;
    }

    var ttsCompleted = false;
    _setupSpeechActive = true;
    _suppressSetupAsrWhileSpeaking = true;
    try {
      await _withSetupTimeout<void>(
        widget.ttsService.speak(
          spoken,
          mode: mode,
          authoritySource: 'setup_single_brain_output',
          authorityResponse: speechAuthorityResponse,
        ),
        _setupTtsTimeoutFor(spoken),
      );
      ttsCompleted = true;
      debugPrint('NOVA_SETUP_TTS_SPEAK_DONE nextStep=$nextStep');
    } catch (error, stackTrace) {
      debugPrint(
        'NOVA_SETUP_TTS_SPEAK_ERROR nextStep=$nextStep type=${error.runtimeType} error=$error',
      );
      debugPrint(stackTrace.toString());
    } finally {
      _setupSpeechActive = false;
      _suppressSetupAsrWhileSpeaking = false;
      _lastSetupSpeechEndedAt = DateTime.now();
    }

    if (!mounted) return;
    if (!ttsCompleted) {
      setState(() {
        _busy = false;
        _orbState = _setupAsrListening
            ? NovaOrbState.listening
            : NovaOrbState.idle;
        _statusText =
            'TTS konuşması tamamlanmadığı için setup ilerletilmedi. Tekrar dinlemeye hazır.';
      });
      return;
    }

    setState(() {
      _busy = false;
      _advanceSetupByVerifiedAiDecision(
        nextStep,
        reason: 'tts_completed_verified_ai_output',
      );
      _orbState = NovaOrbState.listening;
    });

    _scheduleAutoAdvance();
  }

  bool _hasSetupSpeechAuthorityProof(AiResponse? response) {
    if (response == null || response.isError) return false;
    final meta = response.metadata;
    final nativeProof =
        response.hasAuthoritativeBrainProof ||
        meta['nativeSuccess'] == true ||
        meta['authoritativeLocalBrain'] == true ||
        meta['acceptedNativeText'] == true ||
        meta['rawNativeLocalModel'] == true;
    final strictProof =
        meta['singleBrainAllowed'] == true &&
        meta['singleBrainAuthority'] == true &&
        meta['tts_source'] == NovaSingleBrainAuthorityService.brainTtsSource &&
        meta['modelUsed'] == true &&
        NovaFinalTextContract.maySpeakMetadata(meta) &&
        nativeProof;
    if (!strictProof) {
      debugPrint(
        'NOVA_SETUP_TTS_AUTHORITY_PROOF_REJECTED '
        'singleBrainAllowed=${meta['singleBrainAllowed']} '
        'singleBrainAuthority=${meta['singleBrainAuthority']} '
        'tts_source=${meta['tts_source']} '
        'modelUsed=${meta['modelUsed']} authorityProof=$nativeProof',
      );
    }
    return strictProof;
  }

  Future<bool> _speakStatus(
    String text, {
    NovaTtsMode mode = NovaTtsMode.neuralLocal,
  }) async {
    if (!mounted) return false;
    setState(() {
      _busy = true;
      _orbState = NovaOrbState.speaking;
      _statusText = text;
    });
    final spoken = _normalizeSetupPercentSpeech(
      await _safeRenderSetupSpeech(text),
    );
    final speechAuthorityResponse = _lastSetupSpeechAuthorityResponse;
    debugPrint(
      'NOVA_SETUP_TTS_STATUS_SPEAK_START source=setup_single_brain_status '
      'tts_source=${NovaSingleBrainAuthorityService.brainTtsSource} textChars=${spoken.length}',
    );
    if (spoken.trim().isEmpty) {
      debugPrint('NOVA_SETUP_STATUS_TTS_BLOCKED_EMPTY_SINGLE_BRAIN');
      if (mounted) {
        setState(() {
          _busy = false;
          _orbState = _setupAsrListening
              ? NovaOrbState.listening
              : NovaOrbState.idle;
          _statusText =
              'API beyin status cevabı gelmeden setup konuşması başlatılmadı.';
        });
      }
      return false;
    }
    if (!_hasSetupSpeechAuthorityProof(speechAuthorityResponse)) {
      debugPrint('NOVA_SETUP_STATUS_TTS_BLOCKED_NO_AUTHORITY_PROOF');
      if (mounted) {
        setState(() {
          _busy = false;
          _orbState = _setupAsrListening
              ? NovaOrbState.listening
              : NovaOrbState.idle;
          _statusText =
              'SingleBrain/API beyin status konuşma kanıtı gelmeden setup konuşması başlatılmadı.';
        });
      }
      return false;
    }
    var ttsCompleted = false;
    _setupSpeechActive = true;
    _suppressSetupAsrWhileSpeaking = true;
    try {
      await _withSetupTimeout<void>(
        widget.ttsService.speak(
          spoken,
          mode: mode,
          authoritySource: 'setup_single_brain_output',
          authorityResponse: speechAuthorityResponse,
        ),
        _setupTtsTimeoutFor(spoken),
      );
      ttsCompleted = true;
    } catch (error, stackTrace) {
      debugPrint(
        'NOVA_SETUP_STATUS_TTS_SPEAK_ERROR type=${error.runtimeType} error=$error',
      );
      debugPrint(stackTrace.toString());
    } finally {
      _setupSpeechActive = false;
      _suppressSetupAsrWhileSpeaking = false;
      _lastSetupSpeechEndedAt = DateTime.now();
    }
    if (!mounted) return false;
    setState(() {
      _busy = false;
      _orbState = NovaOrbState.listening;
      if (!ttsCompleted) {
        _statusText =
            'Setup status konuşması tamamlanmadı; ilerleme otomatik tetiklenmedi.';
      }
    });
    if (ttsCompleted) {
      _scheduleAutoAdvance();
    }
    return ttsCompleted;
  }

  Future<T> _withSetupTimeout<T>(
    Future<T> future,
    Duration timeout, {
    T? fallback,
  }) async {
    try {
      return await future.timeout(timeout);
    } catch (_) {
      if (fallback != null) return fallback;
      rethrow;
    }
  }

  Duration _setupTtsTimeoutFor(String text) {
    final normalizedLength = text.replaceAll(RegExp(r'\s+'), ' ').trim().length;
    final seconds = 14 + (normalizedLength / 7).ceil();
    return Duration(seconds: seconds.clamp(18, 70).toInt());
  }

  String _normalizeSetupPercentSpeech(String input) {
    var text = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return text;
    text = text.replaceAllMapped(
      RegExp(r'%(\s*)(\d{1,3})(?:[.,](?:\s|$))?'),
      (match) => 'yüzde ${match.group(2)} ',
    );
    text = text.replaceAllMapped(
      RegExp(r'\b[Yy]üzde\s+(\d{1,3})(?:[.,](?:\s|$))?'),
      (match) => 'yüzde ${match.group(1)} ',
    );
    text = text.replaceAllMapped(
      RegExp(r'\b(\d{1,3})\s*\.\s*c[ıiuü]\b', caseSensitive: false),
      (match) => match.group(1) ?? '',
    );
    text = text.replaceAllMapped(
      RegExp(r'\b(\d{1,3})\s*c[ıiuü]\b', caseSensitive: false),
      (match) => match.group(1) ?? '',
    );
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  bool _recentlyFinishedSetupSpeech({
    Duration window = const Duration(milliseconds: 2200),
  }) {
    final endedAt = _lastSetupSpeechEndedAt;
    if (endedAt == null) return false;
    return DateTime.now().difference(endedAt) <= window;
  }

  String _cleanSetupAsrTranscript(String input) {
    var text = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return '';
    text = text
        .replaceAll(RegExp(r'\[[^\]]*\]', unicode: true), ' ')
        .replaceAll(RegExp(r'\([^\)]*\)', unicode: true), ' ')
        .replaceAll(RegExp(r'\{[^\}]*\}', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return text;
  }

  bool _isLikelySetupNoiseTranscript(String text) {
    final stripped = _cleanSetupAsrTranscript(text);
    final lower = stripped.isEmpty
        ? text.toLowerCase().trim()
        : stripped.toLowerCase().trim();
    if (lower.isEmpty) return true;
    if (lower.length <= 1) return true;
    if (RegExp(r'^[\[\(].*[\]\)]$').hasMatch(lower)) return true;
    if (RegExp(r'^[^a-zA-ZçğıöşüÇĞİÖŞÜ0-9]+$', unicode: true).hasMatch(lower)) {
      return true;
    }
    final compact = lower.replaceAll(
      RegExp(r'[^a-zA-Zçğıöşü0-9]+', unicode: true),
      '',
    );
    const blockedFragments = <String>[
      'müzik çalıyor',
      'muzik caliyor',
      'müzik',
      'muzik',
      'şarkı',
      'sarki',
      'altyazı',
      'altyazi',
      'ses efekti',
      'background music',
      'music playing',
      'playing music',
      'hışırtı',
      'hisirti',
      'cızırtı',
      'cizirti',
      'gürültü',
      'gurultu',
      'nefes',
      'uğultu',
      'ugultu',
      'sessizlik',
      'anlaşılmıyor',
      'anlasilmiyor',
      'bilinmeyen ses',
      'unknown sound',
      'noise',
      'static',
      'applause',
      'alkış',
      'alkis',
      'live caption',
      'caption',
    ];
    for (final fragment in blockedFragments) {
      if (lower == fragment || lower.contains(fragment)) return true;
    }
    if (compact.length <= 2) return true;
    final words = lower
        .split(RegExp(r'\s+'))
        .where((e) => e.trim().isNotEmpty)
        .toList(growable: false);
    if (words.length == 1) {
      final one = words.first;
      const filler = <String>{
        'ıı',
        'ee',
        'aaa',
        'hmm',
        'hm',
        'ha',
        'he',
        'hı',
        'hi',
        'ah',
        'eh',
      };
      if (filler.contains(one)) return true;
    }
    if (words.length >= 5) {
      final counts = <String, int>{};
      for (final word in words) {
        counts[word] = (counts[word] ?? 0) + 1;
      }
      final maxCount = counts.values.fold<int>(0, (a, b) => a > b ? a : b);
      if (maxCount >= 3 && maxCount / words.length >= 0.38) return true;
    }
    if (lower.length > 120 &&
        !(lower.contains('adım') ||
            lower.contains('ismim') ||
            lower.contains('adın') ||
            lower.contains('ismin'))) {
      return true;
    }
    return false;
  }

  bool _isTranscriptCompatibleWithSetupStep(String text) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty || _isLikelySetupNoiseTranscript(cleaned)) return false;
    switch (_step) {
      case _SetupStep.askAssistantName:
        return _extractAssistantNameMeaning(
          cleaned,
          requireExplicit: true,
        ).isNotEmpty;
      case _SetupStep.confirmAssistantName:
      case _SetupStep.confirmOwnerName:
      case _SetupStep.confirmWelcomeText:
      case _SetupStep.askVoiceConsent:
        return _isPositiveAnswer(cleaned) || _isNegativeAnswer(cleaned);
      case _SetupStep.askOwnerName:
        final name = _extractOwnerNameMeaning(cleaned).trim();
        return name.length >= 2 &&
            name.split(RegExp(r'\s+')).length <= 3 &&
            RegExp(r'^[A-Za-zÇĞİIÖŞÜçğıiöşü ]+$', unicode: true).hasMatch(name);
      case _SetupStep.askWelcomeText:
        return cleaned.length >= 3 && cleaned.length <= 180;
      case _SetupStep.welcome:
      case _SetupStep.rolloutIdentity:
      case _SetupStep.saving:
      case _SetupStep.done:
        return true;
    }
  }

  bool _shouldIgnoreSetupStreamingText(String text) {
    if (_isLikelySetupNoiseTranscript(text)) return true;
    if (_suppressSetupAsrWhileSpeaking || _setupSpeechActive) return true;
    if (_recentlyFinishedSetupSpeech()) return true;
    return false;
  }

  String _safeLogPreview(String input, {int maxChars = 180}) {
    final compact = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= maxChars) return compact;
    return '${compact.substring(0, maxChars)}…';
  }

  Future<String> _safeRenderSetupSpeech(String text) async {
    // LEGACY_SETUP_ROUTE_SPEECH_DISABLED_V3:
    // This onboarding page is no longer the active first-run voice route.
    // Static setup strings must not be rewritten into speech from here.
    // Dashboard readiness + NovaCoreTurnController own setup dialogue.
    _lastSetupSpeechAuthorityResponse = null;
    return '';
  }

  void _handleLocalModelBootProgress(LocalModelBootProgress progress) {
    if (!mounted) return;
    _lastBootProgress = progress;
    if (progress.phase == 'brain_kernel_verified') {
      _brainKernelVerified = true;
    }
    final message = _sanitizeModelBootMessage(progress);
    final text = progress.hasRealPercent
        ? '$message %${progress.percent}'
        : message;
    final visibleText = _normalizeSetupPercentSpeech(
      text.trim().isEmpty ? progress.phase : text,
    );
    setState(() {
      _statusText = visibleText;
      if (progress.critical) {
        _busy = false;
        _orbState = _setupAsrListening
            ? NovaOrbState.listening
            : NovaOrbState.idle;
      } else if (_orbState == NovaOrbState.idle) {
        _orbState = _setupAsrListening
            ? NovaOrbState.listening
            : NovaOrbState.speaking;
      }
    });

    unawaited(
      NovaRuntimeSignalService.instance.record(
        kind: NovaRuntimeSignalKind.localModel,
        level: progress.critical
            ? NovaRuntimeSignalLevel.error
            : NovaRuntimeSignalLevel.info,
        code: 'local_model_${progress.phase}',
        message: visibleText,
        technicalDetails:
            'phase=${progress.phase} percent=${progress.percent ?? -1} critical=${progress.critical}',
        diagnosticCandidate: progress.critical,
        metadata: <String, dynamic>{
          'phase': progress.phase,
          'percent': progress.percent,
          'critical': progress.critical,
          'source': 'setup_boot_progress',
        },
      ),
    );

    final shouldSpeakPercent =
        progress.hasRealPercent &&
        progress.percent != null &&
        (progress.percent == 0 ||
            progress.percent == 100 ||
            _lastSpokenModelPercent == null ||
            (progress.percent! - _lastSpokenModelPercent!).abs() >= 25);
    final shouldSpeakPhase =
        !progress.hasRealPercent &&
        progress.phase != _lastSpokenModelPhase &&
        (progress.phase == 'native_model_loading' ||
            progress.phase == 'native_model_timeout' ||
            progress.phase == 'native_model_failed' ||
            progress.phase == 'model_prepare_failed' ||
            progress.phase == 'brain_kernel_failed');

    final shouldSuppressAfterKernel =
        _brainKernelVerified && progress.phase != 'brain_kernel_verified';
    final alreadyNarratedKernel =
        progress.phase == 'brain_kernel_verified' &&
        _brainKernelVerifiedNarrated;

    if (false &&
        !_setupSpeechActive &&
        !_suppressSetupAsrWhileSpeaking &&
        !shouldSuppressAfterKernel &&
        !alreadyNarratedKernel &&
        (shouldSpeakPercent || shouldSpeakPhase)) {
      _lastSpokenModelPercent = progress.percent;
      _lastSpokenModelPhase = progress.phase;
      if (progress.phase == 'brain_kernel_verified') {
        _brainKernelVerifiedNarrated = true;
      }
      _lastBootNarrationAt = DateTime.now();
      final spoken = progress.hasRealPercent
          ? '$message yüzde ${progress.percent} tamamlandı'
          : message;
      _speakSetupBootNarration(
        spoken,
        reason: 'local_model_boot_progress_${progress.phase}',
      );
    }
  }

  String _sanitizeModelBootMessage(LocalModelBootProgress progress) {
    var message = progress.message.trim().isEmpty
        ? progress.phase
        : progress.message.trim();
    message = message
        .replaceAll(
          RegExp(
            'yerel düşünme motoru gerçek cevap üretti',
            caseSensitive: false,
          ),
          'API beyin doğrulandı',
        )
        .replaceAll(
          RegExp(
            'local thinking engine produced real response',
            caseSensitive: false,
          ),
          'API beyin doğrulandı',
        )
        .replaceAll(
          RegExp('brain kernel verified', caseSensitive: false),
          'Tek beyin çekirdeği doğrulandı',
        )
        .replaceAll(
          RegExp(
            r'yerel model ilk (?:çıkarımı|cikarimi).*',
            caseSensitive: false,
            unicode: true,
          ),
          'API beyin cevap hazırlıyor',
        )
        .replaceAll(
          RegExp(r'native inference.*', caseSensitive: false, unicode: true),
          'API beyin cevap hazırlıyor',
        )
        .replaceAll(
          RegExp(
            r'prompt\s*\d+\s*char[^.]*',
            caseSensitive: false,
            unicode: true,
          ),
          'API beyin cevap hazırlıyor',
        )
        .replaceAll(
          RegExp(
            r'system\s*\d+\s*char[^.]*',
            caseSensitive: false,
            unicode: true,
          ),
          'API beyin bağlamı hazır',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (progress.phase == 'brain_kernel_verified') {
      return 'Tek beyin çekirdeği doğrulandı';
    }
    return message;
  }

  String _targetDescriptionForStep(_SetupStep step) {
    switch (step) {
      case _SetupStep.askAssistantName:
      case _SetupStep.confirmAssistantName:
        return '${_displayAssistantName} asistan adı';
      case _SetupStep.askOwnerName:
      case _SetupStep.confirmOwnerName:
        return '${_displayAssistantName} cihaz sahibi adı';
      case _SetupStep.askWelcomeText:
      case _SetupStep.confirmWelcomeText:
        return '${_displayAssistantName} karşılama cümlesi';
      case _SetupStep.askVoiceConsent:
        return '${_displayAssistantName} kurulum onayı';
      default:
        return '${_displayAssistantName} kurulum yanıtı';
    }
  }

  void _handleSetupStreamingEvent(NovaStreamingAsrEvent event) {
    final raw = event.transcript.text.trim();
    if (raw.isEmpty) return;
    final normalized = _cleanSetupAsrTranscript(
      raw.replaceAll(RegExp(r'\s+'), ' ').trim(),
    );
    if (normalized.isEmpty) return;
    if (_shouldIgnoreSetupStreamingText(normalized)) {
      debugPrint(
        'NOVA_SETUP_ASR_IGNORED reason=setup_speech_or_noise final=${event.isFinal} chars=${normalized.length}',
      );
      return;
    }
    if (event.isFinal) {
      if (_isLikelySetupNoiseTranscript(normalized)) {
        debugPrint(
          'NOVA_SETUP_ASR_FINAL_REJECTED_NOISE chars=${normalized.length}',
        );
        return;
      }
      debugPrint('NOVA_SETUP_ASR_FINAL chars=${normalized.length}');
      _recentSetupStreamingFinal = normalized;
      _recentSetupStreamingFinalAt = DateTime.now();
      _maybeAnswerBootQuestionFromStreaming(normalized);
      return;
    }
    if (event.isPartial) {
      debugPrint('NOVA_SETUP_ASR_PARTIAL chars=${normalized.length}');
      _recentSetupStreamingPartial = normalized;
      _recentSetupStreamingPartialAt = DateTime.now();
    }
  }

  bool _isBootStatusQuestion(String text) {
    final lower = text.toLowerCase().trim();
    return lower.contains('ne yapıyorsun') ||
        lower.contains('hangi aşama') ||
        lower.contains('ne aşama') ||
        lower.contains('durum') ||
        lower.contains('çalışıyor musun') ||
        lower.contains('calisiyor musun') ||
        lower.contains('beni duyuyor musun') ||
        lower.contains('mikrofon açık mı') ||
        lower.contains('mikrofon acik mi') ||
        lower.contains('setup') ||
        lower.contains('kurulum');
  }

  void _maybeAnswerBootQuestionFromStreaming(String text) {
    if (!mounted ||
        _step != _SetupStep.welcome ||
        !_flowBootStarted ||
        !_brainKernelVerified)
      return;
    if (!_isBootStatusQuestion(text)) return;
    final now = DateTime.now();
    if (_lastBootQuestionAnswerAt != null &&
        now.difference(_lastBootQuestionAnswerAt!) <
            const Duration(seconds: 8)) {
      return;
    }
    _lastBootQuestionAnswerAt = now;

    final progress = _lastBootProgress;
    final progressText = progress == null
        ? 'Brain Kernel first-token proof bekleniyor.'
        : progress.displayMessage;
    final micText = _setupAsrListening
        ? 'Mikrofon ve dinleme zinciri açık.'
        : 'Mikrofon zinciri henüz doğrulanamadı: $_setupAsrStatus';
    final brainText = _brainKernelVerified
        ? 'API beyin doğrulandı.'
        : 'Yerel beynin ilk güvenli cevabını bekliyorum; bu aşamada sahte sohbet başlatmıyorum.';
    final answer = '$micText $brainText Şu anki aşama: $progressText';

    unawaited(
      () async {
        final renderedAnswer = _normalizeSetupPercentSpeech(
          await _safeRenderSetupSpeech(answer),
        );
        final renderedAnswerAuthorityResponse =
            _lastSetupSpeechAuthorityResponse;
        if (renderedAnswer.trim().isNotEmpty &&
            _hasSetupSpeechAuthorityProof(renderedAnswerAuthorityResponse)) {
          await widget.ttsService.speak(
            renderedAnswer,
            mode: NovaTtsMode.neuralLocal,
            interruptCurrentSpeech: false,
            authoritySource: 'setup_single_brain_output',
            authorityResponse: renderedAnswerAuthorityResponse,
          );
        } else {
          debugPrint(
            'NOVA_SETUP_BOOT_STATUS_TTS_BLOCKED_NO_AUTHORITY chars=${renderedAnswer.length}',
          );
        }
      }().catchError((_) {}),
    );
  }

  Future<String?> _listenFromStreaming({
    required Duration maxWait,
    required Duration stablePartialWindow,
  }) async {
    final startedAt = DateTime.now();
    _recentSetupStreamingFinal = '';
    _recentSetupStreamingPartial = '';
    _recentSetupStreamingFinalAt = null;
    _recentSetupStreamingPartialAt = null;
    String lastPartial = '';
    DateTime? lastPartialChangedAt;

    while (mounted && DateTime.now().difference(startedAt) <= maxWait) {
      final finalAt = _recentSetupStreamingFinalAt;
      final finalText = _recentSetupStreamingFinal.trim();
      if (finalAt != null &&
          finalAt.isAfter(startedAt) &&
          finalText.length >= 3 &&
          !_isLikelySetupNoiseTranscript(finalText)) {
        return finalText;
      }

      final partialAt = _recentSetupStreamingPartialAt;
      final partialText = _recentSetupStreamingPartial.trim();
      if (partialText != lastPartial) {
        lastPartial = partialText;
        lastPartialChangedAt = DateTime.now();
      }
      if (partialAt != null &&
          partialAt.isAfter(startedAt) &&
          partialText.length >= 6 &&
          lastPartialChangedAt != null &&
          DateTime.now().difference(lastPartialChangedAt!) >=
              stablePartialWindow &&
          DateTime.now().difference(startedAt) >=
              Duration(milliseconds: (maxWait.inMilliseconds * 0.65).round()) &&
          !_isLikelySetupNoiseTranscript(partialText)) {
        return partialText;
      }
      await Future<void>.delayed(const Duration(milliseconds: 160));
    }
    return null;
  }

  Future<bool> _hasFreshSetupSpeechGate({
    Duration maxAge = const Duration(milliseconds: 2200),
  }) async {
    try {
      final state = await widget.sttService.nativeBridge
          .getStreamingVoiceGateState();
      final running = state['running'] as bool? ?? false;
      if (!running) return false;
      final speechActive = state['speechActive'] as bool? ?? false;
      final speechRecentlyActive =
          state['speechRecentlyActive'] as bool? ?? false;
      if (speechActive || speechRecentlyActive) return true;
      final lastSampleRaw = state['lastSampleAt']?.toString() ?? '';
      final lastSampleAt = DateTime.tryParse(lastSampleRaw);
      if (lastSampleAt != null &&
          DateTime.now().difference(lastSampleAt) <= maxAge) {
        final avgRms = (state['avgRms'] as num?)?.toDouble() ?? 0.0;
        final threshold = (state['speechThreshold'] as num?)?.toDouble() ?? 0.0;
        return threshold > 0 && avgRms >= threshold;
      }
    } catch (_) {}
    return false;
  }

  Future<String?> _decodeSetupStreamingSnapshot({
    required Duration maxWait,
    required String targetDescription,
  }) async {
    if (!await _hasFreshSetupSpeechGate()) {
      debugPrint('NOVA_SETUP_ASR_SNAPSHOT_SKIPPED reason=no_fresh_voice_gate');
      return null;
    }
    try {
      final result = await widget.sttService.nativeBridge
          .decodeStreamingSnapshot(
            AudioCaptureRequest(
              mode: NovaListeningMode.normalCommandListening,
              maxDurationSeconds: maxWait.inSeconds.clamp(6, 14).toInt(),
              targetDescription: targetDescription,
            ),
          );
      final text = _cleanSetupAsrTranscript(
        result.recognizedText.replaceAll(RegExp(r'\s+'), ' ').trim(),
      );
      debugPrint(
        'NOVA_SETUP_ASR_SNAPSHOT success=${result.success} chars=${text.length} message=${result.message}',
      );
      if (result.success && text.length >= 2) {
        return text;
      }
    } catch (error, stackTrace) {
      debugPrint(
        'NOVA_SETUP_ASR_SNAPSHOT_ERROR type=${error.runtimeType} error=$error',
      );
      debugPrint(stackTrace.toString());
    }
    return null;
  }

  void _scheduleRetryForCurrentStep([
    Duration delay = const Duration(milliseconds: 850),
  ]) {
    _autoStepTimer?.cancel();
    if (_busy) return;
    final step = _step;
    const autoSteps = <_SetupStep>{_SetupStep.rolloutIdentity};
    if (!autoSteps.contains(step)) return;
    _autoStepTimer = Timer(delay, () {
      if (!mounted || _busy || _step != step) return;
      unawaited(_handlePrimaryAction());
    });
  }

  String _repairOwnerNameCandidate(String input) {
    final ownerMatch = RegExp(
      r'(?:benim\s+)?(?:adım|ismim)\s+([A-Za-zÇĞİIÖŞÜçğıiöşü]{2,32}(?:\s+[A-Za-zÇĞİIÖŞÜçğıiöşü]{2,32}){0,2})',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(input.trim());
    final source = ownerMatch?.group(1)?.trim() ?? input;
    final normalized = _spokenIntentInterpreter.normalizeMeaning(source).trim();
    final lower = normalized.toLowerCase();
    const directFixes = <String, String>{
      'yerinde': 'İbrahim',
      'yerin de': 'İbrahim',
      'yerimde': 'İbrahim',
      'ibraim': 'İbrahim',
      'ibrahım': 'İbrahim',
      'ibrahim': 'İbrahim',
      'ibram': 'İbrahim',
    };
    return directFixes[lower] ?? normalized;
  }

  Future<String?> _listenOnce({
    required String emptyMessage,
    NovaSttMode mode = NovaSttMode.light,
  }) async {
    if (!mounted) return null;

    setState(() {
      _busy = true;
      _orbState = NovaOrbState.listening;
      _lastHeardText = '';
      _statusText = 'Sizi dinliyorum efendim...';
    });

    final streamingWindow = mode == NovaSttMode.enhanced
        ? const Duration(seconds: 8)
        : const Duration(seconds: 6);
    final stablePartialWindow = mode == NovaSttMode.enhanced
        ? const Duration(milliseconds: 1150)
        : const Duration(milliseconds: 900);

    var released = await widget.sttService.playbackGuardService
        .waitUntilPlaybackInactive(
          timeout: const Duration(seconds: 10),
          pollInterval: const Duration(milliseconds: 180),
        );
    if (!released && !_setupSpeechActive) {
      // Setup sırasında önceki TTS timeout'u playback guard'ı açık bırakırsa
      // kurulum cevap alamaz hale geliyordu. Bu yalnızca setup dinleme adımında
      // stale guard'ı kapatır; owner/security katmanını bypass etmez.
      await widget.sttService.playbackGuardService.markPlaybackEnded();
      released = await widget.sttService.playbackGuardService
          .waitUntilPlaybackInactive(
            timeout: const Duration(milliseconds: 900),
          );
    }
    if (!released) {
      if (!mounted) return null;
      setState(() {
        _busy = false;
        _orbState = NovaOrbState.idle;
        _statusText =
            '${_displayAssistantName} kendi sesini duymamak için kısa bir an bekliyor.';
      });
      _scheduleRetryForCurrentStep(const Duration(milliseconds: 900));
      return null;
    }

    // Canlı runtime logunda setup TTS sonrasında native streaming buffer'ın
    // eski/TTS/arka plan sesini snapshot olarak tekrar decode ettiği görüldü.
    // Her setup dinleme turundan önce buffer temizlenir; bu SingleBrain kararını
    // veya ASR servis sahipliğini değiştirmez, yalnız stale transcript'i düşürür.
    _recentSetupStreamingFinal = '';
    _recentSetupStreamingPartial = '';
    _recentSetupStreamingFinalAt = null;
    _recentSetupStreamingPartialAt = null;
    try {
      await _withSetupTimeout<void>(
        _setupStreamingAsrRuntimeService.flush(),
        const Duration(milliseconds: 700),
      );
      await Future<void>.delayed(const Duration(milliseconds: 180));
    } catch (_) {}

    final bool streamingPreferred = _setupStreamingAsrRuntimeService.isStarted;
    String? heard = streamingPreferred
        ? await _listenFromStreaming(
            maxWait: streamingWindow,
            stablePartialWindow: stablePartialWindow,
          )
        : null;

    if (heard == null || heard.trim().isEmpty) {
      heard = await _decodeSetupStreamingSnapshot(
        maxWait: streamingWindow,
        targetDescription: _targetDescriptionForStep(_step),
      );
    }

    if ((heard == null || heard.trim().isEmpty) && !streamingPreferred) {
      try {
        await _setupStreamingAsrRuntimeService.start();
        await widget.sttService.nativeBridge.startStreamingVoiceGate();
        await widget.sttService.nativeBridge.ensureStreamingAsrReady();
        heard = await _listenFromStreaming(
          maxWait: streamingWindow,
          stablePartialWindow: stablePartialWindow,
        );
        if (heard == null || heard.trim().isEmpty) {
          heard = await _decodeSetupStreamingSnapshot(
            maxWait: streamingWindow,
            targetDescription: _targetDescriptionForStep(_step),
          );
        }
      } catch (error, stackTrace) {
        debugPrint(
          'NOVA_SETUP_ASR_RESTART_LISTEN_ERROR type=${error.runtimeType} error=$error',
        );
        debugPrint(stackTrace.toString());
      }
    }

    if (!mounted) return null;

    final cleaned = _cleanSetupAsrTranscript(
      heard?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '',
    );
    if (cleaned.isNotEmpty) {
      debugPrint(
        'NOVA_SETUP_ASR_TRANSCRIPT_RECEIVED step=$_step chars=${cleaned.length} '
        'asr_transcript_received="${_safeLogPreview(cleaned)}"',
      );
    }

    setState(() {
      _busy = false;
      _lastHeardText = cleaned;
    });

    if (cleaned.isNotEmpty && _isLikelySetupNoiseTranscript(cleaned)) {
      setState(() {
        _statusText =
            'Arka plan sesi kurulum cevabı olarak alınmadı efendim. Sizi tekrar dinliyorum.';
        _orbState = NovaOrbState.idle;
      });
      _scheduleRetryForCurrentStep(const Duration(milliseconds: 600));
      return null;
    }

    final bool isSetupSideQuestion =
        cleaned.isNotEmpty && _looksLikeConversationalInterruption(cleaned);
    if (cleaned.isNotEmpty &&
        !_isTranscriptCompatibleWithSetupStep(cleaned) &&
        !isSetupSideQuestion) {
      _setupStepMismatchCount += 1;
      debugPrint(
        'NOVA_SETUP_ASR_REJECTED_STEP_MISMATCH step=$_step count=$_setupStepMismatchCount '
        'chars=${cleaned.length} text="${_safeLogPreview(cleaned)}"',
      );
      if (_setupStepMismatchCount >= 2) {
        try {
          await _withSetupTimeout<void>(
            _setupStreamingAsrRuntimeService.flush(),
            const Duration(milliseconds: 700),
          );
        } catch (_) {}
      }
      final retryDelay = _setupStepMismatchCount >= 5
          ? const Duration(seconds: 3)
          : (_setupStepMismatchCount >= 3
                ? const Duration(milliseconds: 1600)
                : const Duration(milliseconds: 750));
      setState(() {
        _statusText = _setupStepMismatchCount >= 3
            ? 'Arka plan veya uyumsuz sesi kurulum cevabı saymadım efendim. Kısa ve net cevabınızı bekliyorum.'
            : 'Bu sesi kurulum adımıyla eşleştiremedim efendim. Lütfen cevabı kısa ve net tekrar söyleyin.';
        _orbState = NovaOrbState.idle;
      });
      _scheduleRetryForCurrentStep(retryDelay);
      return null;
    }

    if (cleaned.isEmpty) {
      setState(() {
        _statusText = emptyMessage;
        _orbState = NovaOrbState.idle;
      });
      _scheduleRetryForCurrentStep();
      return null;
    }

    _setupStepMismatchCount = 0;
    return cleaned;
  }

  String _extractMeaningfulText(String input) {
    var text = input.trim();
    if (text.isEmpty) return '';

    final lower = text.toLowerCase();

    const prefixes = <String>[
      'benim adım ',
      'benim ismim ',
      'adım ',
      'ismim ',
      'bana ',
      'beni ',
      'efendim ',
    ];

    for (final prefix in prefixes) {
      if (lower.startsWith(prefix)) {
        text = text.substring(prefix.length).trim();
        break;
      }
    }

    return _spokenIntentInterpreter.extractSetupResponseMeaning(text).trim();
  }

  String _extractAssistantNameMeaning(
    String input, {
    bool requireExplicit = false,
  }) {
    var text = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return '';
    final patterns = <RegExp>[
      RegExp(
        r'(?:senin\s+)?(?:adın|ismin)\s+([A-Za-zÇĞİIÖŞÜçğıiöşü0-9]{2,24})\s+(?:olsun|olacak|kalsın)',
        caseSensitive: false,
        unicode: true,
      ),
      RegExp(
        r'^([A-Za-zÇĞİIÖŞÜçğıiöşü0-9]{2,24})\s+(?:olsun|kalsın|kalabilir)$',
        caseSensitive: false,
        unicode: true,
      ),
      RegExp(
        r'(?:sana|seni)\s+([A-Za-zÇĞİIÖŞÜçğıiöşü0-9]{2,24})\s+(?:diye\s+)?(?:sesleneceğim|çağıracağım|cagiracagim|hitap edeceğim|hitap edecegim)',
        caseSensitive: false,
        unicode: true,
      ),
      RegExp(
        r'(?:bundan\s+sonra|artık|artik)\s+([A-Za-zÇĞİIÖŞÜçğıiöşü0-9]{2,24})\s+(?:ol|olsun|diye)',
        caseSensitive: false,
        unicode: true,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      final candidate = match?.group(1)?.trim() ?? '';
      if (_looksLikeValidAssistantName(candidate)) {
        return _spokenIntentInterpreter.normalizeMeaning(candidate).trim();
      }
    }

    if (requireExplicit) {
      if (_looksLikeValidAssistantName(text)) {
        return _spokenIntentInterpreter.normalizeMeaning(text).trim();
      }
      return '';
    }

    text = _extractMeaningfulText(text)
        .replaceAll(
          RegExp(
            r'\b(adın|ismin|olsun|olacak|kalsın|yap|bundan sonra|artık|artik|sana|seni|diye|hitap|et|seslen|çağır|cagir)\b',
            caseSensitive: false,
            unicode: true,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (!_looksLikeValidAssistantName(text)) return '';
    return _spokenIntentInterpreter.normalizeMeaning(text).trim();
  }

  bool _looksLikeValidAssistantName(String input) {
    final value = input.trim();
    if (value.length < 2 || value.length > 24) return false;
    if (value.split(RegExp(r'\s+')).length > 2) return false;
    final lower = value.toLowerCase();
    const blocked = <String>{
      'evet',
      'hayır',
      'hayir',
      'tamam',
      'olur',
      'bundan',
      'sonra',
      'şunu',
      'sunu',
      'bunu',
      'yapacaksın',
      'yapacaksin',
      'komut',
      'talimat',
    };
    if (blocked.contains(lower)) return false;
    return RegExp(
      r'^[A-Za-zÇĞİIÖŞÜçğıiöşü0-9 ]+$',
      unicode: true,
    ).hasMatch(value);
  }

  String _extractOwnerNameMeaning(String input) {
    final text = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return '';
    final patterns = <RegExp>[
      RegExp(
        r'(?:benim\s+)?(?:adım|ismim)\s+([A-Za-zÇĞİIÖŞÜçğıiöşü]{2,32}(?:\s+[A-Za-zÇĞİIÖŞÜçğıiöşü]{2,32}){0,2})',
        caseSensitive: false,
        unicode: true,
      ),
      RegExp(
        r'(?:bana|beni)\s+([A-Za-zÇĞİIÖŞÜçğıiöşü]{2,32}(?:\s+[A-Za-zÇĞİIÖŞÜçğıiöşü]{2,32}){0,2})\s+(?:diye\s+)?(?:çağır|cagir|seslen|hitap et)',
        caseSensitive: false,
        unicode: true,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      final candidate = _repairOwnerNameCandidate(
        match?.group(1)?.trim() ?? '',
      );
      if (_looksLikeValidOwnerName(candidate)) return candidate;
    }
    if (_looksLikeValidOwnerName(text)) {
      return _repairOwnerNameCandidate(text);
    }
    return '';
  }

  String _normalizeVoiceId(String base) {
    final cleaned = base
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9ğüşöçıİĞÜŞÖÇ ]', unicode: true), '')
        .replaceAll(RegExp(r'\s+'), '_');

    if (cleaned.isEmpty) {
      return 'owner_${DateTime.now().millisecondsSinceEpoch}';
    }

    return 'owner_$cleaned';
  }

  bool _looksLikeValidOwnerName(String input) {
    final value = input.trim();
    if (value.length < 2) return false;
    final normalized = value.toLowerCase();
    const blocked = <String>{
      'ay',
      'evet',
      'hayır',
      'hayir',
      'tamam',
      'olur',
      'hmm',
      'hm',
      'ee',
      'ıı',
      'aaa',
      'nova',
    };
    if (blocked.contains(normalized)) return false;
    final tokens = value
        .split(RegExp(r'\s+'))
        .where((e) => e.trim().isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty || tokens.length > 3) return false;
    for (final token in tokens) {
      final cleaned = token.replaceAll(
        RegExp(r'[^A-Za-zÇĞİIÖŞÜçğıiöşü]', unicode: true),
        '',
      );
      if (cleaned.length < 2) return false;
    }
    return true;
  }

  bool _isPositiveAnswer(String input) {
    final lower = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zçğıöşü0-9 ]+', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final words = lower
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty || words.length > 8) return false;
    const positiveWords = <String>{
      'evet',
      'tamam',
      'aynen',
      'doğru',
      'dogru',
      'olur',
      'onaylıyorum',
      'onayliyorum',
    };
    const exact = <String>{
      'evet',
      'tamam',
      'aynen',
      'doğru',
      'dogru',
      'olur',
      'onaylıyorum',
      'onayliyorum',
    };
    if (exact.contains(lower)) return true;
    if (words.every(positiveWords.contains)) {
      debugPrint(
        'NOVA_SETUP_CONFIRMATION_NORMALIZED positive=true raw="${_safeLogPreview(input)}" normalized="$lower"',
      );
      return true;
    }
    if (words.length <= 5 &&
        (lower.contains('evet doğru') ||
            lower.contains('evet dogru') ||
            lower.contains('tamam doğru') ||
            lower.contains('tamam dogru'))) {
      debugPrint(
        'NOVA_SETUP_CONFIRMATION_NORMALIZED positive=true raw="${_safeLogPreview(input)}" normalized="$lower"',
      );
      return true;
    }
    return false;
  }

  bool _isNegativeAnswer(String input) {
    final lower = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zçğıöşü0-9 ]+', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final words = lower
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty || words.length > 8) return false;
    const negativeWords = <String>{
      'hayır',
      'hayir',
      'yanlış',
      'yanlis',
      'değil',
      'degil',
      'tekrar',
    };
    const exact = <String>{
      'hayır',
      'hayir',
      'yanlış',
      'yanlis',
      'değil',
      'degil',
      'tekrar',
      'hayır tekrar',
      'hayir tekrar',
    };
    if (exact.contains(lower)) return true;
    if (words.every(negativeWords.contains)) {
      debugPrint(
        'NOVA_SETUP_CONFIRMATION_NORMALIZED negative=true raw="${_safeLogPreview(input)}" normalized="$lower"',
      );
      return true;
    }
    if (lower.contains('değiştir') || lower.contains('degistir')) return true;
    return false;
  }

  bool _looksLikeConversationalInterruption(String input) {
    final lower = input.toLowerCase().trim();
    if (lower.isEmpty) return false;

    if (_isPositiveAnswer(input) || _isNegativeAnswer(input)) return false;

    final explicitQuestion =
        lower.contains('?') ||
        lower.contains('kimsin') ||
        lower.contains('ne yapıyorsun') ||
        lower.contains('ne yapiyorsun') ||
        lower.contains('neden') ||
        lower.contains('niye') ||
        lower.contains('nasıl') ||
        lower.contains('nasil') ||
        lower.contains('yardım') ||
        lower.contains('yardim') ||
        lower.contains('ne soruyorsun') ||
        lower.contains('bir şey soracağım') ||
        lower.contains('bir sey soracagim') ||
        lower.contains('soru') ||
        lower.contains('bekle');

    final tokens = lower
        .split(RegExp(r'\s+'))
        .where((e) => e.trim().isNotEmpty)
        .toList(growable: false);
    final shortSetupAnswer = tokens.length <= 4 && !lower.contains('?');
    const setupInputSteps = <_SetupStep>{
      _SetupStep.askAssistantName,
      _SetupStep.confirmAssistantName,
      _SetupStep.askOwnerName,
      _SetupStep.confirmOwnerName,
      _SetupStep.askWelcomeText,
      _SetupStep.confirmWelcomeText,
      _SetupStep.askVoiceConsent,
    };

    if (setupInputSteps.contains(_step) &&
        shortSetupAnswer &&
        !explicitQuestion) {
      return false;
    }

    return explicitQuestion;
  }

  Future<String> _buildSetupSideReply(String input) async {
    final cleaned = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return '';
    final reply = switch (_step) {
      _SetupStep.askAssistantName =>
        'Anladım efendim. Önce bana hangi isimle seslenmek istediğinizi netleştirelim.',
      _SetupStep.confirmAssistantName =>
        'Anladım efendim. Bu adı onaylamak için sadece evet ya da hayır demeniz yeterli.',
      _SetupStep.askOwnerName =>
        'Anladım efendim. Şimdi sizin adınızı kısa ve net söylemenizi bekliyorum.',
      _SetupStep.confirmOwnerName =>
        'Anladım efendim. Sahibimin adını onaylamak için evet ya da hayır demeniz yeterli.',
      _SetupStep.askWelcomeText =>
        'Anladım efendim. Karşılama cümlenizi kısa şekilde söyleyebilirsiniz.',
      _SetupStep.confirmWelcomeText =>
        'Anladım efendim. Karşılama cümlesi doğruysa evet, değiştireceksek hayır deyin.',
      _SetupStep.askVoiceConsent =>
        'Anladım efendim. Ses tanıma izni için evet ya da hayır demeniz yeterli.',
      _ => 'Anladım efendim. Kurulumu koparmadan aynı adıma dönüyorum.',
    };
    debugPrint(
      'NOVA_SETUP_SIDE_REPLY_DETERMINISTIC step=$_step inputChars=${cleaned.length} replyChars=${reply.length}',
    );
    return reply;
  }

  Future<bool> _handlePossibleSetupSideConversation(
    String heard, {
    required _SetupStep returnStep,
    required String returnStatus,
  }) async {
    if (!_looksLikeConversationalInterruption(heard)) {
      return false;
    }
    final reply = await _buildSetupSideReply(heard);
    if (reply.trim().isEmpty) {
      debugPrint(
        'NOVA_SETUP_SIDE_CONVERSATION_NOT_CONSUMED reason=empty_authority_reply step=$_step',
      );
      return false;
    }
    final spoken = await _speakStatus(reply, mode: NovaTtsMode.neuralLocal);
    if (!spoken) {
      debugPrint(
        'NOVA_SETUP_SIDE_CONVERSATION_NOT_CONSUMED reason=tts_not_completed step=$_step',
      );
      return false;
    }
    if (!mounted) return true;
    setState(() {
      _advanceSetupByVerifiedAiDecision(
        returnStep,
        reason: 'side_conversation_ai_return',
      );
      _statusText = returnStatus;
      _orbState = NovaOrbState.listening;
    });
    return true;
  }

  Future<bool> _enrollOwnerVoiceSamples() async {
    final prompts = <String>[
      'Şimdi doğal bir cümleyle kendinizi tanıtın efendim.',
      'Bir cümle daha rica edeceğim efendim. Doğal şekilde konuşabilirsiniz.',
      'Son bir doğal örnek daha alıyorum efendim. Rahat bir cümle söylemeniz yeterli.',
    ];
    var successCount = 0;
    for (var i = 0; i < prompts.length; i++) {
      try {
        final renderedPrompt = _normalizeSetupPercentSpeech(
          await _safeRenderSetupSpeech(prompts[i]),
        );
        final renderedPromptAuthorityResponse =
            _lastSetupSpeechAuthorityResponse;
        debugPrint(
          'NOVA_SETUP_OWNER_ENROLL_TTS_START source=setup_single_brain_output '
          'tts_source=${NovaSingleBrainAuthorityService.brainTtsSource} textChars=${renderedPrompt.length}',
        );
        if (renderedPrompt.trim().isNotEmpty &&
            _hasSetupSpeechAuthorityProof(renderedPromptAuthorityResponse)) {
          await widget.ttsService.speak(
            renderedPrompt,
            mode: NovaTtsMode.neuralLocal,
            authoritySource: 'setup_single_brain_output',
            authorityResponse: renderedPromptAuthorityResponse,
          );
        } else {
          debugPrint(
            'NOVA_SETUP_OWNER_ENROLL_TTS_BLOCKED_NO_AUTHORITY chars=${renderedPrompt.length}',
          );
        }
      } catch (_) {}
      final enrolled = await widget.voiceIdentityRuntimeService
          .enrollFromFreshExternalSample(
            voiceId: _ownerVoiceId,
            displayName: _ownerName,
            maxDurationSeconds: 8,
            outputName: 'nova_owner_enroll_${i + 1}',
          );
      if (enrolled.success && enrolled.voiceId.trim().isNotEmpty) {
        successCount += 1;
      }
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
    return successCount >= 2;
  }

  Future<void> _handleAssistantNameStep() async {
    final heard = await _listenOnce(
      emptyMessage:
          'Asistan adını net duyamadım efendim. “Nova” gibi tek kelimeyle ya da “adın Nova olsun” diye söyleyebilirsiniz.',
      mode: NovaSttMode.enhanced,
    );
    if (heard == null) return;

    final consumed = await _handlePossibleSetupSideConversation(
      heard,
      returnStep: _SetupStep.askAssistantName,
      returnStatus: 'Asistan adı sesli olarak bekleniyor.',
    );
    if (consumed) return;

    await _identityRuntimeService.maybeApplyRenameInstruction(heard);
    final resolved = _extractAssistantNameMeaning(heard, requireExplicit: true);
    if (resolved.trim().isEmpty) {
      setState(() {
        _statusText =
            'Asistan adını net çıkaramadım efendim. Tek kelime isim söyleyebilir ya da “adın Nova olsun” diyebilirsiniz.';
        _orbState = NovaOrbState.idle;
      });
      _scheduleRetryForCurrentStep();
      return;
    }

    _pendingAssistantName = resolved.trim();
    await _speakAndAdvance(
      text:
          'Bana ${_pendingAssistantName.trim()} diye hitap edeceksiniz diye anladım efendim. Doğruysa evet deyin, değiştirmek isterseniz hayır deyin.',
      nextStep: _SetupStep.confirmAssistantName,
      status: 'Asistan adı onayı bekleniyor.',
      mode: NovaTtsMode.neuralLocal,
    );
  }

  Future<void> _handleConfirmAssistantNameStep() async {
    final heard = await _listenOnce(
      emptyMessage:
          'Onayı net duyamadım efendim. Doğruysa evet, değiştirmek isterseniz hayır diyebilirsiniz.',
    );
    if (heard == null) return;

    final consumed = await _handlePossibleSetupSideConversation(
      heard,
      returnStep: _SetupStep.confirmAssistantName,
      returnStatus: 'Asistan adı onayı bekleniyor.',
    );
    if (consumed) return;

    if (_isPositiveAnswer(heard)) {
      _assistantName = _pendingAssistantName.trim().isEmpty
          ? _assistantName
          : _pendingAssistantName.trim();
      await _speakAndAdvance(
        text:
            'Anladım efendim. Seçtiğiniz adı sesli kullanım için kaydediyorum. Kısa bir doğrulama yapıp devam edeceğim.',
        nextStep: _SetupStep.rolloutIdentity,
        status: 'Kimlik yayılımı başlatılıyor.',
        mode: NovaTtsMode.neuralLocal,
      );
      return;
    }

    if (_isNegativeAnswer(heard)) {
      await _speakAndAdvance(
        text:
            'Tamam efendim. Bana hangi isimle sesleneceğinizi tekrar söyleyin.',
        nextStep: _SetupStep.askAssistantName,
        status: 'Asistan adı yeniden bekleniyor.',
        mode: NovaTtsMode.neuralLocal,
      );
      return;
    }

    await _speakStatus(
      'Doğruysa evet, yanlışsa hayır demeniz yeterli efendim.',
      mode: NovaTtsMode.neuralLocal,
    );
  }

  Future<void> _handleIdentityRolloutStep() async {
    if (!mounted) return;
    setState(() {
      _busy = true;
      _orbState = NovaOrbState.speaking;
      _statusText = 'Kimlik yayılımı başlatılıyor. Yüzde 0';
    });

    const rolloutSpeech =
        'Sesli ad kaydını doğruluyorum efendim. Kısa bir eşitlemeden sonra sahibin adını soracağım.';
    try {
      final renderedRolloutSpeech = _normalizeSetupPercentSpeech(
        await _safeRenderSetupSpeech(rolloutSpeech),
      );
      final renderedRolloutSpeechAuthorityResponse =
          _lastSetupSpeechAuthorityResponse;
      debugPrint(
        'NOVA_SETUP_IDENTITY_ROLLOUT_TTS_START source=setup_single_brain_output '
        'tts_source=${NovaSingleBrainAuthorityService.brainTtsSource} textChars=${renderedRolloutSpeech.length}',
      );
      if (renderedRolloutSpeech.trim().isNotEmpty &&
          _hasSetupSpeechAuthorityProof(
            renderedRolloutSpeechAuthorityResponse,
          )) {
        await _withSetupTimeout<void>(
          widget.ttsService.speak(
            renderedRolloutSpeech,
            mode: NovaTtsMode.neuralLocal,
            authoritySource: 'setup_single_brain_output',
            authorityResponse: renderedRolloutSpeechAuthorityResponse,
          ),
          _setupTtsTimeoutFor(renderedRolloutSpeech),
        );
      } else {
        debugPrint(
          'NOVA_SETUP_IDENTITY_ROLLOUT_TTS_BLOCKED_NO_AUTHORITY chars=${renderedRolloutSpeech.length}',
        );
      }
    } catch (_) {}

    NovaIdentityRolloutReport? report;
    try {
      report = await _identityRolloutService.performRollout(
        assistantName: _assistantName,
        minimumRuntime: const Duration(seconds: 14),
        onProgress: (progress) async {
          if (!mounted) return;
          final visible =
              '${progress.title}. ${progress.detail} Yüzde ${progress.percent}';
          debugPrint(
            'NOVA_SETUP_IDENTITY_ROLLOUT_PROGRESS percent=${progress.percent} title=${progress.title}',
          );
          setState(() {
            _busy = true;
            _orbState = NovaOrbState.speaking;
            _statusText = _normalizeSetupPercentSpeech(visible);
          });
        },
      );
    } catch (error, stackTrace) {
      debugPrint(
        'NOVA_SETUP_IDENTITY_ROLLOUT_ERROR type=${error.runtimeType} error=$error',
      );
      debugPrint(stackTrace.toString());
    }

    if (!mounted) return;

    final success = report?.success ?? false;
    final adaptedCount = report?.adaptedSystems.length ?? 0;
    final layerCount =
        report?.auditReport.layerGroups.values.fold<int>(
          0,
          (sum, group) => sum + group.length,
        ) ??
        0;
    final spokenDone = success
        ? 'Sesli ad kaydı tamamlandı efendim. Yeni ismi kurulum boyunca kullanacağım.'
        : 'Kimlik yayılımı tamamlandı fakat bazı doğrulamalar eksik kaldı efendim. Yine de kayıt güvenli şekilde tutuldu; eksik sinyalleri onarım paneline düşüreceğim.';

    unawaited(
      NovaRuntimeSignalService.instance.record(
        kind: NovaRuntimeSignalKind.voiceIdentity,
        level: success
            ? NovaRuntimeSignalLevel.info
            : NovaRuntimeSignalLevel.warning,
        code: success
            ? 'identity_rollout_145_layer_verified'
            : 'voice_first_main_spine_degraded',
        message: spokenDone,
        technicalDetails:
            'adaptedSystems=$adaptedCount layerBindings=$layerCount success=$success',
        diagnosticCandidate: !success,
        metadata: <String, dynamic>{
          'assistantName': _assistantName,
          'adaptedSystems': adaptedCount,
          'layerBindings': layerCount,
          'source': 'first_run_identity_rollout',
        },
      ),
    );

    if (!success) {
      setState(() {
        _busy = false;
        _orbState = NovaOrbState.idle;
        _statusText =
            'Kimlik yayılımı doğrulanmadı. Setup sahibin adımına geçmedi; eksik sinyaller onarım panelinde bekliyor.';
      });
      debugPrint(
        'NOVA_SETUP_IDENTITY_ROLLOUT_BLOCKED success=false adaptedSystems=$adaptedCount layerBindings=$layerCount',
      );
      return;
    }

    setState(() {
      _busy = false;
      _advanceSetupByVerifiedAiDecision(
        _SetupStep.askOwnerName,
        reason: 'identity_rollout_ai_verified',
      );
      _orbState = NovaOrbState.speaking;
      _statusText = 'Kimlik yayılımı tamamlandı. Yüzde 100';
    });

    await _speakStatus(
      '$spokenDone Şimdi cihaz sahibinin adını doğal şekilde söyleyin.',
      mode: NovaTtsMode.neuralLocal,
    );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _advanceSetupByVerifiedAiDecision(
        _SetupStep.askOwnerName,
        reason: 'identity_rollout_ai_listening',
      );
      _orbState = NovaOrbState.listening;
      _statusText =
          'İsim ayarları tamamlandı. Şimdi cihaz sahibinin adını bekliyorum.';
    });
  }

  Future<void> _handleOwnerNameStep() async {
    final heard = await _listenOnce(
      emptyMessage: 'Sahip adı algılanamadı. Tekrar deneyin efendim.',
      mode: NovaSttMode.enhanced,
    );
    if (heard == null) return;

    final consumed = await _handlePossibleSetupSideConversation(
      heard,
      returnStep: _SetupStep.askOwnerName,
      returnStatus: 'Sahip adını sesli olarak bekliyorum.',
    );
    if (consumed) return;

    final extracted = _extractOwnerNameMeaning(heard);
    if (extracted.isEmpty || !_looksLikeValidOwnerName(extracted)) {
      _ownerNameAttempts += 1;
      setState(() {
        _statusText =
            'Sahip adını net duyamadım efendim. Lütfen “adım İbrahim” gibi açık söyleyin.';
        _orbState = NovaOrbState.idle;
      });
      _scheduleRetryForCurrentStep();
      return;
    }

    _pendingOwnerName = extracted;
    await _speakAndAdvance(
      text:
          'Sizi $_pendingOwnerName olarak duydum efendim. Doğruysa evet deyin, değilse hayır deyin ve tekrar söyleyin.',
      nextStep: _SetupStep.confirmOwnerName,
      status: 'Sahip adı onayı bekleniyor.',
      mode: NovaTtsMode.neuralLocal,
    );
  }

  Future<void> _handleConfirmOwnerNameStep() async {
    final heard = await _listenOnce(
      emptyMessage:
          'Onayı net duyamadım efendim. Doğruysa evet, değilse hayır diyebilirsiniz; isterseniz doğal cümleyle de yanıtlayabilirsiniz.',
    );
    if (heard == null) return;

    final consumed = await _handlePossibleSetupSideConversation(
      heard,
      returnStep: _SetupStep.confirmOwnerName,
      returnStatus: 'Sahip adı onayı bekleniyor.',
    );
    if (consumed) return;

    if (_isPositiveAnswer(heard)) {
      _ownerName = _pendingOwnerName;
      _ownerVoiceId = _normalizeVoiceId(_pendingOwnerName);
      await _speakAndAdvance(
        text:
            'Anladım efendim. Şimdi size nasıl hitap etmemi istediğinizi söyleyin. İsterseniz varsayılan karşılama olarak Hoş geldin patron da kalabilir.',
        nextStep: _SetupStep.askWelcomeText,
        status: 'Karşılama metni sesli olarak bekleniyor.',
        mode: NovaTtsMode.neuralLocal,
      );
      return;
    }

    if (_isNegativeAnswer(heard)) {
      await _speakAndAdvance(
        text: 'Tamam efendim. Lütfen adınızı tekrar daha net söyleyin.',
        nextStep: _SetupStep.askOwnerName,
        status: 'Sahip adı yeniden bekleniyor.',
        mode: NovaTtsMode.neuralLocal,
      );
      return;
    }

    await _speakStatus(
      'Doğruysa evet, yanlışsa hayır demeniz yeterli efendim.',
      mode: NovaTtsMode.neuralLocal,
    );
  }

  String _resolveWelcomeTextMeaning(String? heard) {
    const defaultGreeting = 'Hoş geldin patron.';
    if (heard == null) return defaultGreeting;

    final raw = heard.trim();
    final normalized = raw.toLowerCase();

    if (_spokenIntentInterpreter.shouldKeepDefaultGreeting(raw)) {
      return defaultGreeting;
    }

    if (normalized == 'hoş geldin patron' ||
        normalized == 'hos geldin patron') {
      return defaultGreeting;
    }

    var extracted = _spokenIntentInterpreter.normalizeMeaning(
      _extractMeaningfulText(raw),
    );
    extracted = extracted
        .replaceAll(
          RegExp(
            r'\b(olarak\s+kalsin|olarak\s+kalsın|kalsin|kalsın|olsun|kaydet|kaydedebilirsin|kaydedebilirsin\.)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (extracted.isEmpty) return defaultGreeting;
    return extracted;
  }

  Future<void> _handleWelcomeTextStep() async {
    final heard = await _listenOnce(
      emptyMessage:
          'Karşılama cümlesini net duyamadım efendim. İsterseniz varsayılan karşılama ile devam ederiz.',
      mode: NovaSttMode.enhanced,
    );

    if (heard != null) {
      final consumed = await _handlePossibleSetupSideConversation(
        heard,
        returnStep: _SetupStep.askWelcomeText,
        returnStatus: 'Karşılama metni sesli olarak bekleniyor.',
      );
      if (consumed) return;
    }

    _pendingWelcomeText = _resolveWelcomeTextMeaning(heard);

    await _speakAndAdvance(
      text:
          'Karşılama cümlesini $_pendingWelcomeText olarak kaydedeceğim. Doğruysa evet, değiştirmek isterseniz hayır deyin.',
      nextStep: _SetupStep.confirmWelcomeText,
      status: 'Karşılama metni onayı bekleniyor.',
      mode: NovaTtsMode.neuralLocal,
    );
  }

  Future<void> _handleConfirmWelcomeTextStep() async {
    final heard = await _listenOnce(
      emptyMessage:
          'Onayı net duyamadım efendim. Doğruysa evet deyin; değiştirmek isterseniz hayır deyin ya da yeni cümleyi söyleyin.',
    );
    if (heard == null) return;

    final consumed = await _handlePossibleSetupSideConversation(
      heard,
      returnStep: _SetupStep.confirmWelcomeText,
      returnStatus: 'Karşılama metni onayı bekleniyor.',
    );
    if (consumed) return;

    if (_isPositiveAnswer(heard)) {
      _welcomeText = _pendingWelcomeText;
      await _speakAndAdvance(
        text:
            'Tamam efendim. Son onay için evet derseniz birazdan sizden birkaç kısa doğal cümle isteyip ses kimliğinizi güçlü kaydedeceğim. Sonrasında da sizi sürekli tekrar teyit etmeye çalışmak yerine günlük ve yakın konuşma devamlılığını kullanacağım.',
        nextStep: _SetupStep.askVoiceConsent,
        status: 'Kurulum onayı ve owner ses örneği bekleniyor.',
        mode: NovaTtsMode.neuralLocal,
      );
      return;
    }

    if (_isNegativeAnswer(heard)) {
      await _speakAndAdvance(
        text:
            'Tamam efendim. O halde yeni karşılama cümlenizi tekrar söyleyin.',
        nextStep: _SetupStep.askWelcomeText,
        status: 'Karşılama metni yeniden bekleniyor.',
        mode: NovaTtsMode.neuralLocal,
      );
      return;
    }

    await _speakStatus(
      'Doğruysa evet, değiştirmek isterseniz hayır demeniz yeterli efendim.',
      mode: NovaTtsMode.neuralLocal,
    );
  }

  Future<void> _handleVoiceConsentStep() async {
    final heard = await _listenOnce(
      emptyMessage:
          'Onayı net duyamadım efendim. Hazır olduğunuzda evet diyerek devam edebiliriz.',
    );
    if (heard == null) return;

    final consumed = await _handlePossibleSetupSideConversation(
      heard,
      returnStep: _SetupStep.askVoiceConsent,
      returnStatus: 'Kurulum onayı ve owner ses örneği bekleniyor.',
    );
    if (consumed) return;

    if (!_isPositiveAnswer(heard)) {
      _voiceConsentAttempts += 1;
      setState(() {
        _statusText =
            'Kurulum onayı gelmedi. Hazır olduğunuzda tekrar deneyebilirsiniz.';
        _orbState = NovaOrbState.idle;
      });
      _scheduleRetryForCurrentStep();
      return;
    }

    if (!mounted) return;

    setState(() {
      _busy = true;
      _advanceSetupByVerifiedAiDecision(
        _SetupStep.saving,
        reason: 'voice_consent_ai_confirmed',
      );
      _orbState = NovaOrbState.speaking;
      _statusText = 'Owner profili ve ses kimliği kaydediliyor...';
    });

    final enrolledOk = await _enrollOwnerVoiceSamples();

    if (!enrolledOk) {
      if (!mounted) return;

      setState(() {
        _busy = false;
        _advanceSetupByVerifiedAiDecision(
          _SetupStep.askVoiceConsent,
          reason: 'voice_enroll_ai_retry',
        );
        _orbState = NovaOrbState.listening;
        _statusText = 'Owner ses kaydı başarısız oldu. Tekrar deneyin efendim.';
      });

      try {
        final renderedFailure = _normalizeSetupPercentSpeech(
          await _safeRenderSetupSpeech(
            'Ses kimliğinizi kaydedemedim efendim. Lütfen daha net bir örnekle tekrar deneyin.',
          ),
        );
        final renderedFailureAuthorityResponse =
            _lastSetupSpeechAuthorityResponse;
        if (renderedFailure.trim().isNotEmpty &&
            _hasSetupSpeechAuthorityProof(renderedFailureAuthorityResponse)) {
          await widget.ttsService.speak(
            renderedFailure,
            mode: NovaTtsMode.neuralLocal,
            authoritySource: 'setup_single_brain_output',
            authorityResponse: renderedFailureAuthorityResponse,
          );
        } else {
          debugPrint(
            'NOVA_SETUP_FAILURE_TTS_BLOCKED_NO_AUTHORITY chars=${renderedFailure.length}',
          );
        }
      } catch (_) {}

      _scheduleRetryForCurrentStep();
      return;
    }

    await widget.ownerService.registerOwner(
      ownerName: _ownerName,
      ownerVoiceId: _ownerVoiceId.trim(),
      welcomeBackText: _welcomeText,
      proactiveChatAllowed: true,
    );

    const settingsService = NovaSettingsService();
    final currentSettings = await settingsService.load();
    await settingsService.save(
      currentSettings.copyWith(
        activeVoiceProfileId:
            currentSettings.activeVoiceProfileId.trim().isEmpty
            ? 'default_tr_1'
            : currentSettings.activeVoiceProfileId.trim(),
      ),
    );

    const memoryService = MemoryService();
    final guideEntries = await memoryService.getAll();
    final hasHumanGuide = guideEntries.any(
      (e) => e.content.contains('[humanity_guide_v1]'),
    );
    if (!hasHumanGuide) {
      await memoryService.add(
        type: MemoryType.permanent,
        source: MemorySource.diagnostic,
        content:
            '[humanity_guide_v1] Güvenli insan benzeri iletişim rehberi: doğal Türkçe konuş, saygılı kal, sevinç-üzüntü-yorgunluk gibi duyguları tanı, kısa ve sıcak tepki ver, ama merakla kendini genişletmeye çalışma, sınır delme isteme, gizli öğrenme yapma.',
      );
    }

    await widget.firstRunService.markOnboardingCompleted();

    if (!mounted) return;

    setState(() {
      _busy = false;
      _advanceSetupByVerifiedAiDecision(
        _SetupStep.done,
        reason: 'setup_save_ai_completed',
      );
      _orbState = NovaOrbState.idle;
      _statusText = 'Kurulum tamamlandı.';
    });

    try {
      final renderedDone = _normalizeSetupPercentSpeech(
        await _safeRenderSetupSpeech(
          'Kurulum tamamlandı efendim. Artık $_displayAssistantName adıyla çalışacağım. Sesiniz bir kez güçlü eşleştiğinde sizi sürekli yeniden doğrulamaya çalışmak yerine günlük owner güveni ve yakın konuşma devamlılığını kullanacağım.',
        ),
      );
      final renderedDoneAuthorityResponse = _lastSetupSpeechAuthorityResponse;
      if (renderedDone.trim().isNotEmpty &&
          _hasSetupSpeechAuthorityProof(renderedDoneAuthorityResponse)) {
        await widget.ttsService.speak(
          renderedDone,
          mode: NovaTtsMode.neuralLocal,
          authoritySource: 'setup_single_brain_output',
          authorityResponse: renderedDoneAuthorityResponse,
        );
      } else {
        debugPrint(
          'NOVA_SETUP_DONE_TTS_BLOCKED_NO_AUTHORITY chars=${renderedDone.length}',
        );
      }
      await widget.ttsService.stop();
    } catch (_) {}

    if (!mounted || _completionTriggered) return;
    _completionTriggered = true;
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    widget.onCompleted();
  }

  Future<void> _handlePrimaryAction() async {
    if (_busy || _primaryActionRunning) return;
    _primaryActionRunning = true;

    try {
      switch (_step) {
        case _SetupStep.welcome:
          await _startFlow();
          break;
        case _SetupStep.askAssistantName:
          await _handleAssistantNameStep();
          break;
        case _SetupStep.confirmAssistantName:
          await _handleConfirmAssistantNameStep();
          break;
        case _SetupStep.rolloutIdentity:
          await _handleIdentityRolloutStep();
          break;
        case _SetupStep.askOwnerName:
          await _handleOwnerNameStep();
          break;
        case _SetupStep.confirmOwnerName:
          await _handleConfirmOwnerNameStep();
          break;
        case _SetupStep.askWelcomeText:
          await _handleWelcomeTextStep();
          break;
        case _SetupStep.confirmWelcomeText:
          await _handleConfirmWelcomeTextStep();
          break;
        case _SetupStep.askVoiceConsent:
          await _handleVoiceConsentStep();
          break;
        case _SetupStep.saving:
        case _SetupStep.done:
          break;
      }
    } finally {
      _primaryActionRunning = false;
    }
  }

  String _headline() {
    switch (_step) {
      case _SetupStep.welcome:
        return 'İlk kurulum başlıyor';
      case _SetupStep.askAssistantName:
        return 'Bana hangi isimle sesleneceksiniz?';
      case _SetupStep.confirmAssistantName:
        return 'Asistan adını doğruluyorum';
      case _SetupStep.rolloutIdentity:
        return 'İsim ayarlanıyor';
      case _SetupStep.askOwnerName:
        return 'Cihaz sahibini tanıyorum';
      case _SetupStep.confirmOwnerName:
        return 'Sahip adını doğruluyorum';
      case _SetupStep.askWelcomeText:
        return 'Nasıl hitap etmemi istersiniz?';
      case _SetupStep.confirmWelcomeText:
        return 'Karşılama metnini doğruluyorum';
      case _SetupStep.askVoiceConsent:
        return 'Son onayınızı bekliyorum';
      case _SetupStep.saving:
        return 'Kimlik profili kaydediliyor';
      case _SetupStep.done:
        return 'Kurulum tamamlandı';
    }
  }

  String _actionText() {
    switch (_step) {
      case _SetupStep.welcome:
        return 'Sesli akışı elle başlat';
      case _SetupStep.askAssistantName:
        return 'Gerekirse elle tetikle';
      case _SetupStep.confirmAssistantName:
        return 'Gerekirse elle tetikle';
      case _SetupStep.rolloutIdentity:
        return 'Gerekirse elle tetikle';
      case _SetupStep.askOwnerName:
        return 'Gerekirse elle tetikle';
      case _SetupStep.confirmOwnerName:
        return 'Gerekirse elle tetikle';
      case _SetupStep.askWelcomeText:
        return 'Gerekirse elle tetikle';
      case _SetupStep.confirmWelcomeText:
        return 'Gerekirse elle tetikle';
      case _SetupStep.askVoiceConsent:
        return 'Gerekirse elle tetikle';
      case _SetupStep.saving:
        return 'Kaydediliyor...';
      case _SetupStep.done:
        return 'Hazır';
    }
  }

  String _helperText() {
    switch (_step) {
      case _SetupStep.welcome:
        return 'Kurulum her kritik adımda net sesli cevap bekler; otomatik isim/onay seçmez.';
      case _SetupStep.askAssistantName:
        return 'Örnek: Bundan sonra adın Nova olsun';
      case _SetupStep.confirmAssistantName:
        return 'Doğruysa evet, yanlışsa hayır deyin.';
      case _SetupStep.rolloutIdentity:
        return 'Seçtiğiniz isim sessizce uygulanır; teknik ayrıntı göstermem.';
      case _SetupStep.askOwnerName:
        return 'Örnek: Benim adım İbrahim';
      case _SetupStep.confirmOwnerName:
        return 'Doğruysa evet, yanlışsa hayır deyin.';
      case _SetupStep.askWelcomeText:
        return 'Örnek: Hoş geldin efendim';
      case _SetupStep.confirmWelcomeText:
        return 'Cümleyi değiştirmek isterseniz hayır diyebilirsiniz.';
      case _SetupStep.askVoiceConsent:
        return 'Onaydan sonra kısa bir ses örneği alırım; ardından çağrı ve companion için varsayılan telefon rolünü de açabilirsiniz.';
      case _SetupStep.saving:
        return 'Kimlik ve başlangıç ayarları güvenli şekilde kaydediliyor.';
      case _SetupStep.done:
        return 'Kurulum tamamlandıktan sonra normal kullanıma geçilir.';
    }
  }

  void _scheduleAutoAdvance() {
    _autoStepTimer?.cancel();
    const autoSteps = <_SetupStep>{_SetupStep.rolloutIdentity};
    if (!autoSteps.contains(_step) || _busy) return;
    final delay = switch (_step) {
      _SetupStep.rolloutIdentity => const Duration(milliseconds: 620),
      _SetupStep.confirmAssistantName ||
      _SetupStep.confirmOwnerName ||
      _SetupStep.confirmWelcomeText ||
      _SetupStep.askVoiceConsent => const Duration(milliseconds: 620),
      _ => const Duration(milliseconds: 520),
    };
    _autoStepTimer = Timer(delay, () {
      if (!mounted || _busy || !autoSteps.contains(_step)) return;
      unawaited(_handlePrimaryAction());
    });
  }

  Future<void> _setSetupSecurityDiagnosticPassive(bool value) async {
    setState(() {
      _securityDiagnosticSaving = true;
      _securityDiagnosticPassive = value;
      _statusText = value
          ? 'Güvenlik kalkanları pasif gözlem modunda; Nova bu ayarı bilmez.'
          : 'Güvenlik kalkanları aktif engelleme modunda.';
    });
    await _securityDiagnosticModeService.setPassive(
      passive: value,
      updatedBy: 'setup_ui',
    );
    await const NovaSecurityQuarantineService().reset();
    if (!mounted) return;
    setState(() {
      _securityDiagnosticSaving = false;
    });
  }

  Future<void> _openSetupSelfRepairPanel() async {
    final runtimeSignalService = self_repair_signal.NovaRuntimeSignalService.instance;
    final runtimeRegistryService = const NovaCapabilityRuntimeRegistryService();
    final manifestService = NovaCapabilityManifestService(
      runtimeRegistryService: runtimeRegistryService,
    );
    final recognitionService = NovaSelfRecognitionService(
      manifestService: manifestService,
      signalService: runtimeSignalService,
    );
    final diagnosticService = NovaSelfDiagnosticService(
      signalService: runtimeSignalService,
      recognitionService: recognitionService,
    );
    final reportService = const NovaSelfRepairReportService();
    final settingsService = const NovaSelfRepairSettingsService();
    final repairTraceService = const NovaRepairTraceService();
    final repairValidationService = NovaRepairValidationService(
      diagnosticService: diagnosticService,
    );
    const repairResolutionMemoryService = NovaRepairResolutionMemoryService();
    final capabilityProbeService = NovaCapabilityProbeService(
      runtimeSignalService: runtimeSignalService,
    );
    final capabilityCatalogService = NovaCapabilityCatalogService(
      recognitionService: recognitionService,
      probeService: capabilityProbeService,
    );
    final backgroundBridgeService = const NovaBackgroundBridgeService();
    final controlledRestartService = NovaControlledRestartService(
      backgroundBridgeService: backgroundBridgeService,
      ttsService: widget.ttsService,
    );
    final orchestratorService = NovaSelfRepairOrchestratorService(
      ttsService: widget.ttsService,
      backgroundBridgeService: backgroundBridgeService,
      reportService: reportService,
      securityService: const NovaSelfRepairSecurityService(),
      controlledRestartService: controlledRestartService,
      endListeningSessionAction: () async {
        await _ensureSetupSingleAsrListening(reason: 'setup_self_repair');
      },
    );
    final coordinatorService = NovaSelfRepairCoordinatorService(
      diagnosticService: diagnosticService,
      orchestratorService: orchestratorService,
      reportService: reportService,
      settingsService: settingsService,
      commandService: const NovaSelfRepairCommandService(),
      capabilityCatalogService: capabilityCatalogService,
      repairTraceService: repairTraceService,
      repairValidationService: repairValidationService,
      resolutionMemoryService: repairResolutionMemoryService,
    );

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SelfRepairControlPage(
          coordinatorService: coordinatorService,
          settingsService: settingsService,
          repairTraceService: repairTraceService,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _autoStepTimer?.cancel();
    _bootNarrationTimer?.cancel();
    unawaited(_setupStreamingSubscription?.cancel());
    unawaited(_localModelBootSubscription?.cancel());
    super.dispose();
  }

  double? get _realBootProgressValue {
    final progress = _lastBootProgress;
    if (progress == null || !progress.hasRealPercent) return null;
    return (progress.percent!.clamp(0, 100)) / 100.0;
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = const Color(0xFFE8CFC4);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F1),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 1.05,
                  colors: [
                    const Color(0xFFF7DED6).withOpacity(0.82),
                    const Color(0xFFFBF0E8).withOpacity(0.92),
                    const Color(0xFFFFF8F1),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFFFFCF7).withOpacity(0.35),
                      Colors.transparent,
                      Colors.transparent,
                      const Color(0xFFF2CFC3).withOpacity(0.18),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton.filledTonal(
                          tooltip: 'Setup onarım paneli',
                          onPressed: _openSetupSelfRepairPanel,
                          icon: const Icon(Icons.healing_rounded),
                        ),
                      ),
                      Text(
                        _displayAssistantName.toUpperCase(),
                        style: TextStyle(
                          color: const Color(0xFF4A1417),
                          fontSize: 14,
                          letterSpacing: 6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Expanded(
                        child: Center(
                          child: TickerMode(
                            enabled: !_busy,
                            child: NovaCoreOrb(
                              state: _orbState,
                              size: 250,
                              label: _headline(),
                              subtitle: _statusText,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: LinearProgressIndicator(
                          value: _realBootProgressValue,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFF3DED6),
                          color: const Color(0xFFB91C1C),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFCF7),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFED2C2E).withOpacity(0.10),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SwitchListTile(
                              value: _securityDiagnosticPassive,
                              onChanged: _securityDiagnosticSaving
                                  ? null
                                  : (value) =>
                                        _setSetupSecurityDiagnosticPassive(
                                          value,
                                        ),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Güvenlik kalkanları pasif gözlem modu',
                                style: TextStyle(
                                  color: Color(0xFF2A0709),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: const Text(
                                'İlk test için varsayılan açık. Nova bu ayarı göremez, konuşamaz ve değiştiremez.',
                                style: TextStyle(
                                  color: Color(0xFF6A3E3A),
                                  fontSize: 12,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _helperText(),
                              style: TextStyle(
                                color: const Color(0xFF4A1417),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            if (_step == _SetupStep.askVoiceConsent ||
                                _step == _SetupStep.saving ||
                                _step == _SetupStep.done) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Not: çağrı ve companion zinciri için kurulum sonrasında varsayılan telefon rolünü açmanız gerekir.',
                                style: TextStyle(
                                  color: const Color(0xFF6A3E3A),
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                            if (_lastHeardText.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Algılanan son cevap',
                                style: TextStyle(
                                  color: const Color(0xFF8A1116),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFFFCF7,
                                  ).withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE8CFC4),
                                  ),
                                ),
                                child: Text(
                                  _lastHeardText,
                                  style: const TextStyle(
                                    color: Color(0xFF2A0709),
                                    fontSize: 14,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Text(
                              'Sesle otomatik ilerleme açık. Bu düğme yalnızca yedek içindir.',
                              style: TextStyle(
                                color: const Color(0xFF6A3E3A),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _busy || _primaryActionRunning
                                    ? null
                                    : _handlePrimaryAction,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF8A1116),
                                  side: BorderSide(
                                    color: const Color(0xFFE8CFC4),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Text(_actionText()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
