// ignore_for_file: unused_field
// NOVA_APK_STANDALONE_DASHBOARD_V5_VERIFIED_RUNTIME_ONLY
import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/nova_ai_provider_type.dart';
import '../../core/api/nova_api_model_catalog.dart';
import '../../core/audio_runtime/nova_stt_result.dart';
import '../../core/behavior/nova_persona.dart';
import '../../core/behavior/response_style.dart';
import '../../core/settings/nova_settings.dart';
import '../../core/turn/nova_core_turn_controller.dart';
import '../../core/turn/nova_turn_authority.dart';
import '../../services/actions/nova_phone_control_bridge_service.dart';
import '../../services/api/api_service.dart';
import '../../services/call/nova_call_state_service.dart';
import '../../services/conversation/nova_conversation_session_service.dart';
import '../../services/identity/nova_voice_identity_bridge_service.dart';
import '../../services/local_model/local_model_service.dart';
import '../../services/permissions/nova_android_permission_bridge_service.dart';
import '../../services/reminder/nova_reminder_command_service.dart';
import '../../services/reminder/nova_reminder_service.dart';
import '../../services/settings/nova_settings_service.dart';
import '../../services/stt/nova_speech_to_text_service.dart';
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
  static const Color _accent = Color(0xFF0E7490);
  static const Color _success = Color(0xFF047857);
  static const Color _warning = Color(0xFFB45309);
  static const Color _danger = Color(0xFFB91C1C);

  final NovaSettingsService _settingsService = const NovaSettingsService();
  final NovaAndroidPermissionBridgeService _permissionService =
      const NovaAndroidPermissionBridgeService();
  final NovaCallStateService _callStateService = const NovaCallStateService();
  final NovaPhoneControlBridgeService _phoneBridge =
      const NovaPhoneControlBridgeService();
  final NovaCoreTurnController _coreTurnController =
      const NovaCoreTurnController();

  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();

  NovaSettings _settings = const NovaSettings();
  NovaAndroidPermissionSnapshot _permissions =
      const NovaAndroidPermissionSnapshot();
  NovaCallStateSnapshot _callSnapshot = NovaCallStateSnapshot.idle();
  NovaAiProviderType _provider = NovaAiProviderType.gemini;

  bool _loading = true;
  bool _busy = false;
  bool _savingApi = false;
  String _status = 'Nova hazırlanıyor.';
  String _lastTranscript = '';
  String _lastAnswer = 'Henüz bir komut işlenmedi.';
  String _lastAction = 'Henüz Android eylemi çalıştırılmadı.';
  String _lastIdentity = 'Sahip sesi henüz kontrol edilmedi.';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => unawaited(_refreshRuntime(silent: true)),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _apiKeyController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (widget.setupRequired) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status =
            'Doğrulanmış ilk kurulum tamamlanmadan dashboard açılamaz.';
      });
      return;
    }

    if (widget.deferHeavyBootstrap) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
    final settings = await _settingsService.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _provider = settings.activeAiProvider;
      _apiKeyController.text = settings.apiKey;
    });
    await _refreshRuntime(silent: true);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _status = settings.apiKey.trim().isEmpty
          ? 'API anahtarını kaydedin.'
          : 'Gerçek ses → AI → Android → doğrulama hattı hazır.';
    });
  }

  Future<void> _refreshRuntime({bool silent = false}) async {
    try {
      final permissions = await _permissionService.getPermissionSnapshot();
      final call = await _callStateService.getSnapshot();
      if (!mounted) return;
      setState(() {
        _permissions = permissions;
        _callSnapshot = call;
        if (!silent) _status = 'Telefon durumu yenilendi.';
      });
    } catch (error) {
      if (!mounted || silent) return;
      setState(() => _status = 'Telefon durumu okunamadı: $error');
    }
  }

  Future<void> _saveApi() async {
    if (_savingApi) return;
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      setState(() => _status = 'API anahtarı boş olamaz.');
      return;
    }
    setState(() {
      _savingApi = true;
      _status = 'API ayarları güvenli depoya kaydediliyor...';
    });
    try {
      final model = NovaApiModelCatalog.migrateSavedModelId(
        _provider,
        _settings.activeApiModel,
      );
      final next = _settings.copyWith(
        apiKey: key,
        activeAiProvider: _provider,
        activeApiModel: NovaApiModelCatalog.isProductionPreset(
          _provider,
          model,
        )
            ? model
            : NovaApiModelCatalog.defaultModelFor(_provider),
        apiBrainEnabled: true,
        chatGptInternetEnabled: true,
      );
      await _settingsService.save(next);
      if (!mounted) return;
      setState(() {
        _settings = next;
        _status =
            '${_provider.label} / ${next.activeApiModel} kaydedildi.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = 'API ayarları kaydedilemedi: $error');
    } finally {
      if (mounted) setState(() => _savingApi = false);
    }
  }

  Future<void> _runTextTurn() async {
    final text = _promptController.text.trim();
    if (text.isEmpty) return;
    _promptController.clear();
    await _executeTurn(
      text: text,
      source: NovaTurnSource.dashboardText,
      sttResult: null,
    );
  }

  Future<void> _runVoiceTurn() async {
    if (_busy) return;
    var hasMic = await _permissionService.hasRecordAudioPermission();
    if (!hasMic) {
      hasMic = await _permissionService.requestRecordAudioPermission();
    }
    if (!hasMic) {
      setState(() => _status = 'Mikrofon izni olmadan sesli komut alınamaz.');
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Dinliyorum. Komutu doğal şekilde söyleyin.';
      _lastIdentity = 'Aynı konuşma segmenti TitaNet ile kontrol edilecek.';
    });
    try {
      final stt = await widget.sttService.transcribe(
        mode: NovaSttMode.enhanced,
        targetDescription: 'Nova sahip komutu',
        preferExtendedConversationWindow: true,
      );
      if (!stt.success || stt.recognizedText.trim().isEmpty) {
        if (!mounted) return;
        setState(() {
          _status = stt.message;
          _lastIdentity = stt.voiceIdentityChecked
              ? 'Ses kontrol edildi fakat sahip doğrulanmadı.'
              : 'Sahip sesi doğrulanamadı.';
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _lastTranscript = stt.recognizedText.trim();
        _lastIdentity = stt.ownerMatched
            ? 'Sahip doğrulandı: ${stt.speakerName.isEmpty ? stt.speakerVoiceId : stt.speakerName} · ${stt.ownerConfidence.toStringAsFixed(3)}'
            : 'Konuşma yazıya çevrildi; kayıtlı sahip sesi eşleşmedi. Telefon eylemleri engellenecek.';
      });
      await _executeTurn(
        text: stt.recognizedText,
        source: NovaTurnSource.dashboardVoice,
        sttResult: stt,
        preserveBusy: true,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = 'Sesli komut çalıştırılamadı: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _executeTurn({
    required String text,
    required NovaTurnSource source,
    required NovaSttResult? sttResult,
    bool preserveBusy = false,
  }) async {
    if (_busy && !preserveBusy) return;
    if (!preserveBusy) setState(() => _busy = true);
    setState(() {
      _status = 'AI kararı hazırlanıyor; eylem varsa Android sonucu beklenecek.';
      _lastTranscript = text.trim();
    });

    try {
      final settings = await _settingsService.load();
      final phoneState = await _phoneBridge.getStatus();
      final authority = source == NovaTurnSource.dashboardText
          ? NovaTurnAuthority.localUser(
              evidenceId: 'dashboard_text_${DateTime.now().microsecondsSinceEpoch}',
            )
          : (sttResult?.ownerMatched == true &&
                  sttResult!.nativeActionToken.trim().isNotEmpty
              ? NovaTurnAuthority.ownerVoice(
                  ownerVoiceId: sttResult.speakerVoiceId,
                  confidence: sttResult.ownerConfidence,
                  nativeActionToken: sttResult.nativeActionToken,
                  evidenceId: sttResult.identityAudioPath,
                )
              : const NovaTurnAuthority.unverified());
      final result = await _coreTurnController.processUserTurn(
        NovaCoreTurnRequest(
          inputText: text,
          source: source,
          settings: settings,
          requestedByVoice: source == NovaTurnSource.dashboardVoice,
          userInitiated: true,
          userConfirmedThisAction: true,
          authority: authority,
          context: <String, dynamic>{
            'screenLocked': phoneState['screenLocked'] == true,
            'userConfirmedThisAction': true,
            'voiceIdentityChecked': sttResult?.voiceIdentityChecked ?? false,
            'ownerVerified': sttResult?.ownerMatched ?? false,
            'ownerConfidence': sttResult?.ownerConfidence ?? 0.0,
            'speakerVoiceId': sttResult?.speakerVoiceId ?? '',
            'speakerName': sttResult?.speakerName ?? '',
            'relationshipLabel': sttResult?.relationshipLabel ?? 'unknown',
            'identityAudioPath': sttResult?.identityAudioPath ?? '',
            'inputSurface': source.name,
          },
        ),
      );

      final action = _readActionResult(result.response.metadata);
      final answer = result.finalText.trim().isNotEmpty
          ? result.finalText.trim()
          : result.response.displayText.trim();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _provider = settings.activeAiProvider;
        _lastAnswer = answer.isEmpty ? 'AI boş cevap döndürdü.' : answer;
        _lastAction = action.label;
        _status = action.requested
            ? action.statusText
            : result.response.isError
                ? result.response.displayText
                : 'AI cevabı alındı. Telefon eylemi istenmedi.';
      });

      if (result.allowedToSpeak && answer.isNotEmpty) {
        await widget.ttsService.speak(
          answer,
          mode: NovaTtsMode.neuralLocal,
          authoritySource: result.ttsSource,
          authorityResponse: result.response,
          singleBrainApproved: true,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = 'Komut zinciri hata verdi: $error';
        _lastAction = 'Android eylemi tamamlanmadı.';
      });
    } finally {
      if (mounted && !preserveBusy) setState(() => _busy = false);
    }
  }

  _DashboardActionState _readActionResult(Map<String, dynamic> metadata) {
    if (metadata['deviceActionRequested'] != true) {
      return const _DashboardActionState.notRequested();
    }
    final raw = metadata['deviceActionResult'];
    final map = raw is Map
        ? Map<String, dynamic>.from(raw)
        : const <String, dynamic>{};
    final success = map['success'] == true;
    final verified = map['verified'] == true;
    final action = map['action']?.toString() ?? 'unknown';
    final message = map['message']?.toString().trim() ?? '';
    return _DashboardActionState(
      requested: true,
      success: success,
      verified: verified,
      label: '$action · ${verified ? 'doğrulandı' : success ? 'gönderildi, doğrulanmadı' : 'başarısız'}${message.isEmpty ? '' : ' · $message'}',
      statusText: verified
          ? 'Telefon eylemi Android durumundan doğrulandı.'
          : success
              ? 'Komut Android’e gönderildi fakat son durum doğrulanamadı.'
              : 'Telefon eylemi çalıştırılamadı.',
    );
  }

  Future<void> _requestCallPermissions() async {
    await _permissionService.requestEssentialCallPermissions();
    await _refreshRuntime();
  }

  Future<void> _requestDialerRole() async {
    await _permissionService.requestDefaultDialerRole();
    await _refreshRuntime();
  }

  Future<void> _openAccessibility() async {
    await _permissionService.openAccessibilitySettings();
    await _refreshRuntime();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('NOVA · Doğrulanmış Telefon Asistanı'),
        actions: <Widget>[
          IconButton(
            onPressed: _busy ? null : () => _refreshRuntime(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Durumu yenile',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _statusCard(),
            const SizedBox(height: 12),
            _conversationCard(),
            const SizedBox(height: 12),
            _runtimeCard(),
            const SizedBox(height: 12),
            _apiCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _runVoiceTurn,
        backgroundColor: _busy ? Colors.grey : _accent,
        icon: Icon(_busy ? Icons.hourglass_top : Icons.mic),
        label: Text(_busy ? 'Çalışıyor' : 'Sesli komut'),
      ),
    );
  }

  Widget _statusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _status,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(_lastIdentity),
            const SizedBox(height: 6),
            Text(
              _lastAction,
              style: TextStyle(
                color: _lastAction.contains('doğrulandı')
                    ? _success
                    : _lastAction.contains('başarısız')
                        ? _danger
                        : _warning,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conversationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Gerçek komut hattı', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Sesli komutta aynı Silero segmenti hem Whisper’a hem TitaNet’e gider. '
              'AI yalnız yapılandırılmış eylem ister; Android sonucu doğrulanmadan NOVA “yaptım” demez.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _promptController,
              enabled: !_busy,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => unawaited(_runTextTurn()),
              decoration: const InputDecoration(
                labelText: 'NOVA’ya yaz',
                hintText: 'Örnek: Spotify’ı aç veya annemi ara',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _busy ? null : _runTextTurn,
              icon: const Icon(Icons.send),
              label: const Text('Gönder'),
            ),
            const Divider(height: 28),
            Text('Son transcript', style: Theme.of(context).textTheme.labelLarge),
            SelectableText(_lastTranscript.isEmpty ? '—' : _lastTranscript),
            const SizedBox(height: 12),
            Text('NOVA cevabı', style: Theme.of(context).textTheme.labelLarge),
            SelectableText(_lastAnswer),
          ],
        ),
      ),
    );
  }

  Widget _runtimeCard() {
    final callReady = _permissions.canAttemptAuthorizedCallHandling;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Android çalışma durumu', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            _flag('Mikrofon', _permissions.recordAudioGranted),
            _flag('Erişilebilirlik', _permissions.accessibilityEnabled),
            _flag('Temel çağrı izinleri', _permissions.essentialCallPermissionsGranted),
            _flag('Varsayılan telefon uygulaması', _permissions.defaultDialerGranted),
            _flag('Telecom kontrol hattı', callReady),
            const SizedBox(height: 8),
            Text(
              _callSnapshot.inCall
                  ? 'Çağrı: ${_callSnapshot.callerDisplayName.isEmpty ? _callSnapshot.normalizedActiveNumber : _callSnapshot.callerDisplayName} · ${_callSnapshot.state}'
                  : 'Aktif çağrı yok.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton(
                  onPressed: _requestCallPermissions,
                  child: const Text('Çağrı izinleri'),
                ),
                OutlinedButton(
                  onPressed: _requestDialerRole,
                  child: const Text('Telefon rolü'),
                ),
                OutlinedButton(
                  onPressed: _openAccessibility,
                  child: const Text('Erişilebilirlik'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'SIM çağrısını cevaplama/reddetme/sonlandırma gerçek Telecom kontrolüdür. '
              'Karşı taraf sesi ve NOVA TTS’si için doğrulanmış operatör ses taşıması olmadığından tam SIM görüşmesi hazır gösterilmez.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _apiCard() {
    final models = NovaApiModelCatalog.presetsFor(_provider);
    final selectedModel = models.contains(_settings.activeApiModel)
        ? _settings.activeApiModel
        : NovaApiModelCatalog.defaultModelFor(_provider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('AI sağlayıcısı', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            DropdownButtonFormField<NovaAiProviderType>(
              value: _provider,
              decoration: const InputDecoration(
                labelText: 'Sağlayıcı',
                border: OutlineInputBorder(),
              ),
              items: NovaAiProviderType.values
                  .map(
                    (value) => DropdownMenuItem<NovaAiProviderType>(
                      value: value,
                      child: Text(value.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _busy
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _provider = value;
                        _settings = _settings.copyWith(
                          activeAiProvider: value,
                          activeApiModel:
                              NovaApiModelCatalog.defaultModelFor(value),
                        );
                      });
                    },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedModel,
              decoration: const InputDecoration(
                labelText: 'Üretim modeli',
                border: OutlineInputBorder(),
              ),
              items: models
                  .map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(NovaApiModelCatalog.labelFor(value)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _busy
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _settings = _settings.copyWith(activeApiModel: value);
                      });
                    },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              enabled: !_savingApi,
              decoration: const InputDecoration(
                labelText: 'API anahtarı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _savingApi ? null : _saveApi,
              icon: const Icon(Icons.lock),
              label: Text(_savingApi ? 'Kaydediliyor' : 'Güvenli kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _flag(String label, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: enabled ? _success : _danger,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _DashboardActionState {
  final bool requested;
  final bool success;
  final bool verified;
  final String label;
  final String statusText;

  const _DashboardActionState({
    required this.requested,
    required this.success,
    required this.verified,
    required this.label,
    required this.statusText,
  });

  const _DashboardActionState.notRequested()
      : requested = false,
        success = false,
        verified = false,
        label = 'Telefon eylemi istenmedi.',
        statusText = 'Telefon eylemi istenmedi.';
}
