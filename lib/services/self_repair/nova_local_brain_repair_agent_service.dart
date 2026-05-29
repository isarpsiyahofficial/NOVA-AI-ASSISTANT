// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// GEMMA95952_SAFE_SELF_REPAIR_KERNEL
import '../../core/self_repair/nova_repair_manifest.dart';
import 'nova_fault_classifier_service.dart';

class NovaLocalBrainRepairAgentService {
  const NovaLocalBrainRepairAgentService();

  NovaRepairManifest? proposeManifest({
    required NovaFaultClassification classification,
    bool ownerApproved = false,
  }) {
    if (!classification.repairCandidate) return null;
    if (classification.targetPolicy == NovaRepairTargetPolicy.none) return null;

    final now = DateTime.now();
    return NovaRepairManifest(
      id: 'repair_${now.microsecondsSinceEpoch}_${classification.targetPolicy.key}',
      repairType: _repairTypeFor(classification),
      targetPolicy: classification.targetPolicy,
      oldValue: 'current_runtime_policy',
      newValue: _newValueFor(classification),
      riskLevel: classification.riskLevel,
      reason: classification.reason,
      rollbackKey: 'rollback_${classification.targetPolicy.key}',
      expectedSignal: _expectedSignalFor(classification),
      faultType: classification.faultType,
      repeatCount: classification.repeatCount,
      ownerApproved: ownerApproved,
      proposedBy: 'local_brain_repair_agent_gemma_limited',
      createdAt: now,
    );
  }

  String _repairTypeFor(NovaFaultClassification classification) {
    switch (classification.faultType) {
      case NovaRepairFaultType.modelNotReady:
        return 'model_recovery_policy_marker';
      case NovaRepairFaultType.transcriptNotRouted:
      case NovaRepairFaultType.asrNoTranscript:
        return 'asr_single_brain_route_policy_repair';
      case NovaRepairFaultType.ttsWrongSource:
      case NovaRepairFaultType.ttsNotSpeaking:
        return 'tts_brain_decision_route_policy_repair';
      case NovaRepairFaultType.fallbackContamination:
        return 'fallback_speech_gate_policy_repair';
      case NovaRepairFaultType.queueStaleTurn:
        return 'stale_turn_queue_policy_repair';
      case NovaRepairFaultType.securityFalsePositive:
        return 'setup_runtime_boundary_policy_repair';
      case NovaRepairFaultType.nativeChannelFail:
      case NovaRepairFaultType.realSecurityRisk:
      case NovaRepairFaultType.unknown:
        return 'report_only';
    }
  }

  String _newValueFor(NovaFaultClassification classification) {
    switch (classification.targetPolicy) {
      case NovaRepairTargetPolicy.ttsSourcePolicy:
        return 'brain_decision_authority_only_with_reroute';
      case NovaRepairTargetPolicy.asrSingleBrainRoutePolicy:
        return 'transcript_to_single_brain_required';
      case NovaRepairTargetPolicy.modelRetryPolicy:
        return 'bounded_retry_and_runtime_recovery_marker';
      case NovaRepairTargetPolicy.queueStalePolicy:
        return 'drop_stale_turn_before_tts';
      case NovaRepairTargetPolicy.fallbackSpeechPolicy:
        return 'fallback_status_only_no_static_speech';
      case NovaRepairTargetPolicy.setupRuntimeBoundaryPolicy:
        return 'setup_phase_aware_owner_auth_without_security_root_change';
      default:
        return 'bounded_policy_adjustment';
    }
  }

  String _expectedSignalFor(NovaFaultClassification classification) {
    switch (classification.targetPolicy) {
      case NovaRepairTargetPolicy.ttsSourcePolicy:
        return 'SPEECH_PROVENANCE source=brain_decision_ai_output';
      case NovaRepairTargetPolicy.asrSingleBrainRoutePolicy:
        return 'TRANSCRIPT_ROUTED_TO_SINGLE_BRAIN';
      case NovaRepairTargetPolicy.modelRetryPolicy:
        return 'LOCAL_MODEL_RECOVERY_SIGNAL';
      case NovaRepairTargetPolicy.queueStalePolicy:
        return 'STALE_TURN_DROPPED';
      case NovaRepairTargetPolicy.fallbackSpeechPolicy:
        return 'FALLBACK_STATIC_SPEECH_BLOCKED';
      default:
        return 'REPAIR_POLICY_VALIDATED';
    }
  }
}
