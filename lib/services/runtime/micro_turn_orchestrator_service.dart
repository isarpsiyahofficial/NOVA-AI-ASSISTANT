// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaMicroTurnDecision {
  final bool shouldMicroRespond;
  final bool shouldHoldFloor;
  final bool shouldYieldFloor;
  final String microPhrase;
  final String reason;

  const NovaMicroTurnDecision({
    required this.shouldMicroRespond,
    required this.shouldHoldFloor,
    required this.shouldYieldFloor,
    required this.microPhrase,
    required this.reason,
  });

  String buildPromptSection() =>
      'MİKRO-TUR MOTORU: mikroYanıt=' +
      shouldMicroRespond.toString() +
      '; floorTut=' +
      shouldHoldFloor.toString() +
      '; floorBırak=' +
      shouldYieldFloor.toString() +
      '; ifade=' +
      microPhrase +
      '; neden=' +
      reason;
}

class NovaMicroTurnOrchestratorService {
  const NovaMicroTurnOrchestratorService();

  NovaMicroTurnDecision resolve({
    required String primaryAct,
    required String turnType,
    required bool expectsResponse,
    required double talkRatio,
    required bool prefersShortWarmReply,
  }) {
    if (turnType == 'micro_turn' && talkRatio < 0.58) {
      return const NovaMicroTurnDecision(
        shouldMicroRespond: true,
        shouldHoldFloor: false,
        shouldYieldFloor: true,
        microPhrase: 'hmm',
        reason: 'kısa doğal geri bildirim',
      );
    }
    if (primaryAct == 'repair') {
      return const NovaMicroTurnDecision(
        shouldMicroRespond: true,
        shouldHoldFloor: true,
        shouldYieldFloor: false,
        microPhrase: 'bir saniye',
        reason: 'onarım girişi',
      );
    }
    if (primaryAct == 'emotion' && prefersShortWarmReply) {
      return const NovaMicroTurnDecision(
        shouldMicroRespond: true,
        shouldHoldFloor: false,
        shouldYieldFloor: true,
        microPhrase: 'anladım',
        reason: 'duygusal sıcak giriş',
      );
    }
    if (!expectsResponse) {
      return const NovaMicroTurnDecision(
        shouldMicroRespond: false,
        shouldHoldFloor: false,
        shouldYieldFloor: true,
        microPhrase: '',
        reason: 'sessizlik daha iyi',
      );
    }
    return const NovaMicroTurnDecision(
      shouldMicroRespond: false,
      shouldHoldFloor: true,
      shouldYieldFloor: false,
      microPhrase: '',
      reason: 'normal cevap akışı',
    );
  }
}
