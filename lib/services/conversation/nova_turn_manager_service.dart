// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/cognition/nova_emotion_state.dart';
import '../../core/conversation/nova_conversation_state_snapshot.dart';
import '../../core/conversation/nova_turn_decision.dart';
import '../../core/runtime/nova_user_model.dart';

class NovaTurnManagerService {
  const NovaTurnManagerService();

  NovaTurnDecision decide({
    required Map<String, dynamic> understanding,
    required NovaEmotionState emotion,
    NovaConversationStateSnapshot? stateSnapshot,
    NovaUserModel? userModel,
  }) {
    final primaryIntent = understanding['primaryIntent'] as String? ?? 'sohbet';
    final shouldClarify = understanding['shouldClarify'] as bool? ?? false;
    final shouldAskFollowUp =
        understanding['shouldAskFollowUp'] as bool? ?? false;
    final needsExplanation =
        understanding['needsExplanation'] as bool? ?? false;
    final repairSignal = understanding['repairSignal'] as bool? ?? false;
    final continuitySignal =
        understanding['continuitySignal'] as bool? ?? false;
    final explicitQuestion =
        understanding['explicitQuestion'] as bool? ?? false;
    final actionAfterEmotion =
        understanding['actionAfterEmotion'] as bool? ?? false;
    final interruptionSignal =
        understanding['interruptionSignal'] as bool? ?? false;
    final commandStrength =
        (understanding['commandStrength'] as double?) ?? 0.0;
    final emotionalWeight =
        (understanding['emotionalWeight'] as double?) ?? 0.0;
    final directness = (understanding['directness'] as double?) ?? 0.0;
    final confusion = (understanding['confusionLevel'] as double?) ?? 0.0;

    final highUrgency = emotion.urgency >= 0.42;
    final highEmpathyNeed =
        emotion.empathyNeed >= 0.34 || emotionalWeight >= 0.40;
    final heavyConfusion = confusion >= 0.38 || emotion.stability < 0.34;
    final hardCommand =
        primaryIntent == 'eylem' &&
        (commandStrength >= 0.34 || directness >= 0.42);
    final hasReturnTopic = stateSnapshot?.returnTopic.trim().isNotEmpty == true;
    final awaitingUser =
        stateSnapshot?.awaitingUserTopic.trim().isNotEmpty == true;
    final shouldReturn =
        continuitySignal ||
        actionAfterEmotion ||
        highEmpathyNeed ||
        hasReturnTopic;
    final lowConfirmationPreference =
        userModel?.prefersLowConfirmationForTrustedActions ?? true;
    final shouldLeadWithEmpathy =
        highEmpathyNeed ||
        (userModel?.valuesEmotionalAcknowledgement ?? false) &&
            emotion.intensity > 0.46;

    if (repairSignal) {
      return const NovaTurnDecision(
        action: NovaTurnAction.explainLimitation,
        shouldKeepItShort: true,
        shouldExpand: false,
        shouldActFirst: false,
        shouldReturnToPreviousTopic: false,
        shouldStayQuietAfterAction: false,
        shouldLeadWithEmpathy: true,
        shouldConfirmActionOutcome: false,
        shouldTreatAsInterruption: false,
        reason: 'Önce yanlış anlamayı düzelt.',
      );
    }

    if (shouldClarify || heavyConfusion || awaitingUser) {
      return NovaTurnDecision(
        action: NovaTurnAction.askClarifyingQuestion,
        shouldKeepItShort: true,
        shouldExpand: false,
        shouldActFirst: false,
        shouldReturnToPreviousTopic: shouldReturn,
        shouldStayQuietAfterAction: false,
        shouldLeadWithEmpathy: shouldLeadWithEmpathy,
        shouldConfirmActionOutcome: false,
        shouldTreatAsInterruption: interruptionSignal,
        reason: shouldClarify
            ? 'Belirsizlik yüksek.'
            : 'Konuşma akışı karışık; tek netleştirme sorusu gerekli.',
      );
    }

    if (hardCommand) {
      final silentAction =
          highUrgency &&
          !needsExplanation &&
          !highEmpathyNeed &&
          lowConfirmationPreference;
      return NovaTurnDecision(
        action: silentAction
            ? NovaTurnAction.actSilently
            : NovaTurnAction.acknowledgeAndAct,
        shouldKeepItShort: true,
        shouldExpand: false,
        shouldActFirst: true,
        shouldReturnToPreviousTopic: shouldReturn,
        shouldStayQuietAfterAction: silentAction,
        shouldLeadWithEmpathy: shouldLeadWithEmpathy && !silentAction,
        shouldConfirmActionOutcome: !silentAction,
        shouldTreatAsInterruption: interruptionSignal || hasReturnTopic,
        reason: highEmpathyNeed
            ? 'Komut var ama önce insanî teyit de önemli.'
            : 'Komut öncelikli, aksiyon öne alınmalı.',
      );
    }

    if (primaryIntent == 'duygusal' || highEmpathyNeed) {
      return NovaTurnDecision(
        action: shouldAskFollowUp
            ? NovaTurnAction.askFollowUpQuestion
            : NovaTurnAction.answer,
        shouldKeepItShort: false,
        shouldExpand: true,
        shouldActFirst: false,
        shouldReturnToPreviousTopic: continuitySignal || hasReturnTopic,
        shouldStayQuietAfterAction: false,
        shouldLeadWithEmpathy: true,
        shouldConfirmActionOutcome: false,
        shouldTreatAsInterruption: interruptionSignal,
        reason:
            'Önce anlaşıldığını hissettirme ve duygusal çerçeveleme gerekli.',
      );
    }

    if (primaryIntent == 'soru' || explicitQuestion) {
      return NovaTurnDecision(
        action: shouldAskFollowUp
            ? NovaTurnAction.askFollowUpQuestion
            : NovaTurnAction.answer,
        shouldKeepItShort: highUrgency,
        shouldExpand: !highUrgency,
        shouldActFirst: false,
        shouldReturnToPreviousTopic: shouldReturn,
        shouldStayQuietAfterAction: false,
        shouldLeadWithEmpathy: shouldLeadWithEmpathy && !highUrgency,
        shouldConfirmActionOutcome: false,
        shouldTreatAsInterruption: interruptionSignal,
        reason: 'Soru-cevap akışı.',
      );
    }

    if (primaryIntent == 'sohbet' &&
        shouldAskFollowUp &&
        emotion.trustComfort >= 0.42) {
      return NovaTurnDecision(
        action: NovaTurnAction.askFollowUpQuestion,
        shouldKeepItShort: false,
        shouldExpand: true,
        shouldActFirst: false,
        shouldReturnToPreviousTopic: shouldReturn,
        shouldStayQuietAfterAction: false,
        shouldLeadWithEmpathy: shouldLeadWithEmpathy,
        shouldConfirmActionOutcome: false,
        shouldTreatAsInterruption: interruptionSignal,
        reason: 'Doğal sohbeti sürdürmek için takip sorusu uygun.',
      );
    }

    return NovaTurnDecision(
      action: NovaTurnAction.answer,
      shouldKeepItShort: highUrgency && !highEmpathyNeed,
      shouldExpand: !highUrgency || highEmpathyNeed,
      shouldActFirst: false,
      shouldReturnToPreviousTopic: shouldReturn,
      shouldStayQuietAfterAction: false,
      shouldLeadWithEmpathy: shouldLeadWithEmpathy,
      shouldConfirmActionOutcome: false,
      shouldTreatAsInterruption: interruptionSignal,
      reason: 'Doğal sohbet ve bağlamlı cevap akışı.',
    );
  }
}
