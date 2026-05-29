// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'nova_speech_native_planner_service.dart';

class NovaSpeechNativePlannerV2Decision {
  final NovaSpeechNativePlannerDecision base;
  final bool preferMicroTurns;
  final bool preferStreamingStylePhrasing;
  final bool preferShortFirstThenExpand;
  final String latencyClass;

  const NovaSpeechNativePlannerV2Decision({
    required this.base,
    required this.preferMicroTurns,
    required this.preferStreamingStylePhrasing,
    required this.preferShortFirstThenExpand,
    required this.latencyClass,
  });

  String buildPromptSection() =>
      'SPEECH-NATIVE V2: mod=' +
      base.mode +
      '; mikroTur=' +
      preferMicroTurns.toString() +
      '; streamingDil=' +
      preferStreamingStylePhrasing.toString() +
      '; kısaSonraAç=' +
      preferShortFirstThenExpand.toString() +
      '; latency=' +
      latencyClass;
}

class NovaSpeechNativePlannerV2Service {
  const NovaSpeechNativePlannerV2Service();

  static const NovaSpeechNativePlannerService _base =
      NovaSpeechNativePlannerService();

  NovaSpeechNativePlannerV2Decision resolve({
    required String primaryAct,
    required String turnType,
    required String thinkingMode,
    required bool prefersShortWarmReply,
  }) {
    final base = _base.resolve(
      primaryAct: primaryAct,
      turnType: turnType,
      thinkingMode: thinkingMode,
    );
    final preferMicroTurns =
        turnType == 'micro_turn' || primaryAct == 'backchannel';
    final preferShortFirstThenExpand =
        thinkingMode == 'deepThink' ||
        primaryAct == 'repair' ||
        prefersShortWarmReply;
    final latencyClass = preferMicroTurns
        ? 'very_low'
        : (preferShortFirstThenExpand ? 'split' : 'normal');
    return NovaSpeechNativePlannerV2Decision(
      base: base,
      preferMicroTurns: preferMicroTurns,
      preferStreamingStylePhrasing: true,
      preferShortFirstThenExpand: preferShortFirstThenExpand,
      latencyClass: latencyClass,
    );
  }
}
