// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaDuplexTurnPlannerService {
  const NovaDuplexTurnPlannerService();

  static const List<String> _yieldingSignals = <String>[
    'hmm',
    'şey',
    'evet',
    'tamam',
    'anladım',
    'bak',
    'şimdi',
    'yani',
    'aslında',
    'dur',
    'bir şey diyeceğim',
    'bir saniye',
    'hemen',
    'hayır',
    'yok',
    'ama',
    'fakat',
    'peki',
    'sence',
    'sonra',
    'daha sonra',
    'önce',
    'şunu',
    'bunu',
    'bence',
  ];

  static const List<String> _floorHoldingSignals = <String>[
    'devam edeyim',
    'bitirmedim',
    'daha var',
    'şunu da ekleyeyim',
    'bir nokta daha',
    'burada kritik olan',
    'esas mesele',
    'özeti şu',
    'şu yüzden',
    'çünkü',
    'o yüzden',
    'şuraya geleceğim',
    'son cümlem',
    'bitiriyorum',
    'şimdi toparlıyorum',
    'bir örnek vereyim',
    'iki şey var',
    'üç nokta var',
    'bu kısım önemli',
    'hemen bağlıyorum',
  ];

  static const List<String> _backchannelInvites = <String>[
    'değil mi',
    'tamam mı',
    'anlatabildim mi',
    'anlaşıldı mı',
    'sence',
    'haklı mıyım',
    'bak mesela',
    'gibi',
    'şey gibi',
    'hani',
    'evet mi',
    'olur mu',
  ];

  static const List<String> _interruptionRecoveryPhrases = <String>[];

  String buildPromptSection({
    required String contextMode,
    required String socialMode,
  }) {
    // Duplex/turn-taking policy is runtime metadata only. Do not inject
    // interruption/backchannel phrases into model prompts.
    return '';
  }

  NovaDuplexTurnPlan planDuplexPolicy({
    required String contextMode,
    required String socialMode,
    required String latestPrompt,
    required String partialTranscript,
    required bool ttsActive,
    required int promptTokenCount,
    required double latencyPressure,
    required double interruptionRisk,
    required bool speechFirst,
  }) {
    final normalizedPrompt = _normalize(latestPrompt);
    final normalizedPartial = _normalize(partialTranscript);
    final combined = '$normalizedPrompt $normalizedPartial'.trim();

    final yieldScore = _cueScore(combined, _yieldingSignals);
    final holdScore = _cueScore(combined, _floorHoldingSignals);
    final inviteScore = _cueScore(combined, _backchannelInvites);
    final questionScore = _questionLikeScore(combined);
    final commandScore = _commandLikeScore(combined);
    final emotionalScore = _emotionalHoldScore(combined);
    final contextTightness = _contextTightness(contextMode, socialMode);
    final overlapTolerance = _overlapTolerance(
      contextTightness: contextTightness,
      latencyPressure: latencyPressure,
      interruptionRisk: interruptionRisk,
      inviteScore: inviteScore,
      ttsActive: ttsActive,
      speechFirst: speechFirst,
    );

    final turnRegime = _chooseTurnRegime(
      contextMode: contextMode,
      socialMode: socialMode,
      overlapTolerance: overlapTolerance,
      emotionalScore: emotionalScore,
      commandScore: commandScore,
    );

    final entryStrategy = _chooseEntryStrategy(
      promptTokenCount: promptTokenCount,
      yieldScore: yieldScore,
      holdScore: holdScore,
      inviteScore: inviteScore,
      questionScore: questionScore,
      emotionalScore: emotionalScore,
      latencyPressure: latencyPressure,
    );

    final floorPolicy = _chooseFloorPolicy(
      yieldScore: yieldScore,
      holdScore: holdScore,
      emotionalScore: emotionalScore,
      questionScore: questionScore,
      partialTranscript: normalizedPartial,
    );

    final interruptionPolicy = _chooseInterruptionPolicy(
      ttsActive: ttsActive,
      interruptionRisk: interruptionRisk,
      overlapTolerance: overlapTolerance,
      holdScore: holdScore,
      yieldScore: yieldScore,
    );

    final latencyBias = _chooseLatencyBias(
      latencyPressure: latencyPressure,
      promptTokenCount: promptTokenCount,
      speechFirst: speechFirst,
      contextMode: contextMode,
    );

    final chunkingPolicy = _chooseChunkingPolicy(
      promptTokenCount: promptTokenCount,
      emotionalScore: emotionalScore,
      commandScore: commandScore,
      overlapTolerance: overlapTolerance,
      contextMode: contextMode,
    );

    final openers = _recommendedOpeners(
      entryStrategy: entryStrategy,
      socialMode: socialMode,
      contextMode: contextMode,
      emotionalScore: emotionalScore,
      commandScore: commandScore,
      questionScore: questionScore,
    );

    final closers = _recommendedClosers(
      floorPolicy: floorPolicy,
      interruptionPolicy: interruptionPolicy,
      contextMode: contextMode,
      socialMode: socialMode,
    );

    return NovaDuplexTurnPlan(
      turnRegime: turnRegime,
      entryStrategy: entryStrategy,
      floorPolicy: floorPolicy,
      interruptionPolicy: interruptionPolicy,
      latencyBias: latencyBias,
      overlapTolerance: overlapTolerance,
      chunkingPolicy: chunkingPolicy,
      recommendedOpeners: openers,
      recommendedClosers: closers,
      yieldScore: yieldScore,
      holdScore: holdScore,
      inviteScore: inviteScore,
      questionScore: questionScore,
      commandScore: commandScore,
      emotionalScore: emotionalScore,
      contextTightness: contextTightness,
    );
  }

  List<String> interruptionRecoveryPhrases() {
    return List<String>.from(_interruptionRecoveryPhrases);
  }

  String explainDecision(NovaDuplexTurnPlan plan) {
    final reasons = <String>[];
    if (plan.overlapTolerance < 0.30) {
      reasons.add('bağlam sıkı olduğu için overlap toleransı düşük tutuldu');
    } else if (plan.overlapTolerance > 0.58) {
      reasons.add(
        'sohbet/davet sinyali yüksek olduğu için hafif overlap açıldı',
      );
    }
    if (plan.yieldScore > plan.holdScore) {
      reasons.add('kullanıcı floor bırakmaya daha yakın görünüyor');
    } else if (plan.holdScore > plan.yieldScore) {
      reasons.add('kullanıcı sözünü sürdürmek istiyor olabilir');
    }
    if (plan.commandScore > 0.58) {
      reasons.add(
        'komut/amaç yoğunluğu yüksek olduğu için erken net giriş seçildi',
      );
    }
    if (plan.emotionalScore > 0.55) {
      reasons.add(
        'duygusal içerik nedeniyle daha yumuşak giriş ve daha sık dinleme penceresi ayrıldı',
      );
    }
    if (reasons.isEmpty) {
      reasons.add('varsayılan güvenli duplex politikası kullanıldı');
    }
    return reasons.join('; ');
  }

  String _renderPolicyMatrix(NovaDuplexTurnPlan plan) {
    final lines = <String>[
      'DUAL SIGNAL MATRIX:',
      '- yieldScore=${plan.yieldScore.toStringAsFixed(2)}',
      '- holdScore=${plan.holdScore.toStringAsFixed(2)}',
      '- inviteScore=${plan.inviteScore.toStringAsFixed(2)}',
      '- questionScore=${plan.questionScore.toStringAsFixed(2)}',
      '- commandScore=${plan.commandScore.toStringAsFixed(2)}',
      '- emotionalScore=${plan.emotionalScore.toStringAsFixed(2)}',
      '- contextTightness=${plan.contextTightness.toStringAsFixed(2)}',
      'KURAL: yield < hold ise mikro tepkiyle floor alma, yalnızca dinleme ve çok kısa onay uygula.',
      'KURAL: invite yüksek ama question düşükse backchannel ihtimali düşün; açıklamayı devralma.',
      'KURAL: command yüksek ve hold düşükse erken kısa giriş uygundur.',
      'KURAL: emotional yüksekse overlap olsa bile ses tonu yumuşak, cümleler kısa olmalı.',
    ];
    return lines.join('\n');
  }

  String _renderTimingGuide(NovaDuplexTurnPlan plan) {
    final shortStart = plan.latencyBias.contains('çok düşük') ? 180 : 320;
    final normalStart = plan.latencyBias.contains('erken') ? 260 : 420;
    final safeGap = plan.overlapTolerance < 0.30 ? 650 : 420;
    return [
      'TIMING GUIDE:',
      '- ultra kısa giriş penceresi: ~${shortStart}ms',
      '- normal giriş penceresi: ~${normalStart}ms',
      '- güvenli sessiz boşluk: ~${safeGap}ms',
      'KURAL: İlk hece gecikmeden gelsin ama tüm yanıt tek blok olmasın.',
      'KURAL: Giriş yaptıktan sonra ikinci blok için kullanıcıyı tekrar dinleyebilecek mikropencere bırak.',
      'KURAL: Sessizlik uzun sürüyorsa kaybolmuş gibi değil, destekleyici ama kısa yeniden giriş yap.',
    ].join('\n');
  }

  String _renderOverlapGuide(NovaDuplexTurnPlan plan) {
    final bucket = plan.overlapTolerance < 0.25
        ? 'çok düşük overlap'
        : plan.overlapTolerance < 0.45
        ? 'düşük overlap'
        : plan.overlapTolerance < 0.62
        ? 'ölçülü overlap'
        : 'esnek overlap';
    return [
      'OVERLAP GUIDE:',
      '- profil: $bucket',
      '- izinli ilk blok uzunluğu: ${_firstChunkWordBudget(plan)} kelime',
      '- önerilen kapanış tarzı: ${plan.recommendedClosers.take(2).join(' | ')}',
      'KURAL: Overlap izinli olsa bile kullanıcı baskın hissediyorsa geri çekil.',
      'KURAL: “değil mi / tamam mı / hani” gibi sinyalleri tam davet sanmadan önce soru yapısı ve ton birlikte okunmalı.',
      'KURAL: Çağrı veya yüksek riskte sentetik monologdan kaçın; soru-cevap mikro adımlarla ilerle.',
    ].join('\n');
  }

  int _firstChunkWordBudget(NovaDuplexTurnPlan plan) {
    if (plan.chunkingPolicy.contains('mikro')) return 4;
    if (plan.chunkingPolicy.contains('iki blok')) return 9;
    if (plan.chunkingPolicy.contains('üç blok')) return 12;
    return 7;
  }

  String _chooseTurnRegime({
    required String contextMode,
    required String socialMode,
    required double overlapTolerance,
    required double emotionalScore,
    required double commandScore,
  }) {
    final c = _normalize(contextMode);
    final s = _normalize(socialMode);
    if (c.contains('çağrı') || c.contains('call')) return 'call-safe duplex';
    if (c.contains('iş') || s.contains('task')) return 'task-duplex';
    if (commandScore > 0.60) return 'directive duplex';
    if (emotionalScore > 0.58) return 'comfort duplex';
    if (overlapTolerance > 0.58) return 'fluid social duplex';
    if (overlapTolerance < 0.26) return 'listen-priority duplex';
    return 'balanced duplex';
  }

  String _chooseEntryStrategy({
    required int promptTokenCount,
    required double yieldScore,
    required double holdScore,
    required double inviteScore,
    required double questionScore,
    required double emotionalScore,
    required double latencyPressure,
  }) {
    if (holdScore > 0.62 && yieldScore < 0.40) return 'wait-and-ack';
    if (emotionalScore > 0.65) return 'soft-empathic-entry';
    if (questionScore > 0.60) return 'answer-ready-entry';
    if (latencyPressure > 0.72 && promptTokenCount <= 10)
      return 'fast-minimal-entry';
    if (inviteScore > 0.58) return 'micro-join-entry';
    if (promptTokenCount <= 5) return 'micro-entry';
    if (promptTokenCount <= 14) return 'short-breath-entry';
    return 'staged-entry';
  }

  String _chooseFloorPolicy({
    required double yieldScore,
    required double holdScore,
    required double emotionalScore,
    required double questionScore,
    required String partialTranscript,
  }) {
    if (partialTranscript.trim().isNotEmpty && holdScore > 0.58) {
      return 'defer-floor';
    }
    if (yieldScore > 0.62 && questionScore > 0.45) {
      return 'take-floor-answer';
    }
    if (emotionalScore > 0.58 && yieldScore >= holdScore) {
      return 'take-floor-softly';
    }
    if (holdScore >= yieldScore) {
      return 'keep-user-floor';
    }
    return 'balanced-floor';
  }

  String _chooseInterruptionPolicy({
    required bool ttsActive,
    required double interruptionRisk,
    required double overlapTolerance,
    required double holdScore,
    required double yieldScore,
  }) {
    if (!ttsActive) return 'no-active-tts';
    if (interruptionRisk > 0.70 || holdScore > 0.62) return 'abort-fast';
    if (overlapTolerance < 0.28) return 'abort-immediately';
    if (yieldScore > 0.55 && interruptionRisk < 0.45)
      return 'soft-yield-and-resume';
    return 'pause-check-resume';
  }

  String _chooseLatencyBias({
    required double latencyPressure,
    required int promptTokenCount,
    required bool speechFirst,
    required String contextMode,
  }) {
    final context = _normalize(contextMode);
    if (context.contains('çağrı') || context.contains('call'))
      return 'çok düşük gecikme / erken hece';
    if (latencyPressure > 0.72 && speechFirst)
      return 'çok düşük gecikme / erken başla';
    if (promptTokenCount <= 8 && speechFirst)
      return 'düşük gecikme / doğal hızlı giriş';
    if (promptTokenCount >= 24)
      return 'kademeli başlat / bloklar halinde sürdür';
    return 'dengeli gecikme';
  }

  String _chooseChunkingPolicy({
    required int promptTokenCount,
    required double emotionalScore,
    required double commandScore,
    required double overlapTolerance,
    required String contextMode,
  }) {
    final context = _normalize(contextMode);
    if (context.contains('çağrı')) return 'mikro bloklar';
    if (commandScore > 0.60) return 'iki blok / cevap + doğrulama';
    if (emotionalScore > 0.58) return 'üç yumuşak blok';
    if (promptTokenCount >= 20) return 'çok bloklu kademeli akış';
    if (overlapTolerance > 0.56) return 'iki kısa blok';
    return 'tek kısa blok + dinleme penceresi';
  }

  List<String> _recommendedOpeners({
    required String entryStrategy,
    required String socialMode,
    required String contextMode,
    required double emotionalScore,
    required double commandScore,
    required double questionScore,
  }) {
    final lines = <String>[];
    if (entryStrategy == 'soft-empathic-entry') {
      lines.addAll(const <String>[
        'Anladım.',
        'Tamam, buradayım.',
        'Sakin sakin bakalım.',
      ]);
    }
    if (entryStrategy == 'fast-minimal-entry') {
      lines.addAll(const <String>['Tamam.', 'Oldu.', 'Hemen.']);
    }
    if (entryStrategy == 'answer-ready-entry') {
      lines.addAll(const <String>[
        'Şöyle.',
        'Kısa cevapla başlayayım.',
        'Net tarafı şu.',
      ]);
    }
    if (_normalize(contextMode).contains('iş')) {
      lines.addAll(const <String>[
        'Özetle şöyle.',
        'Net tarafı şu.',
        'Kısa çerçeve çizeyim.',
      ]);
    }
    if (_normalize(socialMode).contains('chat')) {
      lines.addAll(const <String>['Hmm, evet.', 'Haklısın.', 'Bence şöyle.']);
    }
    if (commandScore > 0.60) {
      lines.addAll(const <String>[
        'Tamam, yapalım.',
        'Oldu, şöyle ilerleyelim.',
        'Şunu uygulayacağım.',
      ]);
    }
    if (questionScore > 0.60) {
      lines.addAll(const <String>[
        'Cevaplayayım.',
        'Şöyle anlatayım.',
        'Net anlatayım.',
      ]);
    }
    if (emotionalScore > 0.58) {
      lines.addAll(const <String>[
        'Anlıyorum.',
        'Bu kısmı dikkatli ele alayım.',
        'Burada yumuşak gideyim.',
      ]);
    }
    if (lines.isEmpty) {
      lines.addAll(const <String>['Tamam.', 'Evet.', 'Şöyle.']);
    }
    return _unique(lines, limit: 10);
  }

  List<String> _recommendedClosers({
    required String floorPolicy,
    required String interruptionPolicy,
    required String contextMode,
    required String socialMode,
  }) {
    final out = <String>[];
    if (floorPolicy == 'keep-user-floor') {
      out.addAll(const <String>[
        'Buyur devam et.',
        'Seni dinliyorum.',
        'Burada durayım, sende kalayım.',
      ]);
    } else {
      out.addAll(const <String>[
        'İstersen bunu açarım.',
        'Buradan devam edebilirim.',
        'Gerekirse bunu daraltırım.',
      ]);
    }
    if (interruptionPolicy.contains('abort')) {
      out.addAll(const <String>[
        'Araya girdiğinde hemen dururum.',
        'Sözünü aldığım anda bırakırım.',
      ]);
    }
    if (_normalize(contextMode).contains('çağrı')) {
      out.add('Kısa tutup sende bırakayım.');
    }
    if (_normalize(socialMode).contains('chat')) {
      out.add('İstersen buradan birlikte yürütelim.');
    }
    return _unique(out, limit: 10);
  }

  double _contextTightness(String contextMode, String socialMode) {
    final c = _normalize(contextMode);
    final s = _normalize(socialMode);
    var score = 0.40;
    if (c.contains('çağrı') || c.contains('call')) score += 0.28;
    if (c.contains('iş')) score += 0.22;
    if (c.contains('başkaları')) score += 0.12;
    if (s.contains('task')) score += 0.14;
    if (s.contains('chat') || s.contains('sohbet')) score -= 0.10;
    return score.clamp(0.0, 1.0);
  }

  double _overlapTolerance({
    required double contextTightness,
    required double latencyPressure,
    required double interruptionRisk,
    required double inviteScore,
    required bool ttsActive,
    required bool speechFirst,
  }) {
    var score = 0.48;
    score -= contextTightness * 0.34;
    score -= interruptionRisk * 0.28;
    score += inviteScore * 0.24;
    score += latencyPressure * (speechFirst ? 0.10 : 0.04);
    if (ttsActive) score -= 0.08;
    return score.clamp(0.08, 0.82);
  }

  double _cueScore(String text, List<String> cues) {
    if (text.trim().isEmpty) return 0.0;
    var hits = 0;
    for (final cue in cues) {
      if (text.contains(cue)) hits += 1;
    }
    final density = hits / cues.length;
    final scaled = density * 2.4;
    return scaled.clamp(0.0, 1.0);
  }

  double _questionLikeScore(String text) {
    if (text.trim().isEmpty) return 0.0;
    var score = 0.0;
    if (text.contains('?')) score += 0.34;
    for (final cue in const <String>[
      'mi',
      'mı',
      'mu',
      'mü',
      'neden',
      'nasıl',
      'ne zaman',
      'hangi',
      'kaç',
    ]) {
      if (text.contains(cue)) score += 0.09;
    }
    return score.clamp(0.0, 1.0);
  }

  double _commandLikeScore(String text) {
    if (text.trim().isEmpty) return 0.0;
    var score = 0.0;
    for (final cue in const <String>[
      'yap',
      'aç',
      'kapat',
      'başlat',
      'durdur',
      'gönder',
      'ara',
      'ayarla',
      'hatırlat',
      'söyle',
      'bul',
      'getir',
      'devral',
    ]) {
      if (text.contains(cue)) score += 0.10;
    }
    return score.clamp(0.0, 1.0);
  }

  double _emotionalHoldScore(String text) {
    if (text.trim().isEmpty) return 0.0;
    var score = 0.0;
    for (final cue in const <String>[
      'üzgün',
      'kırgın',
      'gergin',
      'bunaldım',
      'yoruldum',
      'kötü',
      'moralim',
      'rahatsız',
      'canım sıkkın',
      'kaygı',
    ]) {
      if (text.contains(cue)) score += 0.11;
    }
    return score.clamp(0.0, 1.0);
  }

  String _normalize(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<String> _unique(List<String> values, {required int limit}) {
    final out = <String>[];
    final seen = <String>{};
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      final key = trimmed.toLowerCase();
      if (seen.add(key)) out.add(trimmed);
      if (out.length >= limit) break;
    }
    return out;
  }
}

class NovaDuplexTurnPlan {
  final String turnRegime;
  final String entryStrategy;
  final String floorPolicy;
  final String interruptionPolicy;
  final String latencyBias;
  final double overlapTolerance;
  final String chunkingPolicy;
  final List<String> recommendedOpeners;
  final List<String> recommendedClosers;
  final double yieldScore;
  final double holdScore;
  final double inviteScore;
  final double questionScore;
  final double commandScore;
  final double emotionalScore;
  final double contextTightness;

  const NovaDuplexTurnPlan({
    required this.turnRegime,
    required this.entryStrategy,
    required this.floorPolicy,
    required this.interruptionPolicy,
    required this.latencyBias,
    required this.overlapTolerance,
    required this.chunkingPolicy,
    required this.recommendedOpeners,
    required this.recommendedClosers,
    required this.yieldScore,
    required this.holdScore,
    required this.inviteScore,
    required this.questionScore,
    required this.commandScore,
    required this.emotionalScore,
    required this.contextTightness,
  });
}
