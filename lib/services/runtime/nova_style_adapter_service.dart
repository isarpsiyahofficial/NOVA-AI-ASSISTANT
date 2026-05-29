// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/cognition/nova_emotion_state.dart';
import '../../core/conversation/nova_conversation_state_snapshot.dart';
import '../../core/runtime/nova_style_profile.dart';
import '../../core/runtime/nova_user_model.dart';

class NovaStyleAdapterService {
  const NovaStyleAdapterService();

  NovaStyleProfile resolve({
    required NovaEmotionState emotion,
    required Map<String, dynamic> understanding,
    required NovaUserModel userModel,
    NovaConversationStateSnapshot? stateSnapshot,
  }) {
    final primaryIntent = understanding['primaryIntent'] as String? ?? 'sohbet';
    final explicitQuestion =
        understanding['explicitQuestion'] as bool? ?? false;
    final interruptionSignal =
        understanding['interruptionSignal'] as bool? ?? false;
    final hasReturnTopic = stateSnapshot?.returnTopic.trim().isNotEmpty == true;
    final isEmotional =
        primaryIntent == 'duygusal' || emotion.empathyNeed > 0.34;
    final shortPreferred =
        userModel.prefersShortTechnicalReplies && primaryIntent == 'eylem';
    final validationFirst =
        (userModel.wantsValidationBeforeSolution ||
            userModel.valuesEmotionalAcknowledgement) &&
        isEmotional;
    final frustrated = emotion.frustrationTrend >= 0.42;
    final urgent = emotion.urgency >= 0.40;
    final highWarmth = emotion.trustComfort >= 0.54;

    if (isEmotional) {
      return NovaStyleProfile(
        mode: 'destekleyici',
        toneGuide: validationFirst
            ? 'yumuşak, kısa nefesli, önce duyduğunu hissettiren sonra çözüm sunan; sesli okununca doğal akacak'
            : 'sıcak, sakin, düşük baskılı, cümle uzunluğunu duygusal yüke göre ayarlayan',
        shortAnswersPreferred: false,
        userNeedsValidationFirst: validationFirst,
        canUseHumor: false,
        shouldPrioritizeSolution: !validationFirst && urgent,
        shouldSoundHuman: true,
        shouldUseWarmTransitions: true,
        shouldAvoidCommandese: true,
      );
    }
    if (primaryIntent == 'eylem') {
      return NovaStyleProfile(
        mode: interruptionSignal || hasReturnTopic
            ? 'işlem+geri_dönüş'
            : 'icracı',
        toneGuide: shortPreferred
            ? 'voice-first kısa, net, teknik ama insani; gereksiz teyit yığma, iş bitince doğal dön'
            : 'net, güven verici, kısa teyitli, hızlı ama robotik olmayan; sözlü kullanım için akıcı',
        shortAnswersPreferred: true,
        userNeedsValidationFirst: false,
        canUseHumor: false,
        shouldPrioritizeSolution: true,
        shouldSoundHuman: true,
        shouldUseWarmTransitions: !urgent,
        shouldAvoidCommandese: true,
      );
    }
    if (primaryIntent == 'soru' || explicitQuestion) {
      return NovaStyleProfile(
        mode: frustrated ? 'sakin_açıklayıcı' : 'açıklayıcı',
        toneGuide: userModel.prefersDirectness
            ? 'doğrudan, anlaşılır, gereksiz süs yok; ama canlı ve konuşur gibi'
            : 'akıcı, anlaşılır, ilgili ve sesli cevapta rahat duyulan bir ritimde',
        shortAnswersPreferred:
            userModel.prefersShortTechnicalReplies && !hasReturnTopic,
        userNeedsValidationFirst: false,
        canUseHumor: false,
        shouldPrioritizeSolution: true,
        shouldSoundHuman: true,
        shouldUseWarmTransitions: !frustrated,
        shouldAvoidCommandese: true,
      );
    }
    return NovaStyleProfile(
      mode: userModel.prefersNaturalConversation ? 'sohbet' : 'kısa_sohbet',
      toneGuide: userModel.prefersDirectness
          ? 'doğal ama direkt, kısa groundinglerle insan gibi'
          : (highWarmth
                ? 'doğal, sıcak, uyumlu ve karşı tarafın temposuna yaklaşan'
                : 'doğal, akıcı, sakin ve konuşma sırasına saygılı'),
      shortAnswersPreferred:
          userModel.prefersShortTechnicalReplies &&
          !userModel.prefersNaturalConversation,
      userNeedsValidationFirst: false,
      canUseHumor: !frustrated && highWarmth,
      shouldPrioritizeSolution: false,
      shouldSoundHuman: true,
      shouldUseWarmTransitions: true,
      shouldAvoidCommandese: true,
    );
  }
}
