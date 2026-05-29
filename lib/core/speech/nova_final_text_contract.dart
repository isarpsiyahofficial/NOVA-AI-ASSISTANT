import 'dart:convert';

import 'package:crypto/crypto.dart';

enum NovaTextOwner {
  aiModelRaw,
  aiModelClean,
  setupAiModel,
  actionResultForAiContext,
  uiOnlyStatus,
  diagnosticOnly,
  runtimeSignalOnly,
  forbiddenNonAiText,
}

class NovaTextMutation {
  final String stage;
  final String kind;
  final String beforeHash;
  final String afterHash;
  final bool lexical;

  const NovaTextMutation({
    required this.stage,
    required this.kind,
    required this.beforeHash,
    required this.afterHash,
    required this.lexical,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'stage': stage,
    'kind': kind,
    'beforeHash': beforeHash,
    'afterHash': afterHash,
    'lexical': lexical,
  };
}

class NovaModelOutputSeal {
  final String turnId;
  final String provider;
  final String model;
  final String rawText;
  final String rawTextHash;
  final DateTime receivedAt;
  final bool providerSuccess;
  final Map<String, dynamic> providerMetadata;

  const NovaModelOutputSeal({
    required this.turnId,
    required this.provider,
    required this.model,
    required this.rawText,
    required this.rawTextHash,
    required this.receivedAt,
    required this.providerSuccess,
    this.providerMetadata = const <String, dynamic>{},
  });

  Map<String, dynamic> toMetadata() => <String, dynamic>{
    'turnId': turnId,
    'provider': provider,
    'model': model,
    'rawModelTextHash': rawTextHash,
    'rawModelTextChars': rawText.length,
    'receivedAt': receivedAt.toIso8601String(),
    'providerSuccess': providerSuccess,
    'providerMetadata': providerMetadata,
  };
}

class NovaCleanModelOutput {
  final String cleanText;
  final String cleanTextHash;
  final String rawTextHash;
  final List<String> allowedCleanups;
  final List<String> controlMarkers;

  const NovaCleanModelOutput({
    required this.cleanText,
    required this.cleanTextHash,
    required this.rawTextHash,
    this.allowedCleanups = const <String>[],
    this.controlMarkers = const <String>[],
  });

  Map<String, dynamic> toMetadata() => <String, dynamic>{
    'cleanModelTextHash': cleanTextHash,
    'rawModelTextHash': rawTextHash,
    'allowedCleanups': allowedCleanups,
    'controlMarkers': controlMarkers,
    'cleanModelTextChars': cleanText.length,
  };
}

class NovaFinalTextEnvelope {
  final String text;
  final NovaTextOwner owner;
  final String turnId;
  final String sourceFile;
  final String sourceService;
  final String stage;
  final String? provider;
  final String? model;
  final String rawModelTextHash;
  final String cleanModelTextHash;
  final bool maySpeak;
  final bool lexicalMutationAfterModel;
  final List<NovaTextMutation> mutations;
  final Map<String, dynamic> metadata;

  const NovaFinalTextEnvelope({
    required this.text,
    required this.owner,
    required this.turnId,
    required this.sourceFile,
    required this.sourceService,
    required this.stage,
    this.provider,
    this.model,
    required this.rawModelTextHash,
    required this.cleanModelTextHash,
    required this.maySpeak,
    required this.lexicalMutationAfterModel,
    this.mutations = const <NovaTextMutation>[],
    this.metadata = const <String, dynamic>{},
  });

  bool get isSpeakableOwner =>
      NovaFinalTextContract.speakableOwners.contains(owner);

  bool get mayEnterTts =>
      maySpeak &&
      isSpeakableOwner &&
      text.trim().isNotEmpty &&
      !lexicalMutationAfterModel &&
      NovaFinalTextContract.hashText(text) == cleanModelTextHash;

  Map<String, dynamic> toMetadata() => <String, dynamic>{
    'novaFinalTextOwner': owner.name,
    'novaMaySpeak': maySpeak,
    'novaMayEnterTts': mayEnterTts,
    'turnId': turnId,
    'sourceFile': sourceFile,
    'sourceService': sourceService,
    'stage': stage,
    'provider': provider,
    'model': model,
    'rawModelTextHash': rawModelTextHash,
    'cleanModelTextHash': cleanModelTextHash,
    'finalSpokenTextHash': NovaFinalTextContract.hashText(text),
    'lexicalMutationAfterModel': lexicalMutationAfterModel,
    'mutations': mutations.map((e) => e.toMap()).toList(growable: false),
    ...metadata,
  };
}

class NovaRouteTrace {
  final String turnId;
  final String inputSource;
  final String acceptedTranscript;
  final String selectedRoute;
  final bool dashboardPath;
  final bool setupPath;
  final bool hotpathOwner;
  final bool runtimeOrchestrator;
  final bool directAi;
  final bool systemSpeechRewrite;
  final String ttsSource;
  final NovaTextOwner finalTextOwner;
  final String apiRawResponseHash;
  final String cleanResponseHash;
  final String finalSpokenHash;
  final bool actionExecuted;
  final bool memoryWritten;
  final bool staticSpokenAttemptBlocked;
  final String finalTextSourceFile;

  const NovaRouteTrace({
    required this.turnId,
    required this.inputSource,
    required this.acceptedTranscript,
    required this.selectedRoute,
    required this.dashboardPath,
    required this.setupPath,
    required this.hotpathOwner,
    required this.runtimeOrchestrator,
    required this.directAi,
    required this.systemSpeechRewrite,
    required this.ttsSource,
    required this.finalTextOwner,
    required this.apiRawResponseHash,
    required this.cleanResponseHash,
    required this.finalSpokenHash,
    required this.actionExecuted,
    required this.memoryWritten,
    required this.staticSpokenAttemptBlocked,
    required this.finalTextSourceFile,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'turnId': turnId,
    'inputSource': inputSource,
    'acceptedTranscript': acceptedTranscript,
    'selectedRoute': selectedRoute,
    'dashboardPath': dashboardPath,
    'setupPath': setupPath,
    'hotpathOwner': hotpathOwner,
    'runtimeOrchestrator': runtimeOrchestrator,
    'directAi': directAi,
    'systemSpeechRewrite': systemSpeechRewrite,
    'ttsSource': ttsSource,
    'finalTextOwner': finalTextOwner.name,
    'apiRawResponseHash': apiRawResponseHash,
    'cleanResponseHash': cleanResponseHash,
    'finalSpokenHash': finalSpokenHash,
    'actionExecuted': actionExecuted,
    'memoryWritten': memoryWritten,
    'staticSpokenAttemptBlocked': staticSpokenAttemptBlocked,
    'finalTextSourceFile': finalTextSourceFile,
  };
}

class NovaFinalTextContract {
  const NovaFinalTextContract();

  static const Set<NovaTextOwner> speakableOwners = <NovaTextOwner>{
    NovaTextOwner.aiModelRaw,
    NovaTextOwner.aiModelClean,
    NovaTextOwner.setupAiModel,
  };

  static String createTurnId({String prefix = 'nova_turn'}) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

  static String hashText(String input) {
    final normalized = normalizeLexical(input);
    return sha256.convert(utf8.encode(normalized)).toString();
  }

  static String normalizeLexical(String input) =>
      input.replaceAll(RegExp(r'\s+'), ' ').trim();

  static NovaModelOutputSeal sealModelOutput({
    required String rawText,
    required String provider,
    required String model,
    String? turnId,
    bool providerSuccess = true,
    Map<String, dynamic> providerMetadata = const <String, dynamic>{},
  }) {
    final cleanTurnId = turnId?.trim();
    return NovaModelOutputSeal(
      turnId: cleanTurnId != null && cleanTurnId.isNotEmpty
          ? cleanTurnId
          : createTurnId(),
      provider: provider,
      model: model,
      rawText: rawText,
      rawTextHash: hashText(rawText),
      receivedAt: DateTime.now(),
      providerSuccess: providerSuccess,
      providerMetadata: providerMetadata,
    );
  }

  static NovaCleanModelOutput cleanModelOutput(NovaModelOutputSeal seal) {
    var clean = seal.rawText;
    final cleanups = <String>[];

    final trimmed = clean.trim();
    if (trimmed != clean) {
      clean = trimmed;
      cleanups.add('trim');
    }

    final controlMarkerMatches = RegExp(
      r'\[(?:NOVA_ACTION_(?:ALLOWED|DENIED)|CALL_ACTION_[A-Z_]+|CALL_[A-Z_]+)\]',
      caseSensitive: false,
    ).allMatches(clean);
    final controlMarkers = controlMarkerMatches
        .map((m) => (m.group(0) ?? '').toUpperCase())
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final markerCleaned = clean.replaceAll(
      RegExp(
        r'\[(?:NOVA_ACTION_(?:ALLOWED|DENIED)|CALL_ACTION_[A-Z_]+|CALL_[A-Z_]+)\]',
        caseSensitive: false,
      ),
      '',
    );
    if (markerCleaned != clean) {
      clean = markerCleaned;
      cleanups.add('control_marker_removal');
    }

    final invisibleCleaned = clean.replaceAll(
      RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]'),
      '',
    );
    if (invisibleCleaned != clean) {
      clean = invisibleCleaned;
      cleanups.add('unsafe_invisible_character_removal');
    }

    final identityCleaned = clean
        .replaceAll(RegExp(r'\bNOVA\b', caseSensitive: false), 'Nova')
        .replaceAll(RegExp(r'\b[Jj]arvis\b'), 'Nova')
        .replaceAll(RegExp(r'\bJAR[Vv][Ii][Ss]\b'), 'Nova');
    if (identityCleaned != clean) {
      clean = identityCleaned;
      cleanups.add('assistant_identity_label_normalization');
    }

    final whitespaceCleaned = clean.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (whitespaceCleaned != clean) {
      clean = whitespaceCleaned;
      cleanups.add('excessive_whitespace_removal');
    }

    return NovaCleanModelOutput(
      cleanText: clean,
      cleanTextHash: hashText(clean),
      rawTextHash: seal.rawTextHash,
      allowedCleanups: List<String>.unmodifiable(cleanups),
      controlMarkers: List<String>.unmodifiable(controlMarkers),
    );
  }

  static NovaFinalTextEnvelope aiEnvelope({
    required String text,
    required NovaTextOwner owner,
    required String turnId,
    required String sourceFile,
    required String sourceService,
    required String stage,
    String? provider,
    String? model,
    required String rawModelTextHash,
    required String cleanModelTextHash,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final finalHash = hashText(text);
    final lexicalMutation =
        cleanModelTextHash.trim().isNotEmpty && finalHash != cleanModelTextHash;
    return NovaFinalTextEnvelope(
      text: text,
      owner: owner,
      turnId: turnId,
      sourceFile: sourceFile,
      sourceService: sourceService,
      stage: stage,
      provider: provider,
      model: model,
      rawModelTextHash: rawModelTextHash,
      cleanModelTextHash: cleanModelTextHash,
      maySpeak: speakableOwners.contains(owner) && !lexicalMutation,
      lexicalMutationAfterModel: lexicalMutation,
      metadata: metadata,
    );
  }

  static bool maySpeakMetadata(Map<String, dynamic> metadata) {
    final ownerName = metadata['novaFinalTextOwner']?.toString().trim() ?? '';
    NovaTextOwner? owner;
    for (final value in NovaTextOwner.values) {
      if (value.name == ownerName) {
        owner = value;
        break;
      }
    }
    if (owner == null || !speakableOwners.contains(owner)) return false;
    if (metadata['novaMaySpeak'] != true) return false;
    if (metadata['lexicalMutationAfterModel'] == true) return false;
    final cleanHash = metadata['cleanModelTextHash']?.toString().trim() ?? '';
    final finalHash = metadata['finalSpokenTextHash']?.toString().trim() ?? '';
    return cleanHash.isNotEmpty &&
        finalHash.isNotEmpty &&
        cleanHash == finalHash;
  }

  static NovaTextOwner ownerFromMetadata(Map<String, dynamic> metadata) {
    final ownerName = metadata['novaFinalTextOwner']?.toString().trim() ?? '';
    return NovaTextOwner.values.firstWhere(
      (value) => value.name == ownerName,
      orElse: () => NovaTextOwner.forbiddenNonAiText,
    );
  }
}
