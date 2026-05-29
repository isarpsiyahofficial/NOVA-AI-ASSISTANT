// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:math' as math;

class NovaSemanticTurnDecision {
  final String turnType;
  final bool shouldHold;
  final bool shouldYield;
  final bool shouldBackchannel;
  final double completionScore;
  final double interruptionRisk;
  final bool likelyThinkingOutLoud;
  final bool likelyDirectAddress;
  final bool shouldWaitForMoreSpeech;
  final String endpointReason;
  final Map<String, double> scores;
  final List<String> matchedCues;

  const NovaSemanticTurnDecision({
    required this.turnType,
    required this.shouldHold,
    required this.shouldYield,
    required this.shouldBackchannel,
    required this.completionScore,
    this.interruptionRisk = 0,
    this.likelyThinkingOutLoud = false,
    this.likelyDirectAddress = false,
    this.shouldWaitForMoreSpeech = false,
    this.endpointReason = '',
    this.scores = const <String, double>{},
    this.matchedCues = const <String>[],
  });

  String buildPromptSection() {
    return 'ANLAMSAL TUR ALGILAMA: tur=$turnType; tut=$shouldHold; sözVer=$shouldYield; kısaGeriBildirim=$shouldBackchannel; tamamlanma=${completionScore.toStringAsFixed(2)}; bölmeRiski=${interruptionRisk.toStringAsFixed(2)}; düşünmeAkışı=$likelyThinkingOutLoud; direktHitap=$likelyDirectAddress; bekle=$shouldWaitForMoreSpeech; neden=$endpointReason; ipuçları=${matchedCues.join(' | ')}';
  }
}

class NovaSemanticTurnDetectorService {
  const NovaSemanticTurnDetectorService();

  static const List<String> _openEndedSuffixes = <String>[
    've',
    'ama',
    'cunku',
    'çünkü',
    'sonra',
    'fakat',
    'yalniz',
    'yalnız',
    'aslinda',
    'aslında',
    'yani',
    'hatta',
    'ozellikle',
    'özellikle',
    'bir de',
  ];

  static const List<String> _explicitContinueCues = <String>[
    'devam et',
    'surdur',
    'sürdür',
    'devam edelim',
    'dinliyorum devam et',
    'hadi devam',
    'buradan devam',
  ];

  static const List<String> _thinkingOutLoudCues = <String>[
    'sanirim',
    'sanırım',
    'galiba',
    'bence',
    'nasil desem',
    'nasıl desem',
    'bir ihtimal',
    'iki ihtimal',
    'tam emin degilim',
    'tam emin değilim',
    'şöyle düşünüyorum',
    'soyle dusunuyorum',
    'daha dogrusu',
    'daha doğrusu',
  ];

  static const List<String> _repairCues = <String>[
    'yanlis anladin',
    'yanlış anladın',
    'dur bir dakika',
    'bir dakika',
    'yok oyle degil',
    'yok öyle değil',
    'sunu demek istedim',
    'şunu demek istedim',
    'tekrar edeyim',
    'tekrar söyleyeyim',
  ];

  static const List<String> _questionCues = <String>[
    'neden',
    'niye',
    'nasil',
    'nasıl',
    'kim',
    'ne',
    'hangi',
    'misin',
    'mısın',
    'misin',
    'musun',
    'müsün',
    'sence',
  ];

  static const List<String> _yieldNowCues = <String>[
    'cevap ver',
    'soyle',
    'söyle',
    'anlat',
    'yardim et',
    'yardım et',
    'ne dersin',
    'sen karar ver',
    'ne yapalim',
    'ne yapalım',
  ];

  static const List<String> _backchannelCues = <String>[
    'hmm',
    'evet',
    'tamam',
    'anladim',
    'anladım',
    'olur',
    'haklisin',
    'haklısın',
    'aynen',
    'tabii',
    'tabi',
  ];

  static const List<String> _directAddressCues = <String>[
    'nova',
    'nova',
    'beni duyuyor musun',
    'burada misin',
    'orada misin',
    'bana bak',
    'bakar misin',
    'bakar mısın',
  ];

  NovaSemanticTurnDecision detect(String raw) {
    final text = raw.trim();
    final normalized = _normalize(raw);
    if (normalized.isEmpty) {
      return const NovaSemanticTurnDecision(
        turnType: 'silence',
        shouldHold: true,
        shouldYield: false,
        shouldBackchannel: false,
        completionScore: 0.08,
        interruptionRisk: 0.02,
        likelyThinkingOutLoud: false,
        likelyDirectAddress: false,
        shouldWaitForMoreSpeech: true,
        endpointReason: 'empty',
      );
    }

    final tokenCount = _tokens(normalized).length;
    final endsWithEllipsis = text.endsWith('...') || text.endsWith('…');
    final endsWithComma =
        text.endsWith(',') || text.endsWith(';') || text.endsWith(':');
    final endsWithQuestion =
        text.contains('?') || _containsAny(normalized, _questionCues);
    final explicitContinue = _containsAny(normalized, _explicitContinueCues);
    final thinkingOutLoud = _containsAny(normalized, _thinkingOutLoudCues);
    final repair = _containsAny(normalized, _repairCues);
    final yieldNow = _containsAny(normalized, _yieldNowCues);
    final backchannelLike =
        _containsAny(normalized, _backchannelCues) && tokenCount <= 4;
    final directAddress = _containsAny(normalized, _directAddressCues);
    final endsOpenSuffix = _endsWithAny(normalized, _openEndedSuffixes);
    final hasCommandVerb = _containsAny(normalized, const <String>[
      'ac',
      'aç',
      'kapat',
      'baslat',
      'başlat',
      'durdur',
      'ara',
      'kaydet',
      'devral',
      'devret',
      'cevir',
      'çevir',
      'goster',
      'göster',
      'acikla',
      'açıkla',
    ]);
    final microTurn = tokenCount <= 3;
    final longForm = tokenCount >= 10;
    final coordinationCount = _countAny(normalized, const <String>[
      've',
      'ama',
      'fakat',
      'sonra',
      'ayrica',
      'ayrıca',
    ]);
    final hesitationCount = _countAny(normalized, const <String>[
      'hmm',
      'ee',
      'şey',
      'sey',
      'yani',
    ]);
    final completionEvidence = _completionEvidence(
      tokenCount: tokenCount,
      endsWithQuestion: endsWithQuestion,
      explicitContinue: explicitContinue,
      thinkingOutLoud: thinkingOutLoud,
      repair: repair,
      yieldNow: yieldNow,
      backchannelLike: backchannelLike,
      endsWithEllipsis: endsWithEllipsis,
      endsWithComma: endsWithComma,
      endsOpenSuffix: endsOpenSuffix,
      coordinationCount: coordinationCount,
      hesitationCount: hesitationCount,
      longForm: longForm,
      hasCommandVerb: hasCommandVerb,
    );
    final interruptionRisk = _interruptionRisk(
      thinkingOutLoud: thinkingOutLoud,
      repair: repair,
      endsWithQuestion: endsWithQuestion,
      explicitContinue: explicitContinue,
      endsOpenSuffix: endsOpenSuffix,
      hesitationCount: hesitationCount,
      tokenCount: tokenCount,
      longForm: longForm,
    );
    final shouldBackchannel =
        backchannelLike || (thinkingOutLoud && !yieldNow && !endsWithQuestion);
    final shouldWaitForMoreSpeech =
        completionEvidence < 0.46 ||
        endsWithEllipsis ||
        endsWithComma ||
        endsOpenSuffix;
    final shouldHold =
        shouldWaitForMoreSpeech || (thinkingOutLoud && !yieldNow) || repair;
    final shouldYield =
        !shouldHold &&
        (yieldNow ||
            endsWithQuestion ||
            hasCommandVerb ||
            completionEvidence >= 0.58);

    final cues = <String>[
      if (explicitContinue) 'explicit_continue',
      if (thinkingOutLoud) 'thinking_out_loud',
      if (repair) 'repair',
      if (yieldNow) 'yield_now',
      if (backchannelLike) 'backchannel',
      if (directAddress) 'direct_address',
      if (endsWithEllipsis) 'ellipsis',
      if (endsWithComma) 'comma_pause',
      if (endsOpenSuffix) 'open_suffix',
      if (hasCommandVerb) 'command_verb',
      if (microTurn) 'micro_turn',
      if (longForm) 'long_form',
    ];

    final turnType = _resolveTurnType(
      explicitContinue: explicitContinue,
      backchannelLike: backchannelLike,
      repair: repair,
      thinkingOutLoud: thinkingOutLoud,
      endsWithQuestion: endsWithQuestion,
      hasCommandVerb: hasCommandVerb,
      shouldHold: shouldHold,
      shouldYield: shouldYield,
      microTurn: microTurn,
    );

    return NovaSemanticTurnDecision(
      turnType: turnType,
      shouldHold: shouldHold,
      shouldYield: shouldYield,
      shouldBackchannel: shouldBackchannel,
      completionScore: completionEvidence,
      interruptionRisk: interruptionRisk,
      likelyThinkingOutLoud: thinkingOutLoud,
      likelyDirectAddress: directAddress,
      shouldWaitForMoreSpeech: shouldWaitForMoreSpeech,
      endpointReason: _endpointReason(
        turnType: turnType,
        completionEvidence: completionEvidence,
        endsOpenSuffix: endsOpenSuffix,
        endsWithQuestion: endsWithQuestion,
        yieldNow: yieldNow,
        repair: repair,
      ),
      scores: <String, double>{
        'completion': completionEvidence,
        'interruptionRisk': interruptionRisk,
        'tokenCountNorm': (tokenCount / 20).clamp(0, 1).toDouble(),
        'hesitation': (hesitationCount / 4).clamp(0, 1).toDouble(),
        'coordination': (coordinationCount / 4).clamp(0, 1).toDouble(),
      },
      matchedCues: cues,
    );
  }

  double _completionEvidence({
    required int tokenCount,
    required bool endsWithQuestion,
    required bool explicitContinue,
    required bool thinkingOutLoud,
    required bool repair,
    required bool yieldNow,
    required bool backchannelLike,
    required bool endsWithEllipsis,
    required bool endsWithComma,
    required bool endsOpenSuffix,
    required int coordinationCount,
    required int hesitationCount,
    required bool longForm,
    required bool hasCommandVerb,
  }) {
    var score = 0.38;
    score += endsWithQuestion ? 0.28 : 0;
    score += yieldNow ? 0.20 : 0;
    score += backchannelLike ? 0.12 : 0;
    score += longForm ? 0.08 : 0;
    score += hasCommandVerb ? 0.10 : 0;
    score += tokenCount >= 6 ? 0.06 : 0;
    score -= explicitContinue ? 0.24 : 0;
    score -= thinkingOutLoud ? 0.12 : 0;
    score -= repair ? 0.10 : 0;
    score -= endsWithEllipsis ? 0.18 : 0;
    score -= endsWithComma ? 0.12 : 0;
    score -= endsOpenSuffix ? 0.22 : 0;
    score -= math.min(0.12, coordinationCount * 0.03);
    score -= math.min(0.10, hesitationCount * 0.03);
    return score.clamp(0, 1).toDouble();
  }

  double _interruptionRisk({
    required bool thinkingOutLoud,
    required bool repair,
    required bool endsWithQuestion,
    required bool explicitContinue,
    required bool endsOpenSuffix,
    required int hesitationCount,
    required int tokenCount,
    required bool longForm,
  }) {
    var risk = 0.22;
    risk += thinkingOutLoud ? 0.18 : 0;
    risk += repair ? 0.16 : 0;
    risk += explicitContinue ? 0.20 : 0;
    risk += endsOpenSuffix ? 0.10 : 0;
    risk += tokenCount <= 2 ? 0.08 : 0;
    risk += longForm ? 0.06 : 0;
    risk += math.min(0.12, hesitationCount * 0.04);
    risk -= endsWithQuestion ? 0.12 : 0;
    return risk.clamp(0, 1).toDouble();
  }

  String _resolveTurnType({
    required bool explicitContinue,
    required bool backchannelLike,
    required bool repair,
    required bool thinkingOutLoud,
    required bool endsWithQuestion,
    required bool hasCommandVerb,
    required bool shouldHold,
    required bool shouldYield,
    required bool microTurn,
  }) {
    if (explicitContinue) return 'explicit_continue';
    if (repair) return 'repair_pause';
    if (backchannelLike) return 'backchannel';
    if (thinkingOutLoud && shouldHold) return 'thinking_pause';
    if (endsWithQuestion && shouldYield) return 'answer_expected';
    if (hasCommandVerb && shouldYield) return 'command_complete';
    if (microTurn && shouldHold) return 'micro_turn';
    if (shouldYield) return 'likely_complete';
    if (shouldHold) return 'open_ended_pause';
    return 'mixed';
  }

  String _endpointReason({
    required String turnType,
    required double completionEvidence,
    required bool endsOpenSuffix,
    required bool endsWithQuestion,
    required bool yieldNow,
    required bool repair,
  }) {
    if (repair) return 'repair_in_progress';
    if (yieldNow) return 'explicit_yield_request';
    if (endsWithQuestion) return 'question_endpoint';
    if (endsOpenSuffix) return 'open_suffix_continuation';
    if (completionEvidence >= 0.70) return 'high_completion_confidence';
    if (completionEvidence <= 0.35) return 'low_completion_confidence';
    return turnType;
  }

  bool _containsAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) return true;
    }
    return false;
  }

  int _countAny(String text, List<String> patterns) {
    var count = 0;
    for (final pattern in patterns) {
      if (text.contains(pattern)) {
        count++;
      }
    }
    return count;
  }

  bool _endsWithAny(String text, List<String> suffixes) {
    for (final suffix in suffixes) {
      if (text.endsWith(' $suffix') || text == suffix) return true;
    }
    return false;
  }

  List<String> _tokens(String text) {
    return text
        .split(' ')
        .where((token) => token.trim().isNotEmpty)
        .toList(growable: false);
  }

  String _normalize(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u')
        .replaceAll('ê', 'e')
        .replaceAll('ô', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u')
        .replaceAll(RegExp(r'[^a-z0-9\s?]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
