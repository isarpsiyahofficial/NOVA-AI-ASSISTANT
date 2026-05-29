// ignore_for_file: avoid_print
// NOVA_V37_DECISION_WRAPPER_CONTRACT_FULL_AUTHORITY_SURFACE
import 'nova_runtime_graph_service.dart';

class NovaDecisionWrapperDescriptor {
  final String name;
  final String role;
  final String pathHint;
  final bool canProduceSpokenText;
  final bool requiresSingleBrainBeforeSpeech;
  final bool securityPrimitive;

  const NovaDecisionWrapperDescriptor({
    required this.name,
    required this.role,
    required this.pathHint,
    this.canProduceSpokenText = false,
    this.requiresSingleBrainBeforeSpeech = true,
    this.securityPrimitive = false,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'name': name,
    'role': role,
    'pathHint': pathHint,
    'canProduceSpokenText': canProduceSpokenText,
    'requiresSingleBrainBeforeSpeech': requiresSingleBrainBeforeSpeech,
    'securityPrimitive': securityPrimitive,
  };
}

/// Contract registry for duplicate/parallel Nova decision mechanisms.
///
/// Rule:
/// - A deterministic classifier/router/guard may exist only as a wrapper or
///   primitive.
/// - Normal spoken output still has to pass NovaSingleBrainAuthorityService
///   and the TTS authority gate.
/// - Security/native permission guards stay primitives; they are not replaced
///   by the model and must not be weakened by SingleBrain.
class NovaDecisionWrapperContractService {
  static const List<NovaDecisionWrapperDescriptor>
  requiredWrappers = <NovaDecisionWrapperDescriptor>[
    NovaDecisionWrapperDescriptor(
      name: 'streaming_transcript_router',
      role: 'asr_final_transcript_route_wrapper',
      pathHint:
          'lib/services/asr/nova_streaming_transcript_router_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'audio_listening_router',
      role: 'listening_mode_route_wrapper',
      pathHint: 'lib/services/audio_runtime/nova_listening_router_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'voice_authorization_runtime',
      role: 'speaker_identity_authority_wrapper',
      pathHint:
          'lib/services/identity/voice_authorization_runtime_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'voice_authorization_service',
      role: 'speaker_identity_authority_wrapper',
      pathHint: 'lib/services/identity/voice_authorization_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'multi_speaker_authority_service',
      role: 'speaker_priority_wrapper',
      pathHint:
          'lib/services/identity/nova_multi_speaker_authority_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'call_decision_service',
      role: 'call_handling_decision_wrapper',
      pathHint: 'lib/services/call/call_decision_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'call_response_policy_service',
      role: 'call_policy_wrapper',
      pathHint: 'lib/services/call/call_response_policy_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'call_companion_gate_service',
      role: 'call_companion_command_gate_wrapper',
      pathHint:
          'lib/services/call_companion/nova_call_companion_gate_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'live_call_companion_brain_service',
      role: 'call_companion_plan_wrapper_not_speech_root',
      pathHint:
          'lib/services/call_companion/nova_live_call_companion_brain_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'call_instruction_command_service',
      role: 'call_instruction_parse_wrapper',
      pathHint:
          'lib/services/call_instruction/nova_call_instruction_command_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'reminder_command_service',
      role: 'reminder_parse_wrapper',
      pathHint: 'lib/services/reminder/nova_reminder_command_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'runtime_intent_router',
      role: 'runtime_intent_classifier_wrapper',
      pathHint: 'lib/services/runtime/nova_runtime_intent_router_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'runtime_orchestrator',
      role: 'system_action_executor_wrapper',
      pathHint: 'lib/services/runtime/nova_runtime_orchestrator_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'owner_action_broker',
      role: 'owner_approved_action_broker_wrapper',
      pathHint: 'lib/services/runtime/nova_owner_action_broker_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'hotpath_owner_service',
      role: 'single_brain_dashboard_turn_wrapper',
      pathHint: 'lib/services/runtime/nova_hotpath_owner_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'spoken_intent_interpreter',
      role: 'spoken_intent_wrapper',
      pathHint:
          'lib/services/runtime/nova_spoken_intent_interpreter_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'personality_command_service',
      role: 'personality_command_wrapper',
      pathHint:
          'lib/services/personality/nova_personality_command_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'media_control_service',
      role: 'media_command_wrapper',
      pathHint: 'lib/services/phone_control/nova_media_control_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'media_dialogue_orchestrator',
      role: 'media_dialogue_wrapper',
      pathHint:
          'lib/services/phone_control/nova_media_dialogue_orchestrator_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'phone_control_guard',
      role: 'phone_control_guard_wrapper',
      pathHint: 'lib/services/phone_control/phone_control_guard_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'dialogue_policy_service',
      role: 'conversation_policy_wrapper',
      pathHint: 'lib/services/conversation/nova_dialogue_policy_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'multi_intent_service',
      role: 'conversation_intent_wrapper',
      pathHint: 'lib/services/conversation/nova_multi_intent_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'turn_manager_service',
      role: 'conversation_turn_wrapper',
      pathHint: 'lib/services/conversation/nova_turn_manager_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'lifecycle_service',
      role: 'power_lifecycle_wrapper',
      pathHint: 'lib/services/system/nova_lifecycle_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'continuous_listening_runtime',
      role: 'continuous_listening_wrapper',
      pathHint:
          'lib/services/system/nova_continuous_listening_runtime_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'speech_runtime_service',
      role: 'tts_authority_gate_wrapper',
      pathHint: 'lib/services/speech_runtime/nova_speech_runtime_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'fast_response_service',
      role: 'fast_speech_wrapper',
      pathHint: 'lib/services/speech_runtime/nova_fast_response_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'fast_turkish_orchestrator',
      role: 'fast_turkish_audio_wrapper',
      pathHint:
          'lib/services/audio_runtime/nova_fast_turkish_orchestrator_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'voice_clone_permission_gate',
      role: 'clone_permission_wrapper',
      pathHint:
          'lib/services/voice_clone/voice_clone_permission_gate_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'screen_observation_voice_gate',
      role: 'screen_voice_gate_wrapper',
      pathHint:
          'lib/services/screen_control/screen_observation_voice_gate_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'adaptive_behavior_hub',
      role: 'adaptive_behavior_wrapper',
      pathHint: 'lib/services/adaptive/adaptive_behavior_hub_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'teachable_behavior_runtime',
      role: 'teachable_behavior_wrapper',
      pathHint:
          'lib/services/runtime/nova_teachable_behavior_runtime_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'memory_promotion_policy',
      role: 'memory_commit_policy_wrapper',
      pathHint:
          'lib/services/cognition/nova_memory_promotion_policy_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'memory_commit_gate',
      role: 'memory_commit_gate_wrapper',
      pathHint: 'lib/services/runtime/memory_commit_gate.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'relationship_update_policy',
      role: 'relationship_policy_wrapper',
      pathHint: 'lib/services/runtime/relationship_update_policy.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'response_enrichment_service',
      role: 'response_style_wrapper_not_speech_root',
      pathHint: 'lib/services/runtime/nova_response_enrichment_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'spoken_response_planner',
      role: 'spoken_response_style_wrapper_not_speech_root',
      pathHint:
          'lib/services/runtime/nova_spoken_response_planner_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'duplex_turn_planner',
      role: 'turn_timing_wrapper',
      pathHint: 'lib/services/runtime/nova_duplex_turn_planner_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'thinking_mode_classifier',
      role: 'thinking_mode_wrapper',
      pathHint:
          'lib/services/runtime/nova_thinking_mode_classifier_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'safe_autonomy_limiter',
      role: 'safe_autonomy_wrapper',
      pathHint: 'lib/services/runtime/nova_safe_autonomy_limiter_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'behavior_decision_engine',
      role: 'behavior_decision_wrapper',
      pathHint:
          'lib/services/runtime/nova_behavior_decision_engine_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'real_time_behavior_reasoner',
      role: 'real_time_behavior_wrapper',
      pathHint:
          'lib/services/runtime/nova_real_time_behavior_reasoner_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'guided_procedure_resolution',
      role: 'guided_resolution_wrapper',
      pathHint:
          'lib/services/runtime/nova_guided_procedure_resolution_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'knowledge_request_router',
      role: 'knowledge_request_wrapper',
      pathHint:
          'lib/services/runtime/nova_knowledge_request_router_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'knowledge_domain_policy',
      role: 'knowledge_policy_wrapper',
      pathHint:
          'lib/services/runtime/nova_knowledge_domain_policy_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'security_policy_service',
      role: 'security_guard_primitive_not_model_authority',
      pathHint: 'lib/services/security/nova_security_policy_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'restricted_capability_guard',
      role: 'security_guard_primitive_not_model_authority',
      pathHint:
          'lib/services/security/nova_restricted_capability_guard_service.dart',
      canProduceSpokenText: true,
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'repair_gateway',
      role: 'self_repair_security_primitive',
      pathHint: 'lib/services/self_repair/nova_repair_gateway_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'adaptive_call_behavior',
      role: 'call_or_phone_decision_wrapper_preserve_native_feature',
      pathHint: 'lib/services/adaptive/adaptive_call_behavior_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'adaptive_social_behavior',
      role: 'decision_wrapper_not_parallel_authority',
      pathHint: 'lib/services/adaptive/adaptive_social_behavior_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'asr_health',
      role: 'voice_asr_identity_wrapper',
      pathHint: 'lib/services/asr/nova_asr_health_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'streaming_asr_bridge',
      role: 'voice_asr_identity_wrapper',
      pathHint: 'lib/services/asr/nova_streaming_asr_bridge_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'streaming_asr_runtime',
      role: 'voice_asr_identity_wrapper',
      pathHint: 'lib/services/asr/nova_streaming_asr_runtime_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'native_audio_bridge',
      role: 'decision_wrapper_not_parallel_authority',
      pathHint:
          'lib/services/audio_runtime/nova_native_audio_bridge_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'stt_runtime',
      role: 'decision_wrapper_not_parallel_authority',
      pathHint: 'lib/services/audio_runtime/nova_stt_runtime_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'voice_clone_capture_runtime',
      role: 'voice_asr_identity_wrapper',
      pathHint:
          'lib/services/audio_runtime/voice_clone_capture_runtime_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'behavior_observability',
      role: 'decision_wrapper_not_parallel_authority',
      pathHint:
          'lib/services/behavior/nova_behavior_observability_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'behavior_resolver',
      role: 'decision_wrapper_not_parallel_authority',
      pathHint: 'lib/services/behavior_control/behavior_resolver_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'call_audio_guard',
      role: 'call_or_phone_decision_wrapper_preserve_native_feature',
      pathHint: 'lib/services/call/call_audio_guard_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'call_conversation',
      role: 'call_or_phone_decision_wrapper_preserve_native_feature',
      pathHint: 'lib/services/call/call_conversation_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'call_handoff',
      role: 'call_or_phone_decision_wrapper_preserve_native_feature',
      pathHint: 'lib/services/call/call_handoff_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'call_intent',
      role: 'call_or_phone_decision_wrapper_preserve_native_feature',
      pathHint: 'lib/services/call/call_intent_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'call_control_bridge',
      role: 'call_or_phone_decision_wrapper_preserve_native_feature',
      pathHint: 'lib/services/call/nova_call_control_bridge_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'call_state',
      role: 'call_or_phone_decision_wrapper_preserve_native_feature',
      pathHint: 'lib/services/call/nova_call_state_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'call_companion_runtime',
      role: 'call_or_phone_decision_wrapper_preserve_native_feature',
      pathHint:
          'lib/services/call_companion/nova_call_companion_runtime_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'call_companion',
      role: 'call_or_phone_decision_wrapper_preserve_native_feature',
      pathHint: 'lib/services/call_companion/nova_call_companion_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'call_instruction_runtime',
      role: 'call_or_phone_decision_wrapper_preserve_native_feature',
      pathHint:
          'lib/services/call_instruction/nova_call_instruction_runtime_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'call_response_resolver',
      role: 'call_or_phone_decision_wrapper_preserve_native_feature',
      pathHint:
          'lib/services/call_learning/call_response_resolver_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'learned_call_response',
      role: 'call_or_phone_decision_wrapper_preserve_native_feature',
      pathHint: 'lib/services/call_learning/learned_call_response_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'learning_engine',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/cognition/nova_learning_engine_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'contact',
      role: 'decision_wrapper_not_parallel_authority',
      pathHint: 'lib/services/contacts/nova_contact_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'conversation_session',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint:
          'lib/services/conversation/nova_conversation_session_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'social_presence',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/conversation/nova_social_presence_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'daily_voice_session',
      role: 'voice_asr_identity_wrapper',
      pathHint: 'lib/services/identity/nova_daily_voice_session_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'voice_identity_runtime',
      role: 'voice_asr_identity_wrapper',
      pathHint:
          'lib/services/identity/nova_voice_identity_runtime_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'voice_identity_session',
      role: 'voice_asr_identity_wrapper',
      pathHint: 'lib/services/identity/voice_identity_session_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'local_model',
      role: 'decision_wrapper_not_parallel_authority',
      pathHint: 'lib/services/local_model/local_model_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'seven_day_context',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/memory/nova_seven_day_context_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'reminder_runtime',
      role: 'decision_wrapper_not_parallel_authority',
      pathHint: 'lib/services/reminder/nova_reminder_runtime_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'identity_boot_compiler',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint:
          'lib/services/runtime/identity/nova_identity_boot_compiler.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'identity_kernel',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/identity/nova_identity_kernel.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'identity_source_kernel',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint:
          'lib/services/runtime/identity/nova_identity_source_kernel.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'affect_governor',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_affect_governor_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'affective_state',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_affective_state_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'anticipatory_companionship',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint:
          'lib/services/runtime/nova_anticipatory_companionship_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'behavior_constitution_engine',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint:
          'lib/services/runtime/nova_behavior_constitution_engine_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'benchmark_harness',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_benchmark_harness_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'call_acoustic_emotion_layer',
      role: 'call_or_phone_decision_wrapper_preserve_native_feature',
      pathHint:
          'lib/services/runtime/nova_call_acoustic_emotion_layer_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'corpus_install',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_corpus_install_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'cross_language_knowledge_bridge',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint:
          'lib/services/runtime/nova_cross_language_knowledge_bridge_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'curated_knowledge_manifest',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint:
          'lib/services/runtime/nova_curated_knowledge_manifest_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'decision_wrapper_contract',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint:
          'lib/services/runtime/nova_decision_wrapper_contract_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'deep_knowledge_corpus',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_deep_knowledge_corpus_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'homeostatic_mind',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_homeostatic_mind_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'human_imperfection',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_human_imperfection_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'identity_rollout',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_identity_rollout_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'identity_runtime',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_identity_runtime_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'inner_stability_engine',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_inner_stability_engine_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'internal_state',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_internal_state_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'json_corpus_runtime',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_json_corpus_runtime_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'knowledge_interpretation_engine',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint:
          'lib/services/runtime/nova_knowledge_interpretation_engine_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'latency_budget',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_latency_budget_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'layer_binding_registry',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_layer_binding_registry_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'meta_awareness',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_meta_awareness_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'micro_reaction_engine',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_micro_reaction_engine_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'mind_loop',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_mind_loop_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'offline_knowledge_library',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint:
          'lib/services/runtime/nova_offline_knowledge_library_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'partial_response_planner',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint:
          'lib/services/runtime/nova_partial_response_planner_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'post_turn_reflection',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_post_turn_reflection_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'presence_identity',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_presence_identity_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'runtime_graph',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_runtime_graph_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'safe_growth_governor',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_safe_growth_governor_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'self_evolution',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_self_evolution_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'self_model',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_self_model_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'shared_life_context',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_shared_life_context_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'shared_world_model',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_shared_world_model_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'silence_comfort',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_silence_comfort_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'simulation_harness',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_simulation_harness_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'single_brain_authority',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_single_brain_authority_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'social_boundary',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_social_boundary_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'speaker_graph_engine',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_speaker_graph_engine_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'speech_native_cognition_bridge',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint:
          'lib/services/runtime/nova_speech_native_cognition_bridge_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'story_memory_lattice',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_story_memory_lattice_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'style_adapter',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_style_adapter_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'system_adaptation_contract',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint:
          'lib/services/runtime/nova_system_adaptation_contract_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'thinking_layer',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_thinking_layer_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'thinking_out_loud',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_thinking_out_loud_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'translator_mode',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_translator_mode_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'turkish_spoken_understanding_layer',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint:
          'lib/services/runtime/nova_turkish_spoken_understanding_layer_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'turkish_voice_quality_metrics',
      role: 'voice_asr_identity_wrapper',
      pathHint:
          'lib/services/runtime/nova_turkish_voice_quality_metrics_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'twelve_shields',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_twelve_shields_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'unified_social_runtime',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/nova_unified_social_runtime_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'post_task_reflection',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/post_task_reflection_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'relationship_retrieval',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/relationship_retrieval_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'runtime_efficiency_analyzer',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/runtime_efficiency_analyzer.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'skill_memory',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/skill_memory_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'task_experience_store',
      role: 'runtime_decision_wrapper_not_parallel_brain',
      pathHint: 'lib/services/runtime/task_experience_store.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'autonomous_security_orchestrator',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint:
          'lib/services/security/nova_autonomous_security_orchestrator_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'device_safe_destroy',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint: 'lib/services/security/nova_device_safe_destroy_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'escalation_sanity',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint: 'lib/services/security/nova_escalation_sanity_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'internet_security_orchestrator',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint:
          'lib/services/security/nova_internet_security_orchestrator_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'native_security_bridge',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint:
          'lib/services/security/nova_native_security_bridge_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'persistent_state_guard',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint:
          'lib/services/security/nova_persistent_state_guard_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'prompt_affect_security',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint:
          'lib/services/security/nova_prompt_affect_security_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'security_incident',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint: 'lib/services/security/nova_security_incident_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'security_signal_scan',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint: 'lib/services/security/nova_security_signal_scan_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'user_origin_security',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint: 'lib/services/security/nova_user_origin_security_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'voice_auth_synthetic_playback_guard',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint:
          'lib/services/security/nova_voice_auth_synthetic_playback_guard_service.dart',
      canProduceSpokenText: true,
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'asr_probe',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint: 'lib/services/self_repair/nova_asr_probe_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'boot_doctor',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint: 'lib/services/self_repair/nova_boot_doctor_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'capability_manifest',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint:
          'lib/services/self_repair/nova_capability_manifest_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'controlled_restart',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint: 'lib/services/self_repair/nova_controlled_restart_service.dart',
      canProduceSpokenText: true,
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'fault_classifier',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint: 'lib/services/self_repair/nova_fault_classifier_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'local_brain_repair_agent',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint:
          'lib/services/self_repair/nova_local_brain_repair_agent_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'owner_blind_patch_guard',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint:
          'lib/services/self_repair/nova_owner_blind_patch_guard_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'owner_directed_speech_patch_execution',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint:
          'lib/services/self_repair/nova_owner_directed_speech_patch_execution_service.dart',
      canProduceSpokenText: true,
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'repair_audit_ledger',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint:
          'lib/services/self_repair/nova_repair_audit_ledger_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'repair_escalation_bridge',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint:
          'lib/services/self_repair/nova_repair_escalation_bridge_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'repair_executor',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint: 'lib/services/self_repair/nova_repair_executor_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'repair_policy_store',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint:
          'lib/services/self_repair/nova_repair_policy_store_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'repair_rollback_manager',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint:
          'lib/services/self_repair/nova_repair_rollback_manager_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'repair_runtime_policy_enforcer',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint:
          'lib/services/self_repair/nova_repair_runtime_policy_enforcer_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'repair_verification_loop',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint:
          'lib/services/self_repair/nova_repair_verification_loop_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'repair_voice_narration',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint:
          'lib/services/self_repair/nova_repair_voice_narration_service.dart',
      canProduceSpokenText: true,
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'self_diagnostic',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint: 'lib/services/self_repair/nova_self_diagnostic_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'self_recognition',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint: 'lib/services/self_repair/nova_self_recognition_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'self_repair_command',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint:
          'lib/services/self_repair/nova_self_repair_command_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'self_repair_coordinator',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint:
          'lib/services/self_repair/nova_self_repair_coordinator_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'self_repair_experience',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint:
          'lib/services/self_repair/nova_self_repair_experience_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'self_repair_orchestrator',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint:
          'lib/services/self_repair/nova_self_repair_orchestrator_service.dart',
      canProduceSpokenText: true,
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'self_repair_safe_kernel',
      role: 'security_or_repair_primitive_not_model_authority',
      pathHint:
          'lib/services/self_repair/nova_self_repair_safe_kernel_service.dart',
      requiresSingleBrainBeforeSpeech: false,
      securityPrimitive: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'tts',
      role: 'decision_wrapper_not_parallel_authority',
      pathHint: 'lib/services/speech/tts_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'voice_profile_runtime',
      role: 'voice_asr_identity_wrapper',
      pathHint:
          'lib/services/speech_runtime/voice_profile_runtime_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'speech_to_text',
      role: 'voice_asr_identity_wrapper',
      pathHint: 'lib/services/stt/nova_speech_to_text_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'overlay_presence_runtime',
      role: 'decision_wrapper_not_parallel_authority',
      pathHint:
          'lib/services/system/nova_overlay_presence_runtime_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'voice_first_presence_runtime',
      role: 'voice_asr_identity_wrapper',
      pathHint:
          'lib/services/system/nova_voice_first_presence_runtime_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'prosody_planner',
      role: 'decision_wrapper_not_parallel_authority',
      pathHint: 'lib/services/tts/nova_prosody_planner_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'tts_2',
      role: 'decision_wrapper_not_parallel_authority',
      pathHint: 'lib/services/tts/nova_tts_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'dashboard_performance_guard',
      role: 'decision_wrapper_not_parallel_authority',
      pathHint: 'lib/services/ui/nova_dashboard_performance_guard_service.dart',
    ),
    NovaDecisionWrapperDescriptor(
      name: 'voice_interaction_policy',
      role: 'voice_asr_identity_wrapper',
      pathHint: 'lib/services/voice/nova_voice_interaction_policy_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'voice_clone_cleanup_command',
      role: 'voice_asr_identity_wrapper',
      pathHint:
          'lib/services/voice_clone/voice_clone_cleanup_command_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'voice_clone_cleanup',
      role: 'voice_asr_identity_wrapper',
      pathHint: 'lib/services/voice_clone/voice_clone_cleanup_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'voice_clone_limit',
      role: 'voice_asr_identity_wrapper',
      pathHint: 'lib/services/voice_clone/voice_clone_limit_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'voice_clone_runtime_guard',
      role: 'voice_asr_identity_wrapper',
      pathHint:
          'lib/services/voice_clone/voice_clone_runtime_guard_service.dart',
      canProduceSpokenText: true,
    ),
    NovaDecisionWrapperDescriptor(
      name: 'voice_clone',
      role: 'voice_asr_identity_wrapper',
      pathHint: 'lib/services/voice_clone/voice_clone_service.dart',
      canProduceSpokenText: true,
    ),
  ];

  const NovaDecisionWrapperContractService._();

  static void registerAll({NovaRuntimeGraphService? graph}) {
    final runtimeGraph = graph ?? NovaRuntimeGraphService.instance;
    for (final descriptor in requiredWrappers) {
      runtimeGraph.registerDecisionWrapper(
        descriptor.name,
        role: descriptor.role,
        pathHint: descriptor.pathHint,
        canProduceSpokenText: descriptor.canProduceSpokenText,
        requiresSingleBrainBeforeSpeech:
            descriptor.requiresSingleBrainBeforeSpeech,
        securityPrimitive: descriptor.securityPrimitive,
      );
    }
  }

  static List<String> requiredNames() => requiredWrappers
      .map((descriptor) => descriptor.name)
      .toList(growable: false);
}
