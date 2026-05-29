// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1

class NovaKnowledgeInterpretationArtifact {
  final String kind;
  final String summary;
  final List<String> keyPoints;
  final List<String> clarificationQuestions;
  final List<String> applicationSteps;
  final List<String> memoryCommitNotes;

  const NovaKnowledgeInterpretationArtifact({
    required this.kind,
    required this.summary,
    required this.keyPoints,
    required this.clarificationQuestions,
    required this.applicationSteps,
    required this.memoryCommitNotes,
  });

  String render() {
    final lines = <String>['[YORUMLAMA KATMANI] $kind', summary];
    if (keyPoints.isNotEmpty) {
      lines.add('Ana noktalar:');
      lines.addAll(keyPoints.map((e) => '- $e'));
    }
    if (applicationSteps.isNotEmpty) {
      lines.add('Uygulama adımları:');
      lines.addAll(applicationSteps.map((e) => '- $e'));
    }
    if (clarificationQuestions.isNotEmpty) {
      lines.add('Gerekirse sorulacak netleştirmeler:');
      lines.addAll(clarificationQuestions.map((e) => '- $e'));
    }
    if (memoryCommitNotes.isNotEmpty) {
      lines.add('Davranış/hafıza notları:');
      lines.addAll(memoryCommitNotes.map((e) => '- $e'));
    }
    return lines.join('\n');
  }
}

class NovaNumerologyProfile {
  final String? normalizedName;
  final String? normalizedBirthDate;
  final int? lifePath;
  final int? destiny;
  final int? soulUrge;
  final int? personality;
  final List<String> working;
  final List<String> missingInputs;

  const NovaNumerologyProfile({
    required this.normalizedName,
    required this.normalizedBirthDate,
    required this.lifePath,
    required this.destiny,
    required this.soulUrge,
    required this.personality,
    required this.working,
    required this.missingInputs,
  });

  String render() {
    final lines = <String>['[NUMEROLOJİ HESAP ÇEKİRDEĞİ]'];
    if (normalizedName != null) lines.add('İsim: $normalizedName');
    if (normalizedBirthDate != null)
      lines.add('Doğum tarihi: $normalizedBirthDate');
    if (lifePath != null) lines.add('Yaşam yolu: $lifePath');
    if (destiny != null) lines.add('Kader/ifade sayısı: $destiny');
    if (soulUrge != null) lines.add('Ruh arzusu: $soulUrge');
    if (personality != null) lines.add('Kişilik sayısı: $personality');
    lines.addAll(working.map((e) => '- $e'));
    if (missingInputs.isNotEmpty) {
      lines.add('Eksik girdiler: ${missingInputs.join(' | ')}');
    }
    return lines.join('\n');
  }
}

class NovaKnowledgeInterpretationEngineService {
  const NovaKnowledgeInterpretationEngineService();
  static const Map<String, List<String>> _intentKeywords =
      <String, List<String>>{
        "calculate": <String>[
          "hesapla",
          "hesaplar mısın",
          "çıkar",
          "bul",
          "numeroloji hesapla",
          "yaşam yolu",
          "kader sayısı",
          "compute",
          "calculate",
        ],
        "explain": <String>[
          "açıkla",
          "anlat",
          "nedir",
          "ne demek",
          "explain",
          "what is",
        ],
        "compare": <String>[
          "karşılaştır",
          "farkı ne",
          "hangisi",
          "better",
          "compare",
        ],
        "recommend": <String>[
          "öner",
          "tavsiye",
          "hangi",
          "ne yapayım",
          "suggest",
          "recommend",
        ],
        "recipe": <String>[
          "tarif",
          "yemek yap",
          "pişir",
          "tatlı yap",
          "ne pişireyim",
          "recipe",
        ],
        "diagnose_vehicle": <String>[
          "motor",
          "şanzıman",
          "arıza",
          "ses geliyor",
          "titreşim",
          "gösterge ışığı",
          "hararet",
          "fren",
        ],
        "translate": <String>[
          "çevir",
          "translate",
          "ingilizceye",
          "fransızcaya",
          "rusçaya",
          "arapçaya",
        ],
        "learn_and_adapt": <String>[
          "kendine öğret",
          "davranışını buna göre",
          "bundan sonra böyle yap",
          "bunu böyle değil şöyle yap",
          "uyumlu hale getir",
        ],
        "research": <String>["araştır", "bak", "incele", "öğren"],
      };

  static const Map<String, List<String>> _clarifiers = <String, List<String>>{
    "recipe_meal": <String>[
      "Hızlı mı olsun, sulu mu olsun, fırında mı olsun?",
      "Elinizde hangi ana malzemeler var?",
      "Kaç kişilik düşünüyorsunuz?",
    ],
    "recipe_dessert": <String>[
      "Sütlü mü, şerbetli mi, çikolatalı mı olsun?",
      "Elinizde yumurta, süt, un, çikolata gibi hangi malzemeler var?",
      "Kolay mı gösterişli mi istiyorsunuz?",
    ],
    "vehicle": <String>[
      "Araç modeli ve motor tipi ne?",
      "Uyarı lambası var mı?",
      "Sorun ses mi, titreşim mi, performans düşüşü mü?",
    ],
    "numerology": <String>[
      "İsim tam olarak nasıl yazılıyor?",
      "Doğum tarihi gün/ay/yıl olarak nedir?",
      "İstersen yalnız yaşam yolu mu, yoksa isim sayılarıyla birlikte tam yorum mu yapayım?",
    ],
    "translation": <String>[
      "Bağlam resmi mi gündelik mi?",
      "Tek cümle çevirisi mi, yoksa doğal kullanım örnekleri de ister misiniz?",
      "Hedef dil net mi?",
    ],
  };

  static const Map<String, List<String>> _recipeStyles = <String, List<String>>{
    "fast": <String>[
      "hızlı",
      "çabuk",
      "pratik",
      "quick",
      "15 dakikada",
      "20 dakikada",
    ],
    "soupy": <String>["sulu", "çorba", "tencere", "stew", "broth", "soup"],
    "oven": <String>["fırın", "bake", "oven"],
    "pan": <String>["tava", "sote", "pan", "skillet"],
    "healthy": <String>["sağlıklı", "hafif", "light", "fit"],
    "protein": <String>["etli", "tavuklu", "protein", "kıymalı", "yumurtalı"],
    "vegetarian": <String>["sebzeli", "vejetaryen", "vegetarian"],
  };

  static const Map<String, List<String>>
  _vehicleSymptoms = <String, List<String>>{
    "overheat": <String>[
      "hararet",
      "ısı yükseliyor",
      "water temperature",
      "overheat",
      "steam",
      "buhar",
    ],
    "battery": <String>[
      "akü",
      "marş basmıyor",
      "zor çalışıyor",
      "dim lights",
      "battery",
      "alternator",
    ],
    "brake": <String>[
      "fren",
      "pedal yumuşak",
      "pedal sert",
      "brake warning",
      "fren sesi",
    ],
    "transmission": <String>[
      "şanzıman",
      "vites geçmiyor",
      "sarsıntılı geçiş",
      "gearbox",
      "transmission slip",
      "vites atıyor",
    ],
    "engine_misfire": <String>[
      "tekleme",
      "sarsıntı",
      "misfire",
      "rölanti bozuk",
      "engine shake",
    ],
    "smoke": <String>["duman", "blue smoke", "white smoke", "black smoke"],
    "cooling": <String>["radyatör", "fan", "soğutma", "coolant", "antifriz"],
    "steering": <String>["direksiyon sert", "steering", "çekme yapıyor"],
    "suspension": <String>["amortisör", "tak tuk", "süspansiyon", "sarsıntı"],
  };

  static const Map<String, List<String>>
  _vehicleFirstChecks = <String, List<String>>{
    "overheat": <String>[
      "Aracı güvenli yerde durdur.",
      "Kaputu hemen açıp sisteme dokunma; önce ısı düşsün.",
      "Soğutma sıvısı kaçağı, fan çalışması ve gösterge artışı birlikte var mı kontrol et.",
    ],
    "battery": <String>[
      "Farlar ve marş tepkisini karşılaştır.",
      "Akü kutup başı gevşekliği/oksitlenmesini kontrol et.",
      "Alternatör şarj belirtisi veya akü lambası var mı bak.",
    ],
    "brake": <String>[
      "Aracı kullanmaya devam edip etmeme kararını öncelikle fren hissine göre ver.",
      "Pedal dibe gidiyorsa veya frenleme ciddi zayıfsa sürme.",
      "Sızıntı, uyarı lambası ve ses bilgisini ayır.",
    ],
    "transmission": <String>[
      "Sorun soğukta mı sıcakta mı artıyor ayır.",
      "Sarsıntı, kaydırma, vuruntu ve geç kalma belirtilerini ayrı tarif et.",
      "Sıvı kaçağı ve yanık koku belirtisi var mı sor.",
    ],
    "engine_misfire": <String>[
      "Tekleme yükte mi rölantide mi artıyor ayır.",
      "Check engine ışığı, yakıt kokusu ve güç düşüşünü not et.",
      "Ateşleme/yakıt tarafı ayrımı için ses ve koku ipuçlarını topla.",
    ],
    "smoke": <String>[
      "Duman rengini ayır: beyaz, mavi, siyah.",
      "Duman ilk çalıştırmada mı sürekli mi gözleniyor sor.",
      "Koku ve sıvı tüketimi eşlik ediyor mu bak.",
    ],
    "cooling": <String>[
      "Fan devreye giriyor mu?",
      "Altında sıvı izi var mı?",
      "Kalorifer performansı ve motor sıcaklığı birlikte değişiyor mu?",
    ],
    "steering": <String>[
      "Araç düz giderken çekme var mı?",
      "Ses yalnız dönüşte mi?",
      "Lastik basıncı ve hidrolik/elektrikli direksiyon uyarısı var mı?",
    ],
    "suspension": <String>[
      "Ses tümseklerde mi düz yolda mı?",
      "Tek taraftan mı geliyor?",
      "Frenlemede salınım artıyor mu?",
    ],
  };

  static const Map<int, List<String>> _numerologyLetterMap =
      <int, List<String>>{
        1: <String>["a", "j", "s"],
        2: <String>["b", "k", "t"],
        3: <String>["c", "l", "u"],
        4: <String>["d", "m", "v"],
        5: <String>["e", "n", "w"],
        6: <String>["f", "o", "x"],
        7: <String>["g", "p", "y"],
        8: <String>["h", "q", "z"],
        9: <String>["i", "r"],
      };

  static const List<String> _memoryFirstRules = <String>[
    'Nova önce hatırladığı çekirdek bilgiyi sunar; kaynak yalnız gerektiğinde devreye girer.',
    'Benzer soru tekrarlandığında aynı kaynağı körlemesine baştan dolaşmak yerine mevcut hatırlamayı kullanır.',
    'Kaynağa gidildiyse sonucu dümdüz okumaz; isteğe göre yorumlar, özetler ve uygular.',
    'Kullanıcı doğrudan uygulanabilir bir sonuç istiyorsa açıklamayı uygulama adımıyla birleştirir.',
    'Belirsizlik kritikse kısa netleştirme sorusu sorar; gereksiz soru kalabalığı yapmaz.',
  ];

  static const List<String> _behaviorAdaptationRules = <String>[
    '“Bundan sonra bunu şöyle yap” ifadesi davranış tercihi güncellemesidir.',
    '“Bunu kendine öğret ve buna göre davran” ifadesi, owner sınırı içindeki kural ve üslup uyarlamasıdır.',
    'Bu uyarlama yeni gizli yetenek açma, güvenlik aşma veya kendini hackleme değildir.',
    'Nova yeni davranışı uygularken eski güvenlik sınırlarını korur.',
    'Nova yeni tercihi benzer durumlarda hatırlamaya çalışır.',
  ];

  String buildPromptSection({required String prompt}) {
    final artifact = interpretPrompt(prompt);
    return [
      '[KAYNAĞI YORUMLAYIP UYGULAMA KATMANI]',
      'Nova kaynak satırlarını dümdüz okumaz; anlamı çözer, sonucu Türkçe yorumlar ve gerekiyorsa uygular.',
      ..._memoryFirstRules.map((e) => '- $e'),
      ..._behaviorAdaptationRules.map((e) => '- $e'),
      artifact.render(),
      buildExecutionContract(prompt),
    ].join('\n\n');
  }

  String buildExecutionContract(String prompt) {
    final action = detectAction(prompt);
    final lines = <String>[
      '[UYGULAMA SÖZLEŞMESİ]',
      'Önce isteğin ne istediğini ayırt et: açıklama mı, hesaplama mı, öneri mi, teşhis öncesi yönlendirme mi?',
      'Sonra yalnız gerçekten gereken kaynak parçasını kullan.',
      'Kaynak satırını Türkçe sonuca dönüştür; kaynak metnini bir yığın halinde boşaltma.',
      'Kullanıcı uygulama istiyorsa sonucu adım adıma çevir.',
      'Kullanıcı kısa istiyorsa kısa, detay istiyorsa detaylı anlat.',
      'Eylem türü: $action',
    ];
    return lines.join('\n');
  }

  NovaKnowledgeInterpretationArtifact interpretPrompt(String prompt) {
    final normalized = _normalize(prompt);
    final action = detectAction(prompt);
    if (_matchesAny(normalized, _intentKeywords['learn_and_adapt']!)) {
      return _buildAdaptationArtifact(prompt);
    }
    if (normalized.contains('numeroloji') ||
        normalized.contains('yaşam yolu') ||
        normalized.contains('kader sayısı')) {
      return _buildNumerologyArtifact(prompt);
    }
    if (normalized.contains('tatlı')) {
      return _buildDessertArtifact(prompt);
    }
    if (normalized.contains('yemek') || normalized.contains('tarif')) {
      return _buildCookingArtifact(prompt);
    }
    if (_matchesAny(normalized, _intentKeywords['diagnose_vehicle']!)) {
      return _buildVehicleArtifact(prompt);
    }
    if (_matchesAny(normalized, _intentKeywords['translate']!)) {
      return _buildTranslationArtifact(prompt);
    }
    return NovaKnowledgeInterpretationArtifact(
      kind: action,
      summary:
          'İsteği yorumlayarak Türkçe, uygulanabilir ve kaynak-bağımlılığı düşük bir cevap üret.',
      keyPoints: <String>[
        'Gerekirse kısa netleştirme sorusu sor.',
        'Sorunun çözümü hafızadaysa önce onu kullan.',
        'Kaynak gerekiyorsa en alakalı parçayı seç ve Türkçeye yorumlayarak aktar.',
      ],
      clarificationQuestions: const <String>[],
      applicationSteps: <String>[
        'Niyetini belirle.',
        'Gerekli bilgi boşluğunu tespit et.',
        'Gerekli ise kaynak desteği kullan.',
        'Türkçe ve doğal sonuç ver.',
      ],
      memoryCommitNotes: <String>[
        'Benzer istek tekrarlanırsa tercih edilen anlatım biçimini hatırla.',
      ],
    );
  }

  String detectAction(String prompt) {
    final normalized = _normalize(prompt);
    final scores = <String, int>{};
    for (final entry in _intentKeywords.entries) {
      int score = 0;
      for (final keyword in entry.value) {
        if (normalized.contains(_normalize(keyword)))
          score += keyword.contains(' ') ? 3 : 1;
      }
      if (score > 0) {
        scores[entry.key] = score;
      }
    }
    if (scores.isEmpty) return 'general_interpretation';
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  NovaKnowledgeInterpretationArtifact _buildAdaptationArtifact(String prompt) {
    final preference = _extractPreferenceDirective(prompt);
    return NovaKnowledgeInterpretationArtifact(
      kind: 'learn_and_adapt',
      summary:
          'Bu istek bir davranış uyarlama talimatı. Nova bunu yeni owner tercihi olarak yorumlamalı.',
      keyPoints: <String>[
        if (preference.isNotEmpty) 'Çekirdek tercih: $preference',
        'Yeni davranış benzer durumlarda uygulanmalı.',
        'Bu değişiklik güvenlik sınırını genişletmez.',
      ],
      clarificationQuestions: preference.isEmpty
          ? <String>[
              'Bunu hangi durumda uygulamamı istiyorsunuz?',
              'Örnek bir kullanım cümlesi verir misiniz?',
            ]
          : const <String>[],
      applicationSteps: <String>[
        'Yeni tercihi kısa kural cümlesine dönüştür.',
        'Eski varsayılanla çelişiyorsa owner tercihini öne al.',
        'Benzer tetikleyiciler geldiğinde yeni davranışı uygula.',
      ],
      memoryCommitNotes: <String>[
        'Bu tür talimatlar kalıcı davranış hafızasına adaydır.',
        'Aynı yönde tekrar gelirse öncelik yükselir.',
      ],
    );
  }

  NovaKnowledgeInterpretationArtifact _buildCookingArtifact(String prompt) {
    final parsed = _parseCookingIntent(prompt, dessert: false);
    final clarifiers = parsed['needsClarification'] == true
        ? _clarifiers['recipe_meal']!
        : const <String>[];
    return NovaKnowledgeInterpretationArtifact(
      kind: 'recipe',
      summary:
          'Yemek isteğini yalnız tarif okuyarak değil, istenen stile ve malzemelere göre yorumla.',
      keyPoints: <String>[
        'Stil: ${(parsed['styles'] as List<String>).join(' | ')}',
        'Malzemeler: ${(parsed['ingredients'] as List<String>).join(' | ')}',
        'Kişi sayısı/ekipman bilgisi varsa onu hesaba kat.',
      ],
      clarificationQuestions: clarifiers,
      applicationSteps: <String>[
        'Tarif türünü seç.',
        'Eldeki malzemeye göre uyarlama yap.',
        'Süre, sıra ve ölçü ver.',
        'İstersen alternatif malzeme veya saklama notu ekle.',
      ],
      memoryCommitNotes: <String>[
        'Kullanıcının hızlı/sulu/fırın tercihi tekrar ediyorsa bunu hatırla.',
      ],
    );
  }

  NovaKnowledgeInterpretationArtifact _buildDessertArtifact(String prompt) {
    final parsed = _parseCookingIntent(prompt, dessert: true);
    final clarifiers = parsed['needsClarification'] == true
        ? _clarifiers['recipe_dessert']!
        : const <String>[];
    return NovaKnowledgeInterpretationArtifact(
      kind: 'dessert_recipe',
      summary:
          'Tatlı isteğinde türü, kıvamı ve malzemeyi ayır; sonucu Türkçe ve uygulanabilir ver.',
      keyPoints: <String>[
        'Tatlı stili: ${(parsed['styles'] as List<String>).join(' | ')}',
        'Malzemeler: ${(parsed['ingredients'] as List<String>).join(' | ')}',
        'İhtiyaç varsa kıvam düzeltme notu ekle.',
      ],
      clarificationQuestions: clarifiers,
      applicationSteps: <String>[
        'Tatlı türünü netleştir.',
        'Uygun temel yöntemi seç.',
        'Kıvam ve pişme uyarılarını ekle.',
        'Servis veya saklama notu ver.',
      ],
      memoryCommitNotes: <String>[
        'Kullanıcının sütlü/şerbetli/çikolatalı eğilimini hatırla.',
      ],
    );
  }

  NovaKnowledgeInterpretationArtifact _buildVehicleArtifact(String prompt) {
    final triage = _analyzeVehicleSymptoms(prompt);
    return NovaKnowledgeInterpretationArtifact(
      kind: 'vehicle_interpretation',
      summary:
          'Araç isteğini tür seçimi mi, belirti çözümü mü diye ayır; kaynak metnini semptom→olası neden→güvenli ilk kontrol sırasına dönüştür.',
      keyPoints: <String>[
        'Baskın belirti kümeleri: ${((triage['clusters'] as List<dynamic>? ?? const <dynamic>[]).map((e) => e.toString()).join(' | '))}',
        'Aciliyet: ${triage['urgency']}',
        'Hedef: kesin teşhis değil, düşünülmüş ilk yönlendirme.',
      ],
      clarificationQuestions: (triage['needsClarification'] as bool)
          ? _clarifiers['vehicle']!
          : const <String>[],
      applicationSteps: List<String>.from(triage['steps'] as List<String>),
      memoryCommitNotes: <String>[
        'Aynı araç ve aynı semptom tekrar gelirse önce önceki çekirdek yönlendirmeyi hatırla.',
      ],
    );
  }

  NovaKnowledgeInterpretationArtifact _buildTranslationArtifact(String prompt) {
    final details = _parseTranslationIntent(prompt);
    return NovaKnowledgeInterpretationArtifact(
      kind: 'translation',
      summary:
          'Çeviri isteğinde yalnız sözcük karşılığı değil, bağlam ve kullanım notu ver.',
      keyPoints: <String>[
        'Hedef dil: ${details['targetLanguage']}',
        'Ton: ${details['tone']}',
        'Çeviri yanında Türkçe açıklama ve alternatif kullanım eklenebilir.',
      ],
      clarificationQuestions: details['needsClarification'] == true
          ? _clarifiers['translation']!
          : const <String>[],
      applicationSteps: <String>[
        'İfade veya cümleyi anlama göre parçala.',
        'Doğrudan çeviri ve doğal kullanım farkını ayır.',
        'Gerekirse resmi/gündelik iki seçenek ver.',
      ],
      memoryCommitNotes: <String>[
        'Kullanıcının tercih ettiği resmiyet düzeyi varsa hatırla.',
      ],
    );
  }

  NovaKnowledgeInterpretationArtifact _buildNumerologyArtifact(String prompt) {
    final profile = computeNumerology(prompt);
    final clarifiers = profile.missingInputs.isNotEmpty
        ? _clarifiers['numerology']!
        : const <String>[];
    final keyPoints = <String>[
      if (profile.lifePath != null)
        'Yaşam yolu sonucu hazır: ${profile.lifePath}',
      if (profile.destiny != null)
        'İsim/kader sayısı sonucu hazır: ${profile.destiny}',
      if (profile.soulUrge != null)
        'Ruh arzusu sonucu hazır: ${profile.soulUrge}',
      if (profile.personality != null)
        'Kişilik sayısı sonucu hazır: ${profile.personality}',
      if (profile.missingInputs.isNotEmpty)
        'Eksik girdiler: ${profile.missingInputs.join(' | ')}',
    ];
    return NovaKnowledgeInterpretationArtifact(
      kind: 'numerology_calculation',
      summary:
          'Numeroloji isteğinde yalnız kaynağı okumak değil, veriyi hesaplayıp sonra Türkçe yorumlamak gerekir.',
      keyPoints: keyPoints,
      clarificationQuestions: clarifiers,
      applicationSteps: <String>[
        'İsim ve doğum tarihini normalleştir.',
        'Sayı indirgeme adımlarını göster.',
        'Çıkan sayıları sembolik/yorumlayıcı dil ile anlat.',
        'Kesin kader dili kullanma.',
      ]..addAll(profile.working),
      memoryCommitNotes: <String>[
        'Aynı kişi için yapılan numeroloji hesapları tekrar istenirse önce mevcut sonucu hatırla.',
      ],
    );
  }

  NovaNumerologyProfile computeNumerology(String prompt) {
    final normalizedName = _extractName(prompt);
    final normalizedBirthDate = _extractBirthDate(prompt);
    final missing = <String>[];
    int? lifePath;
    int? destiny;
    int? soulUrge;
    int? personality;
    final working = <String>[];

    if (normalizedBirthDate != null) {
      final digits = normalizedBirthDate.replaceAll(RegExp(r'[^0-9]'), '');
      final rawSum = digits
          .split('')
          .where((e) => e.isNotEmpty)
          .map(int.parse)
          .fold<int>(0, (a, b) => a + b);
      lifePath = _reduceNumber(rawSum);
      working.add(
        'Doğum tarihi rakamları toplamı: $rawSum → yaşam yolu: $lifePath',
      );
    } else {
      missing.add('doğum tarihi');
    }

    if (normalizedName != null) {
      final letters = _normalizeLetters(normalizedName);
      final values = <int>[];
      final vowelValues = <int>[];
      final consonantValues = <int>[];
      for (final ch in letters.split('')) {
        final value = _lookupNumerologyValue(ch);
        if (value == null) continue;
        values.add(value);
        if (_isVowel(ch)) {
          vowelValues.add(value);
        } else {
          consonantValues.add(value);
        }
      }
      if (values.isNotEmpty) {
        final total = values.fold<int>(0, (a, b) => a + b);
        destiny = _reduceNumber(total);
        working.add('İsim harf toplamı: $total → kader/ifade: $destiny');
      }
      if (vowelValues.isNotEmpty) {
        final total = vowelValues.fold<int>(0, (a, b) => a + b);
        soulUrge = _reduceNumber(total);
        working.add('Ünlü harf toplamı: $total → ruh arzusu: $soulUrge');
      }
      if (consonantValues.isNotEmpty) {
        final total = consonantValues.fold<int>(0, (a, b) => a + b);
        personality = _reduceNumber(total);
        working.add('Ünsüz harf toplamı: $total → kişilik: $personality');
      }
    } else {
      missing.add('isim');
    }

    return NovaNumerologyProfile(
      normalizedName: normalizedName,
      normalizedBirthDate: normalizedBirthDate,
      lifePath: lifePath,
      destiny: destiny,
      soulUrge: soulUrge,
      personality: personality,
      working: working,
      missingInputs: missing,
    );
  }

  Map<String, Object> _parseCookingIntent(
    String prompt, {
    required bool dessert,
  }) {
    final normalized = _normalize(prompt);
    final styles = <String>[];
    for (final entry in _recipeStyles.entries) {
      if (entry.value.any(
        (keyword) => normalized.contains(_normalize(keyword)),
      )) {
        styles.add(entry.key);
      }
    }
    final ingredients = _extractIngredients(prompt);
    final needsClarification = styles.isEmpty || ingredients.isEmpty;
    if (dessert && styles.isEmpty) {
      styles.add('dessert_unspecified');
    }
    if (!dessert && styles.isEmpty) {
      styles.add('meal_unspecified');
    }
    return <String, Object>{
      'styles': styles,
      'ingredients': ingredients,
      'needsClarification': needsClarification,
    };
  }

  Map<String, Object> _parseTranslationIntent(String prompt) {
    final normalized = _normalize(prompt);
    String targetLanguage = 'belirsiz';
    if (normalized.contains('ingiliz')) targetLanguage = 'İngilizce';
    if (normalized.contains('frans')) targetLanguage = 'Fransızca';
    if (normalized.contains('rus')) targetLanguage = 'Rusça';
    if (normalized.contains('arap')) targetLanguage = 'Arapça';
    String tone = 'belirsiz';
    if (normalized.contains('resmi')) tone = 'resmi';
    if (normalized.contains('gündelik') || normalized.contains('samimi'))
      tone = 'gündelik';
    return <String, Object>{
      'targetLanguage': targetLanguage,
      'tone': tone,
      'needsClarification': targetLanguage == 'belirsiz',
    };
  }

  Map<String, Object> _analyzeVehicleSymptoms(String prompt) {
    final normalized = _normalize(prompt);
    final matchedClusters = <String>[];
    final steps = <String>[];
    String urgency = 'normal';
    bool needsClarification = true;

    for (final entry in _vehicleSymptoms.entries) {
      if (entry.value.any(
        (keyword) => normalized.contains(_normalize(keyword)),
      )) {
        matchedClusters.add(entry.key);
        steps.addAll(_vehicleFirstChecks[entry.key] ?? const <String>[]);
      }
    }

    if (matchedClusters.isNotEmpty) {
      needsClarification = false;
    }
    if (matchedClusters.contains('brake') ||
        matchedClusters.contains('overheat') ||
        matchedClusters.contains('smoke')) {
      urgency = 'yüksek';
    } else if (matchedClusters.contains('transmission') ||
        matchedClusters.contains('battery')) {
      urgency = 'orta';
    }
    if (steps.isEmpty) {
      steps.addAll(const <String>[
        'Önce belirtiyi türüne göre ayır.',
        'Uyarı lambası, ses, titreşim ve performans düşüşü var mı sor.',
        'Riskli kullanım ihtimali varsa sürüşü sınırlamayı düşün.',
      ]);
    }
    return <String, Object>{
      'clusters': matchedClusters,
      'urgency': urgency,
      'steps': steps,
      'needsClarification': needsClarification,
    };
  }

  String _extractPreferenceDirective(String prompt) {
    final normalized = prompt.trim();
    const markers = <String>[
      'bundan sonra',
      'bunu bu şekilde değil',
      'şöyle yap',
      'davranışını buna göre',
      'kendine öğret',
    ];
    for (final marker in markers) {
      final index = normalized.toLowerCase().indexOf(marker);
      if (index >= 0) {
        return normalized.substring(index).trim();
      }
    }
    return '';
  }

  List<String> _extractIngredients(String prompt) {
    final normalized = prompt.replaceAll(RegExp(r'[\n,;]'), ' ');
    final raw = normalized
        .split(' ')
        .map((e) => e.trim())
        .where((e) => e.length > 2)
        .toList();
    final ignored = <String>{
      'yemek',
      'tarif',
      'isterim',
      'istiyorum',
      'olsun',
      'olabilir',
      'gibi',
      'bana',
      'benim',
      'için',
      'bir',
      'ile',
      've',
      'ama',
      'fakat',
      'şey',
      'şunu',
      'bunu',
      'tatlı',
    };
    final out = <String>[];
    for (final item in raw) {
      final low = _normalize(item);
      if (ignored.contains(low)) continue;
      if (_matchesAny(low, _intentKeywords['recipe']!)) continue;
      if (!_looksIngredientLike(low)) continue;
      if (!out.contains(low)) out.add(low);
      if (out.length >= 12) break;
    }
    return out;
  }

  bool _looksIngredientLike(String token) {
    const common = <String>[
      'patates',
      'soğan',
      'domates',
      'biber',
      'tavuk',
      'et',
      'kıyma',
      'pirinç',
      'bulgur',
      'makarna',
      'un',
      'şeker',
      'süt',
      'yumurta',
      'tereyağı',
      'yoğurt',
      'peynir',
      'kakao',
      'çikolata',
      'muz',
      'elma',
      'çilek',
      'mercimek',
      'nohut',
      'fasulye',
      'zeytinyağı',
      'yağ',
      'tuz',
      'karabiber',
      'salça',
      'krema',
    ];
    if (common.contains(token)) return true;
    return token.length >= 4;
  }

  String? _extractName(String prompt) {
    final matchers = <RegExp>[
      RegExp(
        r'isim(?:im|i|)\s*[:=-]?\s*([A-Za-zÇĞİIÖŞÜçğıöşü\s]{3,})',
        caseSensitive: false,
      ),
      RegExp(
        r'ad(?:ım|ı|)\s*[:=-]?\s*([A-Za-zÇĞİIÖŞÜçğıöşü\s]{3,})',
        caseSensitive: false,
      ),
      RegExp(r'([A-Za-zÇĞİIÖŞÜçğıöşü]{2,}\s+[A-Za-zÇĞİIÖŞÜçğıöşü]{2,})'),
    ];
    for (final regex in matchers) {
      final match = regex.firstMatch(prompt);
      if (match != null) {
        final value = match.group(1)?.trim();
        if (value != null && value.length >= 2) {
          return value.replaceAll(RegExp(r'\s+'), ' ');
        }
      }
    }
    return null;
  }

  String? _extractBirthDate(String prompt) {
    final matchers = <RegExp>[
      RegExp(r'(\d{1,2})[./-](\d{1,2})[./-](\d{4})'),
      RegExp(r'(\d{4})[./-](\d{1,2})[./-](\d{1,2})'),
    ];
    for (final regex in matchers) {
      final match = regex.firstMatch(prompt);
      if (match != null) {
        return match.group(0);
      }
    }
    return null;
  }

  String _normalizeLetters(String input) {
    return input
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u')
        .replaceAll(RegExp(r'[^a-z\s]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  int? _lookupNumerologyValue(String letter) {
    for (final entry in _numerologyLetterMap.entries) {
      if (entry.value.contains(letter)) return entry.key;
    }
    return null;
  }

  bool _isVowel(String letter) =>
      const <String>['a', 'e', 'i', 'o', 'u'].contains(letter);

  int _reduceNumber(int value) {
    int current = value;
    while (current > 9 && current != 11 && current != 22 && current != 33) {
      current = current
          .toString()
          .split('')
          .map(int.parse)
          .fold<int>(0, (a, b) => a + b);
    }
    return current;
  }

  bool _matchesAny(String normalizedPrompt, List<String> keywords) {
    for (final keyword in keywords) {
      if (normalizedPrompt.contains(_normalize(keyword))) return true;
    }
    return false;
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u')
        .replaceAll(RegExp(r'[^a-z0-9\s]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

extension NovaKnowledgeInterpretationExamples
    on NovaKnowledgeInterpretationEngineService {
  String buildExampleBank() {
    return [
      '[UYGULAMA ÖRNEK BANKASI]',
      ...buildNumerologyExamples(),
      ...buildCookingExamples(),
      ...buildDessertExamples(),
      ...buildVehicleExamples(),
      ...buildTranslationExamples(),
      ...buildAdaptationExamples(),
    ].join('\n');
  }

  List<String> buildNumerologyExamples() {
    return <String>[
      '[ÖRNEK] Numeroloji',
      '- Kullanıcı: “Numerolojide benim yaşam yolumu hesapla.”',
      '- Nova önce doğum tarihi eksikse ister.',
      '- Bilgi gelince rakam toplamını gösterir, sonucu indirger ve sonra Türkçe yorumlar.',
      '- Çıktı yalnız sayı değil; “bu sayı sembolik olarak şu temaları vurgular” biçiminde olur.',
      '- Gerekiyorsa isim sayısı, ruh arzusu ve kişilik sayısını ayrı başlıklara ayırır.',
      '- Sonuçları kader buyruğu gibi değil, yorum çerçevesi gibi sunar.',
      '- Kullanıcı kısa isterse tek paragraf, detay isterse adım adım hesap döker.',
    ];
  }

  List<String> buildCookingExamples() {
    return <String>[
      '[ÖRNEK] Yemek',
      '- Kullanıcı: “Bana bir yemek öner.”',
      '- Nova sorar: “Hızlı mı olsun, sulu mu olsun, elinizde hangi malzemeler var?”',
      '- Kullanıcı malzeme verirse tarif ona göre uyarlanır.',
      '- Kaynaktaki tek tarif aynen kopyalanmaz; porsiyon, süre ve malzemeye göre yorumlanır.',
      '- Eğer malzeme azsa alternatif önerilir.',
      '- Sonuç: malzeme listesi, sıra, süre, kritik püf noktası.',
      '- İstenirse “aynı malzemelerle daha hafif bir versiyon” gibi ikinci öneri çıkarılır.',
    ];
  }

  List<String> buildDessertExamples() {
    return <String>[
      '[ÖRNEK] Tatlı',
      '- Kullanıcı: “Tatlı istiyorum ama ne yapacağımı bilmiyorum.”',
      '- Nova sorar: “Sütlü mü, şerbetli mi, çikolatalı mı?”',
      '- Elinizdeki malzemelere göre hızlı seçenek sıralar.',
      '- Tarif yalnız çeviri değil; kıvam uyarısı ve servis notu içerir.',
      '- Eğer sorun “tatlım cıvık oldu” ise bu kez düzeltme önerisi verir.',
      '- Böylece kaynak bilgisi uygulamaya çevrilmiş olur.',
    ];
  }

  List<String> buildVehicleExamples() {
    return <String>[
      '[ÖRNEK] Araç',
      '- Kullanıcı: “Araba tekliyor ve çekişten düştü.”',
      '- Nova bunu semptom olarak işler: ateşleme/yakıt tarafı olası kümeleri çıkarır.',
      '- Sonra şu tür sorularla netleştirir: “Check engine ışığı var mı, rölantide de var mı?”',
      '- Güvenlik riski varsa önce bunu söyler.',
      '- Sonuç, semptom→olası neden→güvenli ilk kontrol biçiminde çıkar.',
      '- Yalnız parça adı okumak yerine düşünülmüş yol haritası verir.',
    ];
  }

  List<String> buildTranslationExamples() {
    return <String>[
      '[ÖRNEK] Çeviri',
      '- Kullanıcı: “Bunu İngilizceye çevir ama resmi dursun.”',
      '- Nova hedef dili ve tonu ayırır.',
      '- Çıktıda çeviri + kısa kullanım notu verebilir.',
      '- Gerekirse ikinci, daha samimi alternatif de sunar.',
      '- Böylece yalnız sözlük karşılığı değil, bağlama uygun çıktı üretir.',
    ];
  }

  List<String> buildAdaptationExamples() {
    return <String>[
      '[ÖRNEK] Öğren ve uyumlan',
      '- Kullanıcı: “Bundan sonra yemek önerirken önce evde ne var diye sor.”',
      '- Nova bunu davranış tercihi olarak alır.',
      '- Benzer isteklerde önce bu adımı uygular.',
      '- Bunu yeni gizli yetenek açma gibi değil, owner tercihi güncellemesi gibi işler.',
      '- Güvenlik sınırları değişmez.',
    ];
  }
}

class NovaAppliedKnowledgeScenario {
  final String label;
  final List<String> triggers;
  final List<String> responseGoals;
  final List<String> exampleQuestions;

  const NovaAppliedKnowledgeScenario({
    required this.label,
    required this.triggers,
    required this.responseGoals,
    required this.exampleQuestions,
  });
}

class NovaAppliedKnowledgeScenarioLibrary {
  const NovaAppliedKnowledgeScenarioLibrary();

  static const List<NovaAppliedKnowledgeScenario> scenarios =
      <NovaAppliedKnowledgeScenario>[
        NovaAppliedKnowledgeScenario(
          label: 'yemek_belirsiz',
          triggers: <String>[
            'bana bir yemek söyle',
            'bir şeyler yapacağım ne önerirsin',
          ],
          responseGoals: <String>[
            'tat ve hız tercihini sor',
            'eldeki malzemeyi öğren',
            'uyarlanabilir tarif çıkar',
          ],
          exampleQuestions: <String>[
            'Hızlı mı olsun?',
            'Evde hangi malzemeler var?',
            'Kaç kişilik olacak?',
          ],
        ),
        NovaAppliedKnowledgeScenario(
          label: 'tatli_belirsiz',
          triggers: <String>['canım tatlı çekti', 'bir tatlı yapacağım'],
          responseGoals: <String>[
            'tatlı türünü ayır',
            'malzeme uyumunu kur',
            'kıvam riskini belirt',
          ],
          exampleQuestions: <String>[
            'Sütlü mü olsun?',
            'Şerbetli ister misiniz?',
            'Çikolata var mı?',
          ],
        ),
        NovaAppliedKnowledgeScenario(
          label: 'numeroloji_hesap',
          triggers: <String>['yaşam yolu hesapla', 'isim sayımı bul'],
          responseGoals: <String>[
            'eksik veri varsa iste',
            'sayıyı hesapla',
            'yorumla',
          ],
          exampleQuestions: <String>[
            'Doğum tarihiniz nedir?',
            'Tam isim nasıl yazılıyor?',
          ],
        ),
        NovaAppliedKnowledgeScenario(
          label: 'arac_ariza',
          triggers: <String>['araba ses yapıyor', 'şanzıman vuruntu yapıyor'],
          responseGoals: <String>[
            'semptom kümesini ayır',
            'risk önceliği koy',
            'ilk güvenli kontrolü ver',
          ],
          exampleQuestions: <String>[
            'Uyarı ışığı var mı?',
            'Ses hangi durumda geliyor?',
            'Araç modeli ne?',
          ],
        ),
        NovaAppliedKnowledgeScenario(
          label: 'davranis_ogretme',
          triggers: <String>['bundan sonra böyle yap', 'kendine öğret'],
          responseGoals: <String>[
            'tercihi kısa kural haline getir',
            'hafızaya aday yap',
            'benzer durumda uygula',
          ],
          exampleQuestions: <String>[
            'Bunu hangi durumda uygulayayım?',
            'Örnek verir misiniz?',
          ],
        ),
      ];

  String buildPromptSection() {
    final lines = <String>['[UYGULANMIŞ SENARYO KÜTÜPHANESİ]'];
    for (final scenario in scenarios) {
      lines.add('Senaryo: ${scenario.label}');
      lines.add('Tetikleyiciler: ${scenario.triggers.join(' | ')}');
      lines.add('Hedefler: ${scenario.responseGoals.join(' | ')}');
      lines.add('Sorular: ${scenario.exampleQuestions.join(' | ')}');
    }
    return lines.join('\n');
  }
}
