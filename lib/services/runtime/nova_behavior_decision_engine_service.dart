// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/runtime/nova_behavior_decision.dart';
import '../../core/runtime/nova_style_profile.dart';
import '../../core/runtime/nova_thinking_models.dart';
import '../../core/runtime/nova_internal_state.dart';
import 'nova_presence_engine_service.dart';
import 'nova_thinking_mode_classifier_service.dart';
import 'nova_initiative_scoring_service.dart';
import 'nova_dynamic_persona_service.dart';
import 'nova_silence_intelligence_service.dart';

class NovaBehaviorDecisionEngineService {
  final NovaPresenceEngineService _presenceEngineService;
  final NovaThinkingModeClassifierService _thinkingModeClassifierService;
  final NovaInitiativeScoringService _initiativeScoringService;
  final NovaDynamicPersonaService _dynamicPersonaService;
  final NovaSilenceIntelligenceService _silenceIntelligenceService;

  const NovaBehaviorDecisionEngineService({
    NovaPresenceEngineService presenceEngineService =
        const NovaPresenceEngineService(),
    NovaThinkingModeClassifierService thinkingModeClassifierService =
        const NovaThinkingModeClassifierService(),
    NovaInitiativeScoringService initiativeScoringService =
        const NovaInitiativeScoringService(),
    NovaDynamicPersonaService dynamicPersonaService =
        const NovaDynamicPersonaService(),
    NovaSilenceIntelligenceService silenceIntelligenceService =
        const NovaSilenceIntelligenceService(),
  }) : _presenceEngineService = presenceEngineService,
       _thinkingModeClassifierService = thinkingModeClassifierService,
       _initiativeScoringService = initiativeScoringService,
       _dynamicPersonaService = dynamicPersonaService,
       _silenceIntelligenceService = silenceIntelligenceService;

  NovaBehaviorDecision decide({
    required String prompt,
    required NovaThinkingSnapshot thinking,
    required NovaStyleProfile styleProfile,
    required NovaInternalState internalState,
    required Map<String, dynamic> understanding,
    required double empathyNeed,
    required double urgency,
    required double emotionalMomentum,
    required String relationshipLabel,
    required String socialMode,
    required String contextMode,
    required bool proactiveAllowed,
    required bool roomPresenceOpportunity,
    required double ownerConfidence,
    required int recentResponseCount,
    required double socialEnergyRatio,
  }) {
    final presenceScore = _presenceEngineService.score(
      prompt: prompt,
      socialMode: socialMode,
      proactiveAllowed: proactiveAllowed,
      roomPresenceOpportunity: roomPresenceOpportunity,
      conversationDrive: internalState.conversationDrive,
      ownerConfidence: ownerConfidence,
      recentResponseCount: recentResponseCount,
      socialOpenness: internalState.socialOpenness,
      fatigueLevel: internalState.fatigueLevel,
    );
    final silenceWeight = _presenceEngineService.silenceWeight(
      prompt: prompt,
      roomPresenceOpportunity: roomPresenceOpportunity,
      recentResponseCount: recentResponseCount,
      fatigueLevel: internalState.fatigueLevel,
    );
    final initiativeScore = _initiativeScoringService.score(
      prompt: prompt,
      proactiveAllowed: proactiveAllowed,
      roomPresenceOpportunity: roomPresenceOpportunity,
      relationshipLabel: relationshipLabel,
      socialMode: socialMode,
      empathyNeed: empathyNeed,
      recentResponseCount: recentResponseCount,
      socialEnergyRatio: socialEnergyRatio,
    );
    final thinkingMode = _thinkingModeClassifierService.classify(
      prompt: prompt,
      thinking: thinking,
      understanding: understanding,
      empathyNeed: empathyNeed,
    );
    final persona = _dynamicPersonaService.resolve(
      relationshipLabel: relationshipLabel,
      styleMode: styleProfile.mode,
      empathyNeed: empathyNeed,
      urgency: urgency,
      shortAnswersPreferred: styleProfile.shortAnswersPreferred,
      canUseHumor: styleProfile.canUseHumor,
      emotionalMomentum: emotionalMomentum,
      contextMode: contextMode,
    );

    final silenceState = _silenceIntelligenceService.classify(
      prompt: prompt,
      roomPresenceOpportunity: roomPresenceOpportunity,
      recentResponseCount: recentResponseCount,
      shouldClarify: understanding['shouldClarify'] as bool? ?? false,
    );

    final shouldInitiate =
        proactiveAllowed &&
        roomPresenceOpportunity &&
        initiativeScore >= 0.54 &&
        socialEnergyRatio < 0.64;
    final shouldWaitSilently =
        !thinking.shouldStayEngaged &&
        silenceWeight >= 0.64 &&
        !shouldInitiate &&
        prompt.trim().isEmpty;
    final shouldSpeak =
        !shouldWaitSilently ||
        thinking.shouldStayEngaged ||
        prompt.trim().isNotEmpty;
    final shouldUseControlledImperfection =
        thinkingMode != NovaThinkingMode.instant && presenceScore >= 0.34;
    final shouldUseMicroReaction =
        empathyNeed >= 0.32 ||
        thinking.intent == NovaInteractionIntent.conversation;
    final shouldUseThinkingOutLoud =
        thinkingMode != NovaThinkingMode.instant &&
        contextMode != 'iş modu' &&
        !styleProfile.shortAnswersPreferred;
    final shouldPreferSoftRepair =
        understanding['shouldClarify'] as bool? ?? false;
    final shouldUseMetaAwareness =
        styleProfile.shouldSoundHuman && socialEnergyRatio >= 0.58;
    final talkBalanceState = socialEnergyRatio >= 0.62
        ? 'nova baskın'
        : socialEnergyRatio <= 0.32
        ? 'nova pasif'
        : 'dengeli';
    final moodBand = internalState.fatigueLevel >= 0.66
        ? 'yorgun ama kontrollü'
        : internalState.energyLevel >= 0.72
        ? 'canlı'
        : 'dengeli';

    return NovaBehaviorDecision(
      shouldSpeak: shouldSpeak,
      shouldInitiate: shouldInitiate,
      shouldWaitSilently: shouldWaitSilently,
      shouldUseControlledImperfection: shouldUseControlledImperfection,
      shouldUseMicroReaction: shouldUseMicroReaction,
      shouldUseThinkingOutLoud: shouldUseThinkingOutLoud,
      shouldPreferSoftRepair: shouldPreferSoftRepair,
      shouldUseMetaAwareness: shouldUseMetaAwareness,
      thinkingMode: thinkingMode,
      responseShape: persona.responseShape,
      initiativeStyle: shouldInitiate
          ? 'küçük ve doğal katkı'
          : 'bekle-gözle sonra cevap ver',
      dynamicWarmth: persona.warmth,
      dynamicFormality: persona.formality,
      contextMode: contextMode,
      silenceState: silenceState,
      talkBalanceState: talkBalanceState,
      moodBand: moodBand,
      presenceScore: presenceScore,
      initiativeScore: initiativeScore,
      silenceWeight: silenceWeight,
      socialEnergyRatio: socialEnergyRatio,
    );
  }
}
