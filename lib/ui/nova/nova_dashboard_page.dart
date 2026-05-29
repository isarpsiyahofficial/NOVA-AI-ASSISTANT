// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals_to_create_immutables
// NOVA_APK_STANDALONE_DASHBOARD_V4
// Purpose: lightweight, phone-only Nova dashboard. No PC gateway, no localhost server, no local server dependency.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ai/ai_mode.dart';
import '../../core/ai/ai_request.dart';
import '../../core/ai/ai_response.dart';
import '../../core/api/nova_ai_provider_type.dart';
import '../../core/api/nova_api_model_catalog.dart';
import '../../core/turn/nova_core_turn_controller.dart';
import '../../core/behavior/nova_persona.dart';
import '../../core/behavior/response_style.dart';
import '../../core/settings/nova_settings.dart';
import '../../services/api/api_service.dart';
import '../../services/call/nova_call_state_service.dart';
import '../../services/conversation/nova_conversation_session_service.dart';
import '../../services/identity/device_owner_identity_service.dart';
import '../../services/nova/nova_apk_runtime_service.dart';
import '../../services/identity/nova_first_run_service.dart';
import '../../services/identity/nova_voice_identity_bridge_service.dart';
import '../../services/local_model/local_model_service.dart';
import '../../services/permissions/nova_android_permission_bridge_service.dart';
import '../../services/reminder/nova_reminder_command_service.dart';
import '../../services/reminder/nova_reminder_service.dart';
import '../../services/runtime/nova_single_brain_authority_service.dart';
import '../../services/settings/nova_settings_service.dart';
import '../../services/stt/nova_speech_to_text_service.dart';
import '../../services/system/nova_background_bridge_service.dart';
import '../../services/system/nova_overlay_bridge_service.dart';
import '../../services/tts/nova_tts_service.dart';
import '../../services/voice_clone/voice_clone_runtime_control_service.dart';
import '../../services/voice_clone/voice_clone_service.dart';

class NovaDashboardPage extends StatefulWidget {
  final NovaPersona persona;
  final ResponseStyle responseStyle;
  final LocalModelService localModelService;
  final ApiService apiService;
  final VoiceCloneService cloneService;
  final VoiceCloneRuntimeControlService runtimeControl;
  final NovaSpeechToTextService sttService;
  final NovaTtsService ttsService;
  final NovaReminderService reminderService;
  final NovaReminderCommandService reminderCommandService;
  final NovaConversationSessionService conversationSessionService;
  final NovaVoiceIdentityBridgeService voiceIdentityBridgeService;
  final bool deferHeavyBootstrap;
  final bool setupRequired;

  const NovaDashboardPage({
    super.key,
    required this.persona,
    required this.responseStyle,
    required this.localModelService,
    required this.apiService,
    required this.cloneService,
    required this.runtimeControl,
    required this.sttService,
    required this.ttsService,
    required this.reminderService,
    required this.reminderCommandService,
    required this.conversationSessionService,
    required this.voiceIdentityBridgeService,
    this.deferHeavyBootstrap = false,
    this.setupRequired = false,
  });

  @override
  State<NovaDashboardPage> createState() => _NovaDashboardPageState();
}

class _NovaDashboardPageState extends State<NovaDashboardPage> {
  static const Color _bg = Color(0xFFF7FAFC);
  static const Color _panel = Color(0xFFFFFFFF);
  static const Color _panel2 = Color(0xFFF2F7FA);
  static const Color _accent = Color(0xFF0E7490);
  static const Color _accent2 = Color(0xFF4F46E5);
  static const Color _success = Color(0xFF059669);
  static const Color _warning = Color(0xFFD97706);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _text = Color(0xFF102A43);
  static const Color _muted = Color(0xFF52616B);

  final NovaSettingsService _settingsService = const NovaSettingsService();
  final NovaAndroidPermissionBridgeService _permissionService =
      const NovaAndroidPermissionBridgeService();
  final NovaBackgroundBridgeService _backgroundBridge =
      const NovaBackgroundBridgeService();
  final NovaOverlayBridgeService _overlayBridge =
      const NovaOverlayBridgeService();
  final NovaCallStateService _callStateService = const NovaCallStateService();
  final DeviceOwnerIdentityService _ownerService =
      const DeviceOwnerIdentityService();
  final NovaApkRuntimeService _novaRuntime = const NovaApkRuntimeService();
  late final NovaFirstRunService _firstRunService = NovaFirstRunService(
    ownerService: _ownerService,
  );
  final NovaCoreTurnController _coreTurnController =
      const NovaCoreTurnController();

  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController(
    text: 'İbrahim',
  );

  NovaSettings _settings = const NovaSettings();
  NovaAndroidPermissionSnapshot _permissions =
      const NovaAndroidPermissionSnapshot();
  NovaCallStateSnapshot _callSnapshot = NovaCallStateSnapshot.idle();
  NovaRuntimeSnapshot _runtimeSnapshot = NovaRuntimeSnapshot.initial();
  NovaAiProviderType _provider = NovaAiProviderType.gemini;

  bool _loading = true;
  bool _busy = false;
  bool _apiSaving = false;
  bool _voiceRunning = false;
  bool _backgroundRunning = false;
  bool _manualSetupCompleted = false;
  String _status = 'Nova başlatılıyor.';
  String _lastTranscript = '';
  String _lastAnswer =
      'Nova APK modu hazırlandığında burada gerçek beyin cevabı görünecek.';
  String _lastAction = 'Henüz işlem yapılmadı.';
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(
      widget.deferHeavyBootstrap
          ? const Duration(milliseconds: 700)
          : Duration.zero,
      _bootstrap,
    );
    _statusTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => _refreshLightState(silent: true),
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _apiKeyController.dispose();
    _modelController.dispose();
    _promptController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final manualCompleted = await _novaRuntime.loadManualSetupCompleted();
    if (mounted) {
      setState(() {
        _manualSetupCompleted = manualCompleted;
      });
    }
    await _loadSettings();
    await _refreshLightState(silent: true);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _status = widget.setupRequired && !_manualSetupCompleted
          ? 'Nova hafif kurulum modunda. Eski ağır setup bypass edildi; API, izinler ve arka plan buradan hazırlanacak.'
          : 'Nova APK modu hazır.';
    });
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _provider = settings.activeAiProvider;
      _apiKeyController.text = settings.apiKey;
      _modelController.text = settings.activeApiModel.trim().isEmpty
          ? NovaApiModelCatalog.defaultModelFor(settings.activeAiProvider)
          : settings.activeApiModel.trim();
    });
  }

  Future<void> _refreshLightState({bool silent = false}) async {
    final permissions = await _permissionService.getPermissionSnapshot();
    final call = await _callStateService.getSnapshot();
    final runtime = _novaRuntime.buildSnapshot(
      settings: _settings,
      permissions: permissions,
      callSnapshot: call,
      manualSetupCompleted: _manualSetupCompleted,
      backgroundRunning: _backgroundRunning,
    );
    if (!mounted) return;
    setState(() {
      _permissions = permissions;
      _callSnapshot = call;
      _runtimeSnapshot = runtime;
      if (!silent) _lastAction = 'Durum yenilendi.';
    });
  }

  Future<void> _saveApiSettings() async {
    if (_apiSaving) return;
    setState(() {
      _apiSaving = true;
      _status = 'API beyin ayarı kaydediliyor.';
    });
    final key = _apiKeyController.text.trim();
    final model = _modelController.text.trim().isEmpty
        ? NovaApiModelCatalog.defaultModelFor(_provider)
        : _modelController.text.trim();
    final next = _settings.copyWith(
      activeAiProvider: _provider,
      activeApiModel: model,
      apiKey: key,
      apiBrainEnabled: key.isNotEmpty,
      apiLearningEnabled: key.isNotEmpty,
    );
    await _settingsService.save(next);
    if (!mounted) return;
    setState(() {
      _settings = next;
      _runtimeSnapshot = _novaRuntime.buildSnapshot(
        settings: next,
        permissions: _permissions,
        callSnapshot: _callSnapshot,
        manualSetupCompleted: _manualSetupCompleted,
        backgroundRunning: _backgroundRunning,
      );
      _apiSaving = false;
      _status = key.isEmpty
          ? 'API anahtarı boş. Nova arayüz, izin ve overlay çalışır; zeki cevap için API gerekir.'
          : 'API beyin ayarı hazır. Bu APK için local sunucu gerekmez.';
      _lastAction = 'API ayarı kaydedildi.';
    });
  }

  Future<void> _toggleSetting(
    FutureOr<NovaSettings> Function(NovaSettings value) change,
  ) async {
    final next = await change(_settings);
    await _settingsService.save(next);
    if (!mounted) return;
    setState(() {
      _settings = next;
      _runtimeSnapshot = _novaRuntime.buildSnapshot(
        settings: next,
        permissions: _permissions,
        callSnapshot: _callSnapshot,
        manualSetupCompleted: _manualSetupCompleted,
        backgroundRunning: _backgroundRunning,
      );
      _lastAction = 'Ayar güncellendi.';
    });
  }

  Future<void> _completeManualSetup() async {
    final owner = _ownerNameController.text.trim().isEmpty
        ? 'İbrahim'
        : _ownerNameController.text.trim();
    setState(() {
      _busy = true;
      _status = 'Nova ilk kurulum readiness kontrolü yapılıyor.';
    });
    await _refreshLightState(silent: true);
    final apiReady =
        _settings.apiBrainEnabled && _settings.apiKey.trim().isNotEmpty;
    final micReady = _permissions.recordAudioGranted;
    if (!apiReady || !micReady) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _manualSetupCompleted = false;
        _status = !apiReady
            ? 'İlk kurulum tamamlanmadı: API beyin anahtarı/modeli hazır değil.'
            : 'İlk kurulum tamamlanmadı: mikrofon izni eksik.';
        _lastAction =
            'Setup readiness eksik: API ve mikrofon tamamlanmadan Nova hazır sayılmayacak.';
      });
      return;
    }
    final manualVoiceId =
        'nova_manual_owner_${DateTime.now().millisecondsSinceEpoch}';
    await _ownerService.registerOwner(
      ownerName: owner,
      ownerVoiceId: manualVoiceId,
      welcomeBackText: '',
      proactiveChatAllowed: true,
    );
    final setupSettings = _settings.copyWith(
      activeVoiceProfileId: manualVoiceId,
    );
    await _settingsService.save(setupSettings);
    await _firstRunService.markOnboardingCompleted();
    await _novaRuntime.markManualSetupCompleted();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _settings = setupSettings;
      _manualSetupCompleted = true;
      _runtimeSnapshot = _novaRuntime.buildSnapshot(
        settings: setupSettings,
        permissions: _permissions,
        callSnapshot: _callSnapshot,
        manualSetupCompleted: true,
        backgroundRunning: _backgroundRunning,
      );
      _status =
          'İlk kurulum readiness tamamlandı. Nova ana dashboard hattına bağlı.';
      _lastAction =
          'Setup dashboard içinde tamamlandı; statik sesli setup konuşması üretilmedi.';
    });
  }

  Future<void> _requestEssentialPermissions() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = 'Temel Android izinleri isteniyor.';
    });
    try {
      if (!_permissions.recordAudioGranted) {
        await _permissionService.requestRecordAudioPermission();
      }
      if (!_permissions.notificationsGranted) {
        await _permissionService.requestPostNotificationsPermission();
      }
      await _refreshLightState(silent: true);
      if (!mounted) return;
      setState(() {
        _lastAction = 'Mikrofon/bildirim izinleri kontrol edildi.';
        _status = 'Temel izin kontrolü tamamlandı.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestCallPermissions() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = 'Çağrı gözlem/companion izinleri kontrol ediliyor.';
    });
    try {
      await _permissionService.requestEssentialCallPermissions();
      if (!_permissions.callScreeningRoleGranted) {
        await _permissionService.requestCallScreeningRole();
      }
      await _refreshLightState(silent: true);
      if (!mounted) return;
      setState(() {
        _lastAction = 'Çağrı izinleri kontrol edildi.';
        _status =
            'Çağrı sistemi gözlem modu için hazırlandı. Otomatik cevaplama yine ayrı izin/policy ister.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startBackgroundAndOverlay() async {
    setState(() {
      _busy = true;
      _status = 'Nova arka plan ve overlay başlatılıyor.';
    });
    final start = await _backgroundBridge.startBackground();
    final overlay = await _backgroundBridge.showOverlayIdle();
    await _overlayBridge.showPresenceState(
      assistantName: 'Nova',
      mode: 'idle',
      emotion: 'focused',
      energy: 0.55,
      speakingIntensity: 0.0,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _backgroundRunning = start.success || overlay.success;
      _runtimeSnapshot = _novaRuntime.buildSnapshot(
        settings: _settings,
        permissions: _permissions,
        callSnapshot: _callSnapshot,
        manualSetupCompleted: _manualSetupCompleted,
        backgroundRunning: _backgroundRunning,
      );
      _status = start.success || overlay.success
          ? 'Nova arka planda aktif. Overlay hafif modda çalışıyor.'
          : (start.message.isNotEmpty ? start.message : overlay.message);
      _lastAction = 'Arka plan / overlay denendi.';
    });
  }

  Future<void> _setOverlayMode(String mode) async {
    NovaBackgroundBridgeResult result;
    switch (mode) {
      case 'listening':
        result = await _backgroundBridge.showOverlayListening();
        break;
      case 'speaking':
        result = await _backgroundBridge.showOverlaySpeaking();
        break;
      case 'sleeping':
        result = await _backgroundBridge.showOverlaySleeping();
        break;
      default:
        result = await _backgroundBridge.showOverlayIdle();
        break;
    }
    await _overlayBridge.showPresenceState(
      assistantName: 'Nova',
      mode: mode,
      emotion: mode == 'speaking' ? 'warm' : 'focused',
      energy: mode == 'sleeping' ? 0.20 : 0.72,
      speakingIntensity: mode == 'speaking' ? 0.8 : 0.0,
    );
    if (!mounted) return;
    setState(() {
      _lastAction = result.success ? 'Overlay modu: $mode' : result.message;
    });
  }

  Future<void> _runVoiceTurn() async {
    if (_voiceRunning || _busy) return;
    if (!_settings.apiBrainEnabled || _settings.apiKey.trim().isEmpty) {
      setState(() {
        _status =
            'Önce API anahtarı kaydedilmeli. Nova APK için local sunucu yok; beyin API sağlayıcısından gelir.';
      });
      return;
    }
    setState(() {
      _voiceRunning = true;
      _status = 'Nova dinliyor.';
      _lastTranscript = '';
    });
    await _setOverlayMode('listening');
    try {
      final result = await widget.sttService.transcribe(
        mode: NovaSttMode.light,
        targetDescription: 'Nova APK sesli komut',
        rejectSyntheticPlayback: true,
      );
      final transcript = result.recognizedText.trim();
      if (!mounted) return;
      setState(() {
        _lastTranscript = transcript.isEmpty ? result.message : transcript;
        _status = transcript.isEmpty
            ? 'Ses algılanamadı.'
            : 'Nova cevap hazırlıyor.';
      });
      if (transcript.isEmpty) return;
      await _sendToBrain(transcript, speak: true, requestedByVoice: true);
    } finally {
      await _setOverlayMode('idle');
      if (mounted) setState(() => _voiceRunning = false);
    }
  }

  Future<void> _sendManualPrompt() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty || _busy) return;
    if (!_settings.apiBrainEnabled || _settings.apiKey.trim().isEmpty) {
      setState(() {
        _status = 'API anahtarı yok. Yazılı test için önce API ayarını kaydet.';
      });
      return;
    }
    await _sendToBrain(prompt, speak: false, requestedByVoice: false);
  }

  Future<void> _sendToBrain(
    String prompt, {
    required bool speak,
    required bool requestedByVoice,
  }) async {
    setState(() {
      _busy = true;
      _lastAction = requestedByVoice
          ? 'Sesli komut NovaCoreTurnController hattına gönderildi.'
          : 'Yazılı test NovaCoreTurnController hattına gönderildi.';
    });
    try {
      final result = await _coreTurnController.processUserTurn(
        NovaCoreTurnRequest(
          inputText: prompt,
          source: requestedByVoice
              ? NovaTurnSource.dashboardVoice
              : NovaTurnSource.dashboardText,
          settings: _settings,
          requestedByVoice: requestedByVoice,
          userInitiated: true,
          context: <String, dynamic>{
            'assistantName': 'Nova',
            'runtime': 'apk_only_no_local_server',
            'source': 'nova_dashboard',
          },
        ),
      );
      final response = result.response;
      final display = result.finalText.trim().isNotEmpty
          ? result.finalText.trim()
          : response.displayText.trim();
      final safeText = display.isEmpty ? 'Nova boş cevap aldı.' : display;
      if (!mounted) return;
      setState(() {
        _lastAnswer = safeText;
        _status = response.isError
            ? safeText
            : (result.allowedToSpeak
                  ? 'Nova cevap verdi.'
                  : 'Nova cevabı konuşma sözleşmesine takıldı.');
      });
      if (speak && !response.isError && result.allowedToSpeak) {
        await _setOverlayMode('speaking');
        await widget.ttsService.speak(
          result.response.displayText,
          localeCode: 'tr-TR',
          mode: NovaTtsMode.neuralLocal,
          authoritySource: result.ttsSource,
          authorityResponse: result.response,
          singleBrainApproved: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _apiStatus {
    if (!_settings.apiBrainEnabled || _settings.apiKey.trim().isEmpty)
      return 'API kapalı / anahtar yok';
    return '${_settings.activeAiProvider.label} · ${_settings.activeApiModel}';
  }

  String get _callStatus {
    if (_callSnapshot.isRinging) return 'Çalıyor';
    if (_callSnapshot.isActiveCall) return 'Aktif çağrı';
    if (_permissions.callScreeningRoleGranted ||
        _permissions.hybridCallControlReady ||
        _permissions.managedCallSupportReady)
      return 'Gözlem hazır';
    return 'İzin bekliyor';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: _NovaBackground()),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _accent))
                : RefreshIndicator(
                    onRefresh: () => _refreshLightState(silent: false),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      children: <Widget>[
                        _buildHeader(),
                        const SizedBox(height: 14),
                        if (widget.setupRequired && !_manualSetupCompleted)
                          _buildManualSetupCard(),
                        _buildCoreStatusCard(),
                        _buildRuntimeSnapshotCard(),
                        _buildApiCard(),
                        _buildVoiceCard(),
                        _buildPermissionsCard(),
                        _buildBackgroundCard(),
                        _buildCallCard(),
                        _buildRuntimeRulesCard(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: <Color>[_panel2, const Color(0xE0091220)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _accent.withOpacity(0.24)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _accent.withOpacity(0.10),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          const _NovaOrb(size: 76),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'NOVA',
                  style: TextStyle(
                    color: _text,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'APK-only assistant · local server yok · telefon izinleri telefonda',
                  style: TextStyle(
                    color: _muted.withOpacity(0.95),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _miniPill(
                      'Beyin',
                      _apiStatus,
                      _settings.apiKey.trim().isEmpty ? _warning : _success,
                    ),
                    _miniPill(
                      'Çağrı',
                      _callStatus,
                      _permissions.callScreeningRoleGranted
                          ? _success
                          : _warning,
                    ),
                    _miniPill(
                      'Overlay',
                      _permissions.canDrawOverlays ? 'Hazır' : 'İzin yok',
                      _permissions.canDrawOverlays ? _success : _warning,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuntimeSnapshotCard() {
    final score = _runtimeSnapshot.readinessScore.clamp(0, 100);
    return _card(
      title: 'Nova Runtime Durumu',
      icon: Icons.memory_rounded,
      accent: _success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: score / 100.0,
                    minHeight: 10,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    color: score >= 80
                        ? _success
                        : (score >= 55 ? _warning : _danger),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$score%',
                style: const TextStyle(
                  color: _text,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _runtimeSnapshot.summary,
            style: const TextStyle(color: _muted, height: 1.35),
          ),
          const SizedBox(height: 12),
          _infoRow('Çalışma modu', _runtimeSnapshot.mode),
          _infoRow(
            'Local server',
            _runtimeSnapshot.localServerDisabled ? 'Kapalı / gerekmez' : 'Açık',
          ),
          _infoRow(
            'PC/OpenClaw bridge',
            _runtimeSnapshot.pcBridgeDisabled ? 'Kapalı / gerekmez' : 'Açık',
          ),
          _infoRow(
            'API beyin',
            _runtimeSnapshot.apiConfigured ? 'Hazır' : 'Anahtar bekliyor',
          ),
          _infoRow(
            'Otomatik çağrı aksiyonu',
            _runtimeSnapshot.safeToAutoExecuteCallActions
                ? 'İzinli'
                : 'Kapalı / öneri modu',
          ),
          const SizedBox(height: 10),
          _runtimeList('Hazır parçalar', _runtimeSnapshot.readyItems, _success),
          if (_runtimeSnapshot.missingItems.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            _runtimeList(
              'Eksik parçalar',
              _runtimeSnapshot.missingItems,
              _warning,
            ),
          ],
        ],
      ),
    );
  }

  Widget _runtimeList(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        ...items
            .take(8)
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.circle, size: 7, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(color: _muted, height: 1.25),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildManualSetupCard() {
    return _card(
      title: 'Hafif APK Kurulumu',
      icon: Icons.rocket_launch_rounded,
      accent: _warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Eski sesli setup akışı API cevabı beklediği için kilitlenebiliyordu. Nova deneyinde önce uygulama ayağa kalkar; sahip adı, API ve izinler bu panelden hazırlanır.',
            style: TextStyle(color: _muted, height: 1.35),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ownerNameController,
            style: const TextStyle(color: _text),
            decoration: _inputDecoration('Sahip adı', 'Örn. İbrahim'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _completeManualSetup,
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Nova’i Başlat'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreStatusCard() {
    return _card(
      title: 'Canlı Durum',
      icon: Icons.monitor_heart_rounded,
      accent: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _status,
            style: const TextStyle(
              color: _text,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Son işlem: $_lastAction',
            style: const TextStyle(color: _muted, height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _stateChip('Mikrofon', _permissions.recordAudioGranted),
              _stateChip('Bildirim', _permissions.notificationsGranted),
              _stateChip('Overlay', _permissions.canDrawOverlays),
              _stateChip(
                'Çağrı rolü',
                _permissions.callScreeningRoleGranted ||
                    _permissions.defaultDialerGranted,
              ),
              _stateChip('Arka plan', _backgroundRunning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApiCard() {
    final presets = NovaApiModelCatalog.presetsFor(_provider);
    final modelValue = presets.contains(_modelController.text.trim())
        ? _modelController.text.trim()
        : null;
    return _card(
      title: 'API Beyin',
      icon: Icons.psychology_alt_rounded,
      accent: _accent2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Nova APK içinde local sunucu çalıştırmaz. Zeki cevap için seçilen API sağlayıcısı kullanılır; ASR/çağrı/overlay/izin zinciri telefonda kalır.',
            style: TextStyle(color: _muted, height: 1.35),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<NovaAiProviderType>(
            value: _provider,
            dropdownColor: const Color(0xFF0F1722),
            decoration: _inputDecoration('Sağlayıcı', ''),
            items: NovaAiProviderType.values
                .map(
                  (p) => DropdownMenuItem<NovaAiProviderType>(
                    value: p,
                    child: Text(p.label, style: const TextStyle(color: _text)),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _provider = value;
                _modelController.text = NovaApiModelCatalog.defaultModelFor(
                  value,
                );
              });
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: modelValue,
            dropdownColor: const Color(0xFF0F1722),
            decoration: _inputDecoration('Model', ''),
            items: presets
                .map(
                  (model) => DropdownMenuItem<String>(
                    value: model,
                    child: Text(
                      NovaApiModelCatalog.labelFor(model),
                      style: const TextStyle(color: _text),
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _modelController.text = value);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _modelController,
            style: const TextStyle(color: _text),
            decoration: _inputDecoration(
              'Model ID',
              'Sağlayıcının gerçek model adını yaz',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            style: const TextStyle(color: _text),
            decoration: _inputDecoration(
              'API anahtarı',
              'Anahtar cihazda saklanır; kaynak koda yazılmaz',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: _apiSaving ? null : _saveApiSettings,
                  icon: _apiSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text('API Ayarını Kaydet'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceCard() {
    return _card(
      title: 'Sesli ve Yazılı Test',
      icon: Icons.graphic_eq_rounded,
      accent: _success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _lastTranscript.trim().isEmpty
                ? 'Son algılanan ses yok.'
                : 'Son algılanan: $_lastTranscript',
            style: const TextStyle(color: _muted, height: 1.35),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.045),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Text(
              _lastAnswer,
              style: const TextStyle(color: _text, height: 1.38),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _promptController,
            minLines: 2,
            maxLines: 4,
            style: const TextStyle(color: _text),
            decoration: _inputDecoration('Yazılı test', 'Nova’e bir şey sor'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: (_voiceRunning || _busy) ? null : _runVoiceTurn,
                icon: const Icon(Icons.mic_rounded),
                label: Text(_voiceRunning ? 'Dinleniyor...' : 'Sesli Komut'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _sendManualPrompt,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Yazılı Test'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsCard() {
    return _card(
      title: 'İzin Merkezi',
      icon: Icons.verified_user_rounded,
      accent: _warning,
      child: Column(
        children: <Widget>[
          _permissionRow(
            'Mikrofon',
            _permissions.recordAudioGranted,
            () => _permissionService.requestRecordAudioPermission(),
          ),
          _permissionRow(
            'Bildirim',
            _permissions.notificationsGranted,
            () => _permissionService.requestPostNotificationsPermission(),
          ),
          _permissionRow(
            'Overlay',
            _permissions.canDrawOverlays,
            () => _permissionService.openOverlaySettings(),
          ),
          _permissionRow(
            'Accessibility',
            _permissions.accessibilityEnabled,
            () => _permissionService.openAccessibilitySettings(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: _busy ? null : _requestEssentialPermissions,
                icon: const Icon(Icons.mic_external_on_rounded),
                label: const Text('Temel İzinleri İste'),
              ),
              OutlinedButton.icon(
                onPressed: () => _refreshLightState(silent: false),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Yenile'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundCard() {
    return _card(
      title: 'Arka Plan ve Overlay',
      icon: Icons.blur_circular_rounded,
      accent: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Overlay yeni Nova temasına alındı. Hafif animasyonlu, küçük, dokunmayı engellemeyen ve telefonun üst sağında kalan bir durum göstergesi olarak çalışır.',
            style: TextStyle(color: _muted, height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _busy ? null : _startBackgroundAndOverlay,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Arka Planı Başlat'),
              ),
              OutlinedButton(
                onPressed: () => _setOverlayMode('idle'),
                child: const Text('Idle'),
              ),
              OutlinedButton(
                onPressed: () => _setOverlayMode('listening'),
                child: const Text('Dinleme'),
              ),
              OutlinedButton(
                onPressed: () => _setOverlayMode('speaking'),
                child: const Text('Konuşma'),
              ),
              OutlinedButton(
                onPressed: () => _setOverlayMode('sleeping'),
                child: const Text('Uyku'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCallCard() {
    return _card(
      title: 'Çağrı Companion',
      icon: Icons.call_rounded,
      accent: _danger,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _infoRow('Durum', _callStatus),
          _infoRow(
            'Aktif numara',
            _callSnapshot.normalizedActiveNumber.isEmpty
                ? 'Yok'
                : _callSnapshot.normalizedActiveNumber,
          ),
          _infoRow(
            'CallScreening',
            _permissions.callScreeningRoleGranted ? 'Hazır' : 'İzin bekliyor',
          ),
          _infoRow(
            'Default dialer',
            _permissions.defaultDialerGranted ? 'Evet' : 'Hayır',
          ),
          const SizedBox(height: 10),
          const Text(
            'İlk Nova sürümü çağrıyı gözlemler ve öneri üretir. Otomatik cevaplama/reddetme yüksek riskli olduğu için kişi bazlı izin ve policy olmadan açılmaz.',
            style: TextStyle(color: _muted, height: 1.35),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _settings.callHandlingEnabled,
            activeColor: _success,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Çağrı companion aktif',
              style: TextStyle(color: _text),
            ),
            subtitle: const Text(
              'Öneri/gözlem modu. Yüksek riskli aksiyonlar ayrı izin ister.',
              style: TextStyle(color: _muted),
            ),
            onChanged: (value) =>
                _toggleSetting((s) => s.copyWith(callHandlingEnabled: value)),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: _busy ? null : _requestCallPermissions,
                icon: const Icon(Icons.phone_in_talk_rounded),
                label: const Text('Çağrı İzinlerini Hazırla'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await _permissionService.requestDefaultDialerRole();
                  await _refreshLightState(silent: true);
                },
                icon: const Icon(Icons.phone_android_rounded),
                label: const Text('Telefon Rolünü İste'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRuntimeRulesCard() {
    return _card(
      title: 'Nova Çalışma Kuralları',
      icon: Icons.policy_rounded,
      accent: _accent2,
      child: Column(
        children: <Widget>[
          SwitchListTile(
            value: _settings.wakeWordEnabled,
            activeColor: _success,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Wake tetikleri açık',
              style: TextStyle(color: _text),
            ),
            subtitle: const Text(
              'Wake yalnız dinlemeyi başlatır; yetki vermez.',
              style: TextStyle(color: _muted),
            ),
            onChanged: (value) =>
                _toggleSetting((s) => s.copyWith(wakeWordEnabled: value)),
          ),
          SwitchListTile(
            value: _settings.phoneManagementEnabled,
            activeColor: _success,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Telefon yönetimi',
              style: TextStyle(color: _text),
            ),
            subtitle: const Text(
              'Medya/güç/telefon aksiyonları policy gate mantığıyla ilerler.',
              style: TextStyle(color: _muted),
            ),
            onChanged: (value) => _toggleSetting(
              (s) => s.copyWith(phoneManagementEnabled: value),
            ),
          ),
          _rule(
            'Local server yok',
            'APK kendi içinde çalışır; PC/OpenClaw/localhost bağımlılığı yok.',
          ),
          _rule(
            'APK-only Nova kontratı',
            'OpenClaw kaynakları yalnız mimari referans kabul edilir; bu sürüm PC dosyası, daemon veya local gateway beklemez.',
          ),
          _rule(
            'TTS beyin değil',
            'TTS yalnız API/SingleBrain cevabına bağlanan metni okur.',
          ),
          _rule(
            'Çağrı güvenliği',
            'Bilinmeyen arayana kişisel durum sızdırılmaz; otomatik aksiyon ayrı izne bağlıdır.',
          ),
          _rule(
            'Ağ kullanımı',
            'Yalnız seçilen API sağlayıcısı için internet kullanılır; arka planda genel tarama yoktur.',
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required Color accent,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.22)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.16),
                  border: Border.all(color: accent.withOpacity(0.38)),
                ),
                child: Icon(icon, color: accent, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _permissionRow(String label, bool ok, Future<bool> Function() action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Icon(
            ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: ok ? _success : _warning,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _text, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () async {
              await action();
              await _refreshLightState(silent: true);
            },
            child: Text(ok ? 'Açık' : 'Ayarla'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 116,
            child: Text(label, style: const TextStyle(color: _muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: _text, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rule(String title, String body) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.045),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.lock_outline_rounded, color: _accent, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(body, style: const TextStyle(color: _muted, height: 1.32)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stateChip(String label, bool ok) =>
      _miniPill(label, ok ? 'Hazır' : 'Bekliyor', ok ? _success : _warning);

  Widget _miniPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.32)),
      ),
      child: RichText(
        text: TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint.isEmpty ? null : hint,
      labelStyle: const TextStyle(color: _muted),
      hintStyle: TextStyle(color: _muted.withOpacity(0.68)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.055),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _accent, width: 1.3),
      ),
    );
  }
}

class _NovaBackground extends StatelessWidget {
  const _NovaBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _NovaBackgroundPainter());
  }
}

class _NovaBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final rect = Offset.zero & size;
    paint.shader = const LinearGradient(
      colors: <Color>[Color(0xFFF7FAFC), Color(0xFFEAF6FA), Color(0xFFF8FBFD)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(rect);
    canvas.drawRect(rect, paint);

    for (var i = 0; i < 3; i++) {
      final radius = size.shortestSide * (0.32 + i * 0.12);
      final center = Offset(
        size.width * (0.10 + i * 0.32),
        size.height * (0.10 + i * 0.24),
      );
      paint.shader = RadialGradient(
        colors: <Color>[
          const Color(0xFF00E5FF).withOpacity(0.10 - i * 0.02),
          const Color(0x0000E5FF),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NovaOrb extends StatefulWidget {
  final double size;
  const _NovaOrb({required this.size});

  @override
  State<_NovaOrb> createState() => _NovaOrbState();
}

class _NovaOrbState extends State<_NovaOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * math.pi * 2;
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _NovaOrbPainter(t),
        );
      },
    );
  }
}

class _NovaOrbPainter extends CustomPainter {
  final double t;
  const _NovaOrbPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2;
    final paint = Paint()..isAntiAlias = true;

    paint.shader = RadialGradient(
      colors: <Color>[
        const Color(0xFF00E5FF).withOpacity(0.22),
        const Color(0xFF6C5CE7).withOpacity(0.08),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, paint);

    paint
      ..shader = null
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF00E5FF).withOpacity(0.72);
    canvas.drawCircle(center, r * 0.62, paint);

    paint.color = const Color(0xFF6C5CE7).withOpacity(0.72);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 0.42),
      t,
      math.pi * 1.25,
      false,
      paint,
    );
    paint.color = const Color(0xFF00D084).withOpacity(0.80);
    canvas.drawCircle(
      center + Offset(math.cos(t) * r * 0.38, math.sin(t) * r * 0.38),
      r * 0.055,
      paint..style = PaintingStyle.fill,
    );

    paint.shader = const RadialGradient(
      colors: <Color>[Color(0xFFFFFFFF), Color(0xFF00E5FF), Color(0x0000E5FF)],
    ).createShader(Rect.fromCircle(center: center, radius: r * 0.22));
    canvas.drawCircle(center, r * 0.23, paint);
  }

  @override
  bool shouldRepaint(covariant _NovaOrbPainter oldDelegate) =>
      oldDelegate.t != t;
}
