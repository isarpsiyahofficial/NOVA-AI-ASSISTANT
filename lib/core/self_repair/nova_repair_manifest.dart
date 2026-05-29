// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// GEMMA95952_SAFE_SELF_REPAIR_KERNEL

enum NovaRepairRiskLevel { green, yellow, red }

extension NovaRepairRiskLevelX on NovaRepairRiskLevel {
  String get key {
    switch (this) {
      case NovaRepairRiskLevel.green:
        return 'green';
      case NovaRepairRiskLevel.yellow:
        return 'yellow';
      case NovaRepairRiskLevel.red:
        return 'red';
    }
  }

  static NovaRepairRiskLevel fromKey(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    for (final item in NovaRepairRiskLevel.values) {
      if (item.key == value) return item;
    }
    return NovaRepairRiskLevel.red;
  }
}

enum NovaRepairFaultType {
  modelNotReady,
  nativeChannelFail,
  asrNoTranscript,
  transcriptNotRouted,
  ttsWrongSource,
  ttsNotSpeaking,
  fallbackContamination,
  queueStaleTurn,
  securityFalsePositive,
  realSecurityRisk,
  unknown,
}

extension NovaRepairFaultTypeX on NovaRepairFaultType {
  String get key {
    switch (this) {
      case NovaRepairFaultType.modelNotReady:
        return 'MODEL_NOT_READY';
      case NovaRepairFaultType.nativeChannelFail:
        return 'NATIVE_CHANNEL_FAIL';
      case NovaRepairFaultType.asrNoTranscript:
        return 'ASR_NO_TRANSCRIPT';
      case NovaRepairFaultType.transcriptNotRouted:
        return 'TRANSCRIPT_NOT_ROUTED';
      case NovaRepairFaultType.ttsWrongSource:
        return 'TTS_WRONG_SOURCE';
      case NovaRepairFaultType.ttsNotSpeaking:
        return 'TTS_NOT_SPEAKING';
      case NovaRepairFaultType.fallbackContamination:
        return 'FALLBACK_CONTAMINATION';
      case NovaRepairFaultType.queueStaleTurn:
        return 'QUEUE_STALE_TURN';
      case NovaRepairFaultType.securityFalsePositive:
        return 'SECURITY_FALSE_POSITIVE';
      case NovaRepairFaultType.realSecurityRisk:
        return 'REAL_SECURITY_RISK';
      case NovaRepairFaultType.unknown:
        return 'UNKNOWN';
    }
  }

  static NovaRepairFaultType fromKey(String? raw) {
    final value = (raw ?? '').trim().toUpperCase();
    for (final item in NovaRepairFaultType.values) {
      if (item.key == value) return item;
    }
    return NovaRepairFaultType.unknown;
  }
}

enum NovaRepairTargetPolicy {
  personaDigestPolicy,
  responseLengthPolicy,
  contextCompactPolicy,
  modelRetryPolicy,
  queueStalePolicy,
  fallbackSpeechPolicy,
  ttsSourcePolicy,
  asrSingleBrainRoutePolicy,
  memoryRetrievalPolicy,
  modeTransitionPolicy,
  setupRuntimeBoundaryPolicy,
  toolRoutingPolicy,
  callBehaviorPolicy,
  none,
}

extension NovaRepairTargetPolicyX on NovaRepairTargetPolicy {
  String get key {
    switch (this) {
      case NovaRepairTargetPolicy.personaDigestPolicy:
        return 'persona_digest_policy';
      case NovaRepairTargetPolicy.responseLengthPolicy:
        return 'response_length_policy';
      case NovaRepairTargetPolicy.contextCompactPolicy:
        return 'context_compact_policy';
      case NovaRepairTargetPolicy.modelRetryPolicy:
        return 'model_retry_policy';
      case NovaRepairTargetPolicy.queueStalePolicy:
        return 'queue_stale_policy';
      case NovaRepairTargetPolicy.fallbackSpeechPolicy:
        return 'fallback_speech_policy';
      case NovaRepairTargetPolicy.ttsSourcePolicy:
        return 'tts_source_policy';
      case NovaRepairTargetPolicy.asrSingleBrainRoutePolicy:
        return 'asr_single_brain_route_policy';
      case NovaRepairTargetPolicy.memoryRetrievalPolicy:
        return 'memory_retrieval_policy';
      case NovaRepairTargetPolicy.modeTransitionPolicy:
        return 'mode_transition_policy';
      case NovaRepairTargetPolicy.setupRuntimeBoundaryPolicy:
        return 'setup_runtime_boundary_policy';
      case NovaRepairTargetPolicy.toolRoutingPolicy:
        return 'tool_routing_policy';
      case NovaRepairTargetPolicy.callBehaviorPolicy:
        return 'call_behavior_policy';
      case NovaRepairTargetPolicy.none:
        return 'none';
    }
  }

  bool get isGreen {
    return this == NovaRepairTargetPolicy.personaDigestPolicy ||
        this == NovaRepairTargetPolicy.responseLengthPolicy ||
        this == NovaRepairTargetPolicy.contextCompactPolicy ||
        this == NovaRepairTargetPolicy.modelRetryPolicy ||
        this == NovaRepairTargetPolicy.queueStalePolicy ||
        this == NovaRepairTargetPolicy.fallbackSpeechPolicy ||
        this == NovaRepairTargetPolicy.ttsSourcePolicy;
  }

  bool get isYellow {
    return this == NovaRepairTargetPolicy.asrSingleBrainRoutePolicy ||
        this == NovaRepairTargetPolicy.memoryRetrievalPolicy ||
        this == NovaRepairTargetPolicy.modeTransitionPolicy ||
        this == NovaRepairTargetPolicy.setupRuntimeBoundaryPolicy ||
        this == NovaRepairTargetPolicy.toolRoutingPolicy ||
        this == NovaRepairTargetPolicy.callBehaviorPolicy;
  }

  static NovaRepairTargetPolicy fromKey(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    for (final item in NovaRepairTargetPolicy.values) {
      if (item.key == value) return item;
    }
    return NovaRepairTargetPolicy.none;
  }
}

class NovaRepairManifest {
  final String id;
  final String repairType;
  final NovaRepairTargetPolicy targetPolicy;
  final String oldValue;
  final String newValue;
  final NovaRepairRiskLevel riskLevel;
  final String reason;
  final String rollbackKey;
  final String expectedSignal;
  final NovaRepairFaultType faultType;
  final int repeatCount;
  final bool ownerApproved;
  final String proposedBy;
  final DateTime createdAt;

  const NovaRepairManifest({
    required this.id,
    required this.repairType,
    required this.targetPolicy,
    required this.oldValue,
    required this.newValue,
    required this.riskLevel,
    required this.reason,
    required this.rollbackKey,
    required this.expectedSignal,
    required this.faultType,
    required this.repeatCount,
    required this.ownerApproved,
    required this.proposedBy,
    required this.createdAt,
  });

  bool get isAiProposed =>
      proposedBy.trim().toLowerCase().contains('gemma') ||
      proposedBy.trim().toLowerCase().contains('ai') ||
      proposedBy.trim().toLowerCase().contains('localbrain');

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'repairType': repairType,
    'targetPolicy': targetPolicy.key,
    'oldValue': oldValue,
    'newValue': newValue,
    'riskLevel': riskLevel.key,
    'reason': reason,
    'rollbackKey': rollbackKey,
    'expectedSignal': expectedSignal,
    'faultType': faultType.key,
    'repeatCount': repeatCount,
    'ownerApproved': ownerApproved,
    'proposedBy': proposedBy,
    'createdAt': createdAt.toIso8601String(),
  };

  factory NovaRepairManifest.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return NovaRepairManifest(
      id: (map['id'] as String? ?? '').trim(),
      repairType: (map['repairType'] as String? ?? '').trim(),
      targetPolicy: NovaRepairTargetPolicyX.fromKey(
        map['targetPolicy'] as String?,
      ),
      oldValue: (map['oldValue'] as String? ?? '').trim(),
      newValue: (map['newValue'] as String? ?? '').trim(),
      riskLevel: NovaRepairRiskLevelX.fromKey(map['riskLevel'] as String?),
      reason: (map['reason'] as String? ?? '').trim(),
      rollbackKey: (map['rollbackKey'] as String? ?? '').trim(),
      expectedSignal: (map['expectedSignal'] as String? ?? '').trim(),
      faultType: NovaRepairFaultTypeX.fromKey(map['faultType'] as String?),
      repeatCount: (map['repeatCount'] as int? ?? 0).clamp(0, 999),
      ownerApproved: map['ownerApproved'] as bool? ?? false,
      proposedBy: (map['proposedBy'] as String? ?? '').trim(),
      createdAt:
          DateTime.tryParse((map['createdAt'] as String? ?? '').trim()) ?? now,
    );
  }
}
