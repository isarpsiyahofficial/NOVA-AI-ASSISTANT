// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaTurkishSpokenUnderstandingDecision {
  final List<String> cues;
  final List<String> entities;
  final bool hasIndirectRequest;
  final bool hasEmotionalDisclosure;
  final bool hasHalfSentence;
  final String discourseShape;
  final String confidenceBand;
  final List<String> pragmaticHints;
  final List<String> repairRisks;
  final List<String> memoryAnchors;
  final List<String> asrBiasHints;
  final String recommendedResponseMode;
  final Map<String, double> dimensionScores;

  const NovaTurkishSpokenUnderstandingDecision({
    required this.cues,
    required this.entities,
    required this.hasIndirectRequest,
    required this.hasEmotionalDisclosure,
    required this.hasHalfSentence,
    required this.discourseShape,
    required this.confidenceBand,
    required this.pragmaticHints,
    required this.repairRisks,
    required this.memoryAnchors,
    required this.asrBiasHints,
    required this.recommendedResponseMode,
    required this.dimensionScores,
  });

  String buildPromptSection() {
    final scoreText = dimensionScores.entries
        .map((entry) => '${entry.key}=${entry.value.toStringAsFixed(2)}')
        .join(' | ');
    return [
      'TURKISH-FIRST SPOKEN KATMANI:',
      '- ipuçları: ${cues.isEmpty ? 'yok' : cues.join(' | ')}',
      '- varlıklar: ${entities.isEmpty ? 'yok' : entities.join(' | ')}',
      '- discourse shape: $discourseShape',
      '- confidence band: $confidenceBand',
      '- dolaylı rica: ${hasIndirectRequest ? 'evet' : 'hayır'}',
      '- duygu paylaşımı: ${hasEmotionalDisclosure ? 'evet' : 'hayır'}',
      '- yarım cümle: ${hasHalfSentence ? 'evet' : 'hayır'}',
      '- pragmatik ipuçları: ${pragmaticHints.isEmpty ? 'yok' : pragmaticHints.join(' | ')}',
      '- onarım riskleri: ${repairRisks.isEmpty ? 'yok' : repairRisks.join(' | ')}',
      '- bellek ankrajları: ${memoryAnchors.isEmpty ? 'yok' : memoryAnchors.join(' | ')}',
      '- asr bias hints: ${asrBiasHints.isEmpty ? 'yok' : asrBiasHints.join(' | ')}',
      '- önerilen mod: $recommendedResponseMode',
      '- skorlar: $scoreText',
      'KURAL: Türkçede yarım cümle, dolaylı rica, duygu sızması ve “şey / yani / hani” gibi akış işaretleri gerçek anlam katmanı olarak okunmalı.',
      'KURAL: ASR’den gelen metni doğrudan yazı dili sanma; sözlü akışın eksiltili yapısı korunmalı.',
      'KURAL: Belirsizlik yüksekse açıklayıcı ama kısa onarım sorusu tercih edilmeli.',
    ].join('\n');
  }
}

class NovaTurkishSpokenUnderstandingLayerService {
  const NovaTurkishSpokenUnderstandingLayerService();

  static const List<String> _indirectRequestCues = <String>[
    'bakabilir misin',
    'yardımcı olur musun',
    'bir el atar mısın',
    'mümkünse',
    'uygunsa',
    'bir bakar mısın',
    'şuna göz atar mısın',
    'halledebilir misin',
    'bakar mısın',
    'bakıverir misin',
    'yardım etsen',
    'şunu halletsek',
    'bir şey soracağım',
    'bir şey diyecektim',
    'senden ricam',
    'rica etsem',
    'zahmet olmazsa',
    'müsaitsen',
    'vaktin varsa',
    'imkânın varsa',
  ];

  static const List<String> _emotionalDisclosureCues = <String>[
    'moralim',
    'canım sıkkın',
    'üzgünüm',
    'gerginim',
    'bunaldım',
    'yoruldum',
    'kırıldım',
    'sinirlendim',
    'kaygılıyım',
    'rahat değilim',
    'içim daralıyor',
    'çok sevindim',
    'mutlu oldum',
    'heyecanlıyım',
    'bir tuhaf oldum',
    'kafam karıştı',
    'rahatladım',
    'utanıyorum',
    'mahcup oldum',
    'tedirginim',
  ];

  static const List<String> _halfSentenceCues = <String>[
    'şey',
    'yani',
    'hani',
    'eee',
    'ııı',
    'gibi',
    'falan',
    'filan',
    'işte',
    'şimdi',
    'dur bakalım',
    'nasıl desem',
    'neydi',
    'yok ya',
    'tam olarak',
    'bir dakika',
  ];

  static const List<String> _repairRiskCues = <String>[
    'yanlış anladın',
    'öyle değil',
    'demek istediğim',
    'hayır onu demiyorum',
    'dur dur',
    'bir dakika yanlış',
    'şöyle değil böyle',
    'tam o değil',
    'karıştırdın',
    'başka bir şey diyorum',
  ];

  static const List<String> _temporalAnchors = <String>[
    'az önce',
    'biraz önce',
    'demin',
    'bugün',
    'yarın',
    'akşam',
    'sabah',
    'haftaya',
    'sonra',
    'daha sonra',
    'geçen sefer',
    'geçen gün',
  ];

  static const List<String> _socialAnchors = <String>[
    'annem',
    'babam',
    'eşim',
    'arkadaşım',
    'abi',
    'abla',
    'hocam',
    'efendim',
    'nova',
    'nova',
    'biz',
    'beraber',
  ];

  static const List<String> _commandCues = <String>[
    'aç',
    'kapat',
    'başlat',
    'durdur',
    'ara',
    'gönder',
    'hatırlat',
    'ayarla',
    'devral',
    'bırak',
    'konuş',
    'söyle',
    'bul',
    'getir',
    'çal',
    'uyandır',
  ];

  static const List<String> _questionCues = <String>[
    'mi',
    'mı',
    'mu',
    'mü',
    'neden',
    'nasıl',
    'ne zaman',
    'kaç',
    'hangi',
    'kim',
    'nerede',
    'sence',
  ];

  static const List<String> _continuationInvites = <String>[
    'devam et',
    'sürdür',
    'anlat',
    'aç biraz',
    'detay ver',
    'devamını söyle',
    'oradan git',
    'buradan devam',
    'ekle',
    'uzatmadan anlat',
  ];

  NovaTurkishSpokenUnderstandingDecision analyze(String raw) {
    final original = raw.trim();
    final normalized = _normalize(original);
    final tokens = _tokens(original);
    final cues = <String>[];
    final entities = _entities(original);
    final pragmaticHints = <String>[];
    final repairRisks = <String>[];
    final memoryAnchors = <String>[];
    final asrBiasHints = <String>[];

    final indirectScore = _phraseScore(normalized, _indirectRequestCues);
    final emotionalScore = _phraseScore(normalized, _emotionalDisclosureCues);
    final halfSentenceScore = _halfSentenceScore(normalized, tokens);
    final repairScore = _phraseScore(normalized, _repairRiskCues);
    final temporalScore = _phraseScore(normalized, _temporalAnchors);
    final socialScore = _phraseScore(normalized, _socialAnchors);
    final commandScore = _commandScore(normalized, tokens);
    final questionScore = _questionScore(normalized, tokens);
    final continuationScore = _phraseScore(normalized, _continuationInvites);
    final narrativeScore = _narrativeScore(normalized, tokens);
    final ambiguityScore = _ambiguityScore(normalized, tokens);

    final hasIndirectRequest = indirectScore >= 0.32;
    final hasEmotionalDisclosure = emotionalScore >= 0.24;
    final hasHalfSentence = halfSentenceScore >= 0.30;

    if (hasIndirectRequest) cues.add('dolaylı_rica');
    if (hasEmotionalDisclosure) cues.add('duygusal_paylaşım');
    if (hasHalfSentence) cues.add('yarım_cümle');
    if (repairScore >= 0.30) cues.add('onarım_riski');
    if (commandScore >= 0.34) cues.add('sözlü_komut');
    if (questionScore >= 0.34) cues.add('sözlü_soru');
    if (continuationScore >= 0.24) cues.add('devam_daveti');
    if (temporalScore >= 0.24) cues.add('zaman_ankrajı');
    if (socialScore >= 0.24) cues.add('ilişki_ankrajı');
    if (narrativeScore >= 0.30) cues.add('anlatı_akışı');
    if (ambiguityScore >= 0.34) cues.add('asr_belirsizliği');

    pragmaticHints.addAll(
      _pragmaticHints(
        normalized: normalized,
        indirectScore: indirectScore,
        emotionalScore: emotionalScore,
        commandScore: commandScore,
        questionScore: questionScore,
        continuationScore: continuationScore,
        ambiguityScore: ambiguityScore,
      ),
    );

    repairRisks.addAll(
      _repairHints(
        normalized: normalized,
        repairScore: repairScore,
        ambiguityScore: ambiguityScore,
        halfSentenceScore: halfSentenceScore,
      ),
    );

    memoryAnchors.addAll(
      _memoryAnchorHints(
        normalized: normalized,
        temporalScore: temporalScore,
        socialScore: socialScore,
        tokens: tokens,
      ),
    );

    asrBiasHints.addAll(
      _asrBiasHints(
        original: original,
        normalized: normalized,
        commandScore: commandScore,
        questionScore: questionScore,
        ambiguityScore: ambiguityScore,
        entities: entities,
        tokens: tokens,
      ),
    );

    final discourseShape = _discourseShape(
      tokenCount: tokens.length,
      commandScore: commandScore,
      questionScore: questionScore,
      emotionalScore: emotionalScore,
      narrativeScore: narrativeScore,
      halfSentenceScore: halfSentenceScore,
    );

    final confidenceBand = _confidenceBand(
      ambiguityScore: ambiguityScore,
      repairScore: repairScore,
      entityCount: entities.length,
      tokenCount: tokens.length,
    );

    final responseMode = _recommendedMode(
      commandScore: commandScore,
      questionScore: questionScore,
      emotionalScore: emotionalScore,
      indirectScore: indirectScore,
      ambiguityScore: ambiguityScore,
      continuationScore: continuationScore,
      repairScore: repairScore,
    );

    final dimensionScores = <String, double>{
      'indirect': indirectScore,
      'emotional': emotionalScore,
      'halfSentence': halfSentenceScore,
      'repair': repairScore,
      'temporal': temporalScore,
      'social': socialScore,
      'command': commandScore,
      'question': questionScore,
      'continuation': continuationScore,
      'narrative': narrativeScore,
      'ambiguity': ambiguityScore,
    };

    return NovaTurkishSpokenUnderstandingDecision(
      cues: _unique(cues, limit: 14),
      entities: _unique(entities, limit: 12),
      hasIndirectRequest: hasIndirectRequest,
      hasEmotionalDisclosure: hasEmotionalDisclosure,
      hasHalfSentence: hasHalfSentence,
      discourseShape: discourseShape,
      confidenceBand: confidenceBand,
      pragmaticHints: _unique(pragmaticHints, limit: 12),
      repairRisks: _unique(repairRisks, limit: 10),
      memoryAnchors: _unique(memoryAnchors, limit: 10),
      asrBiasHints: _unique(asrBiasHints, limit: 14),
      recommendedResponseMode: responseMode,
      dimensionScores: dimensionScores,
    );
  }

  List<String> _pragmaticHints({
    required String normalized,
    required double indirectScore,
    required double emotionalScore,
    required double commandScore,
    required double questionScore,
    required double continuationScore,
    required double ambiguityScore,
  }) {
    final out = <String>[];
    if (indirectScore >= 0.32) {
      out.add('istek doğrudan komut gibi değil; nezaket perdesi var');
      out.add(
        'yanıta “tamam” diye girip eylem planını kısa vermek iyi çalışabilir',
      );
    }
    if (emotionalScore >= 0.24) {
      out.add('bilgi vermeden önce duygusal alan açmak gerekebilir');
      out.add('cevap tonu yumuşak, kısa ve güvenli kalmalı');
    }
    if (commandScore >= 0.34) {
      out.add(
        'sözlü eylem beklentisi yüksek; yazı dili açıklama yerine icra/plan dili uygun',
      );
    }
    if (questionScore >= 0.34) {
      out.add('soru niyeti baskın; cevabı hızlı başlatmak önemli');
    }
    if (continuationScore >= 0.24) {
      out.add('kullanıcı mevcut akışın sürmesini istiyor olabilir');
    }
    if (ambiguityScore >= 0.34) {
      out.add('olası ASR eksilmesi var; kısa onarım sorusu gerekebilir');
    }
    if (normalized.contains('sence')) {
      out.add('salt bilgi değil, görüş/yorum beklentisi var');
    }
    if (normalized.contains('kısaca') || normalized.contains('özet')) {
      out.add('yanıt boyu sınırı açıkça veya örtük şekilde daraltıldı');
    }
    return out;
  }

  List<String> _repairHints({
    required String normalized,
    required double repairScore,
    required double ambiguityScore,
    required double halfSentenceScore,
  }) {
    final out = <String>[];
    if (repairScore >= 0.30) {
      out.add(
        'önceki dönüşle sürtünme olabilir; savunmasız onarım tonu gerekli',
      );
    }
    if (ambiguityScore >= 0.40) {
      out.add(
        'yüksek belirsizlik: tek cümlelik netleştirme sorusu gerekebilir',
      );
    }
    if (halfSentenceScore >= 0.38) {
      out.add('yarım cümleyi kesin bilgi sanma');
    }
    if (normalized.contains('şöyle değil') ||
        normalized.contains('öyle değil')) {
      out.add('kullanıcı eski yorumu reddediyor; önce yanlış anlamayı kapat');
    }
    if (normalized.contains('ne demek istediğimi')) {
      out.add('niyet açıklığa kavuşmadı; yeniden çerçeveleme önemli');
    }
    return out;
  }

  List<String> _memoryAnchorHints({
    required String normalized,
    required double temporalScore,
    required double socialScore,
    required List<String> tokens,
  }) {
    final out = <String>[];
    if (temporalScore >= 0.24) {
      out.add(
        'zaman referansı var; aynı gün/süreklilik bağlamı önem kazanıyor',
      );
    }
    if (socialScore >= 0.24) {
      out.add(
        'ilişki veya kişi referansı var; ortak yaşam bağlamı aktive edilebilir',
      );
    }
    for (final token in tokens) {
      final lower = token.toLowerCase();
      if (lower.length >= 4 && !_isStopWord(lower) && _looksMemorable(lower)) {
        out.add('ankraj: $lower');
      }
      if (out.length >= 8) break;
    }
    return out;
  }

  List<String> _asrBiasHints({
    required String original,
    required String normalized,
    required double commandScore,
    required double questionScore,
    required double ambiguityScore,
    required List<String> entities,
    required List<String> tokens,
  }) {
    final out = <String>[];
    if (commandScore >= 0.34) {
      out.add('eylem fiillerine bias ver');
    }
    if (questionScore >= 0.34) {
      out.add('soru operatörlerine bias ver');
    }
    if (ambiguityScore >= 0.34) {
      out.add('eksiltili bağlaçlara tolerans artır');
      out.add('tek token yanlış duyulmuş olabilir; anlamsal toparlama uygula');
    }
    for (final entity in entities) {
      out.add('varlık bias: ${entity.toLowerCase()}');
      if (out.length >= 10) break;
    }
    if (original.contains('?')) {
      out.add('soru ritmi korunmalı');
    }
    if (_containsColonLikePause(original)) {
      out.add('durak/sözlü liste yapısı korunmalı');
    }
    for (final token in tokens) {
      final lower = token.toLowerCase();
      if (_commandCues.contains(lower) || _questionCues.contains(lower)) {
        out.add('kritik token: $lower');
      }
      if (out.length >= 14) break;
    }
    return out;
  }

  String _discourseShape({
    required int tokenCount,
    required double commandScore,
    required double questionScore,
    required double emotionalScore,
    required double narrativeScore,
    required double halfSentenceScore,
  }) {
    if (commandScore >= 0.46 && tokenCount <= 8) return 'mikro_komut';
    if (questionScore >= 0.42 && tokenCount <= 10) return 'mikro_soru';
    if (emotionalScore >= 0.24 && halfSentenceScore >= 0.30)
      return 'duygusal_parçalı_akış';
    if (narrativeScore >= 0.34) return 'anlatımsal_akış';
    if (halfSentenceScore >= 0.30) return 'eksiltili_sözlü_akış';
    if (tokenCount <= 6) return 'kısa_sözlü_girdi';
    if (tokenCount <= 16) return 'orta_sözlü_girdi';
    return 'uzun_sözlü_akış';
  }

  String _confidenceBand({
    required double ambiguityScore,
    required double repairScore,
    required int entityCount,
    required int tokenCount,
  }) {
    var score = 0.62;
    score -= ambiguityScore * 0.34;
    score -= repairScore * 0.20;
    score += (entityCount >= 1 ? 0.08 : 0.0);
    score += (tokenCount >= 4 ? 0.04 : -0.06);
    if (score >= 0.72) return 'yüksek';
    if (score >= 0.52) return 'orta';
    return 'düşük';
  }

  String _recommendedMode({
    required double commandScore,
    required double questionScore,
    required double emotionalScore,
    required double indirectScore,
    required double ambiguityScore,
    required double continuationScore,
    required double repairScore,
  }) {
    if (repairScore >= 0.30 || ambiguityScore >= 0.46) return 'short_repair';
    if (emotionalScore >= 0.28) return 'soft_supportive';
    if (commandScore >= 0.42) return 'action_first';
    if (questionScore >= 0.40) return 'answer_first';
    if (indirectScore >= 0.32) return 'gentle_acceptance';
    if (continuationScore >= 0.24) return 'continue_thread';
    return 'balanced_spoken';
  }

  double _phraseScore(String normalized, List<String> cues) {
    if (normalized.isEmpty) return 0.0;
    var hits = 0;
    for (final cue in cues) {
      if (normalized.contains(cue)) hits += 1;
    }
    final density = hits / cues.length;
    return (density * 3.2).clamp(0.0, 1.0);
  }

  double _halfSentenceScore(String normalized, List<String> tokens) {
    var score = 0.0;
    for (final cue in _halfSentenceCues) {
      if (normalized.contains(cue)) score += 0.08;
    }
    if (normalized.endsWith('...')) score += 0.14;
    if (tokens.length <= 3) score += 0.08;
    if (_endsAbruptly(normalized)) score += 0.12;
    return score.clamp(0.0, 1.0);
  }

  double _commandScore(String normalized, List<String> tokens) {
    var score = 0.0;
    for (final cue in _commandCues) {
      if (normalized.contains(cue)) score += 0.08;
    }
    if (tokens.isNotEmpty && _looksImperative(tokens.first.toLowerCase()))
      score += 0.12;
    if (normalized.contains('lütfen')) score += 0.06;
    return score.clamp(0.0, 1.0);
  }

  double _questionScore(String normalized, List<String> tokens) {
    var score = 0.0;
    if (normalized.contains('?')) score += 0.20;
    for (final cue in _questionCues) {
      if (normalized.contains(cue)) score += 0.07;
    }
    if (tokens.isNotEmpty && tokens.first.toLowerCase() == 'neden')
      score += 0.10;
    return score.clamp(0.0, 1.0);
  }

  double _narrativeScore(String normalized, List<String> tokens) {
    var score = 0.0;
    for (final cue in const <String>[
      'sonra',
      'ondan sonra',
      'bir anda',
      'o sırada',
      'sonrasında',
      'önce',
    ]) {
      if (normalized.contains(cue)) score += 0.10;
    }
    if (tokens.length >= 14) score += 0.10;
    return score.clamp(0.0, 1.0);
  }

  double _ambiguityScore(String normalized, List<String> tokens) {
    var score = 0.0;
    if (tokens.length <= 2) score += 0.16;
    if (_repetitionScore(tokens) > 0.28) score += 0.16;
    for (final cue in const <String>['şey', 'yani', 'hani', 'eee', 'ııı']) {
      if (normalized.contains(cue)) score += 0.06;
    }
    if (_containsConfusableSoundPattern(normalized)) score += 0.12;
    return score.clamp(0.0, 1.0);
  }

  List<String> _tokens(String original) {
    return original
        .split(RegExp(r'\s+'))
        .map(
          (e) => e
              .replaceAll(
                RegExp(r'^[^\wçğıöşüÇĞİÖŞÜ]+|[^\wçğıöşüÇĞİÖŞÜ]+$'),
                '',
              )
              .trim(),
        )
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  List<String> _entities(String original) {
    final out = <String>[];
    final tokens = original.split(RegExp(r'\s+'));
    for (final token in tokens) {
      final clean = token
          .replaceAll(RegExp(r'^[^\wçğıöşüÇĞİÖŞÜ]+|[^\wçğıöşüÇĞİÖŞÜ]+$'), '')
          .trim();
      if (clean.length < 2) continue;
      if (clean == clean.toLowerCase()) continue;
      final first = clean.substring(0, 1);
      if (first == first.toUpperCase()) {
        out.add(clean);
      }
    }
    return _unique(out, limit: 12);
  }

  bool _containsColonLikePause(String text) {
    return text.contains(':') || text.contains(';') || text.contains(',');
  }

  bool _endsAbruptly(String normalized) {
    return normalized.endsWith('ve') ||
        normalized.endsWith('ama') ||
        normalized.endsWith('çünkü') ||
        normalized.endsWith('sonra') ||
        normalized.endsWith('işte');
  }

  bool _looksImperative(String token) {
    return token.endsWith('aç') ||
        token.endsWith('kapat') ||
        token.endsWith('başlat') ||
        token.endsWith('söyle') ||
        token.endsWith('ara') ||
        token.endsWith('bul');
  }

  bool _looksMemorable(String token) {
    return token.length >= 5 &&
        !token.endsWith('iyor') &&
        !token.endsWith('acak');
  }

  bool _isStopWord(String token) {
    return const <String>{
      'şöyle',
      'böyle',
      'zaten',
      'çünkü',
      'sonra',
      'biraz',
      'ancak',
      'fakat',
      'olarak',
      'yani',
      'şimdi',
      'bence',
      'benim',
      'senin',
      'onun',
      'bunu',
      'şunu',
      'orada',
      'burada',
    }.contains(token);
  }

  double _repetitionScore(List<String> tokens) {
    if (tokens.isEmpty) return 0.0;
    final counts = <String, int>{};
    for (final token in tokens) {
      final lower = token.toLowerCase();
      counts[lower] = (counts[lower] ?? 0) + 1;
    }
    var repeated = 0;
    for (final value in counts.values) {
      if (value >= 2) repeated += value;
    }
    return (repeated / tokens.length).clamp(0.0, 1.0);
  }

  bool _containsConfusableSoundPattern(String normalized) {
    return normalized.contains('de mi') ||
        normalized.contains('napim') ||
        normalized.contains('noldu') ||
        normalized.contains('bi ') ||
        normalized.contains('yaani') ||
        normalized.contains('şeey');
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
