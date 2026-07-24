// ignore_for_file: avoid_print
// NOVA_API_PROVIDER_AGENT_LOOP_V2_VERIFIED_ANDROID_ACTIONS
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../core/actions/nova_device_action.dart';
import '../../core/ai/ai_request.dart';
import '../../core/ai/ai_response.dart';
import '../../core/api/nova_ai_provider_type.dart';
import '../../core/api/nova_api_model_catalog.dart';
import '../../core/speech/nova_final_text_contract.dart';
import '../actions/nova_device_action_executor_service.dart';
import '../settings/nova_settings_service.dart';

class ApiService {
  final bool isApiConfigured;
  final bool hasAvailableBalance;
  final NovaAiProviderType provider;
  final String apiKey;
  final String model;
  final Duration timeout;
  final NovaDeviceActionExecutorService actionExecutor;

  const ApiService({
    this.isApiConfigured = false,
    this.hasAvailableBalance = false,
    this.provider = NovaAiProviderType.gemini,
    this.apiKey = '',
    this.model = '',
    this.timeout = const Duration(seconds: 45),
    this.actionExecutor = const NovaDeviceActionExecutorService(),
  });

  bool get ready =>
      isApiConfigured && hasAvailableBalance && apiKey.trim().isNotEmpty;

  Future<AiResponse> send(AiRequest request) async {
    final settings = await const NovaSettingsService().load();
    final requestProvider = NovaAiProviderTypeX.fromKey(
      request.activeProviderKey,
    );
    final hasRequestProvider = request.activeProviderKey.trim().isNotEmpty;
    final effectiveProvider = hasRequestProvider
        ? requestProvider
        : settings.activeAiProvider;
    final requestModel = request.activeModelId.trim();
    final settingsModel = settings.activeApiModel.trim();
    final constructorModel = model.trim();
    final effectiveApiKey = settings.apiKey.trim().isNotEmpty
        ? settings.apiKey.trim()
        : apiKey.trim();
    final effectiveModel = requestModel.isNotEmpty
        ? requestModel
        : settingsModel.isNotEmpty
            ? settingsModel
            : constructorModel.isNotEmpty
                ? constructorModel
                : NovaApiModelCatalog.defaultModelFor(effectiveProvider);
    final effectiveConfigured =
        effectiveApiKey.isNotEmpty && settings.apiBrainEnabled;

    if (!effectiveConfigured) {
      return AiResponse.error(
        message: 'API yapılandırılmamış veya kullanılabilir değil.',
        metadata: <String, dynamic>{
          ...request.metadata,
          'route': 'api_not_configured',
          'provider': effectiveProvider.key,
          'tts_source': 'blocked_non_ai_speech',
        },
      );
    }

    final active = ApiService(
      isApiConfigured: true,
      hasAvailableBalance: true,
      provider: effectiveProvider,
      apiKey: effectiveApiKey,
      model: effectiveModel,
      timeout: timeout,
      actionExecutor: actionExecutor,
    );

    final safePrompt = request.prompt.trim();
    if (safePrompt.isEmpty) {
      return AiResponse.error(
        message: 'API isteği boş prompt ile gönderilmedi.',
        metadata: <String, dynamic>{
          ...request.metadata,
          'route': 'api_empty_prompt_blocked',
          'provider': active.provider.key,
        },
      );
    }

    try {
      switch (active.provider) {
        case NovaAiProviderType.gemini:
          return await active._sendGemini(request, safePrompt);
        case NovaAiProviderType.openai:
          return await active._sendOpenAi(request, safePrompt);
        case NovaAiProviderType.qwen:
          return await active._sendQwen(request, safePrompt);
      }
    } on TimeoutException {
      return AiResponse.error(
        message: 'API cevabı zamanında dönmedi.',
        metadata: <String, dynamic>{
          ...request.metadata,
          'route': 'api_timeout',
          'provider': active.provider.key,
        },
      );
    } catch (error) {
      return AiResponse.error(
        message: 'API cevabı alınamadı: $error',
        metadata: <String, dynamic>{
          ...request.metadata,
          'route': 'api_exception',
          'provider': active.provider.key,
          'exceptionType': error.runtimeType.toString(),
        },
      );
    }
  }

  Future<AiResponse> _sendGemini(
    AiRequest request,
    String prompt, {
    bool allowTools = true,
    Map<String, dynamic> extraMetadata = const <String, dynamic>{},
    String expectedActionSummary = '',
  }) async {
    final activeModel = _effectiveModel(
      fallback: NovaApiModelCatalog.geminiFreeTierStable,
    );
    final toolsEnabled = allowTools && _mayOfferDeviceTools(request);
    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$activeModel:generateContent',
      <String, String>{'key': apiKey.trim()},
    );
    final body = <String, dynamic>{
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'role': 'user',
          'parts': <Map<String, dynamic>>[
            <String, dynamic>{
              'text': _buildNovaPrompt(
                request,
                prompt,
                toolsEnabled: toolsEnabled,
              ),
            },
          ],
        },
      ],
      'generationConfig': <String, dynamic>{
        'temperature': expectedActionSummary.isNotEmpty
            ? 0.0
            : request.isFastResponsePriority
                ? 0.25
                : 0.45,
        'maxOutputTokens': expectedActionSummary.isNotEmpty
            ? 96
            : request.isFastResponsePriority
                ? 192
                : 512,
      },
      if (toolsEnabled) 'tools': <Map<String, dynamic>>[
        NovaDeviceActionCatalog.geminiTool(),
      ],
      if (toolsEnabled)
        'toolConfig': <String, dynamic>{
          'functionCallingConfig': <String, dynamic>{'mode': 'AUTO'},
        },
    };

    final response = await _postJson(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey.trim(),
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (toolsEnabled && response.statusCode == 400) {
        return _sendGemini(
          request,
          prompt,
          allowTools: false,
          extraMetadata: <String, dynamic>{
            ...extraMetadata,
            'providerToolCapabilityUnavailable': true,
          },
          expectedActionSummary: expectedActionSummary,
        );
      }
      return _httpError(request, response.statusCode, response.body, 'gemini');
    }

    final decoded = jsonDecode(response.body);
    final actionCall = toolsEnabled ? _extractGeminiAction(decoded) : null;
    if (actionCall != null) {
      final result = await actionExecutor.execute(
        call: actionCall,
        request: request,
      );
      return _sendGemini(
        request,
        _buildActionResultPrompt(result),
        allowTools: false,
        expectedActionSummary: result.spokenOutcome,
        extraMetadata: _actionMetadata(actionCall, result),
      );
    }

    final text = _extractGeminiText(decoded).trim();
    return _finalizeProviderText(
      request: request,
      text: text,
      providerKey: 'gemini',
      activeModel: activeModel,
      expectedActionSummary: expectedActionSummary,
      metadata: <String, dynamic>{
        ...request.metadata,
        ...extraMetadata,
        'route': expectedActionSummary.isNotEmpty
            ? 'api_gemini_verified_action_summary'
            : 'api_gemini_authoritative_brain',
        'httpStatus': response.statusCode,
        'responseSource': 'api',
        'aiOutputReturnedBeforeSideEffects': expectedActionSummary.isEmpty,
      },
    );
  }

  Future<AiResponse> _sendOpenAi(
    AiRequest request,
    String prompt, {
    bool allowTools = true,
    Map<String, dynamic> extraMetadata = const <String, dynamic>{},
    String expectedActionSummary = '',
  }) async {
    final activeModel = _effectiveModel(
      fallback: NovaApiModelCatalog.openAiLowCost,
    );
    final toolsEnabled = allowTools && _mayOfferDeviceTools(request);
    final uri = Uri.https('api.openai.com', '/v1/responses');
    final body = <String, dynamic>{
      'model': activeModel,
      'instructions': _buildNovaSystemInstruction(
        request,
        toolsEnabled: toolsEnabled,
      ),
      'input': prompt,
      if (toolsEnabled) 'tools': <Map<String, dynamic>>[
        NovaDeviceActionCatalog.openAiTool(),
      ],
      if (toolsEnabled) 'tool_choice': 'auto',
      if (toolsEnabled) 'parallel_tool_calls': false,
      if (expectedActionSummary.isNotEmpty) 'temperature': 0,
      'max_output_tokens': expectedActionSummary.isNotEmpty
          ? 96
          : request.isFastResponsePriority
              ? 192
              : 512,
    };

    final response = await _postJson(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${apiKey.trim()}',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (toolsEnabled && response.statusCode == 400) {
        return _sendOpenAi(
          request,
          prompt,
          allowTools: false,
          extraMetadata: <String, dynamic>{
            ...extraMetadata,
            'providerToolCapabilityUnavailable': true,
          },
          expectedActionSummary: expectedActionSummary,
        );
      }
      return _httpError(request, response.statusCode, response.body, 'openai');
    }

    final decoded = jsonDecode(response.body);
    final actionCall = toolsEnabled ? _extractOpenAiAction(decoded) : null;
    if (actionCall != null) {
      final result = await actionExecutor.execute(
        call: actionCall,
        request: request,
      );
      return _sendOpenAi(
        request,
        _buildActionResultPrompt(result),
        allowTools: false,
        expectedActionSummary: result.spokenOutcome,
        extraMetadata: _actionMetadata(actionCall, result),
      );
    }

    final text = _extractOpenAiText(decoded).trim();
    return _finalizeProviderText(
      request: request,
      text: text,
      providerKey: 'openai',
      activeModel: activeModel,
      expectedActionSummary: expectedActionSummary,
      metadata: <String, dynamic>{
        ...request.metadata,
        ...extraMetadata,
        'route': expectedActionSummary.isNotEmpty
            ? 'api_openai_verified_action_summary'
            : 'api_openai_authoritative_brain',
        'httpStatus': response.statusCode,
        'responseSource': 'api',
        'aiOutputReturnedBeforeSideEffects': expectedActionSummary.isEmpty,
      },
    );
  }

  Future<AiResponse> _sendQwen(
    AiRequest request,
    String prompt, {
    bool allowTools = true,
    Map<String, dynamic> extraMetadata = const <String, dynamic>{},
    String expectedActionSummary = '',
  }) async {
    final activeModel = _effectiveModel(
      fallback: NovaApiModelCatalog.qwenTrialFlash,
    );
    final toolsEnabled = allowTools && _mayOfferDeviceTools(request);
    final uri = Uri.https(
      'dashscope-intl.aliyuncs.com',
      '/compatible-mode/v1/chat/completions',
    );
    final body = <String, dynamic>{
      'model': activeModel,
      'messages': <Map<String, dynamic>>[
        <String, dynamic>{
          'role': 'system',
          'content': _buildNovaSystemInstruction(
            request,
            toolsEnabled: toolsEnabled,
          ),
        },
        <String, dynamic>{'role': 'user', 'content': prompt},
      ],
      'temperature': expectedActionSummary.isNotEmpty
          ? 0.0
          : request.isFastResponsePriority
              ? 0.25
              : 0.45,
      'max_tokens': expectedActionSummary.isNotEmpty
          ? 96
          : request.isFastResponsePriority
              ? 192
              : 512,
      if (toolsEnabled) 'tools': <Map<String, dynamic>>[
        NovaDeviceActionCatalog.qwenTool(),
      ],
      if (toolsEnabled) 'tool_choice': 'auto',
    };

    final response = await _postJson(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${apiKey.trim()}',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (toolsEnabled && response.statusCode == 400) {
        return _sendQwen(
          request,
          prompt,
          allowTools: false,
          extraMetadata: <String, dynamic>{
            ...extraMetadata,
            'providerToolCapabilityUnavailable': true,
          },
          expectedActionSummary: expectedActionSummary,
        );
      }
      return _httpError(request, response.statusCode, response.body, 'qwen');
    }

    final decoded = jsonDecode(response.body);
    final actionCall = toolsEnabled ? _extractQwenAction(decoded) : null;
    if (actionCall != null) {
      final result = await actionExecutor.execute(
        call: actionCall,
        request: request,
      );
      return _sendQwen(
        request,
        _buildActionResultPrompt(result),
        allowTools: false,
        expectedActionSummary: result.spokenOutcome,
        extraMetadata: _actionMetadata(actionCall, result),
      );
    }

    final text = _extractQwenText(decoded).trim();
    return _finalizeProviderText(
      request: request,
      text: text,
      providerKey: 'qwen',
      activeModel: activeModel,
      expectedActionSummary: expectedActionSummary,
      metadata: <String, dynamic>{
        ...request.metadata,
        ...extraMetadata,
        'route': expectedActionSummary.isNotEmpty
            ? 'api_qwen_verified_action_summary'
            : 'api_qwen_authoritative_brain',
        'httpStatus': response.statusCode,
        'responseSource': 'api',
        'apiHost': 'dashscope-intl.aliyuncs.com',
        'aiOutputReturnedBeforeSideEffects': expectedActionSummary.isEmpty,
      },
    );
  }

  AiResponse _finalizeProviderText({
    required AiRequest request,
    required String text,
    required String providerKey,
    required String activeModel,
    required String expectedActionSummary,
    required Map<String, dynamic> metadata,
  }) {
    if (text.trim().isEmpty) {
      return AiResponse.error(
        message: '$providerKey API boş cevap döndürdü.',
        metadata: <String, dynamic>{
          ...metadata,
          'route': '${providerKey}_empty_response',
          'provider': providerKey,
          'model': activeModel,
        },
      );
    }

    if (expectedActionSummary.isNotEmpty &&
        !_safeActionSummary(
          actual: text,
          expected: expectedActionSummary,
          actionMetadata: metadata,
        )) {
      return AiResponse.error(
        message: expectedActionSummary,
        metadata: <String, dynamic>{
          ...metadata,
          'route': '${providerKey}_unsafe_action_summary_blocked',
          'provider': providerKey,
          'model': activeModel,
          'unsafeProviderActionSummary': text,
          'tts_source': 'blocked_non_ai_speech',
        },
      );
    }

    return _apiSuccess(
      request: request,
      rawText: text,
      providerKey: providerKey,
      activeModel: activeModel,
      metadata: metadata,
    );
  }

  bool _mayOfferDeviceTools(AiRequest request) {
    if (request.metadata['disableDeviceTools'] == true) return false;
    if (request.isResearchRequest || request.isSelfLearningRequest) return false;
    final localCompanion =
        request.metadata['localCompanionAuthorityProof'] == true;
    if (localCompanion) return true;
    if (!request.userInitiated || !request.userConfirmedThisAction) return false;
    const origins = <String>{
      'user_voice',
      'user_ui',
      'dashboard_stt',
      'dashboard_text',
      'dashboard_manual_voice_entry',
      'background_authorized_voice',
    };
    return origins.contains(request.requestOrigin.trim());
  }

  Map<String, dynamic> _actionMetadata(
    NovaDeviceActionCall call,
    NovaDeviceActionResult result,
  ) => <String, dynamic>{
        'deviceActionRequested': true,
        'deviceActionCall': call.toMap(),
        'deviceActionResult': result.toMap(),
        'actionExecuted': result.success,
        'actionVerified': result.verified,
        'aiOutputReturnedBeforeSideEffects': false,
        'nativeSideEffectCompletedBeforeFinalAnswer': true,
      };

  String _buildActionResultPrompt(NovaDeviceActionResult result) {
    return <String>[
      'GERÇEK ANDROID EYLEM SONUCU:',
      jsonEncode(result.toMap()),
      '',
      'Aşağıdaki cümleyi tek başına ve anlamını değiştirmeden söyle:',
      result.spokenOutcome,
      '',
      'Başarı veya doğrulama ekleme. Cihaz sonucunda olmayan hiçbir işlemi yapılmış gibi anlatma.',
    ].join('\n');
  }

  bool _safeActionSummary({
    required String actual,
    required String expected,
    required Map<String, dynamic> actionMetadata,
  }) {
    final normalizedActual = _normalizeSummary(actual);
    final normalizedExpected = _normalizeSummary(expected);
    if (normalizedActual == normalizedExpected) return true;
    final rawResult = actionMetadata['deviceActionResult'];
    final result = rawResult is Map
        ? Map<String, dynamic>.from(rawResult)
        : const <String, dynamic>{};
    final success = result['success'] == true;
    final verified = result['verified'] == true;
    final folded = normalizedActual.toLowerCase();
    if (!success) {
      final admitsFailure = folded.contains('yapamad') ||
          folded.contains('başarısız') ||
          folded.contains('engellendi') ||
          folded.contains('olmadı') ||
          folded.contains('reddedildi');
      final falseSuccess = folded.contains('tamamlandı') ||
          folded.contains('başarıyla yaptım') ||
          folded.contains('açtım') ||
          folded.contains('kapattım');
      return admitsFailure && !falseSuccess;
    }
    if (!verified) {
      return folded.contains('doğrulanamad') ||
          folded.contains('kontrol edemed') ||
          folded.contains('sonucu kesinleşmedi');
    }
    return true;
  }

  String _normalizeSummary(String input) {
    var value = NovaFinalTextContract.normalizeLexical(input);
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      value = value.substring(1, value.length - 1).trim();
    }
    return value;
  }

  NovaDeviceActionCall? _extractGeminiAction(dynamic decoded) {
    if (decoded is! Map) return null;
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final first = candidates.first;
    if (first is! Map) return null;
    final content = first['content'];
    if (content is! Map) return null;
    final parts = content['parts'];
    if (parts is! List) return null;
    for (final part in parts) {
      if (part is! Map) continue;
      final rawCall = part['functionCall'] ?? part['function_call'];
      if (rawCall is! Map) continue;
      final name = rawCall['name']?.toString().trim() ?? '';
      if (name != NovaDeviceActionCatalog.functionName) continue;
      final args = _argumentsMap(rawCall['args'] ?? rawCall['arguments']);
      return NovaDeviceActionCall.fromArguments(args);
    }
    return null;
  }

  NovaDeviceActionCall? _extractOpenAiAction(dynamic decoded) {
    if (decoded is! Map) return null;
    final output = decoded['output'];
    if (output is! List) return null;
    for (final item in output) {
      if (item is! Map) continue;
      if (item['type']?.toString() != 'function_call') continue;
      final name = item['name']?.toString().trim() ?? '';
      if (name != NovaDeviceActionCatalog.functionName) continue;
      final args = _argumentsMap(item['arguments']);
      return NovaDeviceActionCall.fromArguments(
        args,
        providerCallId:
            item['call_id']?.toString() ?? item['id']?.toString() ?? '',
      );
    }
    return null;
  }

  NovaDeviceActionCall? _extractQwenAction(dynamic decoded) {
    if (decoded is! Map) return null;
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final first = choices.first;
    if (first is! Map) return null;
    final message = first['message'];
    if (message is! Map) return null;
    final calls = message['tool_calls'];
    if (calls is! List || calls.isEmpty) return null;
    for (final raw in calls) {
      if (raw is! Map) continue;
      final function = raw['function'];
      if (function is! Map) continue;
      final name = function['name']?.toString().trim() ?? '';
      if (name != NovaDeviceActionCatalog.functionName) continue;
      final args = _argumentsMap(function['arguments']);
      return NovaDeviceActionCall.fromArguments(
        args,
        providerCallId: raw['id']?.toString() ?? '',
      );
    }
    return null;
  }

  Map<String, dynamic> _argumentsMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return const <String, dynamic>{};
  }

  AiResponse _httpError(
    AiRequest request,
    int statusCode,
    String body,
    String providerKey,
  ) {
    final preview = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    return AiResponse.error(
      message: '$providerKey API HTTP $statusCode hatası verdi.',
      metadata: <String, dynamic>{
        ...request.metadata,
        'route': '${providerKey}_http_error',
        'provider': providerKey,
        'httpStatus': statusCode,
        'httpBodyPreview':
            preview.length > 500 ? preview.substring(0, 500) : preview,
        'tts_source': 'blocked_non_ai_speech',
      },
    );
  }

  String _effectiveModel({required String fallback}) {
    final trimmed = model.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  Future<_ApiHttpResponse> _postJson(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async {
    final httpClient = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await httpClient.postUrl(uri).timeout(timeout);
      headers.forEach(request.headers.set);
      request.write(jsonEncode(body));
      final response = await request.close().timeout(timeout);
      final responseBody = await utf8.decodeStream(response).timeout(timeout);
      return _ApiHttpResponse(
        statusCode: response.statusCode,
        body: responseBody,
      );
    } finally {
      httpClient.close(force: true);
    }
  }

  String _buildNovaPrompt(
    AiRequest request,
    String userPrompt, {
    required bool toolsEnabled,
  }) {
    return <String>[
      _buildNovaSystemInstruction(request, toolsEnabled: toolsEnabled),
      'Kullanıcı sözü:',
      userPrompt,
    ].join('\n\n');
  }

  String _buildNovaSystemInstruction(
    AiRequest request, {
    required bool toolsEnabled,
  }) {
    final speakerName =
        request.metadata['speakerName']?.toString().trim() ?? '';
    final relationship =
        request.metadata['relationshipLabel']?.toString().trim() ?? '';
    final ownerConfidence =
        request.metadata['ownerConfidence']?.toString().trim() ?? '';
    final callMode = request.metadata['callMode']?.toString().trim() ?? '';
    return <String>[
      'Sen Nova adlı telefonda çalışan ses odaklı asistansın.',
      'Yalnız kullanıcının duyacağı nihai Türkçe cevabı yaz.',
      'Debug, sistem etiketi, prompt, metadata, API/model adı, kaynak kod veya iç mimari anlatma.',
      'Kısa istenirse kısa kal; detay istenirse bağlam kadar detay ver.',
      'Özel bilgileri yalnız yetkili kullanıcı bağlamında paylaş.',
      if (toolsEnabled)
        'Kullanıcı telefonda gerçek bir işlem istiyorsa yalnız execute_phone_action aracını çağır. Araç sonucundan önce işlemi yaptığını söyleme.',
      if (toolsEnabled)
        'Telefon numarası uydurma. Yalnız kullanıcı sözünde veya güvenilir yerel bağlamda açıkça verilen değeri araca geçir.',
      if (!toolsEnabled)
        'Bu turda yeni telefon eylemi başlatma. Verilen gerçek Android sonucunu değiştirmeden bildir.',
      if (speakerName.isNotEmpty) 'Konuşan kişi: $speakerName.',
      if (relationship.isNotEmpty) 'İlişki/rol: $relationship.',
      if (ownerConfidence.isNotEmpty)
        'Sahip güven sinyali: $ownerConfidence.',
      if (callMode.isNotEmpty) 'Çağrı modu: $callMode.',
      'İstek kökeni: ${request.requestOrigin}.',
    ].join('\n');
  }

  String _extractGeminiText(dynamic decoded) {
    if (decoded is! Map) return '';
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) return '';
    final first = candidates.first;
    if (first is! Map) return '';
    final content = first['content'];
    if (content is! Map) return '';
    final parts = content['parts'];
    if (parts is! List) return '';
    final out = <String>[];
    for (final part in parts) {
      if (part is Map && part['text'] != null) {
        final value = part['text'].toString().trim();
        if (value.isNotEmpty) out.add(value);
      }
    }
    return out.join('\n').trim();
  }

  String _extractOpenAiText(dynamic decoded) {
    if (decoded is! Map) return '';
    final direct = decoded['output_text']?.toString().trim() ?? '';
    if (direct.isNotEmpty) return direct;
    final output = decoded['output'];
    final collected = <String>[];
    if (output is List) {
      for (final item in output) {
        if (item is! Map) continue;
        final content = item['content'];
        if (content is List) {
          for (final part in content) {
            if (part is Map) {
              final value = part['text'] ?? part['output_text'];
              if (value != null && value.toString().trim().isNotEmpty) {
                collected.add(value.toString().trim());
              }
            }
          }
        }
      }
    }
    return collected.join('\n').trim();
  }

  String _extractQwenText(dynamic decoded) {
    if (decoded is! Map) return '';
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) return '';
    final first = choices.first;
    if (first is! Map) return '';
    final message = first['message'];
    if (message is Map) {
      final content = message['content'];
      if (content is String) return content.trim();
      if (content is List) {
        final collected = <String>[];
        for (final part in content) {
          if (part is Map) {
            final value = part['text'] ?? part['content'];
            if (value != null && value.toString().trim().isNotEmpty) {
              collected.add(value.toString().trim());
            }
          }
        }
        return collected.join('\n').trim();
      }
    }
    return first['text']?.toString().trim() ?? '';
  }

  AiResponse _apiSuccess({
    required AiRequest request,
    required String rawText,
    required String providerKey,
    required String activeModel,
    required Map<String, dynamic> metadata,
  }) {
    final seal = NovaFinalTextContract.sealModelOutput(
      rawText: rawText,
      provider: providerKey,
      model: activeModel,
      turnId: request.metadata['turnId']?.toString(),
      providerMetadata: <String, dynamic>{
        'requestOrigin': request.requestOrigin,
      },
    );
    final clean = NovaFinalTextContract.cleanModelOutput(seal);
    return AiResponse.apiBrainSuccess(
      text: clean.cleanText,
      metadata: <String, dynamic>{
        ...metadata,
        ...seal.toMetadata(),
        ...clean.toMetadata(),
        'provider': providerKey,
        'model': activeModel,
        'responseSource': 'api_provider_raw',
      },
    );
  }
}

class _ApiHttpResponse {
  final int statusCode;
  final String body;

  const _ApiHttpResponse({
    required this.statusCode,
    required this.body,
  });
}
