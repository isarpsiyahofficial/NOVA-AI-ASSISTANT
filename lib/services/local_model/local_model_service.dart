// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals_to_create_immutables
// NOVA_API_FIRST_LOCAL_MODEL_COMPAT_STUB_V1
import 'dart:async';

import '../../core/ai/ai_request.dart';
import '../../core/ai/ai_response.dart';

class LocalModelState {
  final bool ready;
  final String message;
  final String path;

  const LocalModelState({
    required this.ready,
    required this.message,
    required this.path,
  });

  bool get hasUsablePath => path.trim().isNotEmpty;

  String get normalizedMessage {
    final value = message.trim();
    return value.isEmpty ? 'API-first sürümde yerel model devre dışı.' : value;
  }

  String buildSummary() {
    return [
      'LOCAL MODEL STATE:',
      '- ready=$ready',
      '- path=${hasUsablePath ? path.trim() : 'yok'}',
      '- message=$normalizedMessage',
      '- not: bu sürümde ana beyin Gemini/OpenAI API router üzerinden çalışır.',
    ].join('\n');
  }

  String buildHealthBand() => ready ? 'api-first-compat' : 'api-first-disabled';

  Map<String, dynamic> toDebugMap() => <String, dynamic>{
    'ready': ready,
    'hasUsablePath': hasUsablePath,
    'healthBand': buildHealthBand(),
    'message': normalizedMessage,
  };
}

class LocalModelBootProgress {
  final String phase;
  final int? percent;
  final String message;
  final bool critical;
  final DateTime receivedAt;

  const LocalModelBootProgress({
    required this.phase,
    required this.percent,
    required this.message,
    required this.critical,
    required this.receivedAt,
  });

  bool get hasRealPercent =>
      percent != null && percent! >= 0 && percent! <= 100;

  factory LocalModelBootProgress.fromMap(Map<dynamic, dynamic> map) {
    final parsedPercent = _safeInt(map['percent']);
    return LocalModelBootProgress(
      phase: _safeString(map['phase'], fallback: 'unknown'),
      percent: parsedPercent != null && parsedPercent >= 0
          ? parsedPercent.clamp(0, 100).toInt()
          : null,
      message: _safeString(map['message']),
      critical: _safeBool(map['critical']),
      receivedAt: DateTime.now(),
    );
  }

  static String _safeString(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static int? _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static bool _safeBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  String get displayMessage {
    final base = message.trim().isEmpty ? phase : message.trim();
    if (hasRealPercent) return '$base (%$percent)';
    return base;
  }
}

class LocalModelService {
  static final StreamController<LocalModelBootProgress>
  _bootProgressController =
      StreamController<LocalModelBootProgress>.broadcast();

  const LocalModelService();

  Stream<LocalModelBootProgress> get bootProgressEvents =>
      _bootProgressController.stream;

  Future<LocalModelBootProgress> prepareForBoot() async {
    final progress = LocalModelBootProgress(
      phase: 'api_first_local_model_detached',
      percent: 100,
      message:
          'Yerel Gemma/LiteRT-LM boot hattı devre dışı; Nova API beyin hattını kullanacak.',
      critical: false,
      receivedAt: DateTime.now(),
    );
    _bootProgressController.add(progress);
    return progress;
  }

  Future<LocalModelBootProgress> verifyBrainKernelForBoot() async {
    final progress = LocalModelBootProgress(
      phase: 'api_brain_expected',
      percent: 100,
      message:
          'Brain Kernel yerel model yerine Gemini/OpenAI API otoritesinden beklenecek.',
      critical: false,
      receivedAt: DateTime.now(),
    );
    _bootProgressController.add(progress);
    return progress;
  }

  Future<AiResponse> generateSetupMicroResponse({
    required String setupStep,
    required String assistantName,
    required String task,
    String userText = '',
    Map<String, dynamic> authorityMetadata = const <String, dynamic>{},
  }) async {
    return AiResponse.error(
      message:
          'Setup mikro cevabı yerel modelden değil API beyin hattından üretilmelidir.',
      metadata: <String, dynamic>{
        ...authorityMetadata,
        'route': 'local_model_setup_micro_detached',
        'setupStep': setupStep,
        'localModelDetached': true,
        'tts_source': 'blocked_non_ai_speech',
      },
    );
  }

  Future<LocalModelState> getState() async {
    return const LocalModelState(
      ready: false,
      message:
          'API-first sürüm: yerel Gemma/LiteRT-LM üretimi kapalı; ana beyin API routerdır.',
      path: '',
    );
  }

  Future<void> purgeRuntimeState({
    String reason = 'runtime_state_purge',
  }) async {
    _bootProgressController.add(
      LocalModelBootProgress(
        phase: 'api_first_purge_noop',
        percent: 100,
        message:
            'API-first sürümde yerel model runtime temizliği gerekmiyor. reason=$reason',
        critical: false,
        receivedAt: DateTime.now(),
      ),
    );
  }

  Future<AiResponse> generateCompactResponse({
    required AiRequest request,
    String systemHint = '',
  }) async {
    return AiResponse.error(
      message:
          'Kompakt yerel model üretimi API-first sürümde kapalı; ApiService kullanılmalı.',
      metadata: <String, dynamic>{
        ...request.metadata,
        'route': 'compact_local_model_detached',
        'localModelDetached': true,
        'systemHintPresent': systemHint.trim().isNotEmpty,
        'tts_source': 'blocked_non_ai_speech',
      },
    );
  }

  Future<AiResponse> generate({
    required AiRequest request,
    required String systemPrompt,
  }) async {
    return AiResponse.error(
      message:
          'Yerel Gemma/LiteRT-LM üretimi API-first sürümde kapalı; cevap Gemini/OpenAI API router üzerinden alınmalıdır.',
      metadata: <String, dynamic>{
        ...request.metadata,
        'route': 'local_model_detached_api_first',
        'localModelDetached': true,
        'systemPromptPresent': systemPrompt.trim().isNotEmpty,
        'tts_source': 'blocked_non_ai_speech',
      },
    );
  }

  String buildKnowledgeRouteHint(String prompt) {
    final normalized = prompt.trim();
    if (normalized.isEmpty)
      return 'Boş istem; API beyin için bağlam üretimi ertelenmeli.';
    return 'API beyin rotası: prompt uzunluğu=${normalized.length}; yerel corpus zorunlu değil.';
  }

  String buildFallbackNarrative(String prompt) {
    final normalized = prompt.trim();
    if (normalized.isEmpty)
      return 'Boş veya belirsiz istem; önce niyet netleşmeli.';
    if (normalized.length < 24)
      return 'Kısa istem; API cevabı kısa ve doğal tutulmalı.';
    return 'Uzun istem; API cevabı çekirdek niyet + gerekli detay şeklinde düzenlemeli.';
  }

  Future<Map<String, dynamic>> buildCorpusDebugEnvelope(String prompt) async {
    return <String, dynamic>{
      'prompt': prompt.trim(),
      'domainCount': 0,
      'domains': const <String>[],
      'corpus': const <String, dynamic>{
        'ready': false,
        'message':
            'API-first sürümde local corpus debug zorunlu değil; asset klasörü kullanıcı tarafında korunur.',
      },
      'localModelDetached': true,
    };
  }
}
