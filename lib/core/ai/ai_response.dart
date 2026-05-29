// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals_to_create_immutables
// NOVA_API_AUTHORITY_PROOF_V1
import '../speech/nova_final_text_contract.dart';

class AiResponse {
  final String text;
  final String quickReply;
  final bool fromLocalModel;
  final bool fromApi;
  final bool isError;
  final String? errorMessage;
  final Map<String, dynamic> metadata;

  const AiResponse({
    required this.text,
    this.quickReply = '',
    this.fromLocalModel = false,
    this.fromApi = false,
    this.isError = false,
    this.errorMessage,
    this.metadata = const <String, dynamic>{},
  });

  factory AiResponse.success({
    required String text,
    String quickReply = '',
    bool fromLocalModel = false,
    bool fromApi = false,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) => AiResponse(
    text: text,
    quickReply: quickReply,
    fromLocalModel: fromLocalModel,
    fromApi: fromApi,
    metadata: metadata,
  );

  factory AiResponse.nativeProofSuccess({
    required String text,
    String quickReply = '',
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) => AiResponse(
    text: text,
    quickReply: quickReply,
    fromLocalModel: true,
    fromApi: false,
    metadata: nativeProofMetadata(metadata, text: text),
  );

  factory AiResponse.apiBrainSuccess({
    required String text,
    String quickReply = '',
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) => AiResponse(
    text: text,
    quickReply: quickReply,
    fromLocalModel: false,
    fromApi: true,
    metadata: apiBrainProofMetadata(metadata, text: text),
  );

  factory AiResponse.error({
    required String message,
    String quickReply = '',
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) => AiResponse(
    text: '',
    quickReply: quickReply,
    isError: true,
    errorMessage: message,
    metadata: metadata,
  );

  String get displayText =>
      isError ? (errorMessage ?? 'Bilinmeyen bir hata oluştu.') : text;

  static bool safeBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  static bool hasNativeLocalProofInMetadata(Map<String, dynamic> meta) {
    return safeBool(meta['nativeSuccess']) &&
        safeBool(meta['acceptedNativeText']) &&
        safeBool(meta['rawNativeLocalModel']) &&
        safeBool(meta['authoritativeLocalBrain']) &&
        safeBool(meta['localModelAuthorityProof']);
  }

  static bool hasApiBrainProofInMetadata(Map<String, dynamic> meta) {
    return safeBool(meta['apiSuccess']) &&
        safeBool(meta['acceptedApiText']) &&
        safeBool(meta['rawApiProvider']) &&
        safeBool(meta['authoritativeApiBrain']) &&
        safeBool(meta['apiBrainAuthorityProof']) &&
        hasModelOutputSealInMetadata(meta);
  }

  static bool hasModelOutputSealInMetadata(Map<String, dynamic> meta) {
    final rawHash = meta['rawModelTextHash']?.toString().trim() ?? '';
    final cleanHash = meta['cleanModelTextHash']?.toString().trim() ?? '';
    final receivedAt = meta['receivedAt']?.toString().trim() ?? '';
    final provider = meta['provider']?.toString().trim() ?? '';
    final model = meta['model']?.toString().trim() ?? '';
    return rawHash.isNotEmpty &&
        cleanHash.isNotEmpty &&
        receivedAt.isNotEmpty &&
        provider.isNotEmpty &&
        model.isNotEmpty;
  }

  static Map<String, dynamic> forbiddenNonAiMetadata(
    Map<String, dynamic> source, {
    required String text,
    required String reason,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) {
    final normalized = normalizeAuthorityText(text);
    final hash = authorityTextHash(normalized);
    return <String, dynamic>{
      ...source,
      ...extra,
      'novaFinalTextOwner': NovaTextOwner.forbiddenNonAiText.name,
      'novaMaySpeak': false,
      'novaMayEnterTts': false,
      'lexicalMutationAfterModel': true,
      'finalSpokenTextHash': hash,
      'cleanModelTextHash': '',
      'rawModelTextHash': '',
      'proofRejected': true,
      'proofRejectReason': reason,
      'tts_source': 'blocked_non_ai_speech',
    };
  }

  bool get hasNativeLocalProof =>
      !isError && fromLocalModel && hasNativeLocalProofInMetadata(metadata);

  bool get hasApiBrainProof =>
      !isError && fromApi && hasApiBrainProofInMetadata(metadata);

  bool get hasAuthoritativeBrainProof =>
      hasNativeLocalProof || hasApiBrainProof;

  static Map<String, dynamic> nativeProofMetadata(
    Map<String, dynamic> source, {
    String? text,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) {
    final merged = <String, dynamic>{...source, ...extra};
    final normalizedText = text ?? source['authorityText']?.toString() ?? '';
    if (!hasModelOutputSealInMetadata(merged)) {
      return forbiddenNonAiMetadata(
        merged,
        text: normalizedText,
        reason: 'missing_model_output_seal_for_native_proof',
      );
    }
    final out = _withFinalTextContract(
      merged,
      text: normalizedText,
      owner: NovaTextOwner.aiModelClean,
      sourceService: 'AiResponse.nativeProofMetadata',
      stage: 'native_model_clean',
      provider: source['provider']?.toString() ?? 'local',
      model: source['model']?.toString(),
    );
    if (safeBool(out['proofRejected'])) {
      return out;
    }
    out['nativeSuccess'] = true;
    out['acceptedNativeText'] = true;
    out['rawNativeLocalModel'] = true;
    out['authoritativeLocalBrain'] = true;
    out['localModelAuthorityProof'] = true;
    out['authorityProofVersion'] =
        out['authorityProofVersion']?.toString().trim().isNotEmpty == true
        ? out['authorityProofVersion']
        : 'v34_text_bound_native_proof';
    out['tts_source'] = 'brain_decision_ai_output';
    final normalizedAuthorityText = normalizeAuthorityText(
      text ?? out['authorityText']?.toString() ?? '',
    );
    if (normalizedAuthorityText.isNotEmpty) {
      out['authorityText'] = normalizedAuthorityText;
      out['authorityTextHash'] = authorityTextHash(normalizedAuthorityText);
      out['authorityTextChars'] = normalizedAuthorityText.length;
    }
    return out;
  }

  static Map<String, dynamic> apiBrainProofMetadata(
    Map<String, dynamic> source, {
    String? text,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) {
    final merged = <String, dynamic>{...source, ...extra};
    final normalizedText = text ?? source['authorityText']?.toString() ?? '';
    if (!hasModelOutputSealInMetadata(merged)) {
      return forbiddenNonAiMetadata(
        merged,
        text: normalizedText,
        reason: 'missing_model_output_seal_for_api_proof',
      );
    }
    final out = _withFinalTextContract(
      merged,
      text: normalizedText,
      owner: NovaTextOwner.aiModelClean,
      sourceService: 'AiResponse.apiBrainProofMetadata',
      stage: 'api_model_clean',
      provider: source['provider']?.toString() ?? source['route']?.toString(),
      model: source['model']?.toString() ?? source['modelUsed']?.toString(),
    );
    if (safeBool(out['proofRejected'])) {
      return out;
    }
    out['apiSuccess'] = true;
    out['acceptedApiText'] = true;
    out['rawApiProvider'] = true;
    out['authoritativeApiBrain'] = true;
    out['apiBrainAuthorityProof'] = true;
    out['singleBrainAuthority'] = true;
    out['singleBrainAllowed'] = true;
    out['modelUsed'] = true;
    out['authorityProofVersion'] =
        out['authorityProofVersion']?.toString().trim().isNotEmpty == true
        ? out['authorityProofVersion']
        : 'api_text_bound_authority_proof_v2_strict_model_seal';
    out['tts_source'] = 'brain_decision_ai_output';
    final normalizedAuthorityText = normalizeAuthorityText(
      text ?? out['authorityText']?.toString() ?? '',
    );
    if (normalizedAuthorityText.isNotEmpty) {
      out['authorityText'] = normalizedAuthorityText;
      out['authorityTextHash'] = authorityTextHash(normalizedAuthorityText);
      out['authorityTextChars'] = normalizedAuthorityText.length;
    }
    return out;
  }

  static String normalizeAuthorityText(String input) =>
      NovaFinalTextContract.normalizeLexical(input);

  static String authorityTextHash(String input) =>
      NovaFinalTextContract.hashText(input);

  static bool authorityTextMatches(String spokenText, AiResponse? response) {
    if (response == null || response.isError) return false;
    final normalizedSpoken = normalizeAuthorityText(spokenText);
    final normalizedResponse = normalizeAuthorityText(response.displayText);
    if (normalizedSpoken.isEmpty || normalizedResponse.isEmpty) return false;
    if (normalizedSpoken == normalizedResponse) return true;
    final expectedHash =
        response.metadata['authorityTextHash']?.toString().trim() ?? '';
    if (expectedHash.isEmpty) return false;
    return expectedHash == authorityTextHash(normalizedSpoken);
  }

  AiResponse withNativeProofText(
    String newText, {
    String? quickReplyOverride,
    Map<String, dynamic> extraMetadata = const <String, dynamic>{},
  }) {
    return AiResponse.nativeProofSuccess(
      text: newText,
      quickReply: quickReplyOverride ?? quickReply,
      metadata: nativeProofMetadata(
        metadata,
        text: newText,
        extra: extraMetadata,
      ),
    );
  }

  AiResponse withAuthoritativeBrainProofText(
    String newText, {
    String? quickReplyOverride,
    Map<String, dynamic> extraMetadata = const <String, dynamic>{},
  }) {
    if (hasNativeLocalProof && !hasApiBrainProof) {
      return withNativeProofText(
        newText,
        quickReplyOverride: quickReplyOverride,
        extraMetadata: extraMetadata,
      );
    }
    return withApiBrainProofText(
      newText,
      quickReplyOverride: quickReplyOverride,
      extraMetadata: extraMetadata,
    );
  }

  AiResponse withApiBrainProofText(
    String newText, {
    String? quickReplyOverride,
    Map<String, dynamic> extraMetadata = const <String, dynamic>{},
  }) {
    return AiResponse.apiBrainSuccess(
      text: newText,
      quickReply: quickReplyOverride ?? quickReply,
      metadata: apiBrainProofMetadata(
        metadata,
        text: newText,
        extra: extraMetadata,
      ),
    );
  }

  static Map<String, dynamic> _withFinalTextContract(
    Map<String, dynamic> source, {
    required String text,
    required NovaTextOwner owner,
    required String sourceService,
    required String stage,
    String? provider,
    String? model,
  }) {
    final normalized = NovaFinalTextContract.normalizeLexical(text);
    if (normalized.isEmpty) return source;
    final turnId = source['turnId']?.toString().trim().isNotEmpty == true
        ? source['turnId'].toString().trim()
        : NovaFinalTextContract.createTurnId();
    final hash = NovaFinalTextContract.hashText(normalized);
    final rawHash =
        source['rawModelTextHash']?.toString().trim().isNotEmpty == true
        ? source['rawModelTextHash'].toString().trim()
        : '';
    final cleanHash =
        source['cleanModelTextHash']?.toString().trim().isNotEmpty == true
        ? source['cleanModelTextHash'].toString().trim()
        : '';
    final receivedAt = source['receivedAt']?.toString().trim() ?? '';
    final sealedProvider = source['provider']?.toString().trim() ?? '';
    final sealedModel = source['model']?.toString().trim() ?? '';
    if (rawHash.isEmpty ||
        cleanHash.isEmpty ||
        receivedAt.isEmpty ||
        sealedProvider.isEmpty ||
        sealedModel.isEmpty) {
      return forbiddenNonAiMetadata(
        source,
        text: normalized,
        reason: 'final_text_contract_missing_model_output_seal',
      );
    }
    if (hash != cleanHash) {
      return forbiddenNonAiMetadata(
        source,
        text: normalized,
        reason: 'lexical_mutation_after_model_output',
        extra: <String, dynamic>{
          'attemptedFinalSpokenTextHash': hash,
          'expectedCleanModelTextHash': cleanHash,
        },
      );
    }
    final envelope = NovaFinalTextContract.aiEnvelope(
      text: normalized,
      owner: owner,
      turnId: turnId,
      sourceFile: 'lib/core/ai/ai_response.dart',
      sourceService: sourceService,
      stage: stage,
      provider: provider,
      model: model,
      rawModelTextHash: rawHash,
      cleanModelTextHash: cleanHash,
      metadata: <String, dynamic>{'tts_source': 'brain_decision_ai_output'},
    );
    return <String, dynamic>{...source, ...envelope.toMetadata()};
  }
}
