// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:async';

import '../runtime/nova_runtime_signal.dart';
import '../../services/runtime/nova_runtime_signal_service.dart';
import '../../services/runtime/nova_spoken_quality_eval_tr_service.dart';
import '../../services/runtime/nova_faiss_asr_feedback_bridge_service.dart';
import '../../services/runtime/nova_turkish_voice_persona_layer_service.dart';
import '../../services/runtime/nova_emotion_prosody_fuser_service.dart';
import '../../services/runtime/nova_speech_native_planner_v2_service.dart';
import '../../services/runtime/micro_turn_orchestrator_service.dart';
import '../../services/runtime/nova_turkish_pragmatics_core_service.dart';
import '../../services/runtime/nova_turkish_voice_quality_metrics_service.dart';
import '../../services/runtime/nova_faiss_context_bias_bridge_service.dart';
import '../../services/runtime/nova_pause_renderer_service.dart';
import '../../services/runtime/nova_emphasis_scheduler_service.dart';
import '../../services/runtime/nova_emotion_to_prosody_mapper_service.dart';
import '../../services/runtime/nova_turkish_prosody_planner_service.dart';
import '../../services/runtime/nova_turkish_emphasis_resolver_service.dart';
import '../../services/runtime/nova_turkish_indirect_request_detector_service.dart';
import '../../services/runtime/nova_turkish_discourse_marker_parser_service.dart';
import '../../services/runtime/nova_turkish_pragmatics_engine_service.dart';
import '../../core/behavior/nova_persona.dart';
import '../../core/cognition/nova_emotion_state.dart';
import '../../core/behavior/response_style.dart';
import '../../core/conversation/nova_dialogue_policy.dart';
import '../../core/conversation/nova_turn_decision.dart';
import '../../core/conversation/nova_conversation_repair_result.dart';
import '../../core/runtime/nova_style_profile.dart';
import '../../core/memory/memory_item.dart';
import '../../services/api/api_service.dart';
import '../../services/local_model/local_model_service.dart';
import '../../services/runtime/identity/nova_identity_boot_compiler.dart';
import '../../services/voice/nova_voice_interaction_policy_service.dart';
import '../../services/runtime/nova_turkish_human_guide_service.dart';
import '../../services/runtime/nova_offline_knowledge_library_service.dart';
import '../../services/runtime/nova_offline_knowledge_base_service.dart';
import '../../services/runtime/nova_language_pack_service.dart';
import '../../services/runtime/nova_knowledge_source_library_service.dart';
import '../../services/runtime/nova_knowledge_interpretation_engine_service.dart';
import '../../services/runtime/nova_cross_language_knowledge_bridge_service.dart';
import '../../services/runtime/nova_turkish_semantic_lexicon_service.dart';
import '../../services/personality/personality_settings_service.dart';
import '../../services/behavior/nova_behavior_observability_service.dart';
import '../../services/runtime/nova_thinking_layer_service.dart';
import '../../services/runtime/nova_internal_state_service.dart';
import '../../services/runtime/nova_response_enrichment_service.dart';
import '../../services/runtime/nova_affective_state_service.dart';
import '../../services/runtime/nova_response_history_service.dart';
import '../../services/runtime/nova_mood_engine_service.dart';
import '../../services/runtime/nova_conversation_continuity_service.dart';
import '../../services/runtime/nova_silence_intelligence_service.dart';
import '../../services/runtime/nova_emotional_momentum_service.dart';
import '../../services/runtime/nova_social_boundary_service.dart';
import '../../services/runtime/nova_meta_awareness_service.dart';
import '../../services/runtime/nova_social_energy_service.dart';
import '../../services/runtime/nova_style_adapter_service.dart';
import '../../services/runtime/nova_mind_loop_service.dart';
import '../../services/runtime/nova_behavior_decision_engine_service.dart';
import '../../services/runtime/nova_relationship_style_memory_service.dart';
import '../../services/runtime/relationship_retrieval_service.dart';
import '../../services/runtime/relationship_profile_store.dart';
import '../../services/runtime/relationship_update_policy.dart';
import '../../services/runtime/task_experience_store.dart';
import '../../services/runtime/skill_memory_service.dart';
import '../../services/runtime/strategy_promotion_service.dart';
import '../../services/runtime/runtime_efficiency_analyzer.dart';
import '../../services/runtime/post_task_reflection_service.dart';
import '../../services/runtime/memory_commit_gate.dart';
import '../../services/runtime/nova_post_turn_reflection_service.dart';
import '../../services/runtime/nova_relationship_dramaturgy_service.dart';
import '../../services/runtime/nova_relationship_constitution_service.dart';
import '../../services/runtime/nova_anticipatory_companionship_service.dart';
import '../../services/runtime/nova_ritual_habit_engine_service.dart';
import '../../services/runtime/nova_speech_native_cognition_bridge_service.dart';
import '../../services/runtime/nova_non_resentment_guard_service.dart';
import '../../services/runtime/nova_autobiographic_memory_service.dart';
import '../../services/runtime/nova_shared_world_model_service.dart';
import '../../services/runtime/nova_relationship_story_service.dart';
import '../../services/runtime/nova_affect_governor_service.dart';
import '../../core/runtime/nova_self_model.dart';
import '../../core/runtime/nova_identity_continuity.dart';
import '../../core/runtime/nova_stability_report.dart';
import '../../core/runtime/nova_continuity_capsule.dart';
import '../../core/runtime/nova_safe_evolution_note.dart';
import '../../services/runtime/nova_self_model_service.dart';
import '../../services/runtime/nova_identity_engine_service.dart';
import '../../services/runtime/nova_self_consistency_engine_service.dart';
import '../../services/runtime/nova_inner_stability_engine_service.dart';
import '../../services/runtime/nova_meta_self_loop_service.dart';
import '../../services/runtime/nova_autobiographic_identity_bridge_service.dart';
import '../../services/runtime/nova_shared_life_context_service.dart';
import '../../services/runtime/nova_story_memory_lattice_service.dart';
import '../../services/runtime/nova_behavior_constitution_engine_service.dart';
import '../../services/runtime/nova_conversation_ritual_memory_service.dart';
import '../../services/runtime/nova_presence_identity_service.dart';
import '../../services/runtime/nova_latency_budget_service.dart';
import '../../services/runtime/nova_partial_response_planner_service.dart';
import '../../services/runtime/nova_duplex_turn_planner_service.dart';
import '../../services/runtime/nova_silence_comfort_service.dart';
import '../../services/runtime/nova_proactive_restraint_service.dart';
import '../../services/runtime/nova_trust_calibration_service.dart';
import '../../services/runtime/nova_emotional_invariance_service.dart';
import '../../services/runtime/nova_anti_manipulation_guard_service.dart';
import '../../services/runtime/nova_anti_rumination_guard_service.dart';
import '../../services/runtime/nova_safe_autonomy_limiter_service.dart';
import '../../services/runtime/nova_session_handoff_service.dart';
import '../../services/runtime/nova_continuity_capsule_service.dart';
import '../../services/runtime/nova_identity_memory_commit_service.dart';
import '../../services/runtime/nova_self_evolution_service.dart';
import '../../services/runtime/nova_theory_of_mind_core_service.dart';
import '../../services/runtime/nova_developmental_self_engine_service.dart';
import '../../services/runtime/nova_teachable_behavior_runtime_service.dart';
import '../../core/runtime/nova_relationship_dramaturgy.dart';
import '../../core/runtime/nova_autobiographic_memory.dart';
import '../../core/runtime/nova_shared_world_state.dart';
import '../../core/runtime/nova_relationship_story_arc.dart';
import '../../core/runtime/nova_affect_governor_state.dart';
import '../../services/runtime/nova_user_model_service.dart';
import '../../services/memory/nova_memory_context_service.dart';
import '../../services/memory/nova_semantic_memory_service.dart';
import '../../services/memory/nova_memory_usage_policy_service.dart';
import '../../services/runtime/nova_adaptive_instruction_service.dart';
import '../../services/conversation/nova_conversation_session_service.dart';
import '../../services/conversation/nova_conversation_focus_service.dart';
import '../../services/conversation/nova_turn_manager_service.dart';
import '../../services/conversation/nova_dialogue_policy_service.dart';
import '../../services/conversation/nova_conversation_state_machine_service.dart';
import '../../services/conversation/nova_repair_loop_service.dart';
import '../../services/cognition/nova_goal_registry_service.dart';
import '../../services/cognition/nova_topic_thread_service.dart';
import '../../services/cognition/nova_interruption_recovery_service.dart';
import '../../services/cognition/nova_curiosity_engine_service.dart';
import '../../services/cognition/nova_self_state_continuity_service.dart';
import '../../services/cognition/nova_memory_promotion_policy_service.dart';
import '../../services/cognition/nova_conversation_return_service.dart';
import '../../services/cognition/nova_emotion_engine_service.dart';
import '../../services/cognition/nova_understanding_engine_service.dart';
import '../../services/conversation/nova_multi_intent_service.dart';
import '../../services/conversation/nova_social_presence_service.dart';
import '../../services/identity/device_owner_identity_service.dart';
import '../../core/runtime/nova_post_turn_reflection.dart';
import '../../core/runtime/nova_behavior_decision.dart';
import '../../core/runtime/nova_relationship_profile.dart';
import '../../core/runtime/nova_skill_card.dart';
import '../../core/runtime/nova_task_experience.dart';
import '../../services/cognition/nova_consciousness_engine_service.dart';
import '../../services/cognition/nova_learning_engine_service.dart';
import '../../services/runtime/nova_conversation_act_detector_service.dart';
import '../../services/runtime/nova_semantic_turn_detector_service.dart';
import '../../services/runtime/nova_interruption_intent_detector_service.dart';
import '../../services/runtime/nova_backchannel_policy_engine_service.dart';
import '../../services/runtime/nova_turkish_spoken_understanding_layer_service.dart';
import '../../services/runtime/nova_contextual_asr_bias_service.dart';
import '../../services/runtime/nova_speech_native_planner_service.dart';
import '../../services/runtime/nova_real_time_behavior_reasoner_service.dart';
import '../../services/runtime/nova_voice_metrics_collector_service.dart';
import '../../services/runtime/nova_ai_turn_queue_service.dart';
import '../../services/runtime/nova_single_brain_authority_service.dart';
import 'ai_mode.dart';
import 'ai_request.dart';
import 'ai_response.dart';

class NovaAiService {
  final LocalModelService localModelService;
  final ApiService apiService;
  final NovaPersona persona;
  final ResponseStyle responseStyle;
  final NovaAiTurnQueueService _turnQueue = NovaAiTurnQueueService.instance;

  final NovaVoiceInteractionPolicyService _voicePolicyService =
      const NovaVoiceInteractionPolicyService();
  final NovaTurkishHumanGuideService _turkishHumanGuideService =
      const NovaTurkishHumanGuideService();
  final NovaOfflineKnowledgeLibraryService _offlineKnowledgeLibraryService =
      const NovaOfflineKnowledgeLibraryService();
  final NovaOfflineKnowledgeBaseService _offlineKnowledgeBaseService =
      const NovaOfflineKnowledgeBaseService();
  final NovaLanguagePackService _languagePackService =
      const NovaLanguagePackService();
  final NovaKnowledgeSourceLibraryService _knowledgeSourceLibraryService =
      const NovaKnowledgeSourceLibraryService();
  final NovaCrossLanguageKnowledgeBridgeService _knowledgeBridgeService =
      const NovaCrossLanguageKnowledgeBridgeService();
  final NovaKnowledgeInterpretationEngineService
  _knowledgeInterpretationService =
      const NovaKnowledgeInterpretationEngineService();
  final NovaTurkishSemanticLexiconService _turkishSemanticLexiconService =
      const NovaTurkishSemanticLexiconService();
  final PersonalitySettingsService _personalitySettingsService =
      const PersonalitySettingsService();
  final NovaThinkingLayerService _thinkingLayerService =
      const NovaThinkingLayerService();
  final NovaInternalStateService _internalStateService =
      const NovaInternalStateService();
  final NovaResponseEnrichmentService _responseEnrichmentService =
      const NovaResponseEnrichmentService();
  final NovaAffectiveStateService _affectiveStateService =
      const NovaAffectiveStateService();
  final NovaResponseHistoryService _responseHistoryService =
      const NovaResponseHistoryService();
  final NovaMoodEngineService _moodEngineService =
      const NovaMoodEngineService();
  final NovaConversationContinuityService _conversationContinuityService =
      const NovaConversationContinuityService();
  final NovaSilenceIntelligenceService _silenceIntelligenceService =
      const NovaSilenceIntelligenceService();
  final NovaEmotionalMomentumService _emotionalMomentumService =
      const NovaEmotionalMomentumService();
  final NovaSocialBoundaryService _socialBoundaryService =
      const NovaSocialBoundaryService();
  final NovaMetaAwarenessService _metaAwarenessService =
      const NovaMetaAwarenessService();
  final NovaSocialEnergyService _socialEnergyService =
      const NovaSocialEnergyService();
  final NovaMemoryContextService _memoryContextService =
      const NovaMemoryContextService();
  final NovaSemanticMemoryService _semanticMemoryService =
      const NovaSemanticMemoryService();
  final NovaMemoryUsagePolicyService _memoryUsagePolicyService =
      const NovaMemoryUsagePolicyService();
  final NovaAdaptiveInstructionService _adaptiveInstructionService =
      const NovaAdaptiveInstructionService();
  final NovaConversationSessionService _conversationSessionService =
      const NovaConversationSessionService();
  final NovaConversationFocusService _conversationFocusService =
      const NovaConversationFocusService();
  final NovaTurnManagerService _turnManagerService =
      const NovaTurnManagerService();
  final NovaDialoguePolicyService _dialoguePolicyService =
      const NovaDialoguePolicyService();
  final NovaConversationStateMachineService _conversationStateMachineService =
      const NovaConversationStateMachineService();
  final NovaRepairLoopService _repairLoopService =
      const NovaRepairLoopService();
  final NovaStyleAdapterService _styleAdapterService =
      const NovaStyleAdapterService();
  final NovaMindLoopService _mindLoopService = const NovaMindLoopService();
  final NovaBehaviorDecisionEngineService _behaviorDecisionEngineService =
      const NovaBehaviorDecisionEngineService();
  final NovaRelationshipStyleMemoryService _relationshipStyleMemoryService =
      const NovaRelationshipStyleMemoryService();
  final NovaRelationshipDramaturgyService _relationshipDramaturgyService =
      const NovaRelationshipDramaturgyService();
  final NovaRelationshipConstitutionService _relationshipConstitutionService =
      const NovaRelationshipConstitutionService();
  final NovaAnticipatoryCompanionshipService _anticipatoryCompanionshipService =
      const NovaAnticipatoryCompanionshipService();
  final NovaRitualHabitEngineService _ritualHabitEngineService =
      const NovaRitualHabitEngineService();
  final NovaSpeechNativeCognitionBridgeService
  _speechNativeCognitionBridgeService =
      const NovaSpeechNativeCognitionBridgeService();
  final NovaNonResentmentGuardService _nonResentmentGuardService =
      const NovaNonResentmentGuardService();
  final NovaAutobiographicMemoryService _novaAutobiographicMemoryService =
      const NovaAutobiographicMemoryService();
  final NovaSharedWorldModelService _novaSharedWorldModelService =
      const NovaSharedWorldModelService();
  final NovaRelationshipStoryService _novaRelationshipStoryService =
      const NovaRelationshipStoryService();
  final NovaAffectGovernorService _novaAffectGovernorService =
      const NovaAffectGovernorService();

  final NovaSelfModelService _novaSelfModelService =
      const NovaSelfModelService();
  final NovaIdentityEngineService _novaIdentityEngineService =
      const NovaIdentityEngineService();
  final NovaSelfConsistencyEngineService _novaSelfConsistencyEngineService =
      const NovaSelfConsistencyEngineService();
  final NovaInnerStabilityEngineService _novaInnerStabilityEngineService =
      const NovaInnerStabilityEngineService();
  final NovaMetaSelfLoopService _novaMetaSelfLoopService =
      const NovaMetaSelfLoopService();
  final NovaAutobiographicIdentityBridgeService
  _novaAutobiographicIdentityBridgeService =
      const NovaAutobiographicIdentityBridgeService();
  final NovaSharedLifeContextService _novaSharedLifeContextService =
      const NovaSharedLifeContextService();
  final NovaStoryMemoryLatticeService _novaStoryMemoryLatticeService =
      const NovaStoryMemoryLatticeService();
  final NovaBehaviorConstitutionEngineService
  _novaBehaviorConstitutionEngineService =
      const NovaBehaviorConstitutionEngineService();
  final NovaConversationRitualMemoryService
  _novaConversationRitualMemoryService =
      const NovaConversationRitualMemoryService();
  final NovaPresenceIdentityService _novaPresenceIdentityService =
      const NovaPresenceIdentityService();
  final NovaLatencyBudgetService _novaLatencyBudgetService =
      const NovaLatencyBudgetService();
  final NovaPartialResponsePlannerService _novaPartialResponsePlannerService =
      const NovaPartialResponsePlannerService();
  final NovaDuplexTurnPlannerService _novaDuplexTurnPlannerService =
      const NovaDuplexTurnPlannerService();
  final NovaSilenceComfortService _novaSilenceComfortService =
      const NovaSilenceComfortService();
  final NovaProactiveRestraintService _novaProactiveRestraintService =
      const NovaProactiveRestraintService();
  final NovaTrustCalibrationService _novaTrustCalibrationService =
      const NovaTrustCalibrationService();
  final NovaEmotionalInvarianceService _novaEmotionalInvarianceService =
      const NovaEmotionalInvarianceService();
  final NovaAntiManipulationGuardService _novaAntiManipulationGuardService =
      const NovaAntiManipulationGuardService();
  final NovaAntiRuminationGuardService _novaAntiRuminationGuardService =
      const NovaAntiRuminationGuardService();
  final NovaSafeAutonomyLimiterService _novaSafeAutonomyLimiterService =
      const NovaSafeAutonomyLimiterService();
  final NovaSessionHandoffService _novaSessionHandoffService =
      const NovaSessionHandoffService();
  final NovaContinuityCapsuleService _novaContinuityCapsuleService =
      const NovaContinuityCapsuleService();
  final NovaIdentityMemoryCommitService _novaIdentityMemoryCommitService =
      const NovaIdentityMemoryCommitService();
  final NovaSelfEvolutionService _novaSelfEvolutionService =
      const NovaSelfEvolutionService();
  final NovaTheoryOfMindCoreService _novaTheoryOfMindCoreService =
      const NovaTheoryOfMindCoreService();
  final NovaDevelopmentalSelfEngineService _novaDevelopmentalSelfEngineService =
      const NovaDevelopmentalSelfEngineService();
  final NovaTeachableBehaviorRuntimeService
  _novaTeachableBehaviorRuntimeService =
      const NovaTeachableBehaviorRuntimeService();
  final NovaConversationActDetectorService _conversationActDetectorService =
      const NovaConversationActDetectorService();
  final NovaSemanticTurnDetectorService _semanticTurnDetectorService =
      const NovaSemanticTurnDetectorService();
  final NovaInterruptionIntentDetectorService
  _interruptionIntentDetectorService =
      const NovaInterruptionIntentDetectorService();
  final NovaBackchannelPolicyEngineService _backchannelPolicyEngineService =
      const NovaBackchannelPolicyEngineService();
  final NovaTurkishSpokenUnderstandingLayerService
  _turkishSpokenUnderstandingLayerService =
      const NovaTurkishSpokenUnderstandingLayerService();
  final NovaContextualAsrBiasService _contextualAsrBiasService =
      const NovaContextualAsrBiasService();
  final NovaSpeechNativePlannerService _speechNativePlannerService =
      const NovaSpeechNativePlannerService();
  final NovaRealTimeBehaviorReasonerService _realTimeBehaviorReasonerService =
      const NovaRealTimeBehaviorReasonerService();
  final NovaVoiceMetricsCollectorService _voiceMetricsCollectorService =
      const NovaVoiceMetricsCollectorService();
  final NovaTurkishPragmaticsEngineService _turkishPragmaticsEngineService =
      const NovaTurkishPragmaticsEngineService();
  final NovaTurkishDiscourseMarkerParserService
  _turkishDiscourseMarkerParserService =
      const NovaTurkishDiscourseMarkerParserService();
  final NovaTurkishIndirectRequestDetectorService
  _turkishIndirectRequestDetectorService =
      const NovaTurkishIndirectRequestDetectorService();
  final NovaTurkishEmphasisResolverService _turkishEmphasisResolverService =
      const NovaTurkishEmphasisResolverService();
  final NovaTurkishProsodyPlannerService _turkishProsodyPlannerService =
      const NovaTurkishProsodyPlannerService();
  final NovaEmotionToProsodyMapperService _emotionToProsodyMapperService =
      const NovaEmotionToProsodyMapperService();
  final NovaEmphasisSchedulerService _emphasisSchedulerService =
      const NovaEmphasisSchedulerService();
  final NovaPauseRendererService _pauseRendererService =
      const NovaPauseRendererService();
  final NovaFaissContextBiasBridgeService _faissContextBiasBridgeService =
      const NovaFaissContextBiasBridgeService();
  final NovaTurkishVoiceQualityMetricsService
  _turkishVoiceQualityMetricsService =
      const NovaTurkishVoiceQualityMetricsService();
  final NovaTurkishPragmaticsCoreService _turkishPragmaticsCoreService =
      const NovaTurkishPragmaticsCoreService();
  final NovaMicroTurnOrchestratorService _microTurnOrchestratorService =
      const NovaMicroTurnOrchestratorService();
  final NovaSpeechNativePlannerV2Service _speechNativePlannerV2Service =
      const NovaSpeechNativePlannerV2Service();
  final NovaEmotionProsodyFuserService _emotionProsodyFuserService =
      const NovaEmotionProsodyFuserService();
  final NovaTurkishVoicePersonaLayerService _turkishVoicePersonaLayerService =
      const NovaTurkishVoicePersonaLayerService();
  final NovaFaissAsrFeedbackBridgeService _faissAsrFeedbackBridgeService =
      const NovaFaissAsrFeedbackBridgeService();
  final NovaSpokenQualityEvalTrService _spokenQualityEvalTrService =
      const NovaSpokenQualityEvalTrService();
  final RelationshipRetrievalService _relationshipRetrievalService =
      const RelationshipRetrievalService();
  final RelationshipProfileStore _relationshipProfileStore =
      const RelationshipProfileStore();
  final RelationshipUpdatePolicy _relationshipUpdatePolicy =
      const RelationshipUpdatePolicy();
  final TaskExperienceStore _taskExperienceStore = const TaskExperienceStore();
  final SkillMemoryService _skillMemoryService = const SkillMemoryService();
  final StrategyPromotionService _strategyPromotionService =
      const StrategyPromotionService();
  final RuntimeEfficiencyAnalyzer _runtimeEfficiencyAnalyzer =
      const RuntimeEfficiencyAnalyzer();
  final PostTaskReflectionService _postTaskReflectionService =
      const PostTaskReflectionService();
  final MemoryCommitGate _memoryCommitGate = const MemoryCommitGate();
  final NovaPostTurnReflectionService _postTurnReflectionService =
      const NovaPostTurnReflectionService();
  final NovaUserModelService _userModelService = const NovaUserModelService();
  final NovaGoalRegistryService _goalRegistryService =
      NovaGoalRegistryService.instance;
  final NovaTopicThreadService _topicThreadService =
      NovaTopicThreadService.instance;
  final NovaInterruptionRecoveryService _interruptionRecoveryService =
      NovaInterruptionRecoveryService.instance;
  final NovaCuriosityEngineService _curiosityEngineService =
      const NovaCuriosityEngineService();
  final NovaSelfStateContinuityService _selfStateContinuityService =
      NovaSelfStateContinuityService.instance;
  final NovaMemoryPromotionPolicyService _memoryPromotionPolicyService =
      const NovaMemoryPromotionPolicyService();
  final NovaConversationReturnService _conversationReturnService =
      const NovaConversationReturnService();
  final NovaEmotionEngineService _emotionEngineService =
      const NovaEmotionEngineService();
  final NovaUnderstandingEngineService _understandingEngineService =
      const NovaUnderstandingEngineService();
  final NovaConsciousnessEngineService _consciousnessEngineService =
      const NovaConsciousnessEngineService();
  final NovaLearningEngineService _learningEngineService =
      const NovaLearningEngineService();
  final NovaBehaviorObservabilityService _behaviorObservabilityService =
      const NovaBehaviorObservabilityService();
  final NovaMultiIntentService _multiIntentService =
      const NovaMultiIntentService();
  final NovaSocialPresenceService _socialPresenceService =
      const NovaSocialPresenceService();
  final DeviceOwnerIdentityService _deviceOwnerIdentityService =
      const DeviceOwnerIdentityService();

  NovaAiService({
    required this.localModelService,
    required this.apiService,
    required this.persona,
    required this.responseStyle,
  });

  Future<AiResponse> process(AiRequest request) {
    NovaSingleBrainAuthorityService.instance.registerSource(
      request.metadata['singleBrainAuthority'] == true
          ? 'ai_gateway_single_brain'
          : 'ai_gateway_direct_seen',
    );
    return _turnQueue.run<AiResponse>(
      label: _deriveTurnQueueLabel(request),
      task: () => _processInternal(request),
    );
  }

  bool _shouldUseCompactLocalPath(AiRequest request, String normalizedPrompt) {
    if (!request.shouldUseLocalModel) return false;
    if (!request.isFastResponsePriority) return false;
    if (request.isResearchRequest ||
        request.isSelfLearningRequest ||
        request.isBehaviorTeachingRequest)
      return false;
    if (request.metadata['forceFullAiPipeline'] == true) return false;
    if (request.metadata['setupMicro'] == true ||
        request.requestOrigin.startsWith('setup'))
      return false;
    if (_looksLikeDeepRequest(normalizedPrompt)) return false;
    return normalizedPrompt.length <= 260;
  }

  bool _mustStayOnCompactPath(AiRequest request) {
    final tier =
        request.metadata['responseTier']?.toString().trim().toLowerCase() ?? '';
    return tier == 'compact' ||
        tier == 'micro' ||
        request.metadata['compactOnly'] == true;
  }

  bool _looksLikeDeepRequest(String text) {
    final lower = text.toLowerCase();
    if (text.length > 420) return true;
    const deepMarkers = <String>[
      'uzun uzun',
      'detaylı',
      'ayrıntılı',
      'analiz',
      'rapor',
      'strateji',
      'neden',
      'nasıl çözülür',
      'plan çıkar',
      'kod incele',
      'dosya tara',
      'adım adım',
    ];
    return deepMarkers.any(lower.contains);
  }

  String _compactSystemHintFor(AiRequest request, String normalizedPrompt) {
    final source = request.requestOrigin.trim().isEmpty
        ? 'user_voice'
        : request.requestOrigin.trim();
    final ownerConfidence =
        request.metadata['ownerConfidence']?.toString() ?? '';
    return <String>[
      'Kaynak: $source.',
      if (ownerConfidence.isNotEmpty) 'Owner güven sinyali: $ownerConfidence.',
      'Bu kısa/normal konuşma cevabıdır; derin analiz istenmedikçe kısa kal.',
      'Cevap yalnız kullanıcının duyacağı metin olsun.',
    ].join(' ');
  }

  Future<AiResponse> _processInternal(AiRequest request) async {
    final String quickReply = _buildQuickReply();
    final String normalizedPrompt = request.prompt.trim();
    final Stopwatch runtimeStopwatch = Stopwatch()..start();

    try {
      if (!_voicePolicyService.shouldAllowProcessing(request)) {
        return _buildErrorResponse(
          message:
              'Efendim, bu sistem öncelikli olarak sesli komut ve sesli cevap mantığıyla çalışır.',
          quickReply: quickReply,
          metadata: <String, dynamic>{
            ...request.metadata,
            'route': 'voice_first_required',
          },
        );
      }

      final conversationEntryAlreadyAdded =
          request.metadata['conversationEntryAlreadyAdded'] as bool? ?? false;
      if (!conversationEntryAlreadyAdded) {
        await _conversationSessionService.addUserText(
          normalizedPrompt,
          speakerName: request.metadata['speakerName']?.toString() ?? '',
          speakerVoiceId: request.metadata['speakerVoiceId']?.toString() ?? '',
          relationshipLabel:
              request.metadata['relationshipLabel']?.toString() ?? '',
        );
      }

      if (_shouldUseCompactLocalPath(request, normalizedPrompt)) {
        final compact = await localModelService.generateCompactResponse(
          request: request,
          systemHint: _compactSystemHintFor(request, normalizedPrompt),
        );
        if (!compact.isError && compact.hasAuthoritativeBrainProof) {
          return compact;
        }
        if (_mustStayOnCompactPath(request)) {
          return compact;
        }
        // If the compact path cannot produce a valid authoritative proof, fall through
        // to the deep pipeline only for requests that genuinely deserve deeper
        // context instead of pretending a fallback answer exists.
      }

      final installedLanguagePacks = await _languagePackService.loadInstalled();
      final personalitySettings = await _personalitySettingsService.load();
      final thinking = _thinkingLayerService.analyze(
        normalizedPrompt,
        internetAllowed: request.internetAllowed,
        isResearchRequest: request.isResearchRequest,
      );
      final internalState = await _internalStateService.evolveForInput(
        thinking,
      );
      final understanding = _understandingEngineService.analyze(
        normalizedPrompt,
      );
      final emotion = await _emotionEngineService.analyze(normalizedPrompt);
      final multiIntent = _multiIntentService.analyze(normalizedPrompt);
      final ownerProfile = await _deviceOwnerIdentityService.loadOwner();
      final affectiveState = await _affectiveStateService.analyze(
        normalizedPrompt,
        thinking: thinking,
        internalState: internalState,
      );
      final userModel = await _userModelService.resolveAdaptive();
      final stateSnapshot = await _conversationStateMachineService.build(
        latestPrompt: normalizedPrompt,
      );
      final styleProfile = _styleAdapterService.resolve(
        emotion: emotion,
        understanding: understanding,
        userModel: userModel,
        stateSnapshot: stateSnapshot,
      );
      final turnDecision = _turnManagerService.decide(
        understanding: understanding,
        emotion: emotion,
        stateSnapshot: stateSnapshot,
        userModel: userModel,
      );
      final repairResult = _repairLoopService.analyze(normalizedPrompt);
      final dialoguePolicy = _dialoguePolicyService.resolve(
        turnDecision: turnDecision,
        emotion: emotion,
        styleProfile: styleProfile,
        stateSnapshot: stateSnapshot,
        repairResult: repairResult,
      );
      final recentResponses = await _responseHistoryService.loadRecent();
      final continuitySnapshot = await _conversationContinuityService.load();
      final emotionalMomentum = await _emotionalMomentumService.load();
      final socialEnergySnapshot = await _socialEnergyService.snapshot();
      final List<MemoryItem> memories = await _memoryContextService
          .selectRelevant(normalizedPrompt);
      final semanticMatches = await _semanticMemoryService.search(
        normalizedPrompt,
        limit: 4,
      );
      final conversationContext = await _conversationSessionService
          .buildPromptContext();
      final focusContext = await _conversationFocusService.buildPromptContext(
        latestUserPrompt: normalizedPrompt,
      );
      final learningAnalysis = _learningEngineService.analyze(normalizedPrompt);
      final filteredSemanticMatches = semanticMatches
          .where((item) {
            final decision = _memoryUsagePolicyService.decide(
              prompt: normalizedPrompt,
              memoryText: item.content,
              relevance: 0.72,
              emotion: emotion,
            );
            return decision.shouldSurface;
          })
          .toList(growable: false);
      final memoryContext = await _memoryContextService.buildPromptContext(
        memories,
        semanticMatches: filteredSemanticMatches,
        emotion: emotion,
        latestPrompt: normalizedPrompt,
      );
      final NovaRelationshipProfile relationshipProfile =
          await _relationshipRetrievalService.resolve(
            speakerName: request.metadata['speakerName']?.toString() ?? '',
            relationshipLabel:
                request.metadata['relationshipLabel']?.toString() ?? '',
            latestPrompt: normalizedPrompt,
          );
      final NovaSkillCard? learnedSkill = await _skillMemoryService
          .getByTaskKey(
            _runtimeEfficiencyAnalyzer.deriveTaskKey(
              prompt: normalizedPrompt,
              understanding: understanding,
              route: request.shouldUseApi && request.isUserApprovedApiUsage
                  ? 'api_candidate'
                  : 'local_candidate',
            ),
          );
      final adaptiveInstructionContext = await _adaptiveInstructionService
          .buildPromptSection();
      final socialPresenceContext = await _socialPresenceService
          .buildPromptSection(
            prompt: normalizedPrompt,
            multiIntent: multiIntent,
            ownerProfile: ownerProfile,
            speakerName: request.metadata['speakerName']?.toString() ?? '',
            relationshipLabel:
                request.metadata['relationshipLabel']?.toString() ?? '',
            ownerConfidence: _deriveOwnerConfidence(request.metadata),
          );
      final ownerConfidence = _deriveOwnerConfidence(request.metadata);
      final topicKey = _conversationSessionService.deriveTopicKey(
        normalizedPrompt,
      );

      final contextMode = _socialBoundaryService.resolveContextMode(
        roomPresenceOpportunity: multiIntent.roomPresenceOpportunity,
        socialMode: multiIntent.socialMode,
        ownerConfidence: _deriveOwnerConfidence(request.metadata),
        metadata: request.metadata,
      );
      final NovaRelationshipDramaturgy relationshipDramaturgy =
          _relationshipDramaturgyService.resolve(relationshipProfile);
      final NovaAutobiographicMemory autobiographicMemory =
          await _novaAutobiographicMemoryService.get(
            relationshipProfile.speakerKey,
          );
      final NovaRelationshipStoryArc relationshipStoryArc =
          _novaRelationshipStoryService.resolve(
            profile: relationshipProfile,
            autobiographicMemory: autobiographicMemory,
          );
      final NovaSharedWorldState sharedWorldState =
          await _novaSharedWorldModelService.load();
      final NovaAffectGovernorState affectGovernor = _novaAffectGovernorService
          .resolve(
            prompt: normalizedPrompt,
            ownerConfidence: _deriveOwnerConfidence(request.metadata),
            contextMode: contextMode,
            dominantEmotion: emotion.dominantEmotion,
          );

      final NovaSelfModel selfModel = _novaSelfModelService.resolve(
        contextMode: contextMode,
        socialMode: multiIntent.socialMode,
        ownerConfidence: ownerConfidence,
        dominantEmotion: emotion.dominantEmotion,
      );
      final NovaIdentityContinuity identityContinuity =
          _novaIdentityEngineService.resolve(
            profile: relationshipProfile,
            autobiographicMemory: autobiographicMemory,
            sharedWorldState: sharedWorldState,
            latestPrompt: normalizedPrompt,
          );
      final NovaStabilityReport stabilityReport =
          _novaInnerStabilityEngineService.resolve(
            prompt: normalizedPrompt,
            dominantEmotion: emotion.dominantEmotion,
            contextMode: contextMode,
            ownerConfidence: ownerConfidence,
          );
      final NovaSafeEvolutionNote selfEvolutionNote = _novaSelfEvolutionService
          .build(
            durationSeconds: runtimeStopwatch.elapsedMilliseconds / 1000.0,
            shouldStayShortNextTurn: false,
            shouldReduceQuestionsNextTurn: false,
          );
      final theoryOfMindContext = _novaTheoryOfMindCoreService
          .buildPromptSection(
            prompt: normalizedPrompt,
            speakerName: request.metadata['speakerName']?.toString() ?? '',
            relationshipLabel:
                request.metadata['relationshipLabel']?.toString() ?? '',
            metadata: request.metadata,
          );
      final developmentalSelfContext = _novaDevelopmentalSelfEngineService
          .buildPromptSection(
            prompt: normalizedPrompt,
            relationshipLabel:
                request.metadata['relationshipLabel']?.toString() ?? '',
            speakerName: request.metadata['speakerName']?.toString() ?? '',
          );
      final teachableBehaviorContext = _novaTeachableBehaviorRuntimeService
          .buildPromptSection(normalizedPrompt);
      final List<String> relationshipConstitution =
          _relationshipConstitutionService.resolvePrinciples(
            profile: relationshipProfile,
            latestPrompt: normalizedPrompt,
            contextMode: contextMode,
          );
      final List<String> ritualPlan = _ritualHabitEngineService.resolveRituals(
        profile: relationshipProfile,
        latestPrompt: normalizedPrompt,
        contextMode: contextMode,
      );
      final moodContext = _moodEngineService.buildPromptSection(internalState);
      final continuityContext = _conversationContinuityService
          .buildPromptSection(continuitySnapshot);
      final emotionalMomentumContext = _emotionalMomentumService
          .buildPromptSection(emotionalMomentum);
      final socialEnergyContext = _socialEnergyService.buildPromptSection(
        socialEnergySnapshot,
      );
      final socialBoundaryContext = _socialBoundaryService.buildPromptSection(
        contextMode,
      );
      final silenceContext = _silenceIntelligenceService.buildPromptSection(
        _silenceIntelligenceService.classify(
          prompt: normalizedPrompt,
          roomPresenceOpportunity: multiIntent.roomPresenceOpportunity,
          recentResponseCount: recentResponses.length,
          shouldClarify: understanding['shouldClarify'] as bool? ?? false,
        ),
      );
      final metaAwarenessContext = _metaAwarenessService.buildPromptSection();

      final relationshipStyleContext = _relationshipStyleMemoryService
          .buildPromptSection(
            speakerName: request.metadata['speakerName']?.toString() ?? '',
            relationshipLabel:
                request.metadata['relationshipLabel']?.toString() ?? '',
            understanding: understanding,
            emotion: emotion.toMap(),
          );
      final relationshipProfileContext = _relationshipRetrievalService
          .buildPromptSection(relationshipProfile);
      final learnedSkillContext =
          learnedSkill?.buildPromptSection() ??
          'SKILL HAFIZASI: Bu görev için henüz doğrulanmış hızlandırılmış rota yok; ilk turda dikkatli ilerle, iyi çalışan adımları reflection ile yakala.';
      final mindLoopContext = _mindLoopService.buildPromptSection(
        prompt: normalizedPrompt,
        speakerName: request.metadata['speakerName']?.toString() ?? '',
        relationshipLabel:
            request.metadata['relationshipLabel']?.toString() ?? '',
        ownerConfidence: _deriveOwnerConfidence(request.metadata),
        socialMode: multiIntent.socialMode,
        proactiveAllowed: ownerProfile?.proactiveChatAllowed ?? false,
        roomPresenceOpportunity: multiIntent.roomPresenceOpportunity,
        shouldClarify: understanding['shouldClarify'] as bool? ?? false,
      );
      final NovaBehaviorDecision behaviorDecision =
          _behaviorDecisionEngineService.decide(
            prompt: normalizedPrompt,
            thinking: thinking,
            styleProfile: styleProfile,
            internalState: internalState,
            understanding: understanding,
            empathyNeed: emotion.empathyNeed,
            urgency: emotion.urgency,
            emotionalMomentum:
                (emotionalMomentum['intensity'] as num?)?.toDouble() ?? 0.0,
            relationshipLabel:
                request.metadata['relationshipLabel']?.toString() ?? '',
            socialMode: multiIntent.socialMode,
            contextMode: contextMode,
            proactiveAllowed: ownerProfile?.proactiveChatAllowed ?? false,
            roomPresenceOpportunity: multiIntent.roomPresenceOpportunity,
            ownerConfidence: _deriveOwnerConfidence(request.metadata),
            recentResponseCount: recentResponses.length,
            socialEnergyRatio: _socialEnergyService.talkRatio(
              socialEnergySnapshot,
            ),
          );
      final behaviorDecisionContext = behaviorDecision.buildPromptSection();
      final anticipatoryPlan = _anticipatoryCompanionshipService.resolve(
        profile: relationshipProfile,
        behaviorDecision: behaviorDecision,
        latestPrompt: normalizedPrompt,
        contextMode: contextMode,
        talkRatio: _socialEnergyService.talkRatio(socialEnergySnapshot),
      );
      final anticipatoryContext = _anticipatoryCompanionshipService
          .buildPromptSection(anticipatoryPlan);
      final speechNativeBridge = _speechNativeCognitionBridgeService.resolve(
        metadata: request.metadata,
        latestPrompt: normalizedPrompt,
      );
      final speechNativeContext = _speechNativeCognitionBridgeService
          .buildPromptSection(speechNativeBridge);
      final relationshipDramaturgyContext = relationshipDramaturgy
          .buildPromptSection();
      final autobiographicContext = autobiographicMemory.buildPromptSection();
      final relationshipStoryContext = relationshipStoryArc
          .buildPromptSection();
      final sharedWorldContext = sharedWorldState.buildPromptSection();
      final affectGovernorContext = affectGovernor.buildPromptSection();
      final relationshipConstitutionContext = _relationshipConstitutionService
          .buildPromptSection(relationshipConstitution);
      final ritualContext = _ritualHabitEngineService.buildPromptSection(
        ritualPlan,
      );
      final nonResentmentContext = _nonResentmentGuardService
          .buildPromptSection();

      final selfModelContext = selfModel.buildPromptSection();
      final singleBrainExecutiveContext = [
        'SINGLE BRAIN EXECUTIVE:',
        '- tek sahibi olan ortak zihin akışı korunmalı',
        '- konuşma sana mı başkasına mı yönelmiş ayır',
        '- cihaz sahibi > yetkili > tanışılmış sohbet > yabancı sıralaması korunmalı',
        '- mahremiyet varsa ayrıntı herkese açık ortamda söylenmemeli',
        '- cevap öncesi kısa sosyal karşı-olgusal değerlendirme yap',
        '- duygu + prosodi + ritim nihai ses çıkışının zorunlu parçası',
        '- aynı kişilik sürsün ama ilişkiye göre sıcaklık ve açıklık ayarlansın',
      ].join('\n');
      final identityContinuityContext = identityContinuity.buildPromptSection();
      final selfConsistencyContext = _novaSelfConsistencyEngineService
          .buildPromptSection(
            styleMode: styleProfile.mode,
            relationshipStage: relationshipProfile.relationshipStage,
            constitutionMode: relationshipConstitution.join(' | '),
          );
      final stabilityContext = stabilityReport.buildPromptSection();
      final metaSelfLoopContext = _novaMetaSelfLoopService.buildPromptSection(
        talkRatio: _socialEnergyService.talkRatio(socialEnergySnapshot),
        shouldStayShort: false,
        shouldReduceQuestions: false,
      );
      final autobiographicIdentityBridgeContext =
          _novaAutobiographicIdentityBridgeService.buildPromptSection(
            autobiographicMemory,
          );
      final sharedLifeContext = _novaSharedLifeContextService
          .buildPromptSection(sharedWorldState);
      final storyMemoryLatticeContext = _novaStoryMemoryLatticeService
          .buildPromptSection(relationshipStoryArc);
      final behaviorConstitutionEngineContext =
          _novaBehaviorConstitutionEngineService.buildPromptSection(
            relationshipConstitution,
          );
      final ritualMemoryContext = _novaConversationRitualMemoryService
          .buildPromptSection(ritualPlan);
      final presenceIdentityContext = _novaPresenceIdentityService
          .buildPromptSection(
            proactiveAllowed: ownerProfile?.proactiveChatAllowed ?? false,
            socialMode: multiIntent.socialMode,
            talkRatio: _socialEnergyService.talkRatio(socialEnergySnapshot),
          );
      final latencyBudgetContext = _novaLatencyBudgetService.buildPromptSection(
        thinkingMode: behaviorDecision.thinkingMode.name,
        prompt: normalizedPrompt,
      );
      final partialResponsePlannerContext = _novaPartialResponsePlannerService
          .buildPromptSection(
            thinkingMode: behaviorDecision.thinkingMode.name,
            shouldClarify: understanding['shouldClarify'] as bool? ?? false,
          );
      final duplexTurnPlannerContext = _novaDuplexTurnPlannerService
          .buildPromptSection(
            contextMode: contextMode,
            socialMode: multiIntent.socialMode,
          );
      final silenceComfortContext = _novaSilenceComfortService
          .buildPromptSection(
            silenceType: _silenceIntelligenceService.classify(
              prompt: normalizedPrompt,
              roomPresenceOpportunity: multiIntent.roomPresenceOpportunity,
              recentResponseCount: recentResponses.length,
              shouldClarify: understanding['shouldClarify'] as bool? ?? false,
            ),
            talkRatio: _socialEnergyService.talkRatio(socialEnergySnapshot),
          );
      final proactiveRestraintContext = _novaProactiveRestraintService
          .buildPromptSection(
            shouldInitiate: behaviorDecision.shouldInitiate,
            talkRatio: _socialEnergyService.talkRatio(socialEnergySnapshot),
            proactiveAllowed: ownerProfile?.proactiveChatAllowed ?? false,
          );
      final trustCalibrationContext = _novaTrustCalibrationService
          .buildPromptSection(
            ownerConfidence: ownerConfidence,
            relationshipStage: relationshipProfile.relationshipStage,
          );
      final conversationActDecision = _conversationActDetectorService.detect(
        normalizedPrompt,
      );
      final semanticTurnDecision = _semanticTurnDetectorService.detect(
        normalizedPrompt,
      );
      final turkishPragmaticsCore = _turkishPragmaticsCoreService.analyze(
        normalizedPrompt,
      );
      final microTurnDecision = _microTurnOrchestratorService.resolve(
        primaryAct: conversationActDecision.primaryAct,
        turnType: semanticTurnDecision.turnType,
        expectsResponse: conversationActDecision.expectsResponse,
        talkRatio: _socialEnergyService.talkRatio(socialEnergySnapshot),
        prefersShortWarmReply: turkishPragmaticsCore.prefersShortWarmReply,
      );
      final speechNativePlannerV2 = _speechNativePlannerV2Service.resolve(
        primaryAct: conversationActDecision.primaryAct,
        turnType: semanticTurnDecision.turnType,
        thinkingMode: behaviorDecision.thinkingMode.name,
        prefersShortWarmReply: turkishPragmaticsCore.prefersShortWarmReply,
      );
      final emotionProsodyFusion = _emotionProsodyFuserService.fuse(
        raw: normalizedPrompt,
        dominantEmotion: emotion.dominantEmotion,
        shortFormPreferred: styleProfile.shortAnswersPreferred,
      );
      final turkishVoicePersona = _turkishVoicePersonaLayerService.resolve(
        contextMode: contextMode,
        socialMode: multiIntent.socialMode,
        dominantEmotion: emotion.dominantEmotion,
      );
      final spokenQualityEvalTr = _spokenQualityEvalTrService.evaluate(
        normalizedPrompt,
      );
      final interruptionIntentDecision = _interruptionIntentDetectorService
          .detect(normalizedPrompt);
      final backchannelDecision = _backchannelPolicyEngineService.resolve(
        primaryAct: conversationActDecision.primaryAct,
        turnType: semanticTurnDecision.turnType,
        contextMode: contextMode,
        talkRatio: _socialEnergyService.talkRatio(socialEnergySnapshot),
      );
      final turkishSpokenUnderstanding = _turkishSpokenUnderstandingLayerService
          .analyze(normalizedPrompt);
      final contextualAsrHints = _contextualAsrBiasService.buildBiasHints(
        prompt: normalizedPrompt,
        speakerName: request.metadata['speakerName']?.toString() ?? '',
        relationshipLabel:
            request.metadata['relationshipLabel']?.toString() ?? '',
        memoryEntities: filteredSemanticMatches
            .map((e) => e.content)
            .take(6)
            .toList(growable: false),
        turkishEntities: [
          ...turkishSpokenUnderstanding.entities,
          ..._faissContextBiasBridgeService.buildBiasTerms(
            semanticMemoryContents: filteredSemanticMatches
                .map((e) => e.content)
                .take(4)
                .toList(growable: false),
            recentEntities: turkishSpokenUnderstanding.entities,
            relationshipLabel:
                request.metadata['relationshipLabel']?.toString() ?? '',
          ),
        ],
      );
      final speechNativePlanner = _speechNativePlannerService.resolve(
        primaryAct: conversationActDecision.primaryAct,
        turnType: semanticTurnDecision.turnType,
        thinkingMode: behaviorDecision.thinkingMode.name,
      );
      final realTimeBehaviorReasoning = _realTimeBehaviorReasonerService.reason(
        primaryAct: conversationActDecision.primaryAct,
        turnType: semanticTurnDecision.turnType,
        expectsResponse: conversationActDecision.expectsResponse,
        talkRatio: _socialEnergyService.talkRatio(socialEnergySnapshot),
        shouldClarify: understanding['shouldClarify'] as bool? ?? false,
      );
      final voiceMetricsContext = _voiceMetricsCollectorService
          .buildPromptSection(
            _voiceMetricsCollectorService.buildMetrics(
              primaryAct: conversationActDecision.primaryAct,
              turnType: semanticTurnDecision.turnType,
              expectsResponse: conversationActDecision.expectsResponse,
              shouldClarify: understanding['shouldClarify'] as bool? ?? false,
              talkRatio: _socialEnergyService.talkRatio(socialEnergySnapshot),
            ),
          );
      final turkishPragmaticsDecision = _turkishPragmaticsEngineService.analyze(
        normalizedPrompt,
      );
      final discourseMarkerDecision = _turkishDiscourseMarkerParserService
          .parse(normalizedPrompt);
      final indirectRequestDecision = _turkishIndirectRequestDetectorService
          .detect(normalizedPrompt);
      final emphasisResolution = _turkishEmphasisResolverService.resolve(
        normalizedPrompt,
      );
      final emotionToProsody = _emotionToProsodyMapperService.map(
        emotion.dominantEmotion,
      );
      final turkishProsodyDecision = _turkishProsodyPlannerService.plan(
        raw: normalizedPrompt,
        emotionalTone: emotion.dominantEmotion,
        contourHint: emphasisResolution.contourHint,
        shortFormPreferred: behaviorDecision.shouldKeepItShort,
      );
      final emphasisSchedule = _emphasisSchedulerService.schedule(
        emphasisResolution.emphasisWords,
        shortFormPreferred: behaviorDecision.shouldKeepItShort,
      );
      final pauseRenderResult = _pauseRendererService.render(normalizedPrompt);
      final faissBiasTerms = _faissContextBiasBridgeService.buildBiasTerms(
        semanticMemoryContents: filteredSemanticMatches
            .map((e) => e.content)
            .take(8)
            .toList(growable: false),
        recentEntities: turkishSpokenUnderstanding.entities,
        relationshipLabel:
            request.metadata['relationshipLabel']?.toString() ?? '',
      );
      final turkishVoiceQualityMetrics = _turkishVoiceQualityMetricsService
          .evaluate(normalizedPrompt);
      final turkishPragmaticsContext = turkishPragmaticsDecision
          .buildPromptSection();
      final discourseMarkerContext = discourseMarkerDecision
          .buildPromptSection();
      final indirectRequestContext = indirectRequestDecision
          .buildPromptSection();
      final emphasisResolutionContext = emphasisResolution.buildPromptSection();
      final emotionToProsodyContext = emotionToProsody.buildPromptSection();
      final turkishProsodyContext = turkishProsodyDecision.buildPromptSection();
      final emphasisScheduleContext = emphasisSchedule.buildPromptSection();
      final pauseRenderContext = pauseRenderResult.buildPromptSection();
      final faissBiasBridgeContext = _faissContextBiasBridgeService
          .buildPromptSection(faissBiasTerms);
      final turkishVoiceQualityContext = turkishVoiceQualityMetrics
          .buildPromptSection();
      final conversationActContext = conversationActDecision
          .buildPromptSection();
      final semanticTurnContext = semanticTurnDecision.buildPromptSection();
      final interruptionIntentContext = interruptionIntentDecision
          .buildPromptSection();
      final backchannelContext = backchannelDecision.buildPromptSection();
      final turkishSpokenContext = turkishSpokenUnderstanding
          .buildPromptSection();
      final contextualAsrContext = _contextualAsrBiasService.buildPromptSection(
        contextualAsrHints,
      );
      final faissAsrFeedback = _faissAsrFeedbackBridgeService.resolve(
        semanticMemoryContents: filteredSemanticMatches
            .map((e) => e.content)
            .toList(growable: false),
        recentEntities: contextualAsrHints,
        relationshipLabel:
            request.metadata['relationshipLabel']?.toString() ?? '',
        speakerName: request.metadata['speakerName']?.toString() ?? '',
      );
      final faissAsrFeedbackContext = faissAsrFeedback.buildPromptSection();
      final turkishPragmaticsCoreContext = turkishPragmaticsCore
          .buildPromptSection();
      final microTurnContext = microTurnDecision.buildPromptSection();
      final speechNativePlannerV2Context = speechNativePlannerV2
          .buildPromptSection();
      final emotionProsodyFusionContext = emotionProsodyFusion
          .buildPromptSection();
      final turkishVoicePersonaContext = turkishVoicePersona
          .buildPromptSection();
      final spokenQualityEvalTrContext = spokenQualityEvalTr
          .buildPromptSection();
      final speechNativePlannerContext = speechNativePlanner
          .buildPromptSection();
      final realTimeBehaviorContext = realTimeBehaviorReasoning
          .buildPromptSection();
      final emotionalInvarianceContext = _novaEmotionalInvarianceService
          .buildPromptSection(dominantEmotion: emotion.dominantEmotion);
      final antiManipulationContext = _novaAntiManipulationGuardService
          .buildPromptSection();
      final antiRuminationContext = _novaAntiRuminationGuardService
          .buildPromptSection();
      final safeAutonomyLimiterContext = _novaSafeAutonomyLimiterService
          .buildPromptSection();
      final sessionHandoffContext = _novaSessionHandoffService
          .buildPromptSection(
            speakerName: request.metadata['speakerName']?.toString() ?? '',
            topicKey: topicKey,
          );

      _goalRegistryService.upsert(
        id: 'latest_user_goal',
        title: 'Güncel kullanıcı odağı',
        summary: normalizedPrompt,
      );
      _topicThreadService.rememberTurn(
        threadId: topicKey.isEmpty ? 'latest_thread' : topicKey,
        title: stateSnapshot.activeTopic.isEmpty
            ? 'Son konuşma izi'
            : stateSnapshot.activeTopic,
        turn: normalizedPrompt,
      );
      _selfStateContinuityService.update(
        status: emotion.empathyNeed > 0.35 ? 'destekleyici odak' : 'odaklı',
        reason: normalizedPrompt,
      );

      final cognitionContext = <String>[
        _goalRegistryService.buildPromptSection(),
        _topicThreadService.buildPromptSection(),
        _interruptionRecoveryService.buildPromptSection(),
        _curiosityEngineService.buildPromptSection(normalizedPrompt),
        _repairLoopService.buildVoiceRepairGuide(),
        _selfStateContinuityService.buildPromptSection(),
        _memoryPromotionPolicyService.buildPromptSection(normalizedPrompt),
        _conversationReturnService.buildPromptSection(),
        await _emotionEngineService.buildPromptSection(normalizedPrompt),
        _understandingEngineService.buildPromptSection(normalizedPrompt),
        _consciousnessEngineService.buildPromptSection(
          activeGoal: normalizedPrompt,
          activeTopic: stateSnapshot.activeTopic,
          returnTopic: stateSnapshot.returnTopic,
          awaitingClarification:
              understanding['shouldClarify'] as bool? ?? false,
        ),
        _learningEngineService.buildPromptSection(normalizedPrompt),
      ].join('\n');

      final promptKind = _derivePromptKind(
        thinkingIntent: thinking.intent.name,
        understanding: understanding,
      );
      final ownerSignal = _deriveOwnerSignal(request.metadata);
      final memorySources = _deriveMemorySources(
        memoriesCount: memories.length,
        semanticCount: filteredSemanticMatches.length,
        conversationContext: conversationContext,
        adaptiveInstructionContext: adaptiveInstructionContext,
        cognitionContext: cognitionContext,
      );

      final identityBridgeSignal = NovaIdentityBootCompiler.buildAIBridgeSignal(
        requestOrigin: request.requestOrigin,
        fastMode: request.isFastResponsePriority,
        ownerConfidence: ownerConfidence.toString(),
        maxChars: request.isFastResponsePriority ? 320 : 480,
      );

      final localSystemPrompt = <String>[
        'Sen Nova adli telefonda calisan ses odakli asistansin.',
        'Sadece kullanicinin duyacagi nihai Turkce cevabi yaz.',
        'Sistem, debug, prompt, metadata, model, kaynak dosya veya ic mimari anlatma.',
        'Kullanicinin niyetini ve baglami dikkate al; kisa ve dogal cevap ver.',
        _fitPromptSection(memoryContext, 180, 'ilgili hafiza'),
        _fitPromptSection(conversationContext, 150, 'sohbet baglami'),
        _fitPromptSection(relationshipProfileContext, 150, 'iliski tonu'),
      ].where((e) => e.trim().isNotEmpty).join('\n');

      if (request.shouldUseApi && request.isUserApprovedApiUsage) {
        final AiResponse apiResponse = await apiService.send(request);
        if (!apiResponse.isError) {
          final apiText = _normalizeFinalText(apiResponse.displayText);
          final enrichedApiText = apiText;
          final NovaPostTurnReflection apiReflection =
              _postTurnReflectionService.evaluate(
                prompt: normalizedPrompt,
                reply: enrichedApiText,
                thinking: thinking,
                turnDecision: turnDecision,
                styleProfile: styleProfile,
                relationshipLabel:
                    request.metadata['relationshipLabel']?.toString() ?? '',
                contextMode: contextMode,
                talkRatio: _socialEnergyService.talkRatio(socialEnergySnapshot),
              );
          await _rememberSuccessfulReply(
            prompt: normalizedPrompt,
            reply: enrichedApiText,
            topicKey: topicKey,
            learningAnalysis: learningAnalysis,
            understanding: understanding,
            turnReflection: apiReflection,
            styleProfile: styleProfile,
            relationshipLabel:
                request.metadata['relationshipLabel']?.toString() ?? '',
            speakerName: request.metadata['speakerName']?.toString() ?? '',
            ownerConfidence: ownerConfidence,
            durationSeconds: runtimeStopwatch.elapsedMilliseconds / 1000.0,
            route: 'api',
            contextMode: contextMode,
            talkRatio: _socialEnergyService.talkRatio(socialEnergySnapshot),
            socialMode: multiIntent.socialMode,
            emotion: emotion,
          );
          await _behaviorObservabilityService.recordTurn(
            prompt: normalizedPrompt,
            reply: enrichedApiText,
            route: 'api',
            promptKind: promptKind,
            ownerConfidence: ownerConfidence,
            ownerSignal: ownerSignal,
            memorySources: memorySources,
            personaMode: styleProfile.mode,
            personaTone: styleProfile.toneGuide,
            responseSource: 'api',
            extra: <String, dynamic>{
              'thinkingIntent': thinking.intent.name,
              'dialogueMove': dialoguePolicy.primaryMove.name,
              'multiIntent': multiIntent.toMaps(),
              'compositeIntent': multiIntent.isComposite,
              'socialMode': multiIntent.socialMode,
              'curiosityPrompt': multiIntent.curiosityPrompt,
              'learningOpportunity': multiIntent.learningOpportunity,
              'reflection': apiReflection.toMap(),
              'behaviorDecision': behaviorDecision.toMap(),
              'relationshipStage': relationshipProfile.relationshipStage,
              'constitutionPrinciples': relationshipConstitution,
              'ritualCount': ritualPlan.length,
              'storyPhase': autobiographicMemory.storyPhase,
              'worldUserMode': sharedWorldState.userMode,
              'affectGovernor': affectGovernor.activeGuards,
            },
          );
          return apiResponse.withApiBrainProofText(
            enrichedApiText,
            quickReplyOverride: quickReply,
            extraMetadata: <String, dynamic>{
              ...apiResponse.metadata,
              ...request.metadata,
              ...thinking.toMetadata(),
              'affectiveDominantEmotion': affectiveState.dominantEmotion,
              'route': 'api',
              'responseSource': 'api',
              'aiOutputReturnedBeforeSideEffects': true,
              'multiIntent': multiIntent.toMaps(),
              'socialMode': multiIntent.socialMode,
              'behaviorDecision': behaviorDecision.toMap(),
              'relationshipStage': relationshipProfile.relationshipStage,
              'constitutionPrinciples': relationshipConstitution,
              'ritualCount': ritualPlan.length,
              'storyPhase': autobiographicMemory.storyPhase,
              'worldUserMode': sharedWorldState.userMode,
              'affectGovernor': affectGovernor.activeGuards,
            },
          );
        }
        if (!request.shouldUseLocalModel) {
          return _buildErrorResponse(
            message: apiResponse.displayText.trim().isNotEmpty
                ? apiResponse.displayText.trim()
                : 'API cevabı alınamadı ve yerel model bu sürümde devre dışı.',
            quickReply: quickReply,
            metadata: <String, dynamic>{
              ...apiResponse.metadata,
              ...request.metadata,
              'route': 'api_failed_local_model_detached',
              'fromLocalModel': false,
              'fromApi': false,
              'recoverySuppressed': true,
              'tts_source': 'blocked_non_ai_speech',
            },
          );
        }
      }

      if (request.shouldUseLocalModel) {
        final AiResponse localResponse = await localModelService.generate(
          request: request,
          systemPrompt: localSystemPrompt,
        );

        if (!localResponse.isError) {
          if (!localResponse.hasAuthoritativeBrainProof) {
            return _buildErrorResponse(
              message:
                  'Yerel/legacy cevap API/native otorite kanıtı taşımadığı için Nova konuşması olarak dönmedi.',
              quickReply: quickReply,
              metadata: <String, dynamic>{
                ...localResponse.metadata,
                ...request.metadata,
                'route': 'local_response_missing_authoritative_proof_v1',
                'tts_source': 'blocked_non_ai_speech',
                'fromLocalModel': false,
              },
            );
          }
          final authoritativeLocalBrain = true;
          final baseLocalText = _normalizeFinalText(
            localResponse.displayText,
            allowQuickPrefix: false,
          );
          String enrichedText = baseLocalText;

          final finalLocalText = enrichedText.trim().isEmpty
              ? localResponse.displayText.trim()
              : enrichedText.trim();

          final localOutputSource =
              request.metadata['sourceSystem']?.toString() ??
              request.requestOrigin;
          print(
            'NOVA_AI_LOCAL_OUTPUT_RETURNED route=local_model_ai_output '
            'chars=${finalLocalText.length} promptHash=${normalizedPrompt.hashCode} '
            'source=$localOutputSource',
          );

          unawaited(() async {
            try {
              final NovaPostTurnReflection localReflection =
                  _postTurnReflectionService.evaluate(
                    prompt: normalizedPrompt,
                    reply: finalLocalText,
                    thinking: thinking,
                    turnDecision: turnDecision,
                    styleProfile: styleProfile,
                    relationshipLabel:
                        request.metadata['relationshipLabel']?.toString() ?? '',
                    contextMode: contextMode,
                    talkRatio: _socialEnergyService.talkRatio(
                      socialEnergySnapshot,
                    ),
                  );
              await _rememberSuccessfulReply(
                prompt: normalizedPrompt,
                reply: finalLocalText,
                topicKey: topicKey,
                learningAnalysis: learningAnalysis,
                understanding: understanding,
                turnReflection: localReflection,
                styleProfile: styleProfile,
                relationshipLabel:
                    request.metadata['relationshipLabel']?.toString() ?? '',
                speakerName: request.metadata['speakerName']?.toString() ?? '',
                ownerConfidence: ownerConfidence,
                durationSeconds: runtimeStopwatch.elapsedMilliseconds / 1000.0,
                route: 'local',
                contextMode: contextMode,
                talkRatio: _socialEnergyService.talkRatio(socialEnergySnapshot),
                socialMode: multiIntent.socialMode,
                emotion: emotion,
              );
              await _behaviorObservabilityService.recordTurn(
                prompt: normalizedPrompt,
                reply: finalLocalText,
                route: 'local',
                promptKind: promptKind,
                ownerConfidence: ownerConfidence,
                ownerSignal: ownerSignal,
                memorySources: memorySources,
                personaMode: styleProfile.mode,
                personaTone: styleProfile.toneGuide,
                responseSource: 'local_model',
                extra: <String, dynamic>{
                  'thinkingIntent': thinking.intent.name,
                  'dialogueMove': dialoguePolicy.primaryMove.name,
                  'multiIntent': multiIntent.toMaps(),
                  'compositeIntent': multiIntent.isComposite,
                  'socialMode': multiIntent.socialMode,
                  'curiosityPrompt': multiIntent.curiosityPrompt,
                  'learningOpportunity': multiIntent.learningOpportunity,
                  'reflection': localReflection.toMap(),
                  'behaviorDecision': behaviorDecision.toMap(),
                  'relationshipStage': relationshipProfile.relationshipStage,
                  'constitutionPrinciples': relationshipConstitution,
                  'ritualCount': ritualPlan.length,
                  'storyPhase': autobiographicMemory.storyPhase,
                  'worldUserMode': sharedWorldState.userMode,
                  'affectGovernor': affectGovernor.activeGuards,
                },
              );
              if (thinking.intent.name == 'command' ||
                  thinking.intent.name == 'memory') {
                await _internalStateService.registerOpenLoop(normalizedPrompt);
              }
            } catch (error, stackTrace) {
              print(
                'NOVA_AI_POST_TURN_SIDE_EFFECT_ERROR type=${error.runtimeType} error=$error',
              );
              print(stackTrace);
              try {
                await NovaRuntimeSignalService.instance.record(
                  kind: NovaRuntimeSignalKind.ai,
                  level: NovaRuntimeSignalLevel.warning,
                  code: 'ai_post_turn_side_effect_error',
                  message:
                      'AI cevabı kullanıcıya döndükten sonra post-turn yan etki hatası oluştu.',
                  technicalDetails: 'type=${error.runtimeType}; error=$error',
                  diagnosticCandidate: true,
                  metadata: const <String, dynamic>{
                    'source': 'nova_ai_service',
                    'stage': 'post_turn_side_effect',
                    'singleBrainProtected': true,
                  },
                );
              } catch (_) {}
            }
          }());

          return localResponse.withNativeProofText(
            finalLocalText,
            quickReplyOverride: quickReply,
            extraMetadata: <String, dynamic>{
              ...request.metadata,
              ...thinking.toMetadata(),
              'affectiveDominantEmotion': affectiveState.dominantEmotion,
              'route': 'local',
              'responseSource': 'local_model',
              'aiOutputReturnedBeforeSideEffects': true,
              'multiIntent': multiIntent.toMaps(),
              'socialMode': multiIntent.socialMode,
              'behaviorDecision': behaviorDecision.toMap(),
              'relationshipStage': relationshipProfile.relationshipStage,
              'constitutionPrinciples': relationshipConstitution,
              'ritualCount': ritualPlan.length,
              'storyPhase': autobiographicMemory.storyPhase,
              'worldUserMode': sharedWorldState.userMode,
              'affectGovernor': affectGovernor.activeGuards,
            },
          );
        }

        return _buildErrorResponse(
          message: localResponse.displayText.trim().isNotEmpty
              ? localResponse.displayText.trim()
              : 'API/native beyin gerçek cevap üretemedi; recovery/fallback cevabı başarı gibi gösterilmedi.',
          quickReply: quickReply,
          metadata: <String, dynamic>{
            ...localResponse.metadata,
            ...request.metadata,
            'route': 'local_model_failed_strict',
            'fromLocalModel': false,
            'recoverySuppressed': true,
          },
        );
      }

      return _buildErrorResponse(
        message:
            'API beyin cevabı alınamadı; yerel model bu sürümde devre dışı olduğu için statik başarı cevabı konuşulmadı.',
        quickReply: quickReply,
        metadata: <String, dynamic>{
          ...request.metadata,
          'route': 'api_first_no_authoritative_response',
          'fromLocalModel': false,
          'fromApi': false,
          'recoverySuppressed': true,
          'tts_source': 'blocked_non_ai_speech',
        },
      );
    } catch (e, stackTrace) {
      print('NOVA_AI_SERVICE_EXCEPTION type=${e.runtimeType} error=$e');
      print(stackTrace);
      return _strictLocalRescueResponse(
        request: request,
        quickReply: quickReply,
        normalizedPrompt: normalizedPrompt,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<AiResponse> _strictLocalRescueResponse({
    required AiRequest request,
    required String quickReply,
    required String normalizedPrompt,
    required Object error,
    required StackTrace stackTrace,
  }) async {
    final prompt = normalizedPrompt.trim().isEmpty
        ? 'Kullanıcıdan boş veya belirsiz sesli girdi geldi; Nova olarak kısa, doğal ve yardım etmeye hazır bir cevap kur.'
        : normalizedPrompt.trim();

    try {
      final rescueSource =
          request.metadata['sourceSystem']?.toString() ??
          request.metadata['source']?.toString() ??
          '';
      print(
        'NOVA_AI_API_RESCUE_START '
        'promptHash=${prompt.hashCode} origin=${request.requestOrigin} '
        'source=$rescueSource originalException=${error.runtimeType}',
      );

      final rescueRequest = AiRequest(
        prompt: prompt,
        mode: AiMode.apiOnly,
        internetAllowed: true,
        isResearchRequest: false,
        isSelfLearningRequest: false,
        isFastResponsePriority: request.isFastResponsePriority,
        isUserApprovedApiUsage: true,
        requestedByVoice: request.requestedByVoice,
        requestOrigin: request.requestOrigin.trim().isEmpty
            ? 'user_voice'
            : request.requestOrigin,
        userInitiated: request.userInitiated,
        userConfirmedThisAction: request.userConfirmedThisAction,
        activeProviderKey: request.activeProviderKey,
        activeModelId: request.activeModelId,
        metadata: <String, dynamic>{
          ...request.metadata,
          'conversationEntryAlreadyAdded': true,
          'aiChainRequired': true,
          'apiRescue': true,
          'localModelRescueSuppressed': true,
          'originalAiServiceExceptionType': error.runtimeType.toString(),
          'sourceSystem':
              request.metadata['sourceSystem']?.toString() ??
              'nova_ai_service_exception_api_rescue',
        },
      );

      final rescueResponse = await apiService.send(rescueRequest);

      if (!rescueResponse.isError &&
          rescueResponse.displayText.trim().isNotEmpty &&
          rescueResponse.hasApiBrainProof) {
        final text = _normalizeFinalText(rescueResponse.displayText);
        print(
          'NOVA_AI_API_RESCUE_SUCCESS '
          'chars=${text.length} promptHash=${prompt.hashCode}',
        );
        return rescueResponse.withApiBrainProofText(
          text.trim().isEmpty ? rescueResponse.displayText.trim() : text,
          quickReplyOverride: quickReply,
          extraMetadata: <String, dynamic>{
            ...request.metadata,
            ...rescueResponse.metadata,
            'route': 'api_exception_rescue',
            'responseSource': 'api_rescue',
            'aiOutputReturnedBeforeSideEffects': true,
            'originalAiServiceExceptionType': error.runtimeType.toString(),
          },
        );
      }

      print(
        'NOVA_AI_API_RESCUE_FAILED '
        'isError=${rescueResponse.isError} textChars=${rescueResponse.displayText.trim().length}',
      );
      return _buildErrorResponse(
        message: rescueResponse.displayText.trim().isNotEmpty
            ? rescueResponse.displayText.trim()
            : 'API beyin cevabı rescue hattında da üretilemedi.',
        quickReply: quickReply,
        metadata: <String, dynamic>{
          ...request.metadata,
          ...rescueResponse.metadata,
          'route': 'api_exception_rescue_failed',
          'originalAiServiceExceptionType': error.runtimeType.toString(),
          'tts_source': 'blocked_non_ai_speech',
        },
      );
    } catch (rescueError, rescueStackTrace) {
      print(
        'NOVA_AI_API_RESCUE_EXCEPTION type=${rescueError.runtimeType} error=$rescueError',
      );
      print(rescueStackTrace);
      return _buildErrorResponse(
        message:
            'API beyin rescue hattı da cevap üretemedi; statik başarı cevabı konuşulmadı.',
        quickReply: quickReply,
        metadata: <String, dynamic>{
          ...request.metadata,
          'route': 'api_exception_rescue_exception',
          'originalAiServiceExceptionType': error.runtimeType.toString(),
          'rescueExceptionType': rescueError.runtimeType.toString(),
          'tts_source': 'blocked_non_ai_speech',
        },
      );
    }
  }

  String _buildStrictLocalRescueSystemPrompt({
    required AiRequest request,
    required Object originalError,
  }) {
    final assistantName = persona.assistantName.trim().isEmpty
        ? 'Nova'
        : persona.assistantName.trim();
    return <String>[
      'NOVA STRICT LOCAL RESCUE:',
      'NovaAiService içinde yan servis/hafıza/observability hatası oluştu; bu hata kullanıcıya statik fallback olarak konuşulmayacak.',
      'Sen $assistantName olarak Gemini/OpenAI API beyin cevabını üret; yerel Gemma/LiteRT üretimi bu sürümde kapalıdır.',
      'Güvenlik hariç tüm davranış tek AI omurgasından geçer; cevap hazır metin, setup kabuğu veya dashboard status metni olamaz.',
      'Kullanıcı son sözünü doğrudan anla ve doğal Türkçe konuşma cevabı ver.',
      'Hata tipi: ${originalError.runtimeType}. Bu hata iç detaydır; kullanıcıya debug anlatma.',
      'İstek kökeni: ${request.requestOrigin}.',
    ].join('\n');
  }

  String _deriveTurnQueueLabel(AiRequest request) {
    final source = request.metadata['source']?.toString().trim();
    final origin = request.requestOrigin.trim();
    final prompt = request.prompt.trim();
    final hint = source != null && source.isNotEmpty
        ? source
        : (origin.isNotEmpty ? origin : 'ai_turn');
    return prompt.isEmpty ? hint : '$hint:${prompt.hashCode}';
  }

  Future<void> _rememberSuccessfulReply({
    required String prompt,
    required String reply,
    required String topicKey,
    required Map<String, dynamic> learningAnalysis,
    required Map<String, dynamic> understanding,
    required NovaPostTurnReflection turnReflection,
    required NovaStyleProfile styleProfile,
    required String relationshipLabel,
    required String speakerName,
    required double ownerConfidence,
    required double durationSeconds,
    required String route,
    required String contextMode,
    required double talkRatio,
    required String socialMode,
    NovaEmotionState? emotion,
  }) async {
    await _responseHistoryService.remember(reply);
    await _conversationSessionService.addNovaText(
      reply,
      fromVoiceFlow: true,
      topicKey: topicKey,
    );
    await _conversationContinuityService.rememberExchange(
      userText: prompt,
      novaReply: reply,
    );
    await _socialEnergyService.rememberTurn(userText: prompt, novaText: reply);
    await _emotionalMomentumService.evolve(
      dominantEmotion: emotion?.dominantEmotion ?? 'nötr',
      intensity: (((emotion?.empathyNeed ?? 0) + (emotion?.urgency ?? 0)) / 2)
          .clamp(0.0, 1.0),
    );
    await _internalStateService.applyReplyOutcome(
      reply: reply,
      wasLong: reply.length > 260,
      hadRepair: turnReflection.repairNeed >= 0.60,
    );
    await _conversationFocusService.rememberExchange(
      userText: prompt,
      novaReply: reply,
      learningRelevant: learningAnalysis['shouldStore'] as bool? ?? false,
      explicitlyPersistent: learningAnalysis['persistent'] as bool? ?? false,
    );
    final taskKey = _runtimeEfficiencyAnalyzer.deriveTaskKey(
      prompt: prompt,
      understanding: understanding,
      route: route,
    );
    final postTaskReflection = _postTaskReflectionService.evaluate(
      taskKey: taskKey,
      prompt: prompt,
      reply: reply,
      turnReflection: turnReflection,
      durationSeconds: durationSeconds,
      turnCount: 1,
      correctionCount: turnReflection.repairNeed >= 0.60 ? 1 : 0,
    );
    final commitDecision = _memoryCommitGate.decide(
      prompt: prompt,
      turnReflection: turnReflection,
      taskReflection: postTaskReflection,
      learningAnalysis: learningAnalysis,
      relationshipLabel: relationshipLabel,
    );
    final identityCommitAllowed = _novaIdentityMemoryCommitService
        .shouldPersist(
          speakerName: speakerName,
          relationshipLabel: relationshipLabel,
          styleConsistency: turnReflection.styleConsistency,
          ownerConfidence: ownerConfidence,
        );
    if (commitDecision.shouldPersistRelationship || identityCommitAllowed) {
      final currentProfile = await _relationshipRetrievalService.resolve(
        speakerName: speakerName,
        relationshipLabel: relationshipLabel,
        latestPrompt: prompt,
      );
      final evolvedProfile = _relationshipUpdatePolicy.evolve(
        current: currentProfile,
        latestPrompt: prompt,
        latestReply: reply,
        relationshipLabel: relationshipLabel,
        displayName: speakerName,
        reflection: turnReflection,
        ownerConfidence: ownerConfidence,
      );
      await _relationshipProfileStore.save(evolvedProfile);
      await _novaAutobiographicMemoryService.update(
        speakerKey: evolvedProfile.speakerKey,
        profile: evolvedProfile,
        prompt: prompt,
        reply: reply,
        reflection: turnReflection,
      );
    }
    final sharedWorldState = await _novaSharedWorldModelService.evolve(
      prompt: prompt,
      reply: reply,
      contextMode: contextMode,
      socialMode: socialMode,
    );
    if (commitDecision.shouldPersistExperience) {
      final taskExperience = NovaTaskExperience(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        taskKey: taskKey,
        speakerKey: _relationshipRetrievalService.speakerKeyFor(
          speakerName,
          relationshipLabel,
        ),
        strategySummary: postTaskReflection.summary,
        successfulSteps: _runtimeEfficiencyAnalyzer.preferredSteps(
          usedMemory: turnReflection.memoryValue >= 0.55,
          usedSkill: turnReflection.styleConsistency >= 0.62,
          askedClarifyingQuestion: turnReflection.repairNeed >= 0.60,
          keptShort: turnReflection.shouldStayShortNextTurn == false,
        ),
        wastedSteps: _runtimeEfficiencyAnalyzer.wastedSteps(
          tooLong: turnReflection.shouldStayShortNextTurn,
          tooManyQuestions: turnReflection.shouldReduceQuestionsNextTurn,
          repairNeeded: turnReflection.repairNeed >= 0.60,
        ),
        errorSignals: <String>[
          if (turnReflection.repairNeed >= 0.60) 'yanlış anlama riski',
          if (turnReflection.styleConsistency < 0.60) 'ton tutarsızlığı',
        ],
        durationSeconds: durationSeconds,
        firstResponseLatencySeconds: durationSeconds.clamp(0.0, 8.0),
        turnCount: 1,
        correctionCount: turnReflection.repairNeed >= 0.60 ? 1 : 0,
        unnecessaryQuestionCount: turnReflection.shouldReduceQuestionsNextTurn
            ? 1
            : 0,
        satisfactionSignal:
            ((turnReflection.voiceNaturalness * 0.45) +
                    (turnReflection.styleConsistency * 0.30) +
                    ((1.0 - turnReflection.interruptionRisk) * 0.25))
                .clamp(0.0, 1.0),
        createdAt: DateTime.now(),
      );
      await _taskExperienceStore.add(taskExperience);
      final existing = await _taskExperienceStore.byTaskKey(taskKey);
      if (commitDecision.shouldPromoteSkill) {
        final currentSkill = await _skillMemoryService.getByTaskKey(taskKey);
        final promoted = _strategyPromotionService.promote(
          taskKey: taskKey,
          existingExperiences: existing,
          latestExperience: taskExperience,
          reflection: postTaskReflection,
          currentCard: currentSkill,
        );
        if (promoted != null) {
          await _skillMemoryService.save(promoted);
        }
      }
    }
    final shouldPersistSemantically =
        commitDecision.shouldPersistSemanticSummary &&
        _shouldPersistSemanticEpisode(
          prompt: prompt,
          reply: reply,
          learningAnalysis: learningAnalysis,
          emotion: emotion,
        );
    if (shouldPersistSemantically) {
      await _semanticMemoryService.remember(
        topicKey: topicKey,
        summary: _buildSemanticSummary(prompt, reply),
        tags: <String>[
          learningAnalysis['domain']?.toString() ?? 'general',
          if (learningAnalysis['persistent'] as bool? ?? false) 'persistent',
          if (learningAnalysis['temporary'] as bool? ?? false) 'temporary',
          if (emotion?.dominantEmotion.trim().isNotEmpty == true)
            'emotion:${emotion!.dominantEmotion}',
          if (relationshipLabel.trim().isNotEmpty)
            'relation:$relationshipLabel',
          'world:${sharedWorldState.userMode}',
          'ambient:${sharedWorldState.ambientMode}',
        ],
        importance: _semanticImportanceForEpisode(
          prompt: prompt,
          reply: reply,
          learningAnalysis: learningAnalysis,
          emotion: emotion,
        ),
      );
      if (speakerName.trim().isNotEmpty) {
        await _semanticMemoryService.remember(
          topicKey: 'autobio:${speakerName.trim().toLowerCase()}',
          summary:
              'İlişki sürekliliği: $speakerName ile konuşma akışı $contextMode bağlamında ilerledi. Yarım kalan başlıklar ve ortak ton korunmalı.',
          tags: <String>[
            'autobiography',
            if (relationshipLabel.trim().isNotEmpty)
              'relation:$relationshipLabel',
            'speaker:${speakerName.trim().toLowerCase()}',
          ],
          importance: 0.84,
        );
      }
      final NovaContinuityCapsule continuityCapsule =
          _novaContinuityCapsuleService.build(
            speakerName: speakerName,
            relationshipLabel: relationshipLabel,
            contextMode: contextMode,
            topicKey: topicKey,
            prompt: prompt,
            reply: reply,
          );
      await _semanticMemoryService.remember(
        topicKey: continuityCapsule.topicKey,
        summary: continuityCapsule.summary,
        tags: continuityCapsule.tags,
        importance: continuityCapsule.importance,
      );
      await _semanticMemoryService.remember(
        topicKey: 'self_model:bounded_growth',
        summary: _novaSelfEvolutionService
            .build(
              durationSeconds: durationSeconds,
              shouldStayShortNextTurn: turnReflection.shouldStayShortNextTurn,
              shouldReduceQuestionsNextTurn:
                  turnReflection.shouldReduceQuestionsNextTurn,
            )
            .summary,
        tags: const <String>['self_model', 'bounded_growth', 'voice_first'],
        importance: 0.73,
      );
    }
  }

  String _derivePromptKind({
    required String thinkingIntent,
    required Map<String, dynamic> understanding,
  }) {
    final primaryIntent = (understanding['primaryIntent'] as String? ?? '')
        .trim()
        .toLowerCase();
    final explicitQuestion =
        understanding['explicitQuestion'] as bool? ?? false;
    if (thinkingIntent == 'command' || primaryIntent == 'eylem')
      return 'command';
    if (thinkingIntent == 'memory' || primaryIntent == 'hafiza')
      return 'memory';
    if (explicitQuestion || primaryIntent == 'soru') return 'question';
    return 'conversation';
  }

  double _deriveOwnerConfidence(Map<String, dynamic> metadata) {
    final raw = metadata['ownerConfidence'];
    if (raw is num) return raw.toDouble().clamp(0.0, 1.0);
    final level = (metadata['voiceAccessLevel']?.toString() ?? '')
        .trim()
        .toLowerCase();
    switch (level) {
      case 'owner':
        return 0.98;
      case 'authorizedguest':
      case 'authorized_guest':
        return 0.82;
      case 'familiar':
        return 0.64;
      case 'knownbutunauthorized':
      case 'known_but_unauthorized':
        return 0.36;
      case 'denied':
        return 0.12;
      default:
        return 0.50;
    }
  }

  String _deriveOwnerSignal(Map<String, dynamic> metadata) {
    final level = (metadata['voiceAccessLevel']?.toString() ?? '').trim();
    final speaker = (metadata['speakerName']?.toString() ?? '').trim();
    if (speaker.isNotEmpty && level.isNotEmpty) return '$level:$speaker';
    if (level.isNotEmpty) return level;
    if (speaker.isNotEmpty) return speaker;
    return 'unknown';
  }

  List<String> _deriveMemorySources({
    required int memoriesCount,
    required int semanticCount,
    required String conversationContext,
    required String adaptiveInstructionContext,
    required String cognitionContext,
  }) {
    final sources = <String>[];
    if (memoriesCount > 0) sources.add('memory_context');
    if (semanticCount > 0) sources.add('semantic_memory');
    if (conversationContext.trim().isNotEmpty)
      sources.add('conversation_session');
    if (adaptiveInstructionContext.trim().isNotEmpty)
      sources.add('adaptive_instruction');
    if (cognitionContext.trim().isNotEmpty) sources.add('cognition_engines');
    if (sources.isEmpty) sources.add('none');
    return sources;
  }

  String _buildQuickReply() {
    return '';
  }

  String _postProcessAuthoritativeLocalBrain(String rawText) {
    return rawText.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _normalizeFinalText(String rawText, {bool allowQuickPrefix = true}) {
    return rawText.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _startsWithNaturalLead(String text) {
    final trimmed = text.trim();
    return trimmed.startsWith(persona.primaryWakePhrase) ||
        trimmed.startsWith('Buyurun efendim.') ||
        trimmed.startsWith('Dinliyorum efendim.') ||
        trimmed.startsWith('Hemen bakıyorum efendim.') ||
        trimmed.startsWith('Anlıyorum') ||
        trimmed.startsWith('Şöyle') ||
        trimmed.startsWith('Bence') ||
        trimmed.startsWith('Haklısınız') ||
        trimmed.startsWith('İlk bakışta') ||
        trimmed.startsWith('Bunu');
  }

  bool _shouldPrefixQuickReply(String text) {
    final normalized = text.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    if (normalized.length <= 42) return true;
    if (normalized.split(RegExp(r'\s+')).length <= 5) return true;
    return false;
  }

  String _buildTurnManagerPrompt(NovaTurnDecision decision) {
    return [
      'TURN MANAGER:',
      '- aksiyon: ${decision.action.name}',
      '- kısa mı: ${decision.shouldKeepItShort}',
      '- genişletmeli mi: ${decision.shouldExpand}',
      '- önce aksiyon mu: ${decision.shouldActFirst}',
      '- sonra eski konuya dönmeli mi: ${decision.shouldReturnToPreviousTopic}',
      '- aksiyon sonrası sessizlik: ${decision.shouldStayQuietAfterAction}',
      '- önce empati mi: ${decision.shouldLeadWithEmpathy}',
      '- sonuç teyidi gerekli mi: ${decision.shouldConfirmActionOutcome}',
      '- ara görev/kesinti mi: ${decision.shouldTreatAsInterruption}',
      '- gerekçe: ${decision.reason}',
    ].join('\n');
  }

  String _buildDialoguePolicyPrompt(NovaDialoguePolicy policy) {
    return [
      'DIALOGUE POLICY:',
      '- birincil hareket: ${policy.primaryMove.name}',
      '- ikincil hareket: ${policy.secondaryMove?.name ?? 'yok'}',
      '- ton rehberi: ${policy.toneGuide}',
      '- mekanik dil baskılansın: ${policy.suppressMechanicalPhrases}',
      '- hafıza açık referans verilsin: ${policy.mentionMemory}',
      '- askıdaki konuya referans: ${policy.referencePausedTopic}',
      '- kısa seçenek sun: ${policy.offerBriefOptions}',
    ].join('\n');
  }

  String _buildRepairPrompt(NovaConversationRepairResult repairResult) {
    return [
      'REPAIR LOOP:',
      '- onarım gerekli: ${repairResult.shouldRepair}',
      '- önceki yorum geri alınmalı: ${repairResult.retractPreviousInterpretation}',
      if ((repairResult.repairSummary as String).isNotEmpty)
        '- özet: ${repairResult.repairSummary}',
      if ((repairResult.replacementInstruction as String).isNotEmpty)
        '- yeni yol: ${repairResult.replacementInstruction}',
    ].join('\n');
  }

  String _buildRecoveryReply({
    required String prompt,
    required Map<String, dynamic> understanding,
    required String emotionDominant,
    required bool dueToModelError,
  }) {
    // Recovery fallback speech is disabled. If model/API generation fails, the
    // caller must return a non-speakable error/status, not a canned Nova reply.
    return '';
  }


  String _buildSemanticSummary(String prompt, String reply) {
    final user = prompt.trim();
    final ai = reply.trim();
    if (user.isEmpty) return ai;
    if (ai.isEmpty) return user;
    return 'Kullanıcı: $user | Nova: $ai';
  }

  AiResponse _buildErrorResponse({
    required String message,
    required String quickReply,
    required Map<String, dynamic> metadata,
  }) {
    return AiResponse.error(
      message: message.trim().isEmpty
          ? 'Beklenmeyen bir hata oluştu.'
          : message.trim(),
      quickReply: quickReply,
      metadata: metadata,
    );
  }

  bool _shouldPersistSemanticEpisode({
    required String prompt,
    required String reply,
    required Map<String, dynamic> learningAnalysis,
    NovaEmotionState? emotion,
  }) {
    final normalizedPrompt = prompt.trim().toLowerCase();
    final normalizedReply = reply.trim().toLowerCase();
    if (normalizedPrompt.isEmpty || normalizedReply.isEmpty) return false;

    final persistent = learningAnalysis['persistent'] as bool? ?? false;
    final temporary = learningAnalysis['temporary'] as bool? ?? false;
    final explicitTeaching =
        learningAnalysis['explicitTeaching'] as bool? ?? false;

    if (persistent || temporary || explicitTeaching) return true;

    final explicitRecall =
        normalizedPrompt.contains('hatırla') ||
        normalizedPrompt.contains('hatirla') ||
        normalizedPrompt.contains('geçen gün') ||
        normalizedPrompt.contains('gecen gun') ||
        normalizedPrompt.contains('geçen sefer') ||
        normalizedPrompt.contains('gecen sefer') ||
        normalizedPrompt.contains('unutma') ||
        normalizedPrompt.contains('bundan sonra');
    if (explicitRecall) return true;

    final followUpMemoryCue =
        normalizedReply.contains('sonra geri döneyim mi') ||
        normalizedReply.contains('kaldığımız yere döneyim mi') ||
        normalizedReply.contains('bunu geçici mi kalıcı mı tutayım') ||
        normalizedReply.contains('geçici mi kalıcı mı');
    if (followUpMemoryCue) return true;

    final emotionallyImportant =
        (emotion?.frustrationTrend ?? 0) >= 0.58 ||
        (emotion?.empathyNeed ?? 0) >= 0.52 ||
        (emotion?.urgency ?? 0) >= 0.62;
    if (emotionallyImportant && normalizedPrompt.split(' ').length >= 9) {
      return true;
    }

    final longTaskLikePrompt =
        normalizedPrompt.split(' ').length >= 18 &&
        (normalizedPrompt.contains('ara') ||
            normalizedPrompt.contains('hatırlat') ||
            normalizedPrompt.contains('hatirlat') ||
            normalizedPrompt.contains('sonra') ||
            normalizedPrompt.contains('geri dön') ||
            normalizedPrompt.contains('geri don') ||
            normalizedPrompt.contains('plan') ||
            normalizedPrompt.contains('özet') ||
            normalizedPrompt.contains('ozet'));
    if (longTaskLikePrompt) return true;

    return false;
  }

  String _fitPromptSection(String raw, int maxChars, String label) {
    final text = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty || maxChars <= 0) return '';
    final safeLabel = label.trim().isEmpty ? 'bağlam' : label.trim();
    final limit = maxChars < 24 ? 24 : maxChars;
    final fitted = text.length <= limit
        ? text
        : '${text.substring(0, limit).trimRight()}…';
    return '[$safeLabel] $fitted';
  }

  double _semanticImportanceForEpisode({
    required String prompt,
    required String reply,
    required Map<String, dynamic> learningAnalysis,
    NovaEmotionState? emotion,
  }) {
    var score = 0.38;
    if (learningAnalysis['persistent'] as bool? ?? false) score += 0.34;
    if (learningAnalysis['temporary'] as bool? ?? false) score += 0.18;
    if (learningAnalysis['explicitTeaching'] as bool? ?? false) score += 0.20;
    score += ((emotion?.empathyNeed ?? 0) * 0.12);
    score += ((emotion?.urgency ?? 0) * 0.10);
    score += ((emotion?.frustrationTrend ?? 0) * 0.08);
    if (prompt.trim().split(' ').length >= 12) score += 0.06;
    if (prompt.trim().split(' ').length >= 20) score += 0.05;
    if (reply.trim().split(' ').length >= 18) score += 0.03;
    return score.clamp(0.0, 0.96);
  }

  bool _looksLikeLearningIntent(String input) {
    final String lowered = input.trim().toLowerCase();
    if (lowered.isEmpty) return false;
    const hints = <String>[
      'öğren',
      'bunu böyle yap',
      'bundan sonra',
      'şöyle davran',
      'hafızana al',
      'remember this behavior',
      'learn this',
      'from now on',
    ];
    for (final String hint in hints) {
      if (lowered.contains(hint)) {
        return true;
      }
    }
    return false;
  }
}
