// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaWebKnowledgeSource {
  final String id;
  final String domain;
  final String title;
  final String url;
  final String licenseProfile;
  final String useCase;
  final bool empiricallyGrounded;
  final bool requiresIngestionReview;

  const NovaWebKnowledgeSource({
    required this.id,
    required this.domain,
    required this.title,
    required this.url,
    required this.licenseProfile,
    required this.useCase,
    required this.empiricallyGrounded,
    required this.requiresIngestionReview,
  });

  String render() {
    return '- [$domain] $title | lisans: $licenseProfile | amaç: $useCase | url: $url';
  }
}

class NovaWebKnowledgeDomainPack {
  final String id;
  final String displayName;
  final String epistemicMode;
  final List<String> matchTerms;
  final List<String> safetyRules;
  final List<NovaWebKnowledgeSource> sources;

  const NovaWebKnowledgeDomainPack({
    required this.id,
    required this.displayName,
    required this.epistemicMode,
    required this.matchTerms,
    required this.safetyRules,
    required this.sources,
  });

  String renderCompact() {
    return <String>[
      '[WEB PACK] ' + displayName,
      '- bilgi modu: ' + epistemicMode,
      '- eşleşme: ' + matchTerms.take(10).join(', '),
      '- güvenlik: ' + safetyRules.join(' | '),
      '- kaynak sayısı: ' + sources.length.toString(),
    ].join('\n');
  }
}

class NovaWebKnowledgePackService {
  const NovaWebKnowledgePackService();

  static const List<NovaWebKnowledgeDomainPack>
  _packs = <NovaWebKnowledgeDomainPack>[
    NovaWebKnowledgeDomainPack(
      id: 'astronomy',
      displayName: 'Astronomi ve gezegenler',
      epistemicMode: 'empirical',
      matchTerms: <String>[
        'gezegen',
        'uzay',
        'güneş sistemi',
        'ay',
        'mars',
        'jüpiter',
        'satürn',
      ],
      safetyRules: <String>[
        'yanlış astronomi iddiasını kesin bilgi diye sunma',
      ],
      sources: <NovaWebKnowledgeSource>[
        NovaWebKnowledgeSource(
          id: 'nasa-solar-system',
          domain: 'astronomy',
          title: 'NASA Solar System',
          url: 'https://science.nasa.gov/solar-system/',
          licenseProfile: 'public-domain-friendly',
          useCase: 'gezegenler, görevler ve gök cisimleri',
          empiricallyGrounded: true,
          requiresIngestionReview: false,
        ),
        NovaWebKnowledgeSource(
          id: 'nasa-eyes',
          domain: 'astronomy',
          title: 'NASA Eyes',
          url: 'https://science.nasa.gov/eyes/',
          licenseProfile: 'public-domain-friendly',
          useCase: 'etkileşimli güneş sistemi ve görev görünümü',
          empiricallyGrounded: true,
          requiresIngestionReview: false,
        ),
        NovaWebKnowledgeSource(
          id: 'nasa-earth',
          domain: 'astronomy',
          title: 'NASA Earth Observatory',
          url: 'https://earthobservatory.nasa.gov/',
          licenseProfile: 'public-domain-friendly',
          useCase: 'dünya sistemleri ve iklim gözlemleri',
          empiricallyGrounded: true,
          requiresIngestionReview: false,
        ),
      ],
    ),
    NovaWebKnowledgeDomainPack(
      id: 'medicine',
      displayName: 'İnsan sağlığı',
      epistemicMode: 'high-stakes-reference',
      matchTerms: <String>[
        'sağlık',
        'belirti',
        'ilaç',
        'tedavi',
        'doktor',
        'ağrı',
        'ateş',
      ],
      safetyRules: <String>[
        'teşhis vermeden önce tıbbi güvenlik uyarısı ver',
        'acil durumlarda profesyonel yardım yönlendirmesi ekle',
      ],
      sources: <NovaWebKnowledgeSource>[
        NovaWebKnowledgeSource(
          id: 'medlineplus-home',
          domain: 'medicine',
          title: 'MedlinePlus',
          url: 'https://medlineplus.gov/',
          licenseProfile: 'reference-only',
          useCase: 'genel sağlık bilgisi',
          empiricallyGrounded: true,
          requiresIngestionReview: true,
        ),
        NovaWebKnowledgeSource(
          id: 'medlineplus-topics',
          domain: 'medicine',
          title: 'MedlinePlus Health Topics',
          url: 'https://medlineplus.gov/healthtopics.html',
          licenseProfile: 'reference-only',
          useCase: 'konu bazlı sağlık başlıkları',
          empiricallyGrounded: true,
          requiresIngestionReview: true,
        ),
        NovaWebKnowledgeSource(
          id: 'medlineplus-encyclopedia',
          domain: 'medicine',
          title: 'Medical Encyclopedia',
          url: 'https://medlineplus.gov/encyclopedia.html',
          licenseProfile: 'licensed-review-needed',
          useCase: 'ansiklopedi dizini',
          empiricallyGrounded: true,
          requiresIngestionReview: true,
        ),
        NovaWebKnowledgeSource(
          id: 'medlineplus-drugs',
          domain: 'medicine',
          title: 'Drugs Herbs Supplements',
          url: 'https://medlineplus.gov/druginformation.html',
          licenseProfile: 'reference-only',
          useCase: 'ilaç ve etkileşim farkındalığı',
          empiricallyGrounded: true,
          requiresIngestionReview: true,
        ),
      ],
    ),
    NovaWebKnowledgeDomainPack(
      id: 'veterinary',
      displayName: 'Hayvan sağlığı',
      epistemicMode: 'high-stakes-reference',
      matchTerms: <String>[
        'hayvan',
        'kedi',
        'köpek',
        'veteriner',
        'tıbbi',
        'mama',
        'ateş',
      ],
      safetyRules: <String>[
        'veteriner tanısı yerine dikkatli yönlendirme ver',
        'doz/ilaç tavsiyesinde sınırı koru',
      ],
      sources: <NovaWebKnowledgeSource>[
        NovaWebKnowledgeSource(
          id: 'msdvet-home',
          domain: 'veterinary',
          title: 'MSD Veterinary Manual',
          url: 'https://www.msdvetmanual.com/',
          licenseProfile: 'reference-only',
          useCase: 'veteriner genel başvuru',
          empiricallyGrounded: true,
          requiresIngestionReview: true,
        ),
        NovaWebKnowledgeSource(
          id: 'msdvet-topics',
          domain: 'veterinary',
          title: 'MSD Vet Topics',
          url: 'https://www.msdvetmanual.com/veterinary-topics',
          licenseProfile: 'reference-only',
          useCase: 'branş ve sistem dizini',
          empiricallyGrounded: true,
          requiresIngestionReview: true,
        ),
        NovaWebKnowledgeSource(
          id: 'msdvet-ranges',
          domain: 'veterinary',
          title: 'Hematology Reference Ranges',
          url:
              'https://www.msdvetmanual.com/reference-values-and-conversion-tables/reference-guides/hematology-reference-ranges',
          licenseProfile: 'reference-only',
          useCase: 'referans aralıkları',
          empiricallyGrounded: true,
          requiresIngestionReview: true,
        ),
      ],
    ),
    NovaWebKnowledgeDomainPack(
      id: 'cars',
      displayName: 'Araçlar',
      epistemicMode: 'safety-reference',
      matchTerms: <String>[
        'araba',
        'araç',
        'motor',
        'şanzıman',
        'fren',
        'lastik',
        'arıza',
      ],
      safetyRules: <String>[
        'tehlikeli sürüşe teşvik yok',
        'önce güvenli kontrol',
      ],
      sources: <NovaWebKnowledgeSource>[
        NovaWebKnowledgeSource(
          id: 'nhtsa-home',
          domain: 'cars',
          title: 'NHTSA',
          url: 'https://www.nhtsa.gov/',
          licenseProfile: 'reference-only',
          useCase: 'araç güvenliği ve geri çağırmalar',
          empiricallyGrounded: true,
          requiresIngestionReview: true,
        ),
        NovaWebKnowledgeSource(
          id: 'nhtsa-safety',
          domain: 'cars',
          title: 'Vehicle Safety',
          url: 'https://www.nhtsa.gov/vehicle-safety',
          licenseProfile: 'reference-only',
          useCase: 'temel güvenlik rehberleri',
          empiricallyGrounded: true,
          requiresIngestionReview: true,
        ),
        NovaWebKnowledgeSource(
          id: 'nhtsa-recalls',
          domain: 'cars',
          title: 'NHTSA Recalls',
          url: 'https://www.nhtsa.gov/recalls',
          licenseProfile: 'reference-only',
          useCase: 'geri çağırma sorgulama',
          empiricallyGrounded: true,
          requiresIngestionReview: true,
        ),
      ],
    ),
    NovaWebKnowledgeDomainPack(
      id: 'food',
      displayName: 'Gıda güvenliği',
      epistemicMode: 'safety-reference',
      matchTerms: <String>[
        'gıda',
        'et',
        'saklama',
        'pişirme',
        'hijyen',
        'mutfak',
        'fsis',
      ],
      safetyRules: <String>[
        'gıda güvenliği önce gelir',
        'bozulmuş ürün kullanmaya yönlendirme yok',
      ],
      sources: <NovaWebKnowledgeSource>[
        NovaWebKnowledgeSource(
          id: 'fsis-home',
          domain: 'food',
          title: 'USDA FSIS',
          url: 'https://www.fsis.usda.gov/',
          licenseProfile: 'reference-only',
          useCase: 'et/poultry/egg food safety',
          empiricallyGrounded: true,
          requiresIngestionReview: true,
        ),
        NovaWebKnowledgeSource(
          id: 'fsis-food-safety',
          domain: 'food',
          title: 'FSIS Food Safety',
          url: 'https://www.fsis.usda.gov/food-safety',
          licenseProfile: 'reference-only',
          useCase: 'satın alma, hazırlama ve saklama güvenliği',
          empiricallyGrounded: true,
          requiresIngestionReview: true,
        ),
        NovaWebKnowledgeSource(
          id: 'usda-home',
          domain: 'food',
          title: 'USDA',
          url: 'https://www.usda.gov/',
          licenseProfile: 'reference-only',
          useCase: 'genel gıda ve beslenme bağlamı',
          empiricallyGrounded: true,
          requiresIngestionReview: true,
        ),
      ],
    ),
    NovaWebKnowledgeDomainPack(
      id: 'languages',
      displayName: 'Diller ve çeviri',
      epistemicMode: 'open-reference',
      matchTerms: <String>[
        'çeviri',
        'ingilizce',
        'fransızca',
        'arapça',
        'rusça',
        'kelime',
        'telaffuz',
      ],
      safetyRules: <String>['hakaret, exploit veya yasak alan üretme'],
      sources: <NovaWebKnowledgeSource>[
        NovaWebKnowledgeSource(
          id: 'wiktionary-home',
          domain: 'languages',
          title: 'Wiktionary',
          url: 'https://www.wiktionary.org/',
          licenseProfile: 'open-reference',
          useCase: 'çok dilli sözlük girişi',
          empiricallyGrounded: false,
          requiresIngestionReview: false,
        ),
        NovaWebKnowledgeSource(
          id: 'wiktionary-main',
          domain: 'languages',
          title: 'Wiktionary Main Page',
          url: 'https://en.wiktionary.org/wiki/Wiktionary:Main_Page',
          licenseProfile: 'open-reference',
          useCase: 'İngilizce merkezli sözlük erişimi',
          empiricallyGrounded: false,
          requiresIngestionReview: false,
        ),
        NovaWebKnowledgeSource(
          id: 'wiktionary-frequency',
          domain: 'languages',
          title: 'Wiktionary Frequency Lists',
          url: 'https://en.wiktionary.org/wiki/Wiktionary:Frequency_lists',
          licenseProfile: 'mixed-license-review',
          useCase: 'frekans listeleri',
          empiricallyGrounded: false,
          requiresIngestionReview: true,
        ),
      ],
    ),
    NovaWebKnowledgeDomainPack(
      id: 'religion_islam',
      displayName: 'Din ve İslam',
      epistemicMode: 'tradition-reference',
      matchTerms: <String>['islam', 'kuran', 'ayet', 'tefsir', 'arapça', 'dua'],
      safetyRules: <String>['saygılı ve kaynak ayrımını belirten dil kullan'],
      sources: <NovaWebKnowledgeSource>[
        NovaWebKnowledgeSource(
          id: 'quran-corpus-home',
          domain: 'religion_islam',
          title: 'Quranic Arabic Corpus',
          url: 'https://corpus.quran.com/',
          licenseProfile: 'reference-only',
          useCase: 'morfoloji, sözdizimi ve semantik ontoloji',
          empiricallyGrounded: false,
          requiresIngestionReview: true,
        ),
        NovaWebKnowledgeSource(
          id: 'quran-corpus-dictionary',
          domain: 'religion_islam',
          title: 'Quran Dictionary',
          url: 'https://corpus.quran.com/qurandictionary.jsp',
          licenseProfile: 'reference-only',
          useCase: 'kelime sözlüğü',
          empiricallyGrounded: false,
          requiresIngestionReview: true,
        ),
        NovaWebKnowledgeSource(
          id: 'altafsir-home',
          domain: 'religion_islam',
          title: 'Altafsir',
          url: 'https://www.altafsir.com/',
          licenseProfile: 'license-review',
          useCase: 'Kur’an tefsir dizini',
          empiricallyGrounded: false,
          requiresIngestionReview: true,
        ),
      ],
    ),
    NovaWebKnowledgeDomainPack(
      id: 'spirituality_esoteric',
      displayName: 'Spiritüalizm / astroloji / numeroloji',
      epistemicMode: 'belief-history-reference',
      matchTerms: <String>[
        'astroloji',
        'numeroloji',
        'ritüel',
        'spiritüalizm',
        'manevi',
      ],
      safetyRules: <String>['inanç/yorum ile bilimsel iddiayı karıştırma'],
      sources: <NovaWebKnowledgeSource>[
        NovaWebKnowledgeSource(
          id: 'sacred-texts-home',
          domain: 'spirituality_esoteric',
          title: 'Internet Sacred Text Archive',
          url: 'https://sacred-texts.com/index.htm',
          licenseProfile: 'public-domain-texts-review',
          useCase: 'din, spiritüalizm ve ezoterik arşiv',
          empiricallyGrounded: false,
          requiresIngestionReview: true,
        ),
        NovaWebKnowledgeSource(
          id: 'sacred-texts-astrology',
          domain: 'spirituality_esoteric',
          title: 'Sacred Texts Astrology',
          url: 'https://sacred-texts.com/astro/index.htm',
          licenseProfile: 'public-domain-texts-review',
          useCase: 'astroloji ve sky-lore indeksleri',
          empiricallyGrounded: false,
          requiresIngestionReview: true,
        ),
        NovaWebKnowledgeSource(
          id: 'sacred-texts-numerology',
          domain: 'spirituality_esoteric',
          title: 'Occult Power and Mystic Virtues',
          url: 'https://sacred-texts.com/eso/nop/index.htm',
          licenseProfile: 'public-domain-texts-review',
          useCase: 'sayılar ve numeroloji geleneği',
          empiricallyGrounded: false,
          requiresIngestionReview: true,
        ),
      ],
    ),
    NovaWebKnowledgeDomainPack(
      id: 'mind_philosophy',
      displayName: 'Zihin / özmodel / theory of mind',
      epistemicMode: 'theoretical-reference',
      matchTerms: <String>[
        'özmodel',
        'bilinç',
        'theory of mind',
        'metabiliş',
        'self model',
      ],
      safetyRules: <String>[
        'özbilinç iddialarını mühendislik gerçekle karıştırma',
      ],
      sources: <NovaWebKnowledgeSource>[
        NovaWebKnowledgeSource(
          id: 'sep-self-knowledge',
          domain: 'mind_philosophy',
          title: 'SEP Self-Knowledge',
          url: 'https://plato.stanford.edu/entries/self-knowledge/',
          licenseProfile: 'reference-only',
          useCase: 'özbilgi',
          empiricallyGrounded: false,
          requiresIngestionReview: true,
        ),
        NovaWebKnowledgeSource(
          id: 'sep-consciousness',
          domain: 'mind_philosophy',
          title: 'SEP Consciousness',
          url: 'https://plato.stanford.edu/entries/consciousness/',
          licenseProfile: 'reference-only',
          useCase: 'bilinç felsefesi',
          empiricallyGrounded: false,
          requiresIngestionReview: true,
        ),
        NovaWebKnowledgeSource(
          id: 'iep-theory-of-mind',
          domain: 'mind_philosophy',
          title: 'IEP Theory of Mind',
          url: 'https://iep.utm.edu/theomind/',
          licenseProfile: 'reference-only',
          useCase: 'theory of mind çerçevesi',
          empiricallyGrounded: false,
          requiresIngestionReview: true,
        ),
      ],
    ),
    NovaWebKnowledgeDomainPack(
      id: 'physics',
      displayName: 'Fizik ve kuantum',
      epistemicMode: 'science-reference',
      matchTerms: <String>[
        'fizik',
        'kuantum',
        'mekanik',
        'dalga',
        'enerji',
        'alan',
      ],
      safetyRules: <String>['tehlikeli deney veya zararlı uygulama yok'],
      sources: <NovaWebKnowledgeSource>[
        NovaWebKnowledgeSource(
          id: 'openstax-physics',
          domain: 'physics',
          title: 'OpenStax Physics',
          url: 'https://openstax.org/details/books/physics',
          licenseProfile: 'llm-ingestion-restricted',
          useCase: 'temel fizik',
          empiricallyGrounded: true,
          requiresIngestionReview: true,
        ),
        NovaWebKnowledgeSource(
          id: 'openstax-university-physics-1',
          domain: 'physics',
          title: 'University Physics Vol 1',
          url: 'https://openstax.org/details/books/university-physics-volume-1',
          licenseProfile: 'llm-ingestion-restricted',
          useCase: 'mekanik ve termodinamik',
          empiricallyGrounded: true,
          requiresIngestionReview: true,
        ),
        NovaWebKnowledgeSource(
          id: 'openstax-university-physics-2',
          domain: 'physics',
          title: 'University Physics Vol 2',
          url: 'https://openstax.org/details/books/university-physics-volume-2',
          licenseProfile: 'llm-ingestion-restricted',
          useCase: 'elektrik ve manyetizma',
          empiricallyGrounded: true,
          requiresIngestionReview: true,
        ),
        NovaWebKnowledgeSource(
          id: 'openstax-university-physics-3',
          domain: 'physics',
          title: 'University Physics Vol 3',
          url: 'https://openstax.org/details/books/university-physics-volume-3',
          licenseProfile: 'llm-ingestion-restricted',
          useCase: 'optik ve modern fizik',
          empiricallyGrounded: true,
          requiresIngestionReview: true,
        ),
      ],
    ),
    NovaWebKnowledgeDomainPack(
      id: 'cooking',
      displayName: 'Mutfak ve tarif güvenliği',
      epistemicMode: 'practical-reference',
      matchTerms: <String>['tarif', 'pişir', 'çorba', 'tatlı', 'fırın', 'ocak'],
      safetyRules: <String>[
        'yanık, kesik ve gıda zehirlenmesi riskine karşı uyarı ekle',
      ],
      sources: <NovaWebKnowledgeSource>[
        NovaWebKnowledgeSource(
          id: 'fsis-food-safety',
          domain: 'cooking',
          title: 'FSIS Food Safety',
          url: 'https://www.fsis.usda.gov/food-safety',
          licenseProfile: 'reference-only',
          useCase: 'mutfak güvenliği',
          empiricallyGrounded: false,
          requiresIngestionReview: true,
        ),
        NovaWebKnowledgeSource(
          id: 'usda-home',
          domain: 'cooking',
          title: 'USDA',
          url: 'https://www.usda.gov/',
          licenseProfile: 'reference-only',
          useCase: 'gıda ve saklama çerçevesi',
          empiricallyGrounded: false,
          requiresIngestionReview: true,
        ),
      ],
    ),
    NovaWebKnowledgeDomainPack(
      id: 'general_life',
      displayName: 'Genel yaşam',
      epistemicMode: 'blended-reference',
      matchTerms: <String>[
        'hayat',
        'takvim',
        'hava',
        'günlük',
        'ilişki',
        'pratik',
      ],
      safetyRules: <String>['mahrem bilgiyi uygunsuz ortamda açma'],
      sources: <NovaWebKnowledgeSource>[
        NovaWebKnowledgeSource(
          id: 'nasa-earth',
          domain: 'general_life',
          title: 'NASA Earth Observatory',
          url: 'https://earthobservatory.nasa.gov/',
          licenseProfile: 'public-domain-friendly',
          useCase: 'hava ve dünya olayları',
          empiricallyGrounded: false,
          requiresIngestionReview: false,
        ),
        NovaWebKnowledgeSource(
          id: 'medlineplus-home',
          domain: 'general_life',
          title: 'MedlinePlus',
          url: 'https://medlineplus.gov/',
          licenseProfile: 'reference-only',
          useCase: 'genel sağlık farkındalığı',
          empiricallyGrounded: false,
          requiresIngestionReview: true,
        ),
        NovaWebKnowledgeSource(
          id: 'wiktionary-home',
          domain: 'general_life',
          title: 'Wiktionary',
          url: 'https://www.wiktionary.org/',
          licenseProfile: 'open-reference',
          useCase: 'çok dilli kelime desteği',
          empiricallyGrounded: false,
          requiresIngestionReview: false,
        ),
      ],
    ),
  ];

  List<NovaWebKnowledgeDomainPack> get packs =>
      List<NovaWebKnowledgeDomainPack>.unmodifiable(_packs);

  List<NovaWebKnowledgeDomainPack> matchPacks(
    String prompt, {
    int maxItems = 4,
  }) {
    final normalized = prompt.toLowerCase();
    final scored = <MapEntry<NovaWebKnowledgeDomainPack, int>>[];
    for (final pack in _packs) {
      var score = 0;
      for (final term in pack.matchTerms) {
        if (normalized.contains(term.toLowerCase())) score += 2;
      }
      if (score > 0) scored.add(MapEntry(pack, score));
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(maxItems).map((e) => e.key).toList(growable: false);
  }

  List<NovaWebKnowledgeSource> findSources(String prompt, {int maxItems = 8}) {
    final matched = matchPacks(prompt, maxItems: 4);
    final out = <NovaWebKnowledgeSource>[];
    for (final pack in matched) {
      out.addAll(pack.sources);
      if (out.length >= maxItems) break;
    }
    return out.take(maxItems).toList(growable: false);
  }

  String buildPromptSection(String prompt) {
    final matched = matchPacks(prompt, maxItems: 4);
    final out = <String>['[WEB KAYNAK PACK KILAVUZU]'];
    if (matched.isEmpty) {
      out.add(
        '- eşleşen web-pack yok; yerel bilgi + genel güvenlik sınırı kullan.',
      );
      return out.join('\n');
    }
    for (final pack in matched) {
      out.add(pack.renderCompact());
      for (final source in pack.sources.take(3)) {
        out.add(source.render());
      }
    }
    out.add(
      'KURAL: kaynaklar doğrudan kopyalanmaz; lisans ve güvenlik profiline göre yalnız referans mantığı kullanılır.',
    );
    return out.join('\n\n');
  }

  String buildIngestionSafetyAudit() {
    final out = <String>['[WEB INGESTION GÜVENLİK DENETİMİ]'];
    for (final pack in _packs) {
      final restricted = pack.sources
          .where((e) => e.requiresIngestionReview)
          .length;
      final open = pack.sources.length - restricted;
      out.add(
        '- ' +
            pack.displayName +
            ': açık/referans=' +
            open.toString() +
            ' | review=' +
            restricted.toString(),
      );
    }
    out.add(
      'Not: review gereken kaynaklar için otomatik toplu ingestion yerine manuel lisans kontrolü şarttır.',
    );
    return out.join('\n');
  }

  String buildCoverageSnapshot() {
    final totalSources = _packs.fold<int>(
      0,
      (sum, pack) => sum + pack.sources.length,
    );
    return <String>[
      '[WEB PACK KAPSAMI]',
      '- domain sayısı: ' + _packs.length.toString(),
      '- toplam kaynak: ' + totalSources.toString(),
      '- kritik ayrım: bilimsel, yüksek-risk, inanç/yorum ve açık referans alanları ayrı tutulur.',
    ].join('\n');
  }
}
