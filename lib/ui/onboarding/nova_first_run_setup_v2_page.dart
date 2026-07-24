import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/ai/ai_mode.dart';
import '../../core/ai/ai_request.dart';
import '../../core/api/nova_ai_provider_type.dart';
import '../../core/api/nova_api_model_catalog.dart';
import '../../core/settings/nova_settings.dart';
import '../../services/api/api_service.dart';
import '../../services/identity/device_owner_identity_service.dart';
import '../../services/identity/nova_first_run_service.dart';
import '../../services/identity/nova_voice_identity_bridge_service.dart';
import '../../services/settings/nova_settings_service.dart';
import '../../services/stt/nova_speech_to_text_service.dart';
import '../../services/tts/nova_tts_service.dart';

// NOVA_FIRST_RUN_SETUP_V2_VERIFIED_ENGINES_AND_OWNER
// A setup is complete only after API proof, packaged engine proof, a real
// TitaNet enrollment sample and an independent verification sample.
class NovaFirstRunSetupV2Page extends StatefulWidget {
  final NovaSpeechToTextService sttService;
  final NovaTtsService ttsService;
  final ApiService apiService;
  final DeviceOwnerIdentityService ownerService;
  final NovaFirstRunService firstRunService;
  final NovaVoiceIdentityBridgeService voiceIdentityBridgeService;
  final VoidCallback onCompleted;

  const NovaFirstRunSetupV2Page({
    super.key,
    required this.sttService,
    required this.ttsService,
    required this.apiService,
    required this.ownerService,
    required this.firstRunService,
    required this.voiceIdentityBridgeService,
    required this.onCompleted,
  });

  @override
  State<NovaFirstRunSetupV2Page> createState() =>
      _NovaFirstRunSetupV2PageState();
}

class _NovaFirstRunSetupV2PageState
    extends State<NovaFirstRunSetupV2Page> {
  final NovaSettingsService _settingsService = const NovaSettingsService();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();

  NovaSettings _settings = const NovaSettings();
  NovaAiProviderType _provider = NovaAiProviderType.gemini;
  String _model = NovaApiModelCatalog.geminiFreeTierStable;
  String _status = 'Motor kontrolünü başlatın.';
  String _voiceId = '';

  bool _loading = true;
  bool _busy = false;
  bool _runtimeReady = false;
  bool _apiReady = false;
  bool _voiceEnrolled = false;
  bool _voiceVerified = false;
  double _verificationSimilarity = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final settings = await _settingsService.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _provider = settings.activeAiProvider;
      _model = settings.activeApiModel.trim().isEmpty
          ? NovaApiModelCatalog.defaultModelFor(settings.activeAiProvider)
          : settings.activeApiModel.trim();
      _apiKeyController.text = settings.apiKey;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _runRuntimeCheck() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _runtimeReady = false;
      _status = 'ASR, TTS ve ses kimliği motorları doğrulanıyor...';
    });

    try {
      final identity = await widget.voiceIdentityBridgeService.warmup();
      final asrReady = await widget.sttService.nativeBridge
          .ensureStreamingAsrReady();
      final ttsReady = await widget.sttService.nativeBridge.warmupSherpaTts(
        preferredModelKey: 'sherpa_piper_tr_offline',
      );
      final ttsCapabilities = await widget.sttService.nativeBridge
          .getSherpaTtsCapabilities();
      final assetReady = ttsCapabilities['assetReady'] == true;
      final realSherpa =
          ttsCapabilities['engine']?.toString() == 'sherpa_onnx_offline_tts';
      final ok = identity.success && asrReady && ttsReady && assetReady && realSherpa;

      if (!mounted) return;
      setState(() {
        _runtimeReady = ok;
        _status = ok
            ? 'Motorlar hazır: embedded ASR, offline Sherpa TTS ve TitaNet speaker-ID doğrulandı.'
            : 'Motor kontrolü başarısız. ASR=$asrReady TTS=$ttsReady asset=$assetReady speaker=${identity.success}. ${identity.message} ${ttsCapabilities['message'] ?? ''}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _runtimeReady = false;
        _status = 'Motor kontrolü hata verdi: $error';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyApi() async {
    if (_busy || !_runtimeReady) return;
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      setState(() => _status = 'API anahtarı boş olamaz.');
      return;
    }

    setState(() {
      _busy = true;
      _apiReady = false;
      _status = '${_provider.label} API beyni gerçek istekle doğrulanıyor...';
    });

    try {
      final selectedModel = _model.trim().isEmpty
          ? NovaApiModelCatalog.defaultModelFor(_provider)
          : _model.trim();
      final next = _settings.copyWith(
        apiKey: key,
        activeAiProvider: _provider,
        activeApiModel: selectedModel,
        apiBrainEnabled: true,
        chatGptInternetEnabled: true,
      );
      await _settingsService.save(next);

      final response = await widget.apiService.send(
        AiRequest(
          prompt:
              'Bu bir Nova ilk kurulum bağlantı testidir. Yalnızca HAZIR kelimesini yaz.',
          mode: AiMode.apiOnly,
          internetAllowed: true,
          isFastResponsePriority: true,
          requestedByVoice: false,
          requestOrigin: 'setup_ui',
          activeProviderKey: _provider.key,
          activeModelId: selectedModel,
          metadata: const <String, dynamic>{
            'source': 'first_run_setup_v2',
            'connectionTest': true,
          },
        ),
      );
      final ok = !response.isError && response.fromApi && response.text.trim().isNotEmpty;
      if (!mounted) return;
      setState(() {
        _settings = next;
        _model = selectedModel;
        _apiReady = ok;
        _status = ok
            ? 'API beyni doğrulandı. Şimdi sahip sesini kaydedin.'
            : 'API doğrulanamadı: ${response.displayText}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _apiReady = false;
        _status = 'API doğrulaması hata verdi: $error';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enrollOwnerVoice() async {
    if (_busy || !_apiReady) return;
    final ownerName = _ownerNameController.text.trim();
    if (ownerName.length < 2) {
      setState(() => _status = 'Sahip adını girin.');
      return;
    }

    setState(() {
      _busy = true;
      _voiceEnrolled = false;
      _voiceVerified = false;
      _status =
          '8 saniye boyunca doğal sesinizle konuşun. Sessiz kalmayın; telefonun mikrofonuna normal mesafeden konuşun.';
    });

    try {
      await widget.sttService.streamingAsrRuntimeService.stop(force: true);
      final capture = await widget.sttService.nativeBridge
          .captureCloneSampleExternal(
            maxDurationSeconds: 8,
            outputName: 'nova_owner_enrollment',
          );
      final filePath = capture['filePath']?.toString().trim() ?? '';
      if (capture['success'] != true || filePath.isEmpty) {
        throw StateError(
          capture['message']?.toString() ?? 'Sahip ses örneği alınamadı.',
        );
      }

      final voiceId = 'owner_${DateTime.now().microsecondsSinceEpoch}';
      final enrollment = await widget.voiceIdentityBridgeService
          .enrollVoiceprintFromFile(
            voiceId: voiceId,
            displayName: ownerName,
            audioPath: filePath,
          );
      final ok = enrollment.success &&
          enrollment.voiceId.trim().isNotEmpty &&
          enrollment.embeddingSize > 0;
      if (!ok) {
        throw StateError(
          enrollment.message.isEmpty
              ? 'TitaNet geçerli voiceprint üretmedi.'
              : enrollment.message,
        );
      }

      if (!mounted) return;
      setState(() {
        _voiceId = enrollment.voiceId.trim();
        _voiceEnrolled = true;
        _status =
            'Voiceprint kaydedildi. Şimdi ikinci ve bağımsız bir ses örneğiyle doğrulayın.';
      });
    } catch (error) {
      if (_voiceId.isNotEmpty) {
        await widget.voiceIdentityBridgeService.removeVoiceprint(_voiceId);
      }
      if (!mounted) return;
      setState(() {
        _voiceId = '';
        _voiceEnrolled = false;
        _status = 'Ses kaydı başarısız: $error';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyOwnerVoice() async {
    if (_busy || !_voiceEnrolled || _voiceId.isEmpty) return;
    setState(() {
      _busy = true;
      _voiceVerified = false;
      _status =
          '6 saniye boyunca tekrar doğal şekilde konuşun. Bu örnek kayıt örneğinden bağımsız doğrulanacak.';
    });

    try {
      await widget.sttService.streamingAsrRuntimeService.stop(force: true);
      final capture = await widget.sttService.nativeBridge
          .captureCloneSampleExternal(
            maxDurationSeconds: 6,
            outputName: 'nova_owner_verification',
          );
      final filePath = capture['filePath']?.toString().trim() ?? '';
      if (capture['success'] != true || filePath.isEmpty) {
        throw StateError(
          capture['message']?.toString() ?? 'Doğrulama sesi alınamadı.',
        );
      }

      final identity = await widget.voiceIdentityBridgeService
          .identifyVoiceFromFile(audioPath: filePath, minSimilarity: 0.66);
      final ok = identity.success &&
          identity.matched &&
          identity.voiceId.trim() == _voiceId &&
          identity.similarity >= 0.66;
      if (!ok) {
        await widget.voiceIdentityBridgeService.removeVoiceprint(_voiceId);
        throw StateError(
          'Ses eşleşmedi. similarity=${identity.similarity.toStringAsFixed(3)} ${identity.message}',
        );
      }

      if (!mounted) return;
      setState(() {
        _verificationSimilarity = identity.similarity;
        _voiceVerified = true;
        _status =
            'Sahip sesi bağımsız örnekle doğrulandı. Kurulumu tamamlayabilirsiniz.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _voiceId = '';
        _voiceEnrolled = false;
        _voiceVerified = false;
        _verificationSimilarity = 0;
        _status = 'Ses doğrulaması başarısız; kayıt sıfırlandı: $error';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _complete() async {
    if (_busy || !_voiceVerified || _voiceId.isEmpty || !_apiReady) return;
    final ownerName = _ownerNameController.text.trim();
    setState(() {
      _busy = true;
      _status = 'Doğrulanmış profil kaydediliyor...';
    });

    try {
      await widget.ownerService.registerOwner(
        ownerName: ownerName,
        ownerVoiceId: _voiceId,
        welcomeBackText: 'Hoş geldin $ownerName.',
        proactiveChatAllowed: true,
      );
      final next = _settings.copyWith(
        activeVoiceProfileId: _voiceId,
        wakeWordEnabled: true,
      );
      await _settingsService.save(next);
      await widget.firstRunService.markOnboardingCompleted();
      if (!mounted) return;
      setState(() {
        _settings = next;
        _status = 'Kurulum tamamlandı.';
      });
      widget.onCompleted();
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = 'Kurulum kaydedilemedi: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF110607),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final models = NovaApiModelCatalog.presetsFor(_provider);
    if (!models.contains(_model)) {
      _model = NovaApiModelCatalog.defaultModelFor(_provider);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF110607),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                const Text(
                  'NOVA GERÇEK KURULUM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hiçbir adım simüle edilmez. Motor, API ve sahip sesi gerçekten doğrulanmadan uygulama açılmaz.',
                  style: TextStyle(color: Color(0xFFCFBFC0), height: 1.45),
                ),
                const SizedBox(height: 18),
                _StatusCard(
                  status: _status,
                  busy: _busy,
                  runtimeReady: _runtimeReady,
                  apiReady: _apiReady,
                  voiceEnrolled: _voiceEnrolled,
                  voiceVerified: _voiceVerified,
                  similarity: _verificationSimilarity,
                ),
                const SizedBox(height: 16),
                _StepCard(
                  title: '1. Native motor doğrulaması',
                  child: FilledButton(
                    onPressed: _busy ? null : _runRuntimeCheck,
                    child: const Text('ASR + TTS + SPEAKER-ID KONTROL ET'),
                  ),
                ),
                _StepCard(
                  title: '2. API beyni',
                  enabled: _runtimeReady,
                  child: Column(
                    children: <Widget>[
                      DropdownButtonFormField<NovaAiProviderType>(
                        initialValue: _provider,
                        dropdownColor: const Color(0xFF261315),
                        decoration: const InputDecoration(labelText: 'Sağlayıcı'),
                        items: NovaAiProviderType.values
                            .map(
                              (item) => DropdownMenuItem<NovaAiProviderType>(
                                value: item,
                                child: Text(item.label),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: !_runtimeReady || _busy
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() {
                                  _provider = value;
                                  _model = NovaApiModelCatalog.defaultModelFor(value);
                                  _apiReady = false;
                                });
                              },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: models.contains(_model) ? _model : models.first,
                        dropdownColor: const Color(0xFF261315),
                        decoration: const InputDecoration(labelText: 'Model'),
                        items: models
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(NovaApiModelCatalog.labelFor(item)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: !_runtimeReady || _busy
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() {
                                  _model = value;
                                  _apiReady = false;
                                });
                              },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _apiKeyController,
                        obscureText: true,
                        enabled: _runtimeReady && !_busy,
                        decoration: const InputDecoration(
                          labelText: 'API anahtarı',
                          hintText: 'Anahtar yalnız güvenli ayarlarda saklanır',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: !_runtimeReady || _busy ? null : _verifyApi,
                        child: const Text('GERÇEK API İSTEĞİYLE DOĞRULA'),
                      ),
                    ],
                  ),
                ),
                _StepCard(
                  title: '3. Sahip voiceprint kaydı',
                  enabled: _apiReady,
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: _ownerNameController,
                        enabled: _apiReady && !_busy,
                        decoration: const InputDecoration(labelText: 'Sahip adı'),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: !_apiReady || _busy ? null : _enrollOwnerVoice,
                        child: const Text('8 SANİYELİK VOICEPRINT KAYDI'),
                      ),
                    ],
                  ),
                ),
                _StepCard(
                  title: '4. Bağımsız ses doğrulaması',
                  enabled: _voiceEnrolled,
                  child: FilledButton(
                    onPressed: !_voiceEnrolled || _busy
                        ? null
                        : _verifyOwnerVoice,
                    child: const Text('İKİNCİ SES ÖRNEĞİYLE DOĞRULA'),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: !_voiceVerified || _busy ? null : _complete,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('DOĞRULANMIŞ KURULUMU TAMAMLA'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool enabled;

  const _StepCard({
    required this.title,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.45,
      duration: const Duration(milliseconds: 180),
      child: Card(
        color: const Color(0xFF211012),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String status;
  final bool busy;
  final bool runtimeReady;
  final bool apiReady;
  final bool voiceEnrolled;
  final bool voiceVerified;
  final double similarity;

  const _StatusCard({
    required this.status,
    required this.busy,
    required this.runtimeReady,
    required this.apiReady,
    required this.voiceEnrolled,
    required this.voiceVerified,
    required this.similarity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2B1719),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF65353A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (busy) const LinearProgressIndicator(),
          if (busy) const SizedBox(height: 10),
          Text(status, style: const TextStyle(color: Colors.white, height: 1.4)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _badge('Motor', runtimeReady),
              _badge('API', apiReady),
              _badge('Voiceprint', voiceEnrolled),
              _badge(
                voiceVerified
                    ? 'Eşleşme ${(similarity * 100).toStringAsFixed(1)}%'
                    : 'Doğrulama',
                voiceVerified,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFF174A35) : const Color(0xFF4B272A),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '${ok ? '✓' : '○'} $label',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
