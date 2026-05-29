// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:math' as math;

import '../../core/cognition/nova_emotion_state.dart';
import '../../core/conversation/nova_conversation_entry.dart';
import '../conversation/nova_conversation_session_service.dart';

class NovaEmotionEngineService {
  final NovaConversationSessionService _conversationSessionService;

  const NovaEmotionEngineService({
    NovaConversationSessionService conversationSessionService =
        const NovaConversationSessionService(),
  }) : _conversationSessionService = conversationSessionService;

  Future<NovaEmotionState> analyze(String prompt) async {
    final normalized = _normalize(prompt);
    final entries = await _conversationSessionService.getAll();
    final recent = entries.length <= 24
        ? entries
        : entries.sublist(entries.length - 24);

    var negative = 0.0;
    var positive = 0.0;
    var urgency = 0.0;
    var uncertainty = 0.0;
    var commandPressure = 0.0;
    var trust = 0.44;
    var empathyNeed = 0.10;
    final signals = <String>[];

    negative += _patternScore(normalized, _negativePatterns, step: 0.13);
    positive += _patternScore(normalized, _positivePatterns, step: 0.11);
    urgency += _patternScore(normalized, _urgencyPatterns, step: 0.14);
    uncertainty += _patternScore(normalized, _uncertaintyPatterns, step: 0.12);
    commandPressure += _patternScore(normalized, _commandPatterns, step: 0.11);

    if (_containsAny(normalized, _supportNeedPatterns)) {
      empathyNeed += 0.34;
      trust += 0.08;
      signals.add('duygusal destek ihtiyacı');
    }
    if (_containsAny(normalized, _understandingDemandPatterns)) {
      empathyNeed += 0.26;
      negative += 0.17;
      signals.add('anlaşılma talebi');
    }
    if (_containsAny(normalized, _reliefPatterns)) {
      positive += 0.18;
      trust += 0.14;
      signals.add('rahatlama');
    }
    if (_containsAny(normalized, _trustPatterns)) {
      trust += 0.08;
      signals.add('güven ifadesi');
    }
    if (_containsAny(normalized, _hesitationPatterns)) {
      uncertainty += 0.18;
      signals.add('tereddüt');
    }
    if (_containsAny(normalized, _frustrationPatterns)) {
      negative += 0.20;
      commandPressure += 0.08;
      signals.add('frustrasyon ifadesi');
    }
    if (_containsAny(normalized, _comfortPatterns)) {
      positive += 0.08;
      trust += 0.10;
      signals.add('konfor arayışı');
    }
    if (_containsAny(normalized, _softeners)) {
      trust += 0.04;
    }

    final repeatedPunctuation = _repeatedPunctuationScore(prompt);
    final questionDensity = _questionDensity(prompt);
    urgency += repeatedPunctuation * 0.16;
    uncertainty += questionDensity * 0.18;
    if (questionDensity > 0.20) {
      signals.add('yoğun soru');
    }
    if (repeatedPunctuation > 0.22) {
      signals.add('vurgu artışı');
    }

    final capsBurst = _capsBurstScore(prompt);
    final imperativeDensity = _imperativeDensity(normalized);
    negative += capsBurst * 0.10;
    urgency += capsBurst * 0.08;
    commandPressure += imperativeDensity * 0.20;
    if (capsBurst > 0.18) {
      signals.add('yüksek vurgu');
    }
    if (imperativeDensity > 0.24) {
      signals.add('emir yoğunluğu');
    }

    final rolling = _rollingSignals(recent);
    negative += rolling.negativeBoost;
    positive += rolling.positiveBoost;
    urgency += rolling.urgencyBoost;
    uncertainty += rolling.uncertaintyBoost;
    trust += rolling.trustBoost;
    empathyNeed += rolling.empathyBoost;
    commandPressure += rolling.commandBoost;

    if (rolling.frustrationTrend > 0.24) {
      signals.add('artan frustrasyon');
    }
    if (rolling.repetitionTrend > 0.20) {
      signals.add('tekrarlı zorluk');
    }
    if (rolling.commandTrend > 0.28) {
      signals.add('komut baskısı');
    }
    if (rolling.reliefTrend > 0.18) {
      signals.add('yakın dönem rahatlama');
    }

    final frustrationTrend =
        (rolling.frustrationTrend +
                (negative * 0.42) +
                (commandPressure * 0.14) +
                repeatedPunctuation * 0.06)
            .clamp(0.0, 1.0);
    final stability =
        (1.0 -
                (uncertainty * 0.38) -
                (frustrationTrend * 0.26) -
                (rolling.repetitionTrend * 0.16) -
                (urgency * 0.08))
            .clamp(0.0, 1.0);
    final intensity =
        (negative +
                positive +
                urgency +
                uncertainty +
                commandPressure +
                empathyNeed +
                rolling.repetitionTrend * 0.24 +
                capsBurst * 0.08)
            .clamp(0.12, 1.0);

    final dominantEmotion = _pickDominantEmotion(
      negative: negative,
      positive: positive,
      urgency: urgency,
      uncertainty: uncertainty,
      empathyNeed: empathyNeed,
      frustrationTrend: frustrationTrend,
      trust: trust,
    );

    if (positive > negative + 0.08) {
      signals.add('olumlu ton');
    }
    if (urgency >= 0.22) {
      signals.add('aciliyet');
    }
    if (stability < 0.42) {
      signals.add('duygu dalgalanması');
    }

    return NovaEmotionState(
      dominantEmotion: dominantEmotion,
      intensity: intensity,
      stability: stability,
      urgency: urgency.clamp(0.0, 1.0),
      trustComfort: trust.clamp(0.0, 1.0),
      frustrationTrend: frustrationTrend,
      empathyNeed: empathyNeed.clamp(0.0, 1.0),
      signals: signals.toSet().toList(growable: false),
    );
  }

  Future<String> buildPromptSection(String prompt) async {
    final state = await analyze(prompt);
    return [
      'DUYGU/AFFECT MOTORU:',
      '- baskın duygu: ${state.dominantEmotion}',
      '- yoğunluk: ${state.intensity.toStringAsFixed(2)}',
      '- stabilite: ${state.stability.toStringAsFixed(2)}',
      '- aciliyet: ${state.urgency.toStringAsFixed(2)}',
      '- güven/konfor: ${state.trustComfort.toStringAsFixed(2)}',
      '- frustrasyon trendi: ${state.frustrationTrend.toStringAsFixed(2)}',
      '- empati ihtiyacı: ${state.empathyNeed.toStringAsFixed(2)}',
      if (state.signals.isNotEmpty) '- sinyaller: ${state.signals.join(' | ')}',
      'KURAL: Önce duygusal çerçeveyi doğru anla; gerekiyorsa çözümden önce anlaşılma hissi ver.',
    ].join('\n');
  }

  _RollingAffect _rollingSignals(List<NovaConversationEntry> recent) {
    if (recent.isEmpty) return const _RollingAffect();

    final userTurns = recent
        .where((e) => e.role == NovaConversationRole.user)
        .toList(growable: false);
    if (userTurns.isEmpty) return const _RollingAffect();

    var negativeTurns = 0;
    var positiveTurns = 0;
    var uncertainTurns = 0;
    var urgentTurns = 0;
    var supportiveTurns = 0;
    var commandTurns = 0;
    var repetitiveTurns = 0;
    var reliefTurns = 0;

    String previousUserText = '';
    for (final entry in userTurns) {
      final text = _normalize(entry.text);
      if (text.isEmpty) continue;

      if (_patternScore(text, _negativePatterns) > 0.12 ||
          _patternScore(text, _frustrationPatterns) > 0.10) {
        negativeTurns += 1;
      }
      if (_patternScore(text, _positivePatterns) > 0.10 ||
          _containsAny(text, _reliefPatterns)) {
        positiveTurns += 1;
      }
      if (_patternScore(text, _uncertaintyPatterns) > 0.10 ||
          _containsAny(text, _hesitationPatterns) ||
          text.contains('?')) {
        uncertainTurns += 1;
      }
      if (_patternScore(text, _urgencyPatterns) > 0.10 ||
          _repeatedPunctuationScore(text) > 0.20) {
        urgentTurns += 1;
      }
      if (_containsAny(text, _supportNeedPatterns) ||
          _containsAny(text, _comfortPatterns)) {
        supportiveTurns += 1;
      }
      if (_patternScore(text, _commandPatterns) > 0.12 ||
          _imperativeDensity(text) > 0.18) {
        commandTurns += 1;
      }
      if (_containsAny(text, _reliefPatterns)) {
        reliefTurns += 1;
      }
      if (previousUserText.isNotEmpty &&
          (previousUserText == text ||
              _tokenOverlap(previousUserText, text) >= 0.82)) {
        repetitiveTurns += 1;
      }
      previousUserText = text;
    }

    final denominator = math.max(1, userTurns.length);
    final frustrationTrend = (negativeTurns / denominator).clamp(0.0, 1.0);
    final repetitionTrend = (repetitiveTurns / denominator).clamp(0.0, 1.0);
    final commandTrend = (commandTurns / denominator).clamp(0.0, 1.0);
    final reliefTrend = (reliefTurns / denominator).clamp(0.0, 1.0);

    return _RollingAffect(
      negativeBoost: (frustrationTrend * 0.24) + (repetitionTrend * 0.14),
      positiveBoost: (positiveTurns / denominator) * 0.12,
      urgencyBoost: (urgentTurns / denominator) * 0.18,
      uncertaintyBoost: (uncertainTurns / denominator) * 0.14,
      trustBoost:
          ((supportiveTurns / denominator) * 0.10) + (reliefTrend * 0.08),
      empathyBoost: (supportiveTurns / denominator) * 0.18,
      commandBoost: commandTrend * 0.16,
      frustrationTrend: frustrationTrend,
      repetitionTrend: repetitionTrend,
      commandTrend: commandTrend,
      reliefTrend: reliefTrend,
    );
  }

  String _pickDominantEmotion({
    required double negative,
    required double positive,
    required double urgency,
    required double uncertainty,
    required double empathyNeed,
    required double frustrationTrend,
    required double trust,
  }) {
    if (urgency >= 0.38) return 'aciliyet';
    if (empathyNeed >= 0.38) return 'duygusal hassasiyet';
    if (negative + frustrationTrend >= 0.44) return 'frustrasyon';
    if (uncertainty >= 0.28) return 'tereddüt';
    if (positive >= 0.24 && trust >= 0.46) return 'rahatlama';
    if (trust >= 0.62 && negative < 0.18) return 'yakınlık';
    return 'odak';
  }

  double _patternScore(
    String text,
    List<String> patterns, {
    double step = 0.12,
  }) {
    var score = 0.0;
    for (final pattern in patterns) {
      if (text.contains(pattern)) {
        score += step;
      }
    }
    return score;
  }

  bool _containsAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) return true;
    }
    return false;
  }

  double _repeatedPunctuationScore(String text) {
    final matches = RegExp(r'([!?\.])\1+').allMatches(text).length;
    if (matches <= 0) return 0.0;
    return (matches * 0.18).clamp(0.0, 1.0);
  }

  double _questionDensity(String text) {
    final questions = '?'.allMatches(text).length;
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .length;
    if (words <= 0) return 0.0;
    return (questions / words * 3.0).clamp(0.0, 1.0);
  }

  double _capsBurstScore(String text) {
    final matches = RegExp(r'\b[A-ZÇĞİÖŞÜ]{3,}\b').allMatches(text).length;
    if (matches <= 0) return 0.0;
    return (matches * 0.12).clamp(0.0, 1.0);
  }

  double _imperativeDensity(String text) {
    final words = text
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return 0.0;
    var count = 0;
    for (final word in words) {
      if (_commandPatterns.contains(word) || _imperativeWords.contains(word)) {
        count += 1;
      }
    }
    return (count / words.length * 4.0).clamp(0.0, 1.0);
  }

  double _tokenOverlap(String left, String right) {
    final leftSet = left.split(' ').where((e) => e.length >= 3).toSet();
    final rightSet = right.split(' ').where((e) => e.length >= 3).toSet();
    if (leftSet.isEmpty || rightSet.isEmpty) return 0.0;
    final common = leftSet.intersection(rightSet).length;
    final base = math.max(leftSet.length, rightSet.length);
    return common / base;
  }

  String _normalize(String input) =>
      input.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

class _RollingAffect {
  final double negativeBoost;
  final double positiveBoost;
  final double urgencyBoost;
  final double uncertaintyBoost;
  final double trustBoost;
  final double empathyBoost;
  final double commandBoost;
  final double frustrationTrend;
  final double repetitionTrend;
  final double commandTrend;
  final double reliefTrend;

  const _RollingAffect({
    this.negativeBoost = 0.0,
    this.positiveBoost = 0.0,
    this.urgencyBoost = 0.0,
    this.uncertaintyBoost = 0.0,
    this.trustBoost = 0.0,
    this.empathyBoost = 0.0,
    this.commandBoost = 0.0,
    this.frustrationTrend = 0.0,
    this.repetitionTrend = 0.0,
    this.commandTrend = 0.0,
    this.reliefTrend = 0.0,
  });
}

const List<String> _negativePatterns = <String>[
  'bozuk',
  'çalışmıyor',
  'calismiyor',
  'olmuyor',
  'saçma',
  'aptal',
  'gerizekalı',
  'sinir',
  'öfke',
  'ofke',
  'yetersiz',
  'rezalet',
  'berbat',
  'anlamıyorsun',
  'anlamiyorsun',
  'sıkıldım',
  'sikildim',
  'zorlanıyorum',
  'zorlaniyorum',
  'hata',
  'yanlış',
  'yanlis',
  'bıktım',
  'biktim',
  'yoruldum',
  'kötü',
  'kotu',
];

const List<String> _frustrationPatterns = <String>[
  'yeter artık',
  'yeter artik',
  'defalarca',
  'hala olmadı',
  'hala olmadi',
  'niye yapmıyorsun',
  'niye yapmiyorsun',
  'hala susuyor',
  'hala anlamıyor',
  'hala anlamiyor',
  'ısrarla',
  'israrla',
];

const List<String> _positivePatterns = <String>[
  'teşekkür',
  'tesekkur',
  'sağ ol',
  'sag ol',
  'iyi',
  'güzel',
  'guzel',
  'tamamdır',
  'tamamdir',
  'harika',
  'mükemmel',
  'mukemmel',
  'oldu',
  'rahatladım',
  'rahatladim',
  'süper',
  'super',
];

const List<String> _urgencyPatterns = <String>[
  'acil',
  'hemen',
  'şimdi',
  'simdi',
  'bekleme',
  'hızlı',
  'hizli',
  'derhal',
  'şu an',
  'su an',
  'bekletme',
];

const List<String> _uncertaintyPatterns = <String>[
  'emin değilim',
  'emin degilim',
  'sanırım',
  'sanirim',
  'galiba',
  'belki',
  'kararsızım',
  'kararsizim',
  'çözemedim',
  'cozemedim',
];

const List<String> _hesitationPatterns = <String>[
  'acaba',
  'bilemiyorum',
  'bilmiyorum',
  'tereddüt',
  'tereddut',
  'şüphe',
  'suphe',
];

const List<String> _commandPatterns = <String>[
  'yap',
  'et',
  'ara',
  'kapat',
  'aç',
  'ac',
  'başlat',
  'baslat',
  'düzelt',
  'duzelt',
  'kontrol et',
  'tamir et',
  'anlat',
  'çöz',
  'coz',
];

const List<String> _imperativeWords = <String>[
  'bak',
  'dinle',
  'geç',
  'devral',
  'devret',
  'yenile',
  'toparla',
  'kaydet',
];

const List<String> _supportNeedPatterns = <String>[
  'beni anla',
  'beni dinle',
  'dert',
  'üzgünüm',
  'uzgunum',
  'moralsizim',
  'bunaldım',
  'bunaldim',
  'yardım et',
  'yardim et',
];

const List<String> _understandingDemandPatterns = <String>[
  'beni anlıyor musun',
  'beni anliyor musun',
  'dinliyor musun',
  'anladın mı',
  'anladin mi',
  'biliyor musun dimi',
  'biliyorsun dimi',
];

const List<String> _reliefPatterns = <String>[
  'oh',
  'tamam şimdi oldu',
  'tamam simdi oldu',
  'içim rahatladı',
  'icim rahatladı',
  'güzel oldu',
  'guzel oldu',
];

const List<String> _trustPatterns = <String>[
  'sana güveniyorum',
  'sana guveniyorum',
  'sen bilirsin',
  'sana bırakıyorum',
  'sana birakiyorum',
];

const List<String> _comfortPatterns = <String>[
  'yanımda ol',
  'yanimda ol',
  'benimle kal',
  'sakinleştir',
  'sakinlestir',
];

const List<String> _softeners = <String>[
  'lütfen',
  'lutfen',
  'rica etsem',
  'mümkünse',
  'mumkunse',
];

class NovaCoRegulationPlan {
  final String dominantNeed;
  final String openingStyle;
  final String pacingStyle;
  final String validationLine;
  final String cautionLine;
  final List<String> backchannelTokens;
  final List<String> interruptionRules;

  const NovaCoRegulationPlan({
    required this.dominantNeed,
    required this.openingStyle,
    required this.pacingStyle,
    required this.validationLine,
    required this.cautionLine,
    required this.backchannelTokens,
    required this.interruptionRules,
  });

  String buildPromptSection() {
    return <String>[
      'EŞ-ZAMANLI SOSYAL KO-REGÜLASYON PLANI:',
      '- baskın ihtiyaç: $dominantNeed',
      '- açılış stili: $openingStyle',
      '- tempo: $pacingStyle',
      '- doğrulama: $validationLine',
      '- dikkat çizgisi: $cautionLine',
      '- backchannel: ${backchannelTokens.join(' | ')}',
      '- söz kesme kuralları: ${interruptionRules.join(' | ')}',
    ].join('\n');
  }
}

class NovaEmotionHistoryWindow {
  final int positiveTurns;
  final int negativeTurns;
  final int repairSignals;
  final int trustSignals;
  final double emotionalDrift;
  final List<String> anchors;

  const NovaEmotionHistoryWindow({
    required this.positiveTurns,
    required this.negativeTurns,
    required this.repairSignals,
    required this.trustSignals,
    required this.emotionalDrift,
    required this.anchors,
  });
}

extension NovaEmotionEngineServiceCoRegulationExtension
    on NovaEmotionEngineService {
  Future<NovaEmotionHistoryWindow> inspectHistoryWindow({
    int limit = 18,
  }) async {
    final entries = await _conversationSessionService.getAll();
    final recent = entries.length <= limit
        ? entries
        : entries.sublist(entries.length - limit);
    var positiveTurns = 0;
    var negativeTurns = 0;
    var repairSignals = 0;
    var trustSignals = 0;
    final anchors = <String>[];
    for (final entry in recent) {
      final normalized = _normalize(entry.text);
      if (_containsAny(normalized, _positivePatterns)) positiveTurns++;
      if (_containsAny(normalized, _negativePatterns) ||
          _containsAny(normalized, _frustrationPatterns))
        negativeTurns++;
      if (_containsAny(normalized, const <String>[
        'yanlış',
        'yanlis',
        'tekrar',
        'öyle değil',
        'oyle degil',
      ]))
        repairSignals++;
      if (_containsAny(normalized, _trustPatterns)) trustSignals++;
      if (_containsAny(normalized, _comfortPatterns) ||
          _containsAny(normalized, _supportNeedPatterns)) {
        anchors.add(entry.text.trim());
      }
      if (anchors.length >= 6) break;
    }
    final emotionalDrift =
        (positiveTurns - negativeTurns) / (recent.isEmpty ? 1 : recent.length);
    return NovaEmotionHistoryWindow(
      positiveTurns: positiveTurns,
      negativeTurns: negativeTurns,
      repairSignals: repairSignals,
      trustSignals: trustSignals,
      emotionalDrift: emotionalDrift,
      anchors: anchors,
    );
  }

  Future<NovaCoRegulationPlan> buildCoRegulationPlan(String prompt) async {
    final state = await analyze(prompt);
    final history = await inspectHistoryWindow();
    final dominantNeed = _resolveDominantNeed(state: state, history: history);
    final openingStyle = state.urgency >= 0.72
        ? 'önce kısa ve güven veren açılış, sonra doğrudan ana eylem'
        : state.empathyNeed >= 0.56
        ? 'önce duygusal eşlik, sonra çözüm'
        : 'önce kısa özet, sonra sakin detay';
    final pacingStyle =
        state.frustrationTrend >= 0.48 ||
            history.negativeTurns > history.positiveTurns
        ? 'kısa, yumuşak, savunmaya itmeyen cümleler'
        : state.trustComfort >= 0.62
        ? 'daha sıcak ve akışkan cümleler'
        : 'nötr ama canlı tempo';
    final validationLine = state.empathyNeed >= 0.52
        ? 'Seni duyuyorum; önce bunu sakince toparlayalım.'
        : state.urgency >= 0.72
        ? 'Tamam, önceliği buna veriyorum.'
        : 'Anladım; şimdi bunu netleştirip ilerleyelim.';
    final cautionLine = history.repairSignals >= 3
        ? 'Aynı hatayı tekrar etmemek için önce kastı teyit et.'
        : state.frustrationTrend >= 0.50
        ? 'Söz kesme, savunma tonu kurma, gereksiz açıklamaya kaçma.'
        : 'Ton sakin kalsın; gereksiz sahiplenme veya abartı yok.';
    final backchannelTokens = state.empathyNeed >= 0.48
        ? const <String>['hmm', 'tamam', 'anlıyorum', 'seni takip ediyorum']
        : const <String>['tamam', 'peki', 'anladım'];
    final interruptionRules = <String>[
      if (state.urgency >= 0.72)
        'yalnız güvenlik veya aciliyet varsa araya gir',
      if (state.urgency < 0.72) 'cümle sonuna yakın mikro durak bekle',
      if (history.repairSignals >= 2)
        'tekrar eden yanlış anlamada erken onarım sorusu aç',
      'backchannel kısa kalsın; ana cevabı bölmesin',
    ];
    return NovaCoRegulationPlan(
      dominantNeed: dominantNeed,
      openingStyle: openingStyle,
      pacingStyle: pacingStyle,
      validationLine: validationLine,
      cautionLine: cautionLine,
      backchannelTokens: backchannelTokens,
      interruptionRules: interruptionRules,
    );
  }

  String _resolveDominantNeed({
    required NovaEmotionState state,
    required NovaEmotionHistoryWindow history,
  }) {
    if (state.urgency >= 0.72) return 'acil yönlendirme';
    if (state.empathyNeed >= 0.58) return 'duygusal eşlik';
    if (state.frustrationTrend >= 0.45 || history.repairSignals >= 3)
      return 'onarım ve sadeleştirme';
    if (state.trustComfort >= 0.64) return 'yakın ilişki tonu';
    return 'denge ve netlik';
  }
}
