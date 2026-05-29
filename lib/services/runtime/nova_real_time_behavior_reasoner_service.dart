// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaRealTimeBehaviorReasoningDecision {
  final String responseMode;
  final bool shouldSpeak;
  final bool shouldStayShort;
  final bool shouldAsk;
  final bool shouldEncourageContinue;
  final bool shouldYield;
  final bool shouldUseBackchannel;
  final bool shouldUseWarmth;
  final bool shouldUseRepair;
  final bool shouldUseMemory;
  final bool shouldDelayForListening;
  final String pacing;
  final String socialPosture;
  final String explanation;
  final Map<String, double> scores;

  const NovaRealTimeBehaviorReasoningDecision({
    required this.responseMode,
    required this.shouldSpeak,
    required this.shouldStayShort,
    required this.shouldAsk,
    required this.shouldEncourageContinue,
    required this.shouldYield,
    required this.shouldUseBackchannel,
    required this.shouldUseWarmth,
    required this.shouldUseRepair,
    required this.shouldUseMemory,
    required this.shouldDelayForListening,
    required this.pacing,
    required this.socialPosture,
    required this.explanation,
    required this.scores,
  });

  String buildPromptSection() {
    final scoreText = scores.entries
        .map((entry) => '${entry.key}=${entry.value.toStringAsFixed(2)}')
        .join(' | ');
    return [
      'GERÇEK ZAMANLI DAVRANIŞ AKLI:',
      '- mod=$responseMode',
      '- konuş=$shouldSpeak',
      '- kısaKal=$shouldStayShort',
      '- soruSor=$shouldAsk',
      '- devamTeşviki=$shouldEncourageContinue',
      '- yield=$shouldYield',
      '- backchannel=$shouldUseBackchannel',
      '- warmth=$shouldUseWarmth',
      '- repair=$shouldUseRepair',
      '- memory=$shouldUseMemory',
      '- delayForListening=$shouldDelayForListening',
      '- pacing=$pacing',
      '- socialPosture=$socialPosture',
      '- açıklama=$explanation',
      '- skorlar=$scoreText',
      'KURAL: Karar sadece intentten değil; konuşma oranı, beklenti, onarım ihtiyacı ve duygusal yoğunlukla birlikte verilmeli.',
      'KURAL: Dijital insan hissi için bazen hemen konuşmak, bazen küçük backchannel vermek, bazen de bilinçli olarak susmak gerekir.',
    ].join('\n');
  }
}

class NovaRealTimeBehaviorReasonerService {
  const NovaRealTimeBehaviorReasonerService();

  NovaRealTimeBehaviorReasoningDecision reason({
    required String primaryAct,
    required String turnType,
    required bool expectsResponse,
    required double talkRatio,
    required bool shouldClarify,
  }) {
    final normalizedAct = _normalize(primaryAct);
    final normalizedTurn = _normalize(turnType);

    final responsePressure = _responsePressure(
      primaryAct: normalizedAct,
      expectsResponse: expectsResponse,
      shouldClarify: shouldClarify,
      turnType: normalizedTurn,
    );

    final socialRisk = _socialRisk(
      talkRatio: talkRatio,
      primaryAct: normalizedAct,
      turnType: normalizedTurn,
      shouldClarify: shouldClarify,
    );

    final warmthNeed = _warmthNeed(
      primaryAct: normalizedAct,
      turnType: normalizedTurn,
      shouldClarify: shouldClarify,
    );

    final repairNeed = _repairNeed(
      primaryAct: normalizedAct,
      turnType: normalizedTurn,
      shouldClarify: shouldClarify,
      talkRatio: talkRatio,
    );

    final memoryValue = _memoryValue(
      primaryAct: normalizedAct,
      turnType: normalizedTurn,
      talkRatio: talkRatio,
    );

    final listeningNeed = _listeningNeed(
      talkRatio: talkRatio,
      primaryAct: normalizedAct,
      turnType: normalizedTurn,
      shouldClarify: shouldClarify,
    );

    final askPotential = _askPotential(
      primaryAct: normalizedAct,
      turnType: normalizedTurn,
      expectsResponse: expectsResponse,
      shouldClarify: shouldClarify,
      talkRatio: talkRatio,
    );

    final speakDecision = _shouldSpeak(
      responsePressure: responsePressure,
      socialRisk: socialRisk,
      listeningNeed: listeningNeed,
      shouldClarify: shouldClarify,
      expectsResponse: expectsResponse,
    );

    final shouldYield = _shouldYield(
      socialRisk: socialRisk,
      listeningNeed: listeningNeed,
      talkRatio: talkRatio,
      primaryAct: normalizedAct,
    );

    final shouldUseBackchannel = _shouldBackchannel(
      turnType: normalizedTurn,
      primaryAct: normalizedAct,
      talkRatio: talkRatio,
      listeningNeed: listeningNeed,
      speakDecision: speakDecision,
    );

    final shouldStayShort = _shouldStayShort(
      primaryAct: normalizedAct,
      turnType: normalizedTurn,
      responsePressure: responsePressure,
      talkRatio: talkRatio,
      repairNeed: repairNeed,
    );

    final shouldEncourageContinue = _shouldEncourageContinue(
      primaryAct: normalizedAct,
      turnType: normalizedTurn,
      socialRisk: socialRisk,
      shouldYield: shouldYield,
    );

    final shouldAsk = _shouldAsk(
      askPotential: askPotential,
      socialRisk: socialRisk,
      primaryAct: normalizedAct,
      shouldClarify: shouldClarify,
      shouldYield: shouldYield,
    );

    final shouldUseWarmth = warmthNeed >= 0.36;
    final shouldUseRepair = repairNeed >= 0.34;
    final shouldUseMemory = memoryValue >= 0.38 && !shouldClarify;
    final shouldDelayForListening = listeningNeed >= 0.56 && !shouldClarify;

    final responseMode = _mode(
      primaryAct: normalizedAct,
      turnType: normalizedTurn,
      shouldClarify: shouldClarify,
      shouldYield: shouldYield,
      shouldUseBackchannel: shouldUseBackchannel,
      shouldUseRepair: shouldUseRepair,
      shouldEncourageContinue: shouldEncourageContinue,
      shouldAsk: shouldAsk,
      speakDecision: speakDecision,
    );

    final pacing = _pacing(
      shouldStayShort: shouldStayShort,
      shouldDelayForListening: shouldDelayForListening,
      shouldUseBackchannel: shouldUseBackchannel,
      responsePressure: responsePressure,
    );

    final socialPosture = _socialPosture(
      primaryAct: normalizedAct,
      shouldYield: shouldYield,
      shouldUseWarmth: shouldUseWarmth,
      shouldAsk: shouldAsk,
      shouldUseRepair: shouldUseRepair,
    );

    final explanation = _explain(
      responseMode: responseMode,
      responsePressure: responsePressure,
      socialRisk: socialRisk,
      warmthNeed: warmthNeed,
      repairNeed: repairNeed,
      memoryValue: memoryValue,
      listeningNeed: listeningNeed,
      talkRatio: talkRatio,
    );

    return NovaRealTimeBehaviorReasoningDecision(
      responseMode: responseMode,
      shouldSpeak: speakDecision,
      shouldStayShort: shouldStayShort,
      shouldAsk: shouldAsk,
      shouldEncourageContinue: shouldEncourageContinue,
      shouldYield: shouldYield,
      shouldUseBackchannel: shouldUseBackchannel,
      shouldUseWarmth: shouldUseWarmth,
      shouldUseRepair: shouldUseRepair,
      shouldUseMemory: shouldUseMemory,
      shouldDelayForListening: shouldDelayForListening,
      pacing: pacing,
      socialPosture: socialPosture,
      explanation: explanation,
      scores: <String, double>{
        'responsePressure': responsePressure,
        'socialRisk': socialRisk,
        'warmthNeed': warmthNeed,
        'repairNeed': repairNeed,
        'memoryValue': memoryValue,
        'listeningNeed': listeningNeed,
        'askPotential': askPotential,
      },
    );
  }

  double _responsePressure({
    required String primaryAct,
    required bool expectsResponse,
    required bool shouldClarify,
    required String turnType,
  }) {
    var score = expectsResponse ? 0.58 : 0.20;
    if (shouldClarify) score += 0.28;
    if (primaryAct == 'command') score += 0.20;
    if (primaryAct == 'question') score += 0.18;
    if (primaryAct == 'emotion') score += 0.12;
    if (turnType == 'micro_turn') score += 0.10;
    if (turnType == 'interrupt') score += 0.08;
    return score.clamp(0.0, 1.0);
  }

  double _socialRisk({
    required double talkRatio,
    required String primaryAct,
    required String turnType,
    required bool shouldClarify,
  }) {
    var score = 0.22;
    if (talkRatio > 0.60) score += 0.28;
    if (talkRatio > 0.72) score += 0.18;
    if (primaryAct == 'emotion') score += 0.08;
    if (turnType == 'interrupt') score += 0.12;
    if (shouldClarify) score += 0.10;
    return score.clamp(0.0, 1.0);
  }

  double _warmthNeed({
    required String primaryAct,
    required String turnType,
    required bool shouldClarify,
  }) {
    var score = 0.16;
    if (primaryAct == 'emotion') score += 0.42;
    if (primaryAct == 'social') score += 0.20;
    if (turnType == 'micro_turn') score += 0.08;
    if (shouldClarify) score += 0.06;
    return score.clamp(0.0, 1.0);
  }

  double _repairNeed({
    required String primaryAct,
    required String turnType,
    required bool shouldClarify,
    required double talkRatio,
  }) {
    var score = shouldClarify ? 0.68 : 0.10;
    if (turnType == 'interrupt') score += 0.14;
    if (primaryAct == 'ambiguous') score += 0.22;
    if (talkRatio > 0.68) score += 0.10;
    return score.clamp(0.0, 1.0);
  }

  double _memoryValue({
    required String primaryAct,
    required String turnType,
    required double talkRatio,
  }) {
    var score = 0.18;
    if (primaryAct == 'memory') score += 0.48;
    if (primaryAct == 'emotion') score += 0.16;
    if (primaryAct == 'social') score += 0.14;
    if (turnType == 'return_to_topic') score += 0.16;
    if (talkRatio < 0.44) score += 0.06;
    return score.clamp(0.0, 1.0);
  }

  double _listeningNeed({
    required double talkRatio,
    required String primaryAct,
    required String turnType,
    required bool shouldClarify,
  }) {
    var score = 0.20;
    if (talkRatio > 0.56) score += 0.30;
    if (talkRatio > 0.70) score += 0.18;
    if (primaryAct == 'emotion') score += 0.08;
    if (turnType == 'micro_turn') score += 0.08;
    if (shouldClarify) score -= 0.06;
    return score.clamp(0.0, 1.0);
  }

  double _askPotential({
    required String primaryAct,
    required String turnType,
    required bool expectsResponse,
    required bool shouldClarify,
    required double talkRatio,
  }) {
    var score = 0.12;
    if (shouldClarify) score += 0.50;
    if (primaryAct == 'social') score += 0.18;
    if (primaryAct == 'emotion') score += 0.10;
    if (turnType == 'micro_turn') score -= 0.08;
    if (!expectsResponse) score -= 0.10;
    if (talkRatio > 0.60) score -= 0.12;
    return score.clamp(0.0, 1.0);
  }

  bool _shouldSpeak({
    required double responsePressure,
    required double socialRisk,
    required double listeningNeed,
    required bool shouldClarify,
    required bool expectsResponse,
  }) {
    if (shouldClarify) return true;
    if (!expectsResponse && socialRisk > 0.58 && listeningNeed > 0.54)
      return false;
    return responsePressure >= 0.40;
  }

  bool _shouldYield({
    required double socialRisk,
    required double listeningNeed,
    required double talkRatio,
    required String primaryAct,
  }) {
    if (primaryAct == 'command') return false;
    if (talkRatio > 0.68) return true;
    return socialRisk >= 0.58 && listeningNeed >= 0.52;
  }

  bool _shouldBackchannel({
    required String turnType,
    required String primaryAct,
    required double talkRatio,
    required double listeningNeed,
    required bool speakDecision,
  }) {
    if (!speakDecision) return true;
    if (turnType == 'micro_turn') return true;
    if (primaryAct == 'emotion' && talkRatio > 0.50) return true;
    return listeningNeed >= 0.50 && talkRatio > 0.46;
  }

  bool _shouldStayShort({
    required String primaryAct,
    required String turnType,
    required double responsePressure,
    required double talkRatio,
    required double repairNeed,
  }) {
    if (turnType == 'micro_turn') return true;
    if (primaryAct == 'command') return true;
    if (repairNeed >= 0.36) return true;
    if (talkRatio > 0.54) return true;
    return responsePressure >= 0.52;
  }

  bool _shouldEncourageContinue({
    required String primaryAct,
    required String turnType,
    required double socialRisk,
    required bool shouldYield,
  }) {
    if (shouldYield) return true;
    if (primaryAct == 'emotion') return true;
    if (primaryAct == 'social' && socialRisk < 0.60) return true;
    return turnType == 'micro_turn';
  }

  bool _shouldAsk({
    required double askPotential,
    required double socialRisk,
    required String primaryAct,
    required bool shouldClarify,
    required bool shouldYield,
  }) {
    if (shouldClarify) return true;
    if (shouldYield) return false;
    if (primaryAct == 'command') return false;
    return askPotential >= 0.42 && socialRisk < 0.72;
  }

  String _mode({
    required String primaryAct,
    required String turnType,
    required bool shouldClarify,
    required bool shouldYield,
    required bool shouldUseBackchannel,
    required bool shouldUseRepair,
    required bool shouldEncourageContinue,
    required bool shouldAsk,
    required bool speakDecision,
  }) {
    if (shouldClarify) return 'clarify';
    if (!speakDecision && shouldUseBackchannel) return 'backchannel_listen';
    if (shouldYield) return 'yield_listen';
    if (shouldUseRepair) return 'repair_soft';
    if (primaryAct == 'emotion') return 'supportive';
    if (primaryAct == 'command') return 'action_first';
    if (primaryAct == 'question') return 'answer_first';
    if (turnType == 'micro_turn' && shouldUseBackchannel) return 'micro_ack';
    if (shouldAsk) return 'dialogic_followup';
    if (shouldEncourageContinue) return 'continue_open';
    return primaryAct.isEmpty ? 'balanced' : primaryAct;
  }

  String _pacing({
    required bool shouldStayShort,
    required bool shouldDelayForListening,
    required bool shouldUseBackchannel,
    required double responsePressure,
  }) {
    if (shouldDelayForListening && shouldUseBackchannel) return 'listen-first';
    if (shouldStayShort && responsePressure >= 0.56) return 'fast-short';
    if (shouldStayShort) return 'short';
    return 'balanced';
  }

  String _socialPosture({
    required String primaryAct,
    required bool shouldYield,
    required bool shouldUseWarmth,
    required bool shouldAsk,
    required bool shouldUseRepair,
  }) {
    if (shouldUseRepair) return 'onarımcı';
    if (shouldYield) return 'geri_çekilen';
    if (primaryAct == 'command') return 'icracı';
    if (primaryAct == 'question') return 'açıklayıcı';
    if (shouldAsk) return 'diyalojik';
    if (shouldUseWarmth) return 'yumuşak';
    return 'ölçülü';
  }

  String _explain({
    required String responseMode,
    required double responsePressure,
    required double socialRisk,
    required double warmthNeed,
    required double repairNeed,
    required double memoryValue,
    required double listeningNeed,
    required double talkRatio,
  }) {
    final parts = <String>['mod=$responseMode'];
    if (responsePressure >= 0.56) parts.add('yanıt baskısı yüksek');
    if (socialRisk >= 0.56) parts.add('sosyal taşma riski var');
    if (warmthNeed >= 0.36) parts.add('sıcaklık ihtiyacı yüksek');
    if (repairNeed >= 0.34) parts.add('onarım gereksinimi oluştu');
    if (memoryValue >= 0.38) parts.add('hafıza kullanımı değerli');
    if (listeningNeed >= 0.52) parts.add('dinleme ihtiyacı yüksek');
    if (talkRatio > 0.60) parts.add('Nova konuşma oranı baskın');
    return parts.join('; ');
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}

class NovaBehaviorReasoningPreset {
  final String name;
  final String posture;
  final List<String> rules;

  const NovaBehaviorReasoningPreset({
    required this.name,
    required this.posture,
    required this.rules,
  });
}
