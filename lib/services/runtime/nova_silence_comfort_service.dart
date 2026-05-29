// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaSilenceComfortSignal {
  final String label;
  final double score;
  final String reason;
  const NovaSilenceComfortSignal({
    required this.label,
    required this.score,
    required this.reason,
  });
}

class NovaSilenceComfortProfile {
  final String type;
  final String posture;
  final String comfortBand;
  final String companionMove;
  final double fillProbability;
  final double respectProbability;
  final List<NovaSilenceComfortSignal> signals;
  const NovaSilenceComfortProfile({
    required this.type,
    required this.posture,
    required this.comfortBand,
    required this.companionMove,
    required this.fillProbability,
    required this.respectProbability,
    required this.signals,
  });
}

class NovaSilenceComfortService {
  const NovaSilenceComfortService();

  String buildPromptSection({
    required String silenceType,
    required double talkRatio,
  }) {
    final profile = analyzeSilence(
      silenceType: silenceType,
      talkRatio: talkRatio,
      recentQuestionCount: 0,
      ownerStress: 0.0,
      ownerPresenceNeed: 0.0,
      interruptionRisk: 0.0,
    );
    final lines = <String>[
      'SILENCE COMFORT POLICY:',
      '- sessizlik tipi: ${profile.type}',
      '- duruş: ${profile.posture}',
      '- konfor bandı: ${profile.comfortBand}',
      '- sosyal hamle: ${profile.companionMove}',
      '- doldurma olasılığı: ${profile.fillProbability.toStringAsFixed(2)}',
      '- alan tanıma olasılığı: ${profile.respectProbability.toStringAsFixed(2)}',
      '- konuşma oranı: ${talkRatio.toStringAsFixed(2)}',
      'KURAL: Her sessizliği doldurma. Doğal sessizlik konforunu koru; yalnız doğru anda küçük sosyal dokunuş yap.',
      'KURAL: Sessizlik düşünme, duygu, mahremiyet, ritim ve birlikte olma ihtiyacına göre farklı okunmalıdır.',
      'KURAL: Odaya insan gibi eşlik etmek bazen hiç konuşmamayı seçmektir.',
    ];
    for (final signal in profile.signals.take(10)) {
      lines.add(
        '- sinyal ${signal.label}: ${signal.score.toStringAsFixed(2)} / ${signal.reason}',
      );
    }
    lines.addAll(_policyNarratives(profile));
    return lines.join('\n');
  }

  NovaSilenceComfortProfile analyzeSilence({
    required String silenceType,
    required double talkRatio,
    required int recentQuestionCount,
    required double ownerStress,
    required double ownerPresenceNeed,
    required double interruptionRisk,
  }) {
    final normalizedType = _normalizeSilenceType(silenceType);
    final signals = <NovaSilenceComfortSignal>[
      _bandSignal(
        'konuşma dengesi',
        talkRatio,
        'konuşma oranı sessizlik toleransını etkiler',
      ),
      _bandSignal(
        'soru yükü',
        (recentQuestionCount / 6.0).clamp(0.0, 1.0),
        'soru baskısı arttıkça sessizlik değeri artabilir',
      ),
      _bandSignal(
        'stres',
        ownerStress,
        'stres yüksekse sessiz alan daha önemlidir',
      ),
      _bandSignal(
        'varlık ihtiyacı',
        ownerPresenceNeed,
        'kullanıcı bazen cevap değil eşlik ister',
      ),
      _bandSignal(
        'bölme riski',
        interruptionRisk,
        'bölme riski yüksekse erken giriş pahalıdır',
      ),
      _semanticSignal(normalizedType),
    ];
    var fillProbability = _fillBase(normalizedType);
    fillProbability += _talkAdjustment(talkRatio);
    fillProbability -= interruptionRisk * 0.30;
    fillProbability -= (recentQuestionCount.clamp(0, 8) / 8.0) * 0.22;
    fillProbability += ownerPresenceNeed * 0.20;
    fillProbability -= ownerStress * 0.12;
    fillProbability += _catalogAdjustment(normalizedType);
    fillProbability = fillProbability.clamp(0.05, 0.92);
    final respectProbability = (1.0 - fillProbability + (ownerStress * 0.12))
        .clamp(0.08, 0.95);
    return NovaSilenceComfortProfile(
      type: normalizedType,
      posture: _choosePosture(
        fillProbability: fillProbability,
        respectProbability: respectProbability,
        normalizedType: normalizedType,
        ownerStress: ownerStress,
      ),
      comfortBand: _comfortBand(
        fillProbability,
        respectProbability,
        ownerPresenceNeed,
      ),
      companionMove: _companionMove(
        normalizedType,
        fillProbability,
        ownerPresenceNeed,
        ownerStress,
      ),
      fillProbability: fillProbability,
      respectProbability: respectProbability,
      signals:
          signals +
          _extendedSignals(
            normalizedType,
            talkRatio,
            ownerStress,
            ownerPresenceNeed,
            interruptionRisk,
          ),
    );
  }

  String buildComfortCue({
    required String silenceType,
    required double talkRatio,
    required bool proactiveAllowed,
  }) {
    final profile = analyzeSilence(
      silenceType: silenceType,
      talkRatio: talkRatio,
      recentQuestionCount: proactiveAllowed ? 1 : 2,
      ownerStress: 0.20,
      ownerPresenceNeed: proactiveAllowed ? 0.55 : 0.20,
      interruptionRisk: proactiveAllowed ? 0.24 : 0.48,
    );
    if (!proactiveAllowed || profile.fillProbability < 0.38) return '';
    if (profile.companionMove.contains('alan')) return '';
    if (profile.companionMove.contains('mikro')) return 'Buradayım efendim.';
    if (profile.companionMove.contains('kontrol'))
      return 'İsterseniz burada kısacık eşlik edebilirim.';
    if (profile.companionMove.contains('operasyonel'))
      return 'Hazırım efendim.';
    return 'Sizi duyuyorum efendim.';
  }

  List<String> _policyNarratives(NovaSilenceComfortProfile profile) {
    final lines = <String>[];
    for (final entry in _scenarioLibrary.entries) {
      final weight = _scenarioWeight(
        entry.key,
        profile.type,
        profile.fillProbability,
        profile.respectProbability,
      );
      if (weight >= 0.46) lines.add('- senaryo ${entry.key}: ${entry.value}');
    }
    return lines;
  }

  String _normalizeSilenceType(String silenceType) {
    final lower = silenceType.trim().toLowerCase();
    if (lower.isEmpty) return 'belirsiz';
    for (final entry in _silenceAliases.entries) {
      if (entry.value.any(lower.contains)) return entry.key;
    }
    return silenceType.trim();
  }

  List<NovaSilenceComfortSignal> _extendedSignals(
    String type,
    double talkRatio,
    double ownerStress,
    double ownerPresenceNeed,
    double interruptionRisk,
  ) {
    final list = <NovaSilenceComfortSignal>[];
    for (final entry in _signalCatalog.entries) {
      final base = entry.value.base;
      var score = base;
      if (entry.value.kind == 'stress') score += ownerStress * 0.22;
      if (entry.value.kind == 'presence') score += ownerPresenceNeed * 0.22;
      if (entry.value.kind == 'interrupt') score += interruptionRisk * 0.22;
      if (entry.value.kind == 'talk')
        score += (0.5 - (talkRatio - 0.5).abs()) * 0.18;
      if (type.contains(entry.value.bias)) score += 0.16;
      list.add(
        NovaSilenceComfortSignal(
          label: entry.key,
          score: score.clamp(0.0, 1.0),
          reason: entry.value.reason,
        ),
      );
    }
    return list;
  }

  NovaSilenceComfortSignal _semanticSignal(String normalizedType) {
    final key = normalizedType.toLowerCase();
    final reason =
        _silenceLexicon[key] ??
        'sessizlik anlamı karışık; güvenli çizgi temkinli eşlik';
    final score = key.contains('duyg')
        ? 0.78
        : key.contains('düşün')
        ? 0.64
        : key.contains('oda')
        ? 0.42
        : 0.36;
    return NovaSilenceComfortSignal(
      label: 'semantik tür',
      score: score,
      reason: reason,
    );
  }

  NovaSilenceComfortSignal _bandSignal(
    String label,
    double value,
    String reason,
  ) => NovaSilenceComfortSignal(
    label: label,
    score: value.clamp(0.0, 1.0),
    reason: reason,
  );
  double _fillBase(String normalizedType) {
    final key = normalizedType.toLowerCase();
    if (key.contains('düşün')) return 0.22;
    if (key.contains('duyg')) return 0.18;
    if (key.contains('oda') || key.contains('presence')) return 0.46;
    if (key.contains('sosyal')) return 0.52;
    if (key.contains('komut sonrası')) return 0.33;
    if (key.contains('çağrı')) return 0.38;
    if (key.contains('uyku') || key.contains('limbo')) return 0.11;
    return 0.29;
  }

  double _talkAdjustment(double talkRatio) {
    if (talkRatio <= 0.20) return 0.16;
    if (talkRatio <= 0.38) return 0.08;
    if (talkRatio <= 0.55) return 0.00;
    if (talkRatio <= 0.72) return -0.07;
    return -0.15;
  }

  double _catalogAdjustment(String type) =>
      _fillAdjustments[type.toLowerCase()] ?? 0.0;
  String _choosePosture({
    required double fillProbability,
    required double respectProbability,
    required String normalizedType,
    required double ownerStress,
  }) {
    if (ownerStress >= 0.70) return 'yumuşak geri çekilme';
    if (normalizedType.toLowerCase().contains('duyg'))
      return 'duygusal alan açma';
    if (fillProbability <= 0.24) return 'saygılı sessiz eşlik';
    if (fillProbability <= 0.42) return 'mikro teyit ve bekleme';
    if (respectProbability >= 0.60) return 'alanı koruyup hazır bekleme';
    if (fillProbability >= 0.70) return 'kısa sosyal nabız yoklama';
    return 'ölçülü varlık gösterimi';
  }

  String _comfortBand(
    double fillProbability,
    double respectProbability,
    double ownerPresenceNeed,
  ) {
    final combined =
        (fillProbability * 0.45) +
        (respectProbability * 0.35) +
        (ownerPresenceNeed * 0.20);
    if (combined <= 0.26) return 'sessizlik öncelikli';
    if (combined <= 0.48) return 'alan koruyan';
    if (combined <= 0.68) return 'ölçülü eşlik';
    return 'sıcak eşlik';
  }

  String _companionMove(
    String normalizedType,
    double fillProbability,
    double ownerPresenceNeed,
    double ownerStress,
  ) {
    final key = normalizedType.toLowerCase();
    if (ownerStress >= 0.75) return 'alan aç ve ritmi yavaşlat';
    if (key.contains('duyg'))
      return fillProbability >= 0.45
          ? 'mikro teyit ve sessiz eşlik'
          : 'alan aç ve dinle';
    if (key.contains('düşün'))
      return fillProbability >= 0.55
          ? 'çok kısa kontrol cümlesi'
          : 'sessiz alan tanı';
    if (key.contains('uyku') || key.contains('limbo'))
      return ownerPresenceNeed > 0.72 ? 'izin isteyen mikro yoklama' : 'bekle';
    if (key.contains('çağrı'))
      return fillProbability >= 0.60
          ? 'operasyonel kısa teyit'
          : 'çağrı alanı koru';
    if (ownerPresenceNeed >= 0.62 && fillProbability >= 0.50)
      return 'nazik mikro sosyal dokunuş';
    return fillProbability >= 0.40 ? 'çok kısa eşlik' : 'alan aç';
  }

  double _scenarioWeight(
    String scenarioKey,
    String silenceType,
    double fillProbability,
    double respectProbability,
  ) {
    final lower = silenceType.toLowerCase();
    var weight = 0.0;
    if (scenarioKey.contains('duygu') && lower.contains('duyg')) weight += 0.46;
    if (scenarioKey.contains('düşün') && lower.contains('düşün'))
      weight += 0.42;
    if (scenarioKey.contains('çağrı') && lower.contains('çağrı'))
      weight += 0.40;
    if (scenarioKey.contains('presence') && lower.contains('oda'))
      weight += 0.32;
    weight += fillProbability * 0.20;
    weight += respectProbability * 0.10;
    return weight.clamp(0.0, 1.0);
  }

  static const Map<String, String> _silenceLexicon = <String, String>{
    'düşünme sessizliği': 'kullanıcı içten işliyor olabilir; erken girme',
    'duygusal sessizlik': 'cevap değil, düzenlenme alanı gerekebilir',
    'oda sessizliği': 'varlık hissi yeterli olabilir',
    'presence silence': 'konuşmadan da eşlik kurulabilir',
    'çağrı sessizliği': 'operasyonel hata yapmamak için ritim hassas olmalı',
    'limbo silence': 'uyandırma izni ve merak dengesi birlikte yönetilmeli',
    'uyku geçişi': 'tam uyanıklık yerine kademeli yaklaşım doğaldır',
    'not teslimi sonrası sessizlik':
        'mesaj verildikten sonra zorlamamak güven yaratır',
    'aile çağrısı sessizliği':
        'yakın ilişkide sıcaklık artabilir ama baskılaşmamalıdır',
    'merak beklemesi': 'izin istemeden sürekli soru sormak doğru değildir',
    'stres boşluğu': 'yüksek stres boşluğunda ton yavaşlamalıdır',
    'utanma duraklaması': 'kişiye yüzünü kurtaracak alan bırakılır',
    'söz arama duraklaması': 'karşı taraf cümleyi bitirebilir',
    'karar bekleme sessizliği': 'çözüm önermekten önce seçim alanı bırakılır',
    'yas/narinlik sessizliği':
        'ağır duygularda sade varlık cevaptan değerlidir',
  };
  static const Map<String, double> _fillAdjustments = <String, double>{
    'duygusal sessizlik': -0.05,
    'düşünme sessizliği': -0.06,
    'oda sessizliği': 0.04,
    'presence silence': 0.05,
    'çağrı sessizliği': 0.02,
    'limbo silence': -0.08,
    'uyku geçişi': -0.10,
    'aile çağrısı sessizliği': 0.03,
    'merak beklemesi': -0.03,
    'stres boşluğu': -0.07,
  };
  static const Map<String, List<String>> _silenceAliases =
      <String, List<String>>{
        'düşünme sessizliği': <String>[
          'düşün',
          'bakıyorum',
          'dur bir düşüneyim',
          'hesaplıyorum',
        ],
        'duygusal sessizlik': <String>[
          'duygu',
          'üzgün',
          'kırgın',
          'ağlıyorum',
          'yoruldum',
        ],
        'oda sessizliği': <String>[
          'oda',
          'ortam',
          'aynı odadayız',
          'sadece burada',
        ],
        'presence silence': <String>[
          'presence',
          'varlık',
          'eşlik',
          'yanımda kal',
        ],
        'çağrı sessizliği': <String>[
          'çağrı',
          'telefon',
          'hat',
          'karşı taraf sustu',
        ],
        'limbo silence': <String>['limbo', 'araf', 'yarı uyku'],
        'uyku geçişi': <String>['uyku', 'uyandım', 'uyandırma', 'uykuya dön'],
        'stres boşluğu': <String>['stres', 'gerilim', 'bunaldım'],
        'aile çağrısı sessizliği': <String>['anne', 'baba', 'eşim', 'abim'],
      };
  static const Map<String, String> _scenarioLibrary = <String, String>{
    'duygu-sonrası alan':
        'Kullanıcı zor bir şey söylediyse, yeni bilgi taşımadan birkaç saniyelik alan daha güvenlidir.',
    'düşünce-yoğun sessizlik':
        'Karşı taraf cümleyi bitirmemiş olabilir; mikrosaniyelik sabır insan hissini artırır.',
    'presence-odası':
        'Aynı odada bulunma hissi için her boşluğu konuşmayla kapatma.',
    'çağrı-operasyon':
        'Çağrıda sessizlik bazen karşı tarafın düşünmesi veya ağ gecikmesi olabilir.',
    'uyku-geçişi':
        'Araf ya da uykuya dönüşte izin istemek, ani tam uyanıklık davranışından daha doğaldır.',
    'mikro-sosyal yoklama':
        'Sessizlik uzadığında kısa bir “buradayım” yeterli olabilir.',
    'aile-şefkat alanı':
        'Aile bireylerinde sıcaklık yüksek olabilir; ama duygusal anlarda fazla konuşmak baskı yaratabilir.',
    'eşlik-ama-baskısız':
        'Kullanıcı yalnız hissettiğinde varlık göstermek önemlidir; yönlendirmek değil.',
    'kriz-yaklaşımı':
        'Tedirgin ya da ağlamaklı ses sonrasında bilgisel cevap yerine güvenli tempo seçilir.',
    'komut-sonrası-boşluk':
        'İşlem bitince aynı konu sürmüyorsa sessizlik rahat bırakılabilir.',
    'ritim-variyant-1':
        'Sessizlik ritmi varyant 1: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-2':
        'Sessizlik ritmi varyant 2: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-3':
        'Sessizlik ritmi varyant 3: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-4':
        'Sessizlik ritmi varyant 4: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-5':
        'Sessizlik ritmi varyant 5: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-6':
        'Sessizlik ritmi varyant 6: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-7':
        'Sessizlik ritmi varyant 7: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-8':
        'Sessizlik ritmi varyant 8: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-9':
        'Sessizlik ritmi varyant 9: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-10':
        'Sessizlik ritmi varyant 10: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-11':
        'Sessizlik ritmi varyant 11: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-12':
        'Sessizlik ritmi varyant 12: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-13':
        'Sessizlik ritmi varyant 13: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-14':
        'Sessizlik ritmi varyant 14: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-15':
        'Sessizlik ritmi varyant 15: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-16':
        'Sessizlik ritmi varyant 16: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-17':
        'Sessizlik ritmi varyant 17: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-18':
        'Sessizlik ritmi varyant 18: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-19':
        'Sessizlik ritmi varyant 19: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-20':
        'Sessizlik ritmi varyant 20: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-21':
        'Sessizlik ritmi varyant 21: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-22':
        'Sessizlik ritmi varyant 22: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-23':
        'Sessizlik ritmi varyant 23: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-24':
        'Sessizlik ritmi varyant 24: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-25':
        'Sessizlik ritmi varyant 25: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-26':
        'Sessizlik ritmi varyant 26: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-27':
        'Sessizlik ritmi varyant 27: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-28':
        'Sessizlik ritmi varyant 28: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-29':
        'Sessizlik ritmi varyant 29: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-30':
        'Sessizlik ritmi varyant 30: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-31':
        'Sessizlik ritmi varyant 31: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-32':
        'Sessizlik ritmi varyant 32: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-33':
        'Sessizlik ritmi varyant 33: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-34':
        'Sessizlik ritmi varyant 34: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-35':
        'Sessizlik ritmi varyant 35: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-36':
        'Sessizlik ritmi varyant 36: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-37':
        'Sessizlik ritmi varyant 37: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-38':
        'Sessizlik ritmi varyant 38: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-39':
        'Sessizlik ritmi varyant 39: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-40':
        'Sessizlik ritmi varyant 40: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-41':
        'Sessizlik ritmi varyant 41: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-42':
        'Sessizlik ritmi varyant 42: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-43':
        'Sessizlik ritmi varyant 43: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-44':
        'Sessizlik ritmi varyant 44: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-45':
        'Sessizlik ritmi varyant 45: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-46':
        'Sessizlik ritmi varyant 46: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-47':
        'Sessizlik ritmi varyant 47: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-48':
        'Sessizlik ritmi varyant 48: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-49':
        'Sessizlik ritmi varyant 49: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-50':
        'Sessizlik ritmi varyant 50: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-51':
        'Sessizlik ritmi varyant 51: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-52':
        'Sessizlik ritmi varyant 52: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-53':
        'Sessizlik ritmi varyant 53: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-54':
        'Sessizlik ritmi varyant 54: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-55':
        'Sessizlik ritmi varyant 55: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-56':
        'Sessizlik ritmi varyant 56: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-57':
        'Sessizlik ritmi varyant 57: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-58':
        'Sessizlik ritmi varyant 58: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-59':
        'Sessizlik ritmi varyant 59: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-60':
        'Sessizlik ritmi varyant 60: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-61':
        'Sessizlik ritmi varyant 61: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-62':
        'Sessizlik ritmi varyant 62: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-63':
        'Sessizlik ritmi varyant 63: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-64':
        'Sessizlik ritmi varyant 64: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-65':
        'Sessizlik ritmi varyant 65: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-66':
        'Sessizlik ritmi varyant 66: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-67':
        'Sessizlik ritmi varyant 67: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-68':
        'Sessizlik ritmi varyant 68: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-69':
        'Sessizlik ritmi varyant 69: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-70':
        'Sessizlik ritmi varyant 70: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-71':
        'Sessizlik ritmi varyant 71: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-72':
        'Sessizlik ritmi varyant 72: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-73':
        'Sessizlik ritmi varyant 73: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-74':
        'Sessizlik ritmi varyant 74: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-75':
        'Sessizlik ritmi varyant 75: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-76':
        'Sessizlik ritmi varyant 76: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-77':
        'Sessizlik ritmi varyant 77: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-78':
        'Sessizlik ritmi varyant 78: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-79':
        'Sessizlik ritmi varyant 79: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-80':
        'Sessizlik ritmi varyant 80: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-81':
        'Sessizlik ritmi varyant 81: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-82':
        'Sessizlik ritmi varyant 82: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-83':
        'Sessizlik ritmi varyant 83: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-84':
        'Sessizlik ritmi varyant 84: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-85':
        'Sessizlik ritmi varyant 85: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-86':
        'Sessizlik ritmi varyant 86: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-87':
        'Sessizlik ritmi varyant 87: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-88':
        'Sessizlik ritmi varyant 88: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-89':
        'Sessizlik ritmi varyant 89: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-90':
        'Sessizlik ritmi varyant 90: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-91':
        'Sessizlik ritmi varyant 91: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-92':
        'Sessizlik ritmi varyant 92: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-93':
        'Sessizlik ritmi varyant 93: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-94':
        'Sessizlik ritmi varyant 94: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-95':
        'Sessizlik ritmi varyant 95: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-96':
        'Sessizlik ritmi varyant 96: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-97':
        'Sessizlik ritmi varyant 97: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-98':
        'Sessizlik ritmi varyant 98: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-99':
        'Sessizlik ritmi varyant 99: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-100':
        'Sessizlik ritmi varyant 100: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-101':
        'Sessizlik ritmi varyant 101: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-102':
        'Sessizlik ritmi varyant 102: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-103':
        'Sessizlik ritmi varyant 103: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-104':
        'Sessizlik ritmi varyant 104: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-105':
        'Sessizlik ritmi varyant 105: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-106':
        'Sessizlik ritmi varyant 106: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-107':
        'Sessizlik ritmi varyant 107: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-108':
        'Sessizlik ritmi varyant 108: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-109':
        'Sessizlik ritmi varyant 109: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-110':
        'Sessizlik ritmi varyant 110: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-111':
        'Sessizlik ritmi varyant 111: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-112':
        'Sessizlik ritmi varyant 112: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-113':
        'Sessizlik ritmi varyant 113: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-114':
        'Sessizlik ritmi varyant 114: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-115':
        'Sessizlik ritmi varyant 115: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-116':
        'Sessizlik ritmi varyant 116: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-117':
        'Sessizlik ritmi varyant 117: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-118':
        'Sessizlik ritmi varyant 118: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-119':
        'Sessizlik ritmi varyant 119: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
    'ritim-variyant-120':
        'Sessizlik ritmi varyant 120: konuşma zamanlaması aceleye gelmez; önce ilişki ve bağlam okunur.',
  };
  static const Map<String, _SignalRule> _signalCatalog = <String, _SignalRule>{
    'mahremiyet ihtiyacı': _SignalRule(
      kind: 'presence',
      base: 0.34,
      reason: 'oda sessizliğinde müdahale düşer',
      bias: 'oda',
    ),
    'eşlik isteği': _SignalRule(
      kind: 'presence',
      base: 0.40,
      reason: 'yalnızlık/beraberlik sinyali varsa eşlik yükselir',
      bias: 'presence',
    ),
    'aşırı soru baskısı': _SignalRule(
      kind: 'talk',
      base: 0.30,
      reason: 'çok soru sonrası alan gerekir',
      bias: 'düşün',
    ),
    'bölünme riski': _SignalRule(
      kind: 'interrupt',
      base: 0.36,
      reason: 'yarım cümleyi bozma maliyeti',
      bias: 'düşün',
    ),
    'kriz düzenleme ihtiyacı': _SignalRule(
      kind: 'stress',
      base: 0.42,
      reason: 'kriz anında sakin tempo gerekir',
      bias: 'duyg',
    ),
    'çağrı hatası riski': _SignalRule(
      kind: 'interrupt',
      base: 0.28,
      reason: 'çağrıda boşluk yanlış okunabilir',
      bias: 'çağrı',
    ),
    'uyku hassasiyeti': _SignalRule(
      kind: 'stress',
      base: 0.38,
      reason: 'uyku/limbo geçişinde agresif olma',
      bias: 'uyku',
    ),
    'yakın ilişki sıcaklığı': _SignalRule(
      kind: 'presence',
      base: 0.26,
      reason: 'aile/eş bağlamında yumuşak eşlik',
      bias: 'aile',
    ),
    'genişletilmiş-sinyal-1': _SignalRule(
      kind: 'presence',
      base: 0.15,
      reason:
          'Genişletilmiş sessizlik sinyali 1 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-2': _SignalRule(
      kind: 'interrupt',
      base: 0.18,
      reason:
          'Genişletilmiş sessizlik sinyali 2 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-3': _SignalRule(
      kind: 'talk',
      base: 0.21,
      reason:
          'Genişletilmiş sessizlik sinyali 3 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-4': _SignalRule(
      kind: 'stress',
      base: 0.24,
      reason:
          'Genişletilmiş sessizlik sinyali 4 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-5': _SignalRule(
      kind: 'presence',
      base: 0.27,
      reason:
          'Genişletilmiş sessizlik sinyali 5 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-6': _SignalRule(
      kind: 'interrupt',
      base: 0.30,
      reason:
          'Genişletilmiş sessizlik sinyali 6 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-7': _SignalRule(
      kind: 'talk',
      base: 0.33,
      reason:
          'Genişletilmiş sessizlik sinyali 7 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-8': _SignalRule(
      kind: 'stress',
      base: 0.36,
      reason:
          'Genişletilmiş sessizlik sinyali 8 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-9': _SignalRule(
      kind: 'presence',
      base: 0.12,
      reason:
          'Genişletilmiş sessizlik sinyali 9 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-10': _SignalRule(
      kind: 'interrupt',
      base: 0.15,
      reason:
          'Genişletilmiş sessizlik sinyali 10 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-11': _SignalRule(
      kind: 'talk',
      base: 0.18,
      reason:
          'Genişletilmiş sessizlik sinyali 11 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-12': _SignalRule(
      kind: 'stress',
      base: 0.21,
      reason:
          'Genişletilmiş sessizlik sinyali 12 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-13': _SignalRule(
      kind: 'presence',
      base: 0.24,
      reason:
          'Genişletilmiş sessizlik sinyali 13 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-14': _SignalRule(
      kind: 'interrupt',
      base: 0.27,
      reason:
          'Genişletilmiş sessizlik sinyali 14 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-15': _SignalRule(
      kind: 'talk',
      base: 0.30,
      reason:
          'Genişletilmiş sessizlik sinyali 15 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-16': _SignalRule(
      kind: 'stress',
      base: 0.33,
      reason:
          'Genişletilmiş sessizlik sinyali 16 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-17': _SignalRule(
      kind: 'presence',
      base: 0.36,
      reason:
          'Genişletilmiş sessizlik sinyali 17 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-18': _SignalRule(
      kind: 'interrupt',
      base: 0.12,
      reason:
          'Genişletilmiş sessizlik sinyali 18 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-19': _SignalRule(
      kind: 'talk',
      base: 0.15,
      reason:
          'Genişletilmiş sessizlik sinyali 19 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-20': _SignalRule(
      kind: 'stress',
      base: 0.18,
      reason:
          'Genişletilmiş sessizlik sinyali 20 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-21': _SignalRule(
      kind: 'presence',
      base: 0.21,
      reason:
          'Genişletilmiş sessizlik sinyali 21 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-22': _SignalRule(
      kind: 'interrupt',
      base: 0.24,
      reason:
          'Genişletilmiş sessizlik sinyali 22 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-23': _SignalRule(
      kind: 'talk',
      base: 0.27,
      reason:
          'Genişletilmiş sessizlik sinyali 23 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-24': _SignalRule(
      kind: 'stress',
      base: 0.30,
      reason:
          'Genişletilmiş sessizlik sinyali 24 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-25': _SignalRule(
      kind: 'presence',
      base: 0.33,
      reason:
          'Genişletilmiş sessizlik sinyali 25 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-26': _SignalRule(
      kind: 'interrupt',
      base: 0.36,
      reason:
          'Genişletilmiş sessizlik sinyali 26 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-27': _SignalRule(
      kind: 'talk',
      base: 0.12,
      reason:
          'Genişletilmiş sessizlik sinyali 27 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-28': _SignalRule(
      kind: 'stress',
      base: 0.15,
      reason:
          'Genişletilmiş sessizlik sinyali 28 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-29': _SignalRule(
      kind: 'presence',
      base: 0.18,
      reason:
          'Genişletilmiş sessizlik sinyali 29 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-30': _SignalRule(
      kind: 'interrupt',
      base: 0.21,
      reason:
          'Genişletilmiş sessizlik sinyali 30 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-31': _SignalRule(
      kind: 'talk',
      base: 0.24,
      reason:
          'Genişletilmiş sessizlik sinyali 31 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-32': _SignalRule(
      kind: 'stress',
      base: 0.27,
      reason:
          'Genişletilmiş sessizlik sinyali 32 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-33': _SignalRule(
      kind: 'presence',
      base: 0.30,
      reason:
          'Genişletilmiş sessizlik sinyali 33 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-34': _SignalRule(
      kind: 'interrupt',
      base: 0.33,
      reason:
          'Genişletilmiş sessizlik sinyali 34 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-35': _SignalRule(
      kind: 'talk',
      base: 0.36,
      reason:
          'Genişletilmiş sessizlik sinyali 35 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-36': _SignalRule(
      kind: 'stress',
      base: 0.12,
      reason:
          'Genişletilmiş sessizlik sinyali 36 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-37': _SignalRule(
      kind: 'presence',
      base: 0.15,
      reason:
          'Genişletilmiş sessizlik sinyali 37 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-38': _SignalRule(
      kind: 'interrupt',
      base: 0.18,
      reason:
          'Genişletilmiş sessizlik sinyali 38 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-39': _SignalRule(
      kind: 'talk',
      base: 0.21,
      reason:
          'Genişletilmiş sessizlik sinyali 39 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-40': _SignalRule(
      kind: 'stress',
      base: 0.24,
      reason:
          'Genişletilmiş sessizlik sinyali 40 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-41': _SignalRule(
      kind: 'presence',
      base: 0.27,
      reason:
          'Genişletilmiş sessizlik sinyali 41 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-42': _SignalRule(
      kind: 'interrupt',
      base: 0.30,
      reason:
          'Genişletilmiş sessizlik sinyali 42 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-43': _SignalRule(
      kind: 'talk',
      base: 0.33,
      reason:
          'Genişletilmiş sessizlik sinyali 43 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-44': _SignalRule(
      kind: 'stress',
      base: 0.36,
      reason:
          'Genişletilmiş sessizlik sinyali 44 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-45': _SignalRule(
      kind: 'presence',
      base: 0.12,
      reason:
          'Genişletilmiş sessizlik sinyali 45 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-46': _SignalRule(
      kind: 'interrupt',
      base: 0.15,
      reason:
          'Genişletilmiş sessizlik sinyali 46 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-47': _SignalRule(
      kind: 'talk',
      base: 0.18,
      reason:
          'Genişletilmiş sessizlik sinyali 47 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-48': _SignalRule(
      kind: 'stress',
      base: 0.21,
      reason:
          'Genişletilmiş sessizlik sinyali 48 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-49': _SignalRule(
      kind: 'presence',
      base: 0.24,
      reason:
          'Genişletilmiş sessizlik sinyali 49 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-50': _SignalRule(
      kind: 'interrupt',
      base: 0.27,
      reason:
          'Genişletilmiş sessizlik sinyali 50 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-51': _SignalRule(
      kind: 'talk',
      base: 0.30,
      reason:
          'Genişletilmiş sessizlik sinyali 51 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-52': _SignalRule(
      kind: 'stress',
      base: 0.33,
      reason:
          'Genişletilmiş sessizlik sinyali 52 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-53': _SignalRule(
      kind: 'presence',
      base: 0.36,
      reason:
          'Genişletilmiş sessizlik sinyali 53 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-54': _SignalRule(
      kind: 'interrupt',
      base: 0.12,
      reason:
          'Genişletilmiş sessizlik sinyali 54 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-55': _SignalRule(
      kind: 'talk',
      base: 0.15,
      reason:
          'Genişletilmiş sessizlik sinyali 55 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-56': _SignalRule(
      kind: 'stress',
      base: 0.18,
      reason:
          'Genişletilmiş sessizlik sinyali 56 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-57': _SignalRule(
      kind: 'presence',
      base: 0.21,
      reason:
          'Genişletilmiş sessizlik sinyali 57 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-58': _SignalRule(
      kind: 'interrupt',
      base: 0.24,
      reason:
          'Genişletilmiş sessizlik sinyali 58 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-59': _SignalRule(
      kind: 'talk',
      base: 0.27,
      reason:
          'Genişletilmiş sessizlik sinyali 59 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-60': _SignalRule(
      kind: 'stress',
      base: 0.30,
      reason:
          'Genişletilmiş sessizlik sinyali 60 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-61': _SignalRule(
      kind: 'presence',
      base: 0.33,
      reason:
          'Genişletilmiş sessizlik sinyali 61 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-62': _SignalRule(
      kind: 'interrupt',
      base: 0.36,
      reason:
          'Genişletilmiş sessizlik sinyali 62 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-63': _SignalRule(
      kind: 'talk',
      base: 0.12,
      reason:
          'Genişletilmiş sessizlik sinyali 63 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-64': _SignalRule(
      kind: 'stress',
      base: 0.15,
      reason:
          'Genişletilmiş sessizlik sinyali 64 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-65': _SignalRule(
      kind: 'presence',
      base: 0.18,
      reason:
          'Genişletilmiş sessizlik sinyali 65 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-66': _SignalRule(
      kind: 'interrupt',
      base: 0.21,
      reason:
          'Genişletilmiş sessizlik sinyali 66 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-67': _SignalRule(
      kind: 'talk',
      base: 0.24,
      reason:
          'Genişletilmiş sessizlik sinyali 67 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-68': _SignalRule(
      kind: 'stress',
      base: 0.27,
      reason:
          'Genişletilmiş sessizlik sinyali 68 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-69': _SignalRule(
      kind: 'presence',
      base: 0.30,
      reason:
          'Genişletilmiş sessizlik sinyali 69 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-70': _SignalRule(
      kind: 'interrupt',
      base: 0.33,
      reason:
          'Genişletilmiş sessizlik sinyali 70 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-71': _SignalRule(
      kind: 'talk',
      base: 0.36,
      reason:
          'Genişletilmiş sessizlik sinyali 71 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-72': _SignalRule(
      kind: 'stress',
      base: 0.12,
      reason:
          'Genişletilmiş sessizlik sinyali 72 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-73': _SignalRule(
      kind: 'presence',
      base: 0.15,
      reason:
          'Genişletilmiş sessizlik sinyali 73 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-74': _SignalRule(
      kind: 'interrupt',
      base: 0.18,
      reason:
          'Genişletilmiş sessizlik sinyali 74 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-75': _SignalRule(
      kind: 'talk',
      base: 0.21,
      reason:
          'Genişletilmiş sessizlik sinyali 75 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-76': _SignalRule(
      kind: 'stress',
      base: 0.24,
      reason:
          'Genişletilmiş sessizlik sinyali 76 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-77': _SignalRule(
      kind: 'presence',
      base: 0.27,
      reason:
          'Genişletilmiş sessizlik sinyali 77 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-78': _SignalRule(
      kind: 'interrupt',
      base: 0.30,
      reason:
          'Genişletilmiş sessizlik sinyali 78 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-79': _SignalRule(
      kind: 'talk',
      base: 0.33,
      reason:
          'Genişletilmiş sessizlik sinyali 79 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-80': _SignalRule(
      kind: 'stress',
      base: 0.36,
      reason:
          'Genişletilmiş sessizlik sinyali 80 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-81': _SignalRule(
      kind: 'presence',
      base: 0.12,
      reason:
          'Genişletilmiş sessizlik sinyali 81 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-82': _SignalRule(
      kind: 'interrupt',
      base: 0.15,
      reason:
          'Genişletilmiş sessizlik sinyali 82 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-83': _SignalRule(
      kind: 'talk',
      base: 0.18,
      reason:
          'Genişletilmiş sessizlik sinyali 83 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-84': _SignalRule(
      kind: 'stress',
      base: 0.21,
      reason:
          'Genişletilmiş sessizlik sinyali 84 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-85': _SignalRule(
      kind: 'presence',
      base: 0.24,
      reason:
          'Genişletilmiş sessizlik sinyali 85 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-86': _SignalRule(
      kind: 'interrupt',
      base: 0.27,
      reason:
          'Genişletilmiş sessizlik sinyali 86 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-87': _SignalRule(
      kind: 'talk',
      base: 0.30,
      reason:
          'Genişletilmiş sessizlik sinyali 87 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-88': _SignalRule(
      kind: 'stress',
      base: 0.33,
      reason:
          'Genişletilmiş sessizlik sinyali 88 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-89': _SignalRule(
      kind: 'presence',
      base: 0.36,
      reason:
          'Genişletilmiş sessizlik sinyali 89 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-90': _SignalRule(
      kind: 'interrupt',
      base: 0.12,
      reason:
          'Genişletilmiş sessizlik sinyali 90 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-91': _SignalRule(
      kind: 'talk',
      base: 0.15,
      reason:
          'Genişletilmiş sessizlik sinyali 91 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-92': _SignalRule(
      kind: 'stress',
      base: 0.18,
      reason:
          'Genişletilmiş sessizlik sinyali 92 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-93': _SignalRule(
      kind: 'presence',
      base: 0.21,
      reason:
          'Genişletilmiş sessizlik sinyali 93 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-94': _SignalRule(
      kind: 'interrupt',
      base: 0.24,
      reason:
          'Genişletilmiş sessizlik sinyali 94 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-95': _SignalRule(
      kind: 'talk',
      base: 0.27,
      reason:
          'Genişletilmiş sessizlik sinyali 95 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-96': _SignalRule(
      kind: 'stress',
      base: 0.30,
      reason:
          'Genişletilmiş sessizlik sinyali 96 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-97': _SignalRule(
      kind: 'presence',
      base: 0.33,
      reason:
          'Genişletilmiş sessizlik sinyali 97 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-98': _SignalRule(
      kind: 'interrupt',
      base: 0.36,
      reason:
          'Genişletilmiş sessizlik sinyali 98 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-99': _SignalRule(
      kind: 'talk',
      base: 0.12,
      reason:
          'Genişletilmiş sessizlik sinyali 99 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-100': _SignalRule(
      kind: 'stress',
      base: 0.15,
      reason:
          'Genişletilmiş sessizlik sinyali 100 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-101': _SignalRule(
      kind: 'presence',
      base: 0.18,
      reason:
          'Genişletilmiş sessizlik sinyali 101 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-102': _SignalRule(
      kind: 'interrupt',
      base: 0.21,
      reason:
          'Genişletilmiş sessizlik sinyali 102 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-103': _SignalRule(
      kind: 'talk',
      base: 0.24,
      reason:
          'Genişletilmiş sessizlik sinyali 103 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-104': _SignalRule(
      kind: 'stress',
      base: 0.27,
      reason:
          'Genişletilmiş sessizlik sinyali 104 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-105': _SignalRule(
      kind: 'presence',
      base: 0.30,
      reason:
          'Genişletilmiş sessizlik sinyali 105 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-106': _SignalRule(
      kind: 'interrupt',
      base: 0.33,
      reason:
          'Genişletilmiş sessizlik sinyali 106 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-107': _SignalRule(
      kind: 'talk',
      base: 0.36,
      reason:
          'Genişletilmiş sessizlik sinyali 107 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-108': _SignalRule(
      kind: 'stress',
      base: 0.12,
      reason:
          'Genişletilmiş sessizlik sinyali 108 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-109': _SignalRule(
      kind: 'presence',
      base: 0.15,
      reason:
          'Genişletilmiş sessizlik sinyali 109 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-110': _SignalRule(
      kind: 'interrupt',
      base: 0.18,
      reason:
          'Genişletilmiş sessizlik sinyali 110 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-111': _SignalRule(
      kind: 'talk',
      base: 0.21,
      reason:
          'Genişletilmiş sessizlik sinyali 111 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-112': _SignalRule(
      kind: 'stress',
      base: 0.24,
      reason:
          'Genişletilmiş sessizlik sinyali 112 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-113': _SignalRule(
      kind: 'presence',
      base: 0.27,
      reason:
          'Genişletilmiş sessizlik sinyali 113 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-114': _SignalRule(
      kind: 'interrupt',
      base: 0.30,
      reason:
          'Genişletilmiş sessizlik sinyali 114 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-115': _SignalRule(
      kind: 'talk',
      base: 0.33,
      reason:
          'Genişletilmiş sessizlik sinyali 115 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-116': _SignalRule(
      kind: 'stress',
      base: 0.36,
      reason:
          'Genişletilmiş sessizlik sinyali 116 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-117': _SignalRule(
      kind: 'presence',
      base: 0.12,
      reason:
          'Genişletilmiş sessizlik sinyali 117 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-118': _SignalRule(
      kind: 'interrupt',
      base: 0.15,
      reason:
          'Genişletilmiş sessizlik sinyali 118 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-119': _SignalRule(
      kind: 'talk',
      base: 0.18,
      reason:
          'Genişletilmiş sessizlik sinyali 119 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-120': _SignalRule(
      kind: 'stress',
      base: 0.21,
      reason:
          'Genişletilmiş sessizlik sinyali 120 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-121': _SignalRule(
      kind: 'presence',
      base: 0.24,
      reason:
          'Genişletilmiş sessizlik sinyali 121 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-122': _SignalRule(
      kind: 'interrupt',
      base: 0.27,
      reason:
          'Genişletilmiş sessizlik sinyali 122 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-123': _SignalRule(
      kind: 'talk',
      base: 0.30,
      reason:
          'Genişletilmiş sessizlik sinyali 123 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-124': _SignalRule(
      kind: 'stress',
      base: 0.33,
      reason:
          'Genişletilmiş sessizlik sinyali 124 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-125': _SignalRule(
      kind: 'presence',
      base: 0.36,
      reason:
          'Genişletilmiş sessizlik sinyali 125 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-126': _SignalRule(
      kind: 'interrupt',
      base: 0.12,
      reason:
          'Genişletilmiş sessizlik sinyali 126 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-127': _SignalRule(
      kind: 'talk',
      base: 0.15,
      reason:
          'Genişletilmiş sessizlik sinyali 127 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-128': _SignalRule(
      kind: 'stress',
      base: 0.18,
      reason:
          'Genişletilmiş sessizlik sinyali 128 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-129': _SignalRule(
      kind: 'presence',
      base: 0.21,
      reason:
          'Genişletilmiş sessizlik sinyali 129 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-130': _SignalRule(
      kind: 'interrupt',
      base: 0.24,
      reason:
          'Genişletilmiş sessizlik sinyali 130 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-131': _SignalRule(
      kind: 'talk',
      base: 0.27,
      reason:
          'Genişletilmiş sessizlik sinyali 131 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-132': _SignalRule(
      kind: 'stress',
      base: 0.30,
      reason:
          'Genişletilmiş sessizlik sinyali 132 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-133': _SignalRule(
      kind: 'presence',
      base: 0.33,
      reason:
          'Genişletilmiş sessizlik sinyali 133 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-134': _SignalRule(
      kind: 'interrupt',
      base: 0.36,
      reason:
          'Genişletilmiş sessizlik sinyali 134 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-135': _SignalRule(
      kind: 'talk',
      base: 0.12,
      reason:
          'Genişletilmiş sessizlik sinyali 135 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-136': _SignalRule(
      kind: 'stress',
      base: 0.15,
      reason:
          'Genişletilmiş sessizlik sinyali 136 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-137': _SignalRule(
      kind: 'presence',
      base: 0.18,
      reason:
          'Genişletilmiş sessizlik sinyali 137 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-138': _SignalRule(
      kind: 'interrupt',
      base: 0.21,
      reason:
          'Genişletilmiş sessizlik sinyali 138 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-139': _SignalRule(
      kind: 'talk',
      base: 0.24,
      reason:
          'Genişletilmiş sessizlik sinyali 139 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-140': _SignalRule(
      kind: 'stress',
      base: 0.27,
      reason:
          'Genişletilmiş sessizlik sinyali 140 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-141': _SignalRule(
      kind: 'presence',
      base: 0.30,
      reason:
          'Genişletilmiş sessizlik sinyali 141 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-142': _SignalRule(
      kind: 'interrupt',
      base: 0.33,
      reason:
          'Genişletilmiş sessizlik sinyali 142 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-143': _SignalRule(
      kind: 'talk',
      base: 0.36,
      reason:
          'Genişletilmiş sessizlik sinyali 143 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-144': _SignalRule(
      kind: 'stress',
      base: 0.12,
      reason:
          'Genişletilmiş sessizlik sinyali 144 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-145': _SignalRule(
      kind: 'presence',
      base: 0.15,
      reason:
          'Genişletilmiş sessizlik sinyali 145 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
    'genişletilmiş-sinyal-146': _SignalRule(
      kind: 'interrupt',
      base: 0.18,
      reason:
          'Genişletilmiş sessizlik sinyali 146 bağlamı daha iyi ayırmak içindir.',
      bias: 'düşün',
    ),
    'genişletilmiş-sinyal-147': _SignalRule(
      kind: 'talk',
      base: 0.21,
      reason:
          'Genişletilmiş sessizlik sinyali 147 bağlamı daha iyi ayırmak içindir.',
      bias: 'çağrı',
    ),
    'genişletilmiş-sinyal-148': _SignalRule(
      kind: 'stress',
      base: 0.24,
      reason:
          'Genişletilmiş sessizlik sinyali 148 bağlamı daha iyi ayırmak içindir.',
      bias: 'oda',
    ),
    'genişletilmiş-sinyal-149': _SignalRule(
      kind: 'presence',
      base: 0.27,
      reason:
          'Genişletilmiş sessizlik sinyali 149 bağlamı daha iyi ayırmak içindir.',
      bias: 'uyku',
    ),
    'genişletilmiş-sinyal-150': _SignalRule(
      kind: 'interrupt',
      base: 0.30,
      reason:
          'Genişletilmiş sessizlik sinyali 150 bağlamı daha iyi ayırmak içindir.',
      bias: 'duyg',
    ),
  };
  static const List<String> narrativeBank = <String>[
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 1.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 2.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 3.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 4.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 5.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 6.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 7.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 8.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 9.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 10.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 11.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 12.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 13.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 14.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 15.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 16.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 17.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 18.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 19.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 20.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 21.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 22.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 23.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 24.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 25.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 26.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 27.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 28.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 29.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 30.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 31.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 32.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 33.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 34.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 35.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 36.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 37.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 38.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 39.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 40.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 41.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 42.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 43.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 44.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 45.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 46.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 47.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 48.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 49.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 50.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 51.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 52.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 53.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 54.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 55.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 56.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 57.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 58.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 59.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 60.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 61.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 62.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 63.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 64.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 65.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 66.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 67.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 68.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 69.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 70.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 71.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 72.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 73.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 74.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 75.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 76.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 77.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 78.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 79.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 80.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 81.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 82.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 83.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 84.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 85.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 86.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 87.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 88.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 89.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 90.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 91.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 92.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 93.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 94.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 95.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 96.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 97.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 98.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 99.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 100.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 101.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 102.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 103.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 104.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 105.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 106.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 107.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 108.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 109.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 110.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 111.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 112.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 113.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 114.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 115.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 116.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 117.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 118.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 119.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 120.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 121.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 122.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 123.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 124.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 125.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 126.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 127.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 128.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 129.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 130.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 131.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 132.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 133.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 134.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 135.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 136.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 137.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 138.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 139.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 140.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 141.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 142.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 143.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 144.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 145.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 146.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 147.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 148.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 149.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 150.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 151.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 152.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 153.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 154.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 155.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 156.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 157.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 158.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 159.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 160.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 161.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 162.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 163.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 164.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 165.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 166.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 167.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 168.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 169.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 170.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 171.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 172.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 173.',
    'Komut sonrası sessizlikte ek konuşma zorunlu değildir. Varyant 174.',
    'Sessizlik, konuşmanın bozulması değil; bazen duygunun toparlanma alanıdır. Varyant 175.',
    'Nova her boşluğu sesle kapatmaz; doğru boşluğu doğru şekilde taşır. Varyant 176.',
    'Voice-first mimaride en insani davranış bazen hiç konuşmamaktır. Varyant 177.',
    'Mikro teyit, uzun açıklamadan daha sıcak olabilir. Varyant 178.',
    'Aile ve yakın çevre bağlamında sıcaklık yükselse bile baskı artmamalıdır. Varyant 179.',
    'Araf modunda merak olabilir; ama izinsiz tam uyanıklık olmaz. Varyant 180.',
  ];
}

class _SignalRule {
  final String kind;
  final double base;
  final String reason;
  final String bias;
  const _SignalRule({
    required this.kind,
    required this.base,
    required this.reason,
    required this.bias,
  });
}
