// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaSpeechNativePlannerDecision {
  final String mode;
  final bool preferPartialPlan;
  final bool preferFastAck;
  final bool preferBargeInRespect;

  const NovaSpeechNativePlannerDecision({
    required this.mode,
    required this.preferPartialPlan,
    required this.preferFastAck,
    required this.preferBargeInRespect,
  });

  String buildPromptSection() {
    return 'SPEECH-NATIVE PLANLAYICI: mod=$mode; kısmiPlan=$preferPartialPlan; hızlıAck=$preferFastAck; bargeInSaygı=$preferBargeInRespect';
  }
}

class NovaSpeechNativePlannerService {
  const NovaSpeechNativePlannerService();

  NovaSpeechNativePlannerDecision resolve({
    required String primaryAct,
    required String turnType,
    required String thinkingMode,
  }) {
    if (primaryAct == 'repair') {
      return const NovaSpeechNativePlannerDecision(
        mode: 'repair_fast',
        preferPartialPlan: true,
        preferFastAck: true,
        preferBargeInRespect: true,
      );
    }
    if (thinkingMode == 'deepThink') {
      return const NovaSpeechNativePlannerDecision(
        mode: 'two_stage',
        preferPartialPlan: true,
        preferFastAck: true,
        preferBargeInRespect: true,
      );
    }
    if (turnType == 'micro_turn') {
      return const NovaSpeechNativePlannerDecision(
        mode: 'micro',
        preferPartialPlan: true,
        preferFastAck: true,
        preferBargeInRespect: true,
      );
    }
    return const NovaSpeechNativePlannerDecision(
      mode: 'standard_voice_first',
      preferPartialPlan: false,
      preferFastAck: false,
      preferBargeInRespect: true,
    );
  }
}
