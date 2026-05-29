// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals_to_create_immutables
// NOVA_API_PROVIDER_ROUTER_V1
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../core/ai/ai_request.dart';
import '../../core/ai/ai_response.dart';
import '../../core/api/nova_ai_provider_type.dart';
import '../../core/api/nova_api_model_catalog.dart';
import '../../core/runtime/response_cleaner.dart';
import '../../core/speech/nova_final_text_contract.dart';
import '../settings/nova_settings_service.dart';

class ApiService {
  final bool isApiConfigured;
  final bool hasAvailableBalance;
  final NovaAiProviderType provider;
  final String apiKey;
  final String model;
  final Duration timeout;

  const ApiService({
    this.isApiConfigured = false,
    this.hasAvailableBalance = false,
    this.provider = NovaAiProviderType.gemini,
    this.apiKey = '',
    this.model = '',
    this.timeout = const Duration(seconds: 45),
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

  Future<AiResponse> _sendGemini(AiRequest request, String prompt) async {
    final activeModel = _effectiveModel(
      fallback: NovaApiModelCatalog.geminiFreeTierStable,
    );
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
            <String, dynamic>{'text': _buildNovaPrompt(request, prompt)},
          ],
        },
      ],
      'generationConfig': <String, dynamic>{
        'temperature': request.isFastResponsePriority ? 0.35 : 0.55,
        'maxOutputTokens': request.isFastResponsePriority ? 192 : 512,
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
      return _httpError(request, response.statusCode, response.body, 'gemini');
    }

    final decoded = jsonDecode(response.body);
    final text = _extractGeminiText(decoded).trim();
    if (text.isEmpty) {
      return AiResponse.error(
        message: 'Gemini API boş cevap döndürdü.',
        metadata: <String, dynamic>{
          ...request.metadata,
          'route': 'gemini_empty_response',
          'provider': 'gemini',
          'model': activeModel,
        },
      );
    }

    return _apiSuccess(
      request: request,
      rawText: text,
      providerKey: 'gemini',
      activeModel: activeModel,
      metadata: <String, dynamic>{
        ...request.metadata,
        'route': 'api_gemini_authoritative_brain',
        'httpStatus': response.statusCode,
        'responseSource': 'api',
      },
    );
  }

  Future<AiResponse> _sendOpenAi(AiRequest request, String prompt) async {
    final activeModel = _effectiveModel(
      fallback: NovaApiModelCatalog.openAiLowCost,
    );
    final uri = Uri.https('api.openai.com', '/v1/responses');
    final body = <String, dynamic>{
      'model': activeModel,
      'instructions': _buildNovaSystemInstruction(request),
      'input': prompt,
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
      return _httpError(request, response.statusCode, response.body, 'openai');
    }

    final decoded = jsonDecode(response.body);
    final text = _extractOpenAiText(decoded).trim();
    if (text.isEmpty) {
      return AiResponse.error(
        message: 'OpenAI API boş cevap döndürdü.',
        metadata: <String, dynamic>{
          ...request.metadata,
          'route': 'openai_empty_response',
          'provider': 'openai',
          'model': activeModel,
        },
      );
    }

    return _apiSuccess(
      request: request,
      rawText: text,
      providerKey: 'openai',
      activeModel: activeModel,
      metadata: <String, dynamic>{
        ...request.metadata,
        'route': 'api_openai_authoritative_brain',
        'httpStatus': response.statusCode,
        'responseSource': 'api',
      },
    );
  }

  Future<AiResponse> _sendQwen(AiRequest request, String prompt) async {
    final activeModel = _effectiveModel(
      fallback: NovaApiModelCatalog.qwenTrialFlash,
    );
    final uri = Uri.https(
      'dashscope-intl.aliyuncs.com',
      '/compatible-mode/v1/chat/completions',
    );
    final body = <String, dynamic>{
      'model': activeModel,
      'messages': <Map<String, dynamic>>[
        <String, dynamic>{
          'role': 'system',
          'content': _buildNovaSystemInstruction(request),
        },
        <String, dynamic>{'role': 'user', 'content': prompt},
      ],
      'temperature': request.isFastResponsePriority ? 0.35 : 0.55,
      'max_tokens': request.isFastResponsePriority ? 192 : 512,
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
      return _httpError(request, response.statusCode, response.body, 'qwen');
    }

    final decoded = jsonDecode(response.body);
    final text = _extractQwenText(decoded).trim();
    if (text.isEmpty) {
      return AiResponse.error(
        message: 'Qwen API boş cevap döndürdü.',
        metadata: <String, dynamic>{
          ...request.metadata,
          'route': 'qwen_empty_response',
          'provider': 'qwen',
          'model': activeModel,
        },
      );
    }

    return _apiSuccess(
      request: request,
      rawText: text,
      providerKey: 'qwen',
      activeModel: activeModel,
      metadata: <String, dynamic>{
        ...request.metadata,
        'route': 'api_qwen_authoritative_brain',
        'httpStatus': response.statusCode,
        'responseSource': 'api',
        'apiHost': 'dashscope-intl.aliyuncs.com',
      },
    );
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
        'httpBodyPreview': preview.length > 500
            ? preview.substring(0, 500)
            : preview,
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
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });
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

  String _buildNovaPrompt(AiRequest request, String userPrompt) {
    return <String>[
      _buildNovaSystemInstruction(request),
      'Kullanıcı sözü:',
      userPrompt,
    ].join('\n\n');
  }

  String _buildNovaSystemInstruction(AiRequest request) {
    final speakerName =
        request.metadata['speakerName']?.toString().trim() ?? '';
    final relationship =
        request.metadata['relationshipLabel']?.toString().trim() ?? '';
    final ownerConfidence =
        request.metadata['ownerConfidence']?.toString().trim() ?? '';
    final callMode = request.metadata['callMode']?.toString().trim() ?? '';
    return <String>[
      'Sen Nova adli telefonda calisan ses odakli asistansin.',
      'Yalniz kullanicinin duyacagi nihai Turkce cevabi yaz.',
      'Debug, sistem etiketi, prompt, metadata, API/model adi, kaynak kod veya ic mimari anlatma.',
      'Kisa istenirse kisa kal; detay istenirse baglam kadar detay ver.',
      'Ozel bilgileri yalniz yetkili kullanici baglaminda paylas.',
      if (speakerName.isNotEmpty) 'Konusan kisi: $speakerName.',
      if (relationship.isNotEmpty) 'Iliski/rol: $relationship.',
      if (ownerConfidence.isNotEmpty) 'Sahip guven sinyali: $ownerConfidence.',
      if (callMode.isNotEmpty) 'Cagri modu: $callMode.',
      'Istek kokeni: ${request.requestOrigin}.',
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
    final direct = first['text']?.toString().trim() ?? '';
    return direct;
  }

  String _cleanApiText(String input) =>
      const NovaResponseCleaner().cleanForSpeech(input);

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

  const _ApiHttpResponse({required this.statusCode, required this.body});
}
