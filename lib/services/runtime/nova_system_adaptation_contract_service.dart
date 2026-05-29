// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../cognition/nova_emotion_engine_service.dart';
import 'nova_call_acoustic_emotion_layer_service.dart';
import 'nova_identity_runtime_service.dart';
import 'nova_literal_sweep_service.dart';

class NovaSystemAdaptationContractService {
  final NovaEmotionEngineService emotionEngineService;
  final NovaCallAcousticEmotionLayerService callAcousticEmotionLayerService;
  final NovaIdentityRuntimeService identityRuntimeService;
  final NovaLiteralSweepService literalSweepService;

  const NovaSystemAdaptationContractService({
    this.emotionEngineService = const NovaEmotionEngineService(),
    this.callAcousticEmotionLayerService =
        const NovaCallAcousticEmotionLayerService(),
    this.identityRuntimeService = const NovaIdentityRuntimeService(),
    this.literalSweepService = const NovaLiteralSweepService(),
  });

  Future<Map<String, dynamic>> buildMetadata({
    required String prompt,
    required String sourceSystem,
    Map<String, dynamic> baseMetadata = const <String, dynamic>{},
    String requestOrigin = '',
    String speakerName = '',
    String relationshipLabel = '',
    String speakerVoiceId = '',
    double? ownerConfidence,
    String callerName = '',
    String callerNumber = '',
    bool companionMode = false,
    bool mediaMode = false,
    bool callMode = false,
  }) async {
    await identityRuntimeService.ensureLoaded();
    await identityRuntimeService.maybeApplyRenameInstruction(prompt);
    final safeBase = literalSweepService.sweepMetadataSync(<String, dynamic>{
      ...baseMetadata,
    });
    final emotion = await emotionEngineService.analyze(prompt.trim());
    final acoustic = callAcousticEmotionLayerService.analyze(
      transcript: prompt.trim(),
      sourceSystem: sourceSystem,
      context: safeBase,
    );
    final resolvedSpeakerName = _pick(
      safeBase['speakerName'],
      speakerName,
      callerName,
    );
    final resolvedRelationship = _pick(
      safeBase['relationshipLabel'],
      relationshipLabel,
      companionMode ? 'çağrı kişisi' : '',
    );
    final resolvedVoiceId = _pick(
      safeBase['speakerVoiceId'],
      speakerVoiceId,
      callMode && callerNumber.trim().isNotEmpty
          ? 'call:${callerNumber.trim()}'
          : '',
    );
    final resolvedOwnerConfidence = _resolveOwnerConfidence(
      safeBase['ownerConfidence'],
      ownerConfidence,
      resolvedRelationship,
      companionMode,
    );

    return literalSweepService.sweepMetadataSync(<String, dynamic>{
      ...safeBase,
      ...acoustic,
      'adaptiveContractVersion': '2026-04-19',
      'socialCommandMode': 'conversation_first',
      'dynamicEntityMode': 'enabled',
      'futureSystemAutoAdaptReady': true,
      'identityContinuityEnabled': true,
      'relationshipMemoryEnabled': true,
      'safeAutoAdaptEligible': true,
      'sourceSystem': sourceSystem.trim().isEmpty
          ? 'unknown'
          : sourceSystem.trim(),
      'assistantDisplayName': identityRuntimeService.currentDisplayName,
      'assistantAliases': identityRuntimeService.knownAliases,
      'assistantRenameAutoPropagation': true,
      'requestOrigin': _pick(safeBase['requestOrigin'], requestOrigin),
      'speakerName': resolvedSpeakerName,
      'relationshipLabel': resolvedRelationship,
      'speakerVoiceId': resolvedVoiceId,
      'ownerConfidence': resolvedOwnerConfidence,
      'emotionHint': emotion.dominantEmotion,
      'emotionIntensity': emotion.intensity,
      'emotionUrgency': emotion.urgency,
      'emotionEmpathyNeed': emotion.empathyNeed,
      'emotionStability': emotion.stability,
      'emotionTrustComfort': emotion.trustComfort,
      'emotionSignals': emotion.signals,
      'toneDirective': _toneDirective(
        dominantEmotion: emotion.dominantEmotion,
        urgency: emotion.urgency,
        empathyNeed: emotion.empathyNeed,
        companionMode: companionMode,
        mediaMode: mediaMode,
      ),
      'callMode': callMode || companionMode,
      'companionMode': companionMode || (safeBase['companionMode'] == true),
      'mediaMode': mediaMode || (safeBase['mediaMode'] == true),
      'runtimeContractRequired': true,
      'mediaRuntimeContractRequired':
          mediaMode || (safeBase['mediaMode'] == true),
      'callRuntimeContractRequired': callMode || companionMode,
      'futureSystemMustUseContract': true,
      'callerName': _pick(safeBase['callerName'], callerName),
      'callerNumber': _pick(safeBase['callerNumber'], callerNumber),
      'callAcousticConfidenceBand': acoustic['callAcousticConfidenceBand'],
    });
  }

  String _pick(Object? first, [String second = '', String third = '']) {
    final candidates = <Object?>[first, second, third];
    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  double _resolveOwnerConfidence(
    Object? current,
    double? fallback,
    String relationshipLabel,
    bool companionMode,
  ) {
    final currentNumber = _asDouble(current);
    if (currentNumber != null) return currentNumber.clamp(0.0, 1.0);
    if (fallback != null) return fallback.clamp(0.0, 1.0);
    final normalizedRelationship = relationshipLabel.trim().toLowerCase();
    if (normalizedRelationship.contains('cihaz sahibi') ||
        normalizedRelationship.contains('owner')) {
      return 0.98;
    }
    if (normalizedRelationship.contains('yetki') ||
        normalizedRelationship.contains('tanıştır')) {
      return 0.82;
    }
    if (companionMode) return 0.56;
    return 0.40;
  }

  double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  String _toneDirective({
    required String dominantEmotion,
    required double urgency,
    required double empathyNeed,
    required bool companionMode,
    required bool mediaMode,
  }) {
    final emotion = dominantEmotion.trim().toLowerCase();
    if (mediaMode) return 'hızlı, kısa, komut dostu';
    if (companionMode && urgency >= 0.62) return 'kısa, güven veren, ciddi';
    if (emotion.contains('üz') ||
        emotion.contains('kayg') ||
        empathyNeed >= 0.55) {
      return companionMode
          ? 'şefkatli, güven veren, sakin'
          : 'sakin, destekleyici, özenli';
    }
    if (urgency >= 0.60) return 'net, hızlı, sakin';
    if (emotion.contains('öf') || emotion.contains('gerg'))
      return 'sakinleştirici, net, kontrollü';
    return companionMode
        ? 'doğal, sıcak, insan gibi'
        : 'doğal, konuşma odaklı, dinamik';
  }
}
