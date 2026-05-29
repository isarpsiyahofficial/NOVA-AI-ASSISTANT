// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaUnderstandingEngineService {
  const NovaUnderstandingEngineService();

  Map<String, dynamic> analyze(String prompt) {
    final normalized = prompt.toLowerCase().trim();
    final primaryIntent = _resolvePrimaryIntent(normalized);
    final secondaryIntent = _resolveSecondaryIntent(normalized, primaryIntent);
    final commandStrength = _commandStrength(normalized);
    final continuitySignal = _containsAny(normalized, const [
      'geri dön',
      'geri don',
      'az önce',
      'az once',
      'demin',
      'kaldığımız',
      'kaldigimiz',
      'devam edelim',
      'oradan devam',
      'biraz önce',
      'biraz once',
    ]);
    final interruptionSignal = _containsAny(normalized, const [
      'bir de',
      'şunu da',
      'sunu da',
      'bu arada',
      'önce bunu',
      'once bunu',
      'arada şunu',
      'arada sunu',
    ]);
    final teachingSignal = _containsAny(normalized, const [
      'bundan sonra',
      'böyle yap',
      'boyle yap',
      'öğren',
      'ögren',
      'unutma',
      'kural',
    ]);
    final repairSignal = _containsAny(normalized, const [
      'yanlış anladın',
      'yanlis anladin',
      'beni kastetmedim',
      'hayır',
      'hayir',
      'şimdi değil',
      'simdi degil',
      'sohbet ediyorum',
      'komut vermiyorum',
      'onu demedim',
      'beni dinle',
      'seni kastetmedim',
      'çağrıyı kastettim',
      'yarın yap',
      'yarin yap',
    ]);
    final needsExplanation = _containsAny(normalized, const [
      'neden',
      'niye',
      'nasıl',
      'nasil',
      'nasıl yapamıyorsun',
      'neden yapmıyorsun',
      'neden olmadı',
      'neden olmadi',
      'ne oldu',
    ]);
    final explicitQuestion = normalized.contains('?');
    final conversationBid = _containsAny(normalized, const [
      'sohbet',
      'konuşalım',
      'konusalim',
      'orada mısın',
      'beni duyuyor musun',
      'ne düşünüyorsun',
      'ne dusunuyorsun',
      'bir şey soracağım',
      'dertleşelim',
      'dertleselim',
      'benimle konuş',
      'benimle konus',
      'sohbet edelim',
      'seninle konuşmak istiyorum',
      'biraz konuşalım',
      'beni dinliyor musun',
    ]);
    final memoryReference = _containsAny(normalized, const [
      'hatırlıyor musun',
      'hatirliyor musun',
      'geçen gün',
      'gecen gun',
      'az önce',
      'az once',
      'unutma',
      'kaldığımız yer',
      'geçen sefer',
      'gecen sefer',
    ]);
    final actionAfterEmotion =
        primaryIntent == 'eylem' &&
        _containsAny(normalized, const [
          'üzgün',
          'uzgun',
          'sinir',
          'bunaldım',
          'bunaldim',
        ]);
    final emotionalWeight = _emotionWeight(normalized);
    final directness = _directness(normalized);
    final confusionLevel = _confusionLevel(normalized);

    return <String, dynamic>{
      'primaryIntent': primaryIntent,
      'secondaryIntent': secondaryIntent,
      'commandStrength': commandStrength,
      'continuitySignal': continuitySignal,
      'interruptionSignal': interruptionSignal,
      'teachingSignal': teachingSignal,
      'repairSignal': repairSignal,
      'needsExplanation': needsExplanation,
      'explicitQuestion': explicitQuestion,
      'conversationBid': conversationBid,
      'memoryReference': memoryReference,
      'actionAfterEmotion': actionAfterEmotion,
      'topicSummary': _topicSummary(normalized),
      'emotionalWeight': emotionalWeight,
      'directness': directness,
      'confusionLevel': confusionLevel,
      'shouldClarify': _shouldClarify(
        text: normalized,
        primaryIntent: primaryIntent,
        explicitQuestion: explicitQuestion,
        commandStrength: commandStrength,
        confusionLevel: confusionLevel,
      ),
      'shouldAskFollowUp': _shouldAskFollowUp(
        text: normalized,
        primaryIntent: primaryIntent,
        needsExplanation: needsExplanation,
        emotionalWeight: emotionalWeight,
      ),
    };
  }

  String buildPromptSection(String prompt) {
    final analysis = analyze(prompt);
    return [
      'ANLAMA MOTORU:',
      '- birincil niyet: ${analysis['primaryIntent']}',
      '- ikincil niyet: ${analysis['secondaryIntent']}',
      '- komut gücü: ${(analysis['commandStrength'] as double).toStringAsFixed(2)}',
      '- duygusal ağırlık: ${(analysis['emotionalWeight'] as double).toStringAsFixed(2)}',
      '- direktlik: ${(analysis['directness'] as double).toStringAsFixed(2)}',
      '- karışıklık: ${(analysis['confusionLevel'] as double).toStringAsFixed(2)}',
      '- konu özeti: ${analysis['topicSummary']}',
      '- süreklilik sinyali: ${analysis['continuitySignal']}',
      '- kesinti/ara görev sinyali: ${analysis['interruptionSignal']}',
      '- öğretim sinyali: ${analysis['teachingSignal']}',
      '- düzeltme sinyali: ${analysis['repairSignal']}',
      '- açıklama beklentisi: ${analysis['needsExplanation']}',
      '- hafıza referansı: ${analysis['memoryReference']}',
      'KURAL: Kullanıcı doğal konuşsa bile yalnız sabit komut kalıplarını bekleme. Sohbet ve görev niyetini birlikte çöz.',
    ].join('\n');
  }

  String _resolvePrimaryIntent(String text) {
    if (_containsAny(text, const [
      'ara',
      'aç',
      'ac',
      'kapat',
      'yap',
      'başlat',
      'baslat',
      'gönder',
      'gonder',
      'uyandır',
      'uyandir',
      'çal',
      'cal',
      'değiştir',
      'degistir',
      'hallet',
    ]))
      return 'eylem';
    if (_containsAny(text, const [
      'nasıl',
      'nasil',
      'neden',
      'niye',
      'ne düşünüyorsun',
      'ne dusunuyorsun',
      'sence',
      'biliyor musun',
    ]))
      return 'soru';
    if (_containsAny(text, const [
      'sohbet',
      'konuşalım',
      'konusalim',
      'orada mısın',
      'beni duyuyor musun',
      'dertleşelim',
      'dertleselim',
      'benimle konuş',
      'benimle konus',
      'sohbet edelim',
      'biraz konuşalım',
      'seninle konuşmak istiyorum',
      'beni dinliyor musun',
    ]))
      return 'sohbet';
    if (_containsAny(text, const [
      'üzgünüm',
      'üzgün',
      'uzgun',
      'yoruldum',
      'bunaldım',
      'bunaldim',
      'moralim bozuk',
      'sinirliyim',
      'kirildim',
      'kırıldım',
    ]))
      return 'duygusal';
    if (_containsAny(text, const [
      'bundan sonra',
      'böyle yap',
      'boyle yap',
      'öğren',
      'ögren',
      'kural',
    ]))
      return 'öğretim';
    if (text.isEmpty || text.length <= 5) return 'belirsiz';
    return 'sohbet';
  }

  String _resolveSecondaryIntent(String text, String primary) {
    if (primary != 'öğretim' &&
        _containsAny(text, const ['bundan sonra', 'unutma', 'kural']))
      return 'öğretim';
    if (primary != 'duygusal' &&
        _containsAny(text, const ['üzgün', 'uzgun', 'yoruldum', 'sinirliyim']))
      return 'duygusal';
    if (primary != 'eylem' &&
        _containsAny(text, const ['ara', 'yap', 'hallet', 'başlat', 'baslat']))
      return 'eylem';
    if (primary != 'soru' && text.contains('?')) return 'soru';
    return 'yok';
  }

  double _commandStrength(String text) {
    var score = 0.0;
    if (_containsAny(text, const ['yap', 'hallet', 'ara', 'aç', 'ac', 'kapat']))
      score += 0.42;
    if (_containsAny(text, const ['hemen', 'şimdi', 'simdi', 'derhal']))
      score += 0.22;
    if (_containsAny(text, const ['lütfen', 'lutfen', 'rica', 'eder misin']))
      score -= 0.08;
    if (_containsAny(text, const ['sadece konuşuyorum', 'sohbet ediyorum']))
      score -= 0.18;
    return score.clamp(0.0, 1.0);
  }

  double _emotionWeight(String text) {
    var score = 0.0;
    if (_containsAny(text, const [
      'üzgün',
      'uzgun',
      'bunaldım',
      'bunaldim',
      'yoruldum',
      'sinir',
    ]))
      score += 0.44;
    if (_containsAny(text, const [
      'biliyorsun dimi',
      'beni anlıyor musun',
      'beni anliyor musun',
    ]))
      score += 0.20;
    if (_containsAny(text, const ['acil', 'hemen'])) score += 0.10;
    return score.clamp(0.0, 1.0);
  }

  double _directness(String text) {
    var score = 0.0;
    if (_containsAny(text, const [
      'yap',
      'hallet',
      'ara',
      'aç',
      'ac',
      'hemen',
      'şimdi',
      'simdi',
    ]))
      score += 0.34;
    if (_containsAny(text, const ['lütfen', 'lutfen', 'rica'])) score -= 0.06;
    return score.clamp(0.0, 1.0);
  }

  double _confusionLevel(String text) {
    var score = 0.0;
    if (text.isEmpty || text.length < 6) score += 0.32;
    if (_containsAny(text, const ['şey', 'sey', 'işte', 'yani'])) score += 0.10;
    if (_containsAny(text, const ['tam olarak', 'emin değilim', 'bilmiyorum']))
      score += 0.18;
    return score.clamp(0.0, 1.0);
  }

  bool _shouldClarify({
    required String text,
    required String primaryIntent,
    required bool explicitQuestion,
    required double commandStrength,
    required double confusionLevel,
  }) {
    if (primaryIntent == 'belirsiz') return true;
    if (explicitQuestion && text.length < 8) return true;
    if (confusionLevel >= 0.34) return true;
    if (primaryIntent == 'eylem' &&
        commandStrength > 0.30 &&
        !_containsAny(text, const [
          'ara',
          'aç',
          'ac',
          'kapat',
          'başlat',
          'baslat',
        ])) {
      return true;
    }
    return false;
  }

  bool _shouldAskFollowUp({
    required String text,
    required String primaryIntent,
    required bool needsExplanation,
    required double emotionalWeight,
  }) {
    if (primaryIntent == 'duygusal') return true;
    if (needsExplanation) return true;
    if (emotionalWeight >= 0.42) return true;
    if (primaryIntent == 'sohbet' &&
        _containsAny(text, const [
          'sohbet edelim',
          'benimle konuş',
          'benimle konus',
          'biraz konuşalım',
          'biraz konusalim',
        ])) {
      return true;
    }
    return _containsAny(text, const [
      'ne önerirsin',
      'ne onerirsin',
      'sence ne yapayım',
      'sence ne yapayim',
    ]);
  }

  String _topicSummary(String text) {
    final words = text
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü ]', unicode: true), ' ')
        .split(' ')
        .where((e) => e.trim().length >= 3)
        .take(7)
        .toList(growable: false);
    return words.isEmpty ? 'genel konuşma' : words.join(' ');
  }

  bool _containsAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) return true;
    }
    return false;
  }
}
