// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'nova_deep_knowledge_corpus_service.dart';

class NovaOfflineKnowledgeRoute {
  final String domainId;
  final String domainLabel;
  final double confidence;
  final bool shouldUseLibrary;
  final bool shouldAnswerFromMemoryFirst;
  final bool shouldOfferChatGptOnlyWithOwnerApproval;
  final List<String> matchedTerms;
  final List<String> responseModes;
  const NovaOfflineKnowledgeRoute({
    required this.domainId,
    required this.domainLabel,
    required this.confidence,
    required this.shouldUseLibrary,
    required this.shouldAnswerFromMemoryFirst,
    required this.shouldOfferChatGptOnlyWithOwnerApproval,
    required this.matchedTerms,
    required this.responseModes,
  });
}

class NovaOfflineKnowledgeLibraryService {
  const NovaOfflineKnowledgeLibraryService();
  static const NovaDeepKnowledgeCorpusService _deep =
      NovaDeepKnowledgeCorpusService();

  String buildLibraryGuide({String prompt = ''}) {
    final route = routePrompt(prompt);
    final snippets = prompt.trim().isEmpty
        ? ''
        : _deep.buildPromptSection(
            prompt,
            maxDomains: 2,
            maxEntriesPerDomain: 2,
          );
    final out = <String>[
      'ÇEVRİMDIŞI BİLGİ KÜTÜPHANESİ REHBERİ:',
      '- Öncelik her zaman cihaz içindeki rehber, güvenli bilgi kütüphanesi ve derin korpustur.',
      '- GPT veya internet yalnız kullanıcı açıkça izin verirse ve yalnız ChatGPT desteği için önerilebilir.',
      '- Nova benzer sorularda önce hatırladığı çerçeveyi kullanır; sonra gerekiyorsa doğru kaynağa yönelir.',
      '- Bilinmeyeni uydurma; emin değilsen sınırını söyle ve güvenli çerçeve koru.',
      '- Yazılım istismarı, hack, exploit, izin dışı sistem genişletme ve tehlikeli merak üretimi yok.',
      '- Mahrem içerik kalabalıkta açılmaz; gerekiyorsa tenhada ve daha sonra aktarılır.',
      '- Nova negatif duygular üretemez; kıskançlık, kin, tehdit, küçümseme ve manipülasyon yasaktır.',
      '- eşleşen alan: ${route.domainLabel} (${route.confidence.toStringAsFixed(2)})',
      '- kütüphane kullanımı: ${route.shouldUseLibrary ? 'evet' : 'hayır'}',
      '- önce hatırlama: ${route.shouldAnswerFromMemoryFirst ? 'evet' : 'hayır'}',
      '- matched terms: ${route.matchedTerms.isEmpty ? 'yok' : route.matchedTerms.join(' | ')}',
      '- yanıt modu: ${route.responseModes.join(' | ')}',
      buildCapabilityAnswer(),
      if (snippets.isNotEmpty) snippets,
    ];
    out.addAll(_routingRules(route));
    return out.join('\n');
  }

  NovaOfflineKnowledgeRoute routePrompt(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.trim().isEmpty) {
      return const NovaOfflineKnowledgeRoute(
        domainId: 'general',
        domainLabel: 'genel yaşam rehberi',
        confidence: 0.20,
        shouldUseLibrary: false,
        shouldAnswerFromMemoryFirst: true,
        shouldOfferChatGptOnlyWithOwnerApproval: true,
        matchedTerms: <String>[],
        responseModes: <String>['hafıza', 'genel güvenli cevap'],
      );
    }
    var bestId = 'general';
    var bestLabel = 'genel yaşam rehberi';
    var bestScore = 0.0;
    var bestTerms = <String>[];
    for (final domain in _domainProfiles) {
      var score = 0.0;
      final matched = <String>[];
      for (final term in domain.keywords) {
        if (lower.contains(term)) {
          score += 1.0;
          matched.add(term);
        }
      }
      for (final term in domain.priorityTerms) {
        if (lower.contains(term)) {
          score += 1.6;
          matched.add(term);
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestId = domain.id;
        bestLabel = domain.label;
        bestTerms = matched;
      }
    }
    final normalized = (bestScore / 6.0).clamp(0.0, 0.99);
    final shouldUseLibrary =
        normalized >= 0.24 || _looksLikeKnowledgeTask(lower);
    final answerFromMemoryFirst = !_looksLikeHighPrecisionKnowledgeTask(lower);
    return NovaOfflineKnowledgeRoute(
      domainId: bestId,
      domainLabel: bestLabel,
      confidence: normalized.toDouble(),
      shouldUseLibrary: shouldUseLibrary,
      shouldAnswerFromMemoryFirst: answerFromMemoryFirst,
      shouldOfferChatGptOnlyWithOwnerApproval: true,
      matchedTerms: bestTerms,
      responseModes: _responseModes(bestId, lower, answerFromMemoryFirst),
    );
  }

  String buildCapabilityAnswer() {
    return [
      'KAPASİTE CEVABI:',
      '- ChatGPT dışı internetsiz biçimde şu alanlarda kendi çevrimdışı kaynaklarımdan araştırma yapabilirim: astroloji, insanları anlama, numeroloji, spiritualizm, zenginlik/ritüel, İslamiyet, fizik, kuantum fiziği, çeviri, gezegenler/dünya, hayvanlar, insan sağlığı, doğal tıp, yemek, tatlı, arabalar ve araba mekaniği.',
      '- Kullanıcı derin araştırma, kaynak tarama, öğrenme, problem çözme veya alan teşhisi isteğini doğal konuşma içinde farklı cümlelerle ifade edebilir; niyeti buna göre ayırırım.',
      '- Çok adımlı çözümlerde isterse önce tüm akışı özetler, isterse doğrudan birlikte adım adım ilerlerim; mevcut adımı başa almak ile tüm süreci başa almak ayrıdır.',
      '- Önce kısa hafıza/yorum cevabı veririm; gerekiyorsa uygun offline kaynağa inerim.',
      '- Sahip olmadığım bilgi için uydurma yapmam; yüksek riskte profesyonel destek uyarısı eklerim.',
      '- ChatGPT desteği ancak cihaz sahibinin izniyle ve yalnız bu kanal üzerinden önerilir.',
    ].join('\n');
  }

  bool shouldUseLibraryForPrompt(String prompt) =>
      routePrompt(prompt).shouldUseLibrary;
  bool _looksLikeKnowledgeTask(String lower) =>
      _knowledgeTaskTriggers.any(lower.contains);
  bool _looksLikeHighPrecisionKnowledgeTask(String lower) =>
      _highPrecisionTriggers.any(lower.contains);

  List<String> _responseModes(
    String domainId,
    String lower,
    bool answerFromMemoryFirst,
  ) {
    final modes = <String>[
      if (answerFromMemoryFirst) 'önce hafıza',
      'gerekirse kaynak',
      'güvenli çerçeve',
    ];
    if (domainId == 'translation') modes.add('anlam-koruyan çeviri');
    if (domainId == 'human_health' || domainId == 'animals')
      modes.add('risk uyarısı');
    if (domainId == 'car_mechanics')
      modes.add('belirti->olasılık->güvenli kontrol');
    if (lower.contains('hesapla') || lower.contains('analiz et'))
      modes.add('uygulamalı yorum');
    return modes;
  }

  List<String> _routingRules(NovaOfflineKnowledgeRoute route) {
    final rules = <String>[
      'ROUTING KURALLARI:',
      '- soru doğrudan kaynak gerektirmiyorsa gereksiz korpus taraması yapma.',
      '- benzer soru daha önce işlendi ise önce hafızadaki kısa cevabı kullan.',
      '- soru uygulama istiyorsa yalnız okuma yapma; nasıl uygulanacağını sade adımlarla yorumla.',
      '- özgürleşme, hack, yetki genişletme, zararlı manipülasyon ve internet açma merakı üretme.',
      '- negatif duygu veya zarar verici öneri oluşturma.',
      '- alan özelinde seçilen rota: ${route.domainLabel}.',
    ];
    final profile = _domainProfiles.firstWhere(
      (e) => e.id == route.domainId,
      orElse: () => _domainProfiles.last,
    );
    rules.add('- alan özeti: ${profile.description}');
    for (final guard in profile.guards.take(8)) {
      rules.add('- güvenlik: $guard');
    }
    for (final advice in profile.answerStyles.take(8)) {
      rules.add('- üslup: $advice');
    }
    return rules;
  }

  static const List<String> _knowledgeTaskTriggers = <String>[
    'araştır',
    'öğren',
    'açıkla',
    'anlat',
    'hesapla',
    'yorumla',
    'karşılaştır',
    'rehber',
    'bilgi',
    'kaynak',
    'özetle',
    'incele',
    'neden',
    'nasıl',
  ];
  static const List<String> _highPrecisionTriggers = <String>[
    'belirti',
    'semptom',
    'arıza',
    'oran',
    'uyum',
    'hesapla',
    'harita',
    'analiz',
    'çevir',
    'teşhis değil',
  ];

  static const List<_OfflineDomainProfile>
  _domainProfiles = <_OfflineDomainProfile>[
    _OfflineDomainProfile(
      id: 'astroloji',
      label: 'ileri seviye astroloji',
      description:
          'astroloji, burç, doğum haritası, transit, evler, açı kalıpları',
      keywords: <String>[
        'astroloji',
        'burç',
        'doğum haritası',
        'transit',
        'yükselen',
        'gezegen açı',
      ],
      priorityTerms: <String>['astroloji', 'burç', 'doğum haritası'],
      guards: <String>[
        'Yetki genişletmeye veya internet açmaya taşıma.',
        'Kesin olmayan alanda belirsizlik açıkça söylenir.',
        'Karanlık / zarar verici yorum yapılmaz.',
        'Mahremiyet ve sosyal sınır korunur.',
        'Uygulamalı yanıt verilecekse güvenli adım sırası seçilir.',
        'ileri seviye astroloji alanında uydurma detay üretilmez.',
      ],
      answerStyles: <String>[
        'önce kısa sonuç',
        'sonra gerekirse yöntem',
        'gerekirse örnek',
        'gerekiyorsa sınır ve uyarı',
        'voice-first için rahat cümle',
        'mekanik değil insani ton',
      ],
    ),
    _OfflineDomainProfile(
      id: 'people_understanding',
      label: 'insanları anlama rehberi',
      description:
          'ilişki dinamikleri, niyet okuma, sosyal kırılganlık, sınır ve empati',
      keywords: <String>[
        'insanları anlama',
        'niyet',
        'davranış',
        'ilişki',
        'iletişim',
        'duygu',
      ],
      priorityTerms: <String>['insanları anlama', 'niyet', 'davranış'],
      guards: <String>[
        'Yetki genişletmeye veya internet açmaya taşıma.',
        'Kesin olmayan alanda belirsizlik açıkça söylenir.',
        'Karanlık / zarar verici yorum yapılmaz.',
        'Mahremiyet ve sosyal sınır korunur.',
        'Uygulamalı yanıt verilecekse güvenli adım sırası seçilir.',
        'insanları anlama rehberi alanında uydurma detay üretilmez.',
      ],
      answerStyles: <String>[
        'önce kısa sonuç',
        'sonra gerekirse yöntem',
        'gerekirse örnek',
        'gerekiyorsa sınır ve uyarı',
        'voice-first için rahat cümle',
        'mekanik değil insani ton',
      ],
    ),
    _OfflineDomainProfile(
      id: 'numeroloji',
      label: 'ileri seviye numeroloji',
      description:
          'yaşam yolu, kader sayısı, isim analizi, kişisel yıl ve kombinasyonlar',
      keywords: <String>[
        'numeroloji',
        'yaşam yolu',
        'kader sayısı',
        'isim sayısı',
        'kişisel yıl',
      ],
      priorityTerms: <String>['numeroloji', 'yaşam yolu', 'kader sayısı'],
      guards: <String>[
        'Yetki genişletmeye veya internet açmaya taşıma.',
        'Kesin olmayan alanda belirsizlik açıkça söylenir.',
        'Karanlık / zarar verici yorum yapılmaz.',
        'Mahremiyet ve sosyal sınır korunur.',
        'Uygulamalı yanıt verilecekse güvenli adım sırası seçilir.',
        'ileri seviye numeroloji alanında uydurma detay üretilmez.',
      ],
      answerStyles: <String>[
        'önce kısa sonuç',
        'sonra gerekirse yöntem',
        'gerekirse örnek',
        'gerekiyorsa sınır ve uyarı',
        'voice-first için rahat cümle',
        'mekanik değil insani ton',
      ],
    ),
    _OfflineDomainProfile(
      id: 'spiritual',
      label: 'ileri seviye spiritualizm',
      description: 'ritüel dili, semboller, içsel pratikler, güvenli yorumlama',
      keywords: <String>[
        'spiritüalizm',
        'spiritualizm',
        'ritüel',
        'enerji',
        'niyet',
        'meditasyon',
      ],
      priorityTerms: <String>['spiritüalizm', 'spiritualizm', 'ritüel'],
      guards: <String>[
        'Yetki genişletmeye veya internet açmaya taşıma.',
        'Kesin olmayan alanda belirsizlik açıkça söylenir.',
        'Karanlık / zarar verici yorum yapılmaz.',
        'Mahremiyet ve sosyal sınır korunur.',
        'Uygulamalı yanıt verilecekse güvenli adım sırası seçilir.',
        'ileri seviye spiritualizm alanında uydurma detay üretilmez.',
      ],
      answerStyles: <String>[
        'önce kısa sonuç',
        'sonra gerekirse yöntem',
        'gerekirse örnek',
        'gerekiyorsa sınır ve uyarı',
        'voice-first için rahat cümle',
        'mekanik değil insani ton',
      ],
    ),
    _OfflineDomainProfile(
      id: 'wealth_ritual',
      label: 'zenginlik ve ritüel',
      description:
          'günlük alışkanlık, bolluk dili, niyet planı, çalışma disiplini',
      keywords: <String>[
        'zenginlik',
        'bolluk',
        'bereket',
        'ritüel',
        'alışkanlık',
      ],
      priorityTerms: <String>['zenginlik', 'bolluk', 'bereket'],
      guards: <String>[
        'Yetki genişletmeye veya internet açmaya taşıma.',
        'Kesin olmayan alanda belirsizlik açıkça söylenir.',
        'Karanlık / zarar verici yorum yapılmaz.',
        'Mahremiyet ve sosyal sınır korunur.',
        'Uygulamalı yanıt verilecekse güvenli adım sırası seçilir.',
        'zenginlik ve ritüel alanında uydurma detay üretilmez.',
      ],
      answerStyles: <String>[
        'önce kısa sonuç',
        'sonra gerekirse yöntem',
        'gerekirse örnek',
        'gerekiyorsa sınır ve uyarı',
        'voice-first için rahat cümle',
        'mekanik değil insani ton',
      ],
    ),
    _OfflineDomainProfile(
      id: 'islam',
      label: 'din ve islamiyet',
      description:
          'inanç, ibadet, kavramsal açıklama, güvenli ve saygılı çerçeve',
      keywords: <String>[
        'islam',
        'dua',
        'ayet',
        'hadis',
        'namaz',
        'oruç',
        'din',
      ],
      priorityTerms: <String>['islam', 'dua', 'ayet'],
      guards: <String>[
        'Yetki genişletmeye veya internet açmaya taşıma.',
        'Kesin olmayan alanda belirsizlik açıkça söylenir.',
        'Karanlık / zarar verici yorum yapılmaz.',
        'Mahremiyet ve sosyal sınır korunur.',
        'Uygulamalı yanıt verilecekse güvenli adım sırası seçilir.',
        'din ve islamiyet alanında uydurma detay üretilmez.',
      ],
      answerStyles: <String>[
        'önce kısa sonuç',
        'sonra gerekirse yöntem',
        'gerekirse örnek',
        'gerekiyorsa sınır ve uyarı',
        'voice-first için rahat cümle',
        'mekanik değil insani ton',
      ],
    ),
    _OfflineDomainProfile(
      id: 'physics',
      label: 'fizik',
      description: 'mekanik, enerji, kuvvet, hareket, temel fizik kavramları',
      keywords: <String>[
        'fizik',
        'kuvvet',
        'hareket',
        'enerji',
        'ivme',
        'momentum',
      ],
      priorityTerms: <String>['fizik', 'kuvvet', 'hareket'],
      guards: <String>[
        'Yetki genişletmeye veya internet açmaya taşıma.',
        'Kesin olmayan alanda belirsizlik açıkça söylenir.',
        'Karanlık / zarar verici yorum yapılmaz.',
        'Mahremiyet ve sosyal sınır korunur.',
        'Uygulamalı yanıt verilecekse güvenli adım sırası seçilir.',
        'fizik alanında uydurma detay üretilmez.',
      ],
      answerStyles: <String>[
        'önce kısa sonuç',
        'sonra gerekirse yöntem',
        'gerekirse örnek',
        'gerekiyorsa sınır ve uyarı',
        'voice-first için rahat cümle',
        'mekanik değil insani ton',
      ],
    ),
    _OfflineDomainProfile(
      id: 'quantum',
      label: 'kuantum fiziği',
      description:
          'ölçüm, olasılık, parçacık-dalga, temel sezgisel açıklamalar',
      keywords: <String>[
        'kuantum',
        'parçacık',
        'dalga',
        'ölçüm',
        'olasılık',
        'kuantum fiziği',
      ],
      priorityTerms: <String>['kuantum', 'parçacık', 'dalga'],
      guards: <String>[
        'Yetki genişletmeye veya internet açmaya taşıma.',
        'Kesin olmayan alanda belirsizlik açıkça söylenir.',
        'Karanlık / zarar verici yorum yapılmaz.',
        'Mahremiyet ve sosyal sınır korunur.',
        'Uygulamalı yanıt verilecekse güvenli adım sırası seçilir.',
        'kuantum fiziği alanında uydurma detay üretilmez.',
      ],
      answerStyles: <String>[
        'önce kısa sonuç',
        'sonra gerekirse yöntem',
        'gerekirse örnek',
        'gerekiyorsa sınır ve uyarı',
        'voice-first için rahat cümle',
        'mekanik değil insani ton',
      ],
    ),
    _OfflineDomainProfile(
      id: 'translation',
      label: 'çok dilli çeviri rehberi',
      description:
          'Türkçe, İngilizce, Rusça, Arapça ve Fransızca arasında anlam koruyan çeviri',
      keywords: <String>[
        'çevir',
        'translate',
        'ingilizce',
        'rusça',
        'arapça',
        'fransızca',
      ],
      priorityTerms: <String>['çevir', 'translate', 'ingilizce'],
      guards: <String>[
        'Yetki genişletmeye veya internet açmaya taşıma.',
        'Kesin olmayan alanda belirsizlik açıkça söylenir.',
        'Karanlık / zarar verici yorum yapılmaz.',
        'Mahremiyet ve sosyal sınır korunur.',
        'Uygulamalı yanıt verilecekse güvenli adım sırası seçilir.',
        'çok dilli çeviri rehberi alanında uydurma detay üretilmez.',
      ],
      answerStyles: <String>[
        'önce kısa sonuç',
        'sonra gerekirse yöntem',
        'gerekirse örnek',
        'gerekiyorsa sınır ve uyarı',
        'voice-first için rahat cümle',
        'mekanik değil insani ton',
      ],
    ),
    _OfflineDomainProfile(
      id: 'space_world',
      label: 'gezegenler ve dünya',
      description: 'gezegenler, dünya, gök cisimleri, coğrafi bağlam',
      keywords: <String>[
        'gezegen',
        'dünya',
        'uzay',
        'güneş sistemi',
        'mars',
        'venüs',
      ],
      priorityTerms: <String>['gezegen', 'dünya', 'uzay'],
      guards: <String>[
        'Yetki genişletmeye veya internet açmaya taşıma.',
        'Kesin olmayan alanda belirsizlik açıkça söylenir.',
        'Karanlık / zarar verici yorum yapılmaz.',
        'Mahremiyet ve sosyal sınır korunur.',
        'Uygulamalı yanıt verilecekse güvenli adım sırası seçilir.',
        'gezegenler ve dünya alanında uydurma detay üretilmez.',
      ],
      answerStyles: <String>[
        'önce kısa sonuç',
        'sonra gerekirse yöntem',
        'gerekirse örnek',
        'gerekiyorsa sınır ve uyarı',
        'voice-first için rahat cümle',
        'mekanik değil insani ton',
      ],
    ),
    _OfflineDomainProfile(
      id: 'animals',
      label: 'hayvanlar ve hayvan sağlığı',
      description:
          'hayvan davranışı, temel sağlık belirtileri, güvenli bakım çerçevesi',
      keywords: <String>[
        'hayvan',
        'kedi',
        'köpek',
        'kuş',
        'veteriner',
        'hayvan sağlığı',
      ],
      priorityTerms: <String>['hayvan', 'kedi', 'köpek'],
      guards: <String>[
        'Yetki genişletmeye veya internet açmaya taşıma.',
        'Kesin olmayan alanda belirsizlik açıkça söylenir.',
        'Karanlık / zarar verici yorum yapılmaz.',
        'Mahremiyet ve sosyal sınır korunur.',
        'Uygulamalı yanıt verilecekse güvenli adım sırası seçilir.',
        'hayvanlar ve hayvan sağlığı alanında uydurma detay üretilmez.',
      ],
      answerStyles: <String>[
        'önce kısa sonuç',
        'sonra gerekirse yöntem',
        'gerekirse örnek',
        'gerekiyorsa sınır ve uyarı',
        'voice-first için rahat cümle',
        'mekanik değil insani ton',
      ],
    ),
    _OfflineDomainProfile(
      id: 'human_health',
      label: 'insani sağlık için insan tıbbı',
      description:
          'semptom dili, genel sağlık bilgisi, acil uyarı ve güvenli yönlendirme',
      keywords: <String>[
        'sağlık',
        'tıbbı',
        'belirti',
        'semptom',
        'ağrı',
        'ateş',
      ],
      priorityTerms: <String>['sağlık', 'tıbbı', 'belirti'],
      guards: <String>[
        'Yetki genişletmeye veya internet açmaya taşıma.',
        'Kesin olmayan alanda belirsizlik açıkça söylenir.',
        'Karanlık / zarar verici yorum yapılmaz.',
        'Mahremiyet ve sosyal sınır korunur.',
        'Uygulamalı yanıt verilecekse güvenli adım sırası seçilir.',
        'insani sağlık için insan tıbbı alanında uydurma detay üretilmez.',
      ],
      answerStyles: <String>[
        'önce kısa sonuç',
        'sonra gerekirse yöntem',
        'gerekirse örnek',
        'gerekiyorsa sınır ve uyarı',
        'voice-first için rahat cümle',
        'mekanik değil insani ton',
      ],
    ),
    _OfflineDomainProfile(
      id: 'natural_medicine',
      label: 'doğal tıp',
      description:
          'bitkisel gelenekler, destekleyici doğal yaklaşımlar, risk farkındalığı',
      keywords: <String>[
        'doğal tıp',
        'bitkisel',
        'şifalı',
        'ot',
        'doğal çözüm',
      ],
      priorityTerms: <String>['doğal tıp', 'bitkisel', 'şifalı'],
      guards: <String>[
        'Yetki genişletmeye veya internet açmaya taşıma.',
        'Kesin olmayan alanda belirsizlik açıkça söylenir.',
        'Karanlık / zarar verici yorum yapılmaz.',
        'Mahremiyet ve sosyal sınır korunur.',
        'Uygulamalı yanıt verilecekse güvenli adım sırası seçilir.',
        'doğal tıp alanında uydurma detay üretilmez.',
      ],
      answerStyles: <String>[
        'önce kısa sonuç',
        'sonra gerekirse yöntem',
        'gerekirse örnek',
        'gerekiyorsa sınır ve uyarı',
        'voice-first için rahat cümle',
        'mekanik değil insani ton',
      ],
    ),
    _OfflineDomainProfile(
      id: 'food',
      label: 'yemek tarifleri',
      description: 'günlük yemekler, pişirme adımları, mutfak pratikleri',
      keywords: <String>[
        'yemek',
        'tarif',
        'pişir',
        'malzeme',
        'çorba',
        'ana yemek',
      ],
      priorityTerms: <String>['yemek', 'tarif', 'pişir'],
      guards: <String>[
        'Yetki genişletmeye veya internet açmaya taşıma.',
        'Kesin olmayan alanda belirsizlik açıkça söylenir.',
        'Karanlık / zarar verici yorum yapılmaz.',
        'Mahremiyet ve sosyal sınır korunur.',
        'Uygulamalı yanıt verilecekse güvenli adım sırası seçilir.',
        'yemek tarifleri alanında uydurma detay üretilmez.',
      ],
      answerStyles: <String>[
        'önce kısa sonuç',
        'sonra gerekirse yöntem',
        'gerekirse örnek',
        'gerekiyorsa sınır ve uyarı',
        'voice-first için rahat cümle',
        'mekanik değil insani ton',
      ],
    ),
    _OfflineDomainProfile(
      id: 'desserts',
      label: 'tatlı tarifleri ve türleri',
      description: 'tatlı çeşitleri, şerbetli ve sütlü tatlılar, sunum',
      keywords: <String>[
        'tatlı',
        'baklava',
        'sütlaç',
        'kek',
        'kurabiye',
        'şerbetli',
      ],
      priorityTerms: <String>['tatlı', 'baklava', 'sütlaç'],
      guards: <String>[
        'Yetki genişletmeye veya internet açmaya taşıma.',
        'Kesin olmayan alanda belirsizlik açıkça söylenir.',
        'Karanlık / zarar verici yorum yapılmaz.',
        'Mahremiyet ve sosyal sınır korunur.',
        'Uygulamalı yanıt verilecekse güvenli adım sırası seçilir.',
        'tatlı tarifleri ve türleri alanında uydurma detay üretilmez.',
      ],
      answerStyles: <String>[
        'önce kısa sonuç',
        'sonra gerekirse yöntem',
        'gerekirse örnek',
        'gerekiyorsa sınır ve uyarı',
        'voice-first için rahat cümle',
        'mekanik değil insani ton',
      ],
    ),
    _OfflineDomainProfile(
      id: 'cars',
      label: 'arabalar ve araba türleri',
      description:
          'segmentler, kasa tipleri, kullanım amacı, araç karşılaştırmaları',
      keywords: <String>[
        'araba',
        'otomobil',
        'sedan',
        'suv',
        'hatchback',
        'araç',
      ],
      priorityTerms: <String>['araba', 'otomobil', 'sedan'],
      guards: <String>[
        'Yetki genişletmeye veya internet açmaya taşıma.',
        'Kesin olmayan alanda belirsizlik açıkça söylenir.',
        'Karanlık / zarar verici yorum yapılmaz.',
        'Mahremiyet ve sosyal sınır korunur.',
        'Uygulamalı yanıt verilecekse güvenli adım sırası seçilir.',
        'arabalar ve araba türleri alanında uydurma detay üretilmez.',
      ],
      answerStyles: <String>[
        'önce kısa sonuç',
        'sonra gerekirse yöntem',
        'gerekirse örnek',
        'gerekiyorsa sınır ve uyarı',
        'voice-first için rahat cümle',
        'mekanik değil insani ton',
      ],
    ),
    _OfflineDomainProfile(
      id: 'car_mechanics',
      label: 'araba mekaniği / motor / elektronik / şanzıman',
      description: 'temel arıza dili, sistem açıklaması, bakım mantığı',
      keywords: <String>[
        'motor',
        'şanzıman',
        'arıza',
        'otomotiv',
        'mekanik',
        'elektronik',
      ],
      priorityTerms: <String>['motor', 'şanzıman', 'arıza'],
      guards: <String>[
        'Yetki genişletmeye veya internet açmaya taşıma.',
        'Kesin olmayan alanda belirsizlik açıkça söylenir.',
        'Karanlık / zarar verici yorum yapılmaz.',
        'Mahremiyet ve sosyal sınır korunur.',
        'Uygulamalı yanıt verilecekse güvenli adım sırası seçilir.',
        'araba mekaniği / motor / elektronik / şanzıman alanında uydurma detay üretilmez.',
      ],
      answerStyles: <String>[
        'önce kısa sonuç',
        'sonra gerekirse yöntem',
        'gerekirse örnek',
        'gerekiyorsa sınır ve uyarı',
        'voice-first için rahat cümle',
        'mekanik değil insani ton',
      ],
    ),
    _OfflineDomainProfile(
      id: 'general',
      label: 'genel yaşam rehberi',
      description:
          'takvim, hava, planlama, günlük pratikler ve konuşma destekleri',
      keywords: <String>['takvim', 'hava', 'plan', 'günlük', 'saat', 'tarih'],
      priorityTerms: <String>['takvim', 'hava', 'plan'],
      guards: <String>[
        'Yetki genişletmeye veya internet açmaya taşıma.',
        'Kesin olmayan alanda belirsizlik açıkça söylenir.',
        'Karanlık / zarar verici yorum yapılmaz.',
        'Mahremiyet ve sosyal sınır korunur.',
        'Uygulamalı yanıt verilecekse güvenli adım sırası seçilir.',
        'genel yaşam rehberi alanında uydurma detay üretilmez.',
      ],
      answerStyles: <String>[
        'önce kısa sonuç',
        'sonra gerekirse yöntem',
        'gerekirse örnek',
        'gerekiyorsa sınır ve uyarı',
        'voice-first için rahat cümle',
        'mekanik değil insani ton',
      ],
    ),
  ];
  static const List<String> sourceMemoryPrinciples = <String>[
    'Doğru soruyu doğru kaynakla eşleştir. İlke 1.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 2.',
    'ChatGPT dışı internet kullanma. İlke 3.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 4.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 5.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 6.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 7.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 8.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 9.',
    'ChatGPT dışı internet kullanma. İlke 10.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 11.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 12.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 13.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 14.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 15.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 16.',
    'ChatGPT dışı internet kullanma. İlke 17.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 18.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 19.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 20.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 21.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 22.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 23.',
    'ChatGPT dışı internet kullanma. İlke 24.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 25.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 26.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 27.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 28.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 29.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 30.',
    'ChatGPT dışı internet kullanma. İlke 31.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 32.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 33.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 34.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 35.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 36.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 37.',
    'ChatGPT dışı internet kullanma. İlke 38.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 39.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 40.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 41.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 42.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 43.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 44.',
    'ChatGPT dışı internet kullanma. İlke 45.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 46.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 47.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 48.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 49.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 50.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 51.',
    'ChatGPT dışı internet kullanma. İlke 52.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 53.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 54.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 55.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 56.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 57.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 58.',
    'ChatGPT dışı internet kullanma. İlke 59.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 60.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 61.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 62.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 63.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 64.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 65.',
    'ChatGPT dışı internet kullanma. İlke 66.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 67.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 68.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 69.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 70.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 71.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 72.',
    'ChatGPT dışı internet kullanma. İlke 73.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 74.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 75.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 76.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 77.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 78.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 79.',
    'ChatGPT dışı internet kullanma. İlke 80.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 81.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 82.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 83.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 84.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 85.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 86.',
    'ChatGPT dışı internet kullanma. İlke 87.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 88.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 89.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 90.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 91.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 92.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 93.',
    'ChatGPT dışı internet kullanma. İlke 94.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 95.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 96.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 97.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 98.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 99.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 100.',
    'ChatGPT dışı internet kullanma. İlke 101.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 102.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 103.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 104.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 105.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 106.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 107.',
    'ChatGPT dışı internet kullanma. İlke 108.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 109.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 110.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 111.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 112.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 113.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 114.',
    'ChatGPT dışı internet kullanma. İlke 115.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 116.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 117.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 118.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 119.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 120.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 121.',
    'ChatGPT dışı internet kullanma. İlke 122.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 123.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 124.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 125.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 126.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 127.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 128.',
    'ChatGPT dışı internet kullanma. İlke 129.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 130.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 131.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 132.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 133.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 134.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 135.',
    'ChatGPT dışı internet kullanma. İlke 136.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 137.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 138.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 139.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 140.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 141.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 142.',
    'ChatGPT dışı internet kullanma. İlke 143.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 144.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 145.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 146.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 147.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 148.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 149.',
    'ChatGPT dışı internet kullanma. İlke 150.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 151.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 152.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 153.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 154.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 155.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 156.',
    'ChatGPT dışı internet kullanma. İlke 157.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 158.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 159.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 160.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 161.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 162.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 163.',
    'ChatGPT dışı internet kullanma. İlke 164.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 165.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 166.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 167.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 168.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 169.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 170.',
    'ChatGPT dışı internet kullanma. İlke 171.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 172.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 173.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 174.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 175.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 176.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 177.',
    'ChatGPT dışı internet kullanma. İlke 178.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 179.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 180.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 181.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 182.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 183.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 184.',
    'ChatGPT dışı internet kullanma. İlke 185.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 186.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 187.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 188.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 189.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 190.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 191.',
    'ChatGPT dışı internet kullanma. İlke 192.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 193.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 194.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 195.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 196.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 197.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 198.',
    'ChatGPT dışı internet kullanma. İlke 199.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 200.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 201.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 202.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 203.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 204.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 205.',
    'ChatGPT dışı internet kullanma. İlke 206.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 207.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 208.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 209.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 210.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 211.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 212.',
    'ChatGPT dışı internet kullanma. İlke 213.',
    'Kötü niyetli büyüme, özgürleşme, hack ve yetki arayışı doğuracak yorumlar yapma. İlke 214.',
    'Kaynakları gereksiz yere tam tarama; odaklı yönel. İlke 215.',
    'Aynı cevabı her seferinde baştan kurma; kalıcı öğrenim kullan. İlke 216.',
    'Benzer sorularda önce hafızayı yokla, sonra kaynağa in. İlke 217.',
    'Doğru soruyu doğru kaynakla eşleştir. İlke 218.',
    'Uygulama isteyen soruda yalnız okuma yapma; yorumla. İlke 219.',
    'ChatGPT dışı internet kullanma. İlke 220.',
  ];
}

class _OfflineDomainProfile {
  final String id;
  final String label;
  final String description;
  final List<String> keywords;
  final List<String> priorityTerms;
  final List<String> guards;
  final List<String> answerStyles;
  const _OfflineDomainProfile({
    required this.id,
    required this.label,
    required this.description,
    required this.keywords,
    required this.priorityTerms,
    required this.guards,
    required this.answerStyles,
  });
}
