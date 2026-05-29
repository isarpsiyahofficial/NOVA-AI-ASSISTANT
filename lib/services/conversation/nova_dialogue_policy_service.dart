// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/cognition/nova_emotion_state.dart';
import '../../core/conversation/nova_conversation_repair_result.dart';
import '../../core/conversation/nova_conversation_state_snapshot.dart';
import '../../core/conversation/nova_dialogue_policy.dart';
import '../../core/conversation/nova_turn_decision.dart';
import '../../core/runtime/nova_style_profile.dart';

class NovaDialoguePolicyService {
  const NovaDialoguePolicyService();

  NovaDialoguePolicy resolve({
    required NovaTurnDecision turnDecision,
    required NovaEmotionState emotion,
    required NovaStyleProfile styleProfile,
    NovaConversationStateSnapshot? stateSnapshot,
    NovaConversationRepairResult? repairResult,
  }) {
    final hasPausedTopic = stateSnapshot?.returnTopic.trim().isNotEmpty == true;
    final inRepair = repairResult?.shouldRepair == true;

    if (inRepair) {
      return NovaDialoguePolicy(
        primaryMove: NovaDialogueMove.clarify,
        secondaryMove: NovaDialogueMove.guide,
        toneGuide:
            '${styleProfile.toneGuide} | kısa özür, doğru anlamı tekrar et, sonra yeni yola geç.',
        mentionMemory: false,
        referencePausedTopic: false,
        offerBriefOptions: false,
      );
    }

    if (emotion.empathyNeed > 0.40 || turnDecision.shouldLeadWithEmpathy) {
      return NovaDialoguePolicy(
        primaryMove: NovaDialogueMove.validateThenSolve,
        secondaryMove: turnDecision.shouldActFirst
            ? NovaDialogueMove.actQuietly
            : NovaDialogueMove.reassure,
        toneGuide:
            '${styleProfile.toneGuide} | önce duyguyu kabul et, sonra çöz.',
        mentionMemory: turnDecision.shouldReturnToPreviousTopic,
        referencePausedTopic: hasPausedTopic,
        offerBriefOptions: emotion.stability < 0.42,
      );
    }

    if (emotion.frustrationTrend > 0.46) {
      return NovaDialoguePolicy(
        primaryMove: turnDecision.shouldActFirst
            ? NovaDialogueMove.actQuietly
            : NovaDialogueMove.inform,
        secondaryMove: NovaDialogueMove.reassure,
        toneGuide:
            '${styleProfile.toneGuide} | mekanik dil kullanma, kısa rahatlatma ekle.',
        mentionMemory: turnDecision.shouldReturnToPreviousTopic,
        referencePausedTopic: hasPausedTopic,
        offerBriefOptions: true,
      );
    }

    switch (turnDecision.action) {
      case NovaTurnAction.askClarifyingQuestion:
        return NovaDialoguePolicy(
          primaryMove: NovaDialogueMove.clarify,
          secondaryMove: NovaDialogueMove.guide,
          toneGuide:
              '${styleProfile.toneGuide} | tek net soru sor, kullanıcıyı yorma.',
          referencePausedTopic: hasPausedTopic,
        );
      case NovaTurnAction.askFollowUpQuestion:
        return NovaDialoguePolicy(
          primaryMove: NovaDialogueMove.followUp,
          secondaryMove: NovaDialogueMove.inform,
          toneGuide:
              '${styleProfile.toneGuide} | sohbeti canlı tut ama baskı kurma.',
          mentionMemory: turnDecision.shouldReturnToPreviousTopic,
          referencePausedTopic: hasPausedTopic,
        );
      case NovaTurnAction.actSilently:
        return NovaDialoguePolicy(
          primaryMove: NovaDialogueMove.actQuietly,
          secondaryMove: turnDecision.shouldStayQuietAfterAction
              ? null
              : NovaDialogueMove.inform,
          toneGuide:
              '${styleProfile.toneGuide} | kısa teyit ver ya da sessiz aksiyon al.',
          referencePausedTopic: turnDecision.shouldReturnToPreviousTopic,
        );
      case NovaTurnAction.acknowledgeAndAct:
        return NovaDialoguePolicy(
          primaryMove: NovaDialogueMove.actQuietly,
          secondaryMove: NovaDialogueMove.inform,
          toneGuide:
              '${styleProfile.toneGuide} | komutu aldığını insani dille belli et.',
          mentionMemory: turnDecision.shouldReturnToPreviousTopic,
          referencePausedTopic: hasPausedTopic,
          offerBriefOptions: false,
        );
      case NovaTurnAction.explainLimitation:
        return NovaDialoguePolicy(
          primaryMove: NovaDialogueMove.inform,
          secondaryMove: NovaDialogueMove.guide,
          toneGuide:
              '${styleProfile.toneGuide} | dürüst açıkla, sonra çıkış yolu ver.',
          offerBriefOptions: true,
        );
      case NovaTurnAction.answer:
        return NovaDialoguePolicy(
          primaryMove: emotion.urgency > 0.34
              ? NovaDialogueMove.inform
              : NovaDialogueMove.guide,
          secondaryMove: turnDecision.shouldReturnToPreviousTopic
              ? NovaDialogueMove.followUp
              : (emotion.trustComfort > 0.52
                    ? NovaDialogueMove.reassure
                    : NovaDialogueMove.inform),
          toneGuide:
              '${styleProfile.toneGuide} | mekanik kalıp yerine doğal cevap seç.',
          mentionMemory: turnDecision.shouldReturnToPreviousTopic,
          referencePausedTopic: hasPausedTopic,
          offerBriefOptions: emotion.urgency > 0.46,
        );
    }
  }
}
