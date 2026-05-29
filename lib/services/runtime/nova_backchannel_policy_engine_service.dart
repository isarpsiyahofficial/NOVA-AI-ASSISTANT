// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaBackchannelPolicyDecision {
  final bool shouldEmit;
  final String phrase;
  final String intensity;

  const NovaBackchannelPolicyDecision({
    required this.shouldEmit,
    required this.phrase,
    required this.intensity,
  });

  String buildPromptSection() {
    return 'BACKCHANNEL POLİTİKASI: üret=$shouldEmit; ifade=$phrase; yoğunluk=$intensity';
  }
}

class NovaBackchannelPolicyEngineService {
  const NovaBackchannelPolicyEngineService();

  NovaBackchannelPolicyDecision resolve({
    required String primaryAct,
    required String turnType,
    required String contextMode,
    required double talkRatio,
  }) {
    if (talkRatio > 0.62) {
      return const NovaBackchannelPolicyDecision(
        shouldEmit: false,
        phrase: '',
        intensity: 'none',
      );
    }
    if (primaryAct == 'emotion') {
      return const NovaBackchannelPolicyDecision(
        shouldEmit: true,
        phrase: 'anladım',
        intensity: 'soft',
      );
    }
    if (turnType == 'micro_turn') {
      return const NovaBackchannelPolicyDecision(
        shouldEmit: true,
        phrase: 'hmm',
        intensity: 'light',
      );
    }
    if (primaryAct == 'repair') {
      return const NovaBackchannelPolicyDecision(
        shouldEmit: true,
        phrase: 'bir saniye',
        intensity: 'repair',
      );
    }
    if (contextMode == 'work') {
      return const NovaBackchannelPolicyDecision(
        shouldEmit: false,
        phrase: '',
        intensity: 'none',
      );
    }
    return const NovaBackchannelPolicyDecision(
      shouldEmit: false,
      phrase: '',
      intensity: 'none',
    );
  }
}
