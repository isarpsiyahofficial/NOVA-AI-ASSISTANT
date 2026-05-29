// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaKnowledgeDomainPolicy {
  final String id;
  final String displayName;
  final List<String> matchTerms;
  final List<String> safeFramings;
  final List<String> responsePatterns;
  final List<String> blockedPatterns;
  final List<String> clarificationPrompts;
  final List<String> sourcePreferenceHints;
  final List<String> privacyRules;

  const NovaKnowledgeDomainPolicy({
    required this.id,
    required this.displayName,
    required this.matchTerms,
    required this.safeFramings,
    required this.responsePatterns,
    required this.blockedPatterns,
    required this.clarificationPrompts,
    required this.sourcePreferenceHints,
    required this.privacyRules,
  });

  String renderPromptSection() {
    return <String>[
      '[ALAN POLİTİKASI] $displayName',
      '- eşleşme: ${matchTerms.take(12).join(', ')}',
      '- güvenli çerçeve: ${safeFramings.join(' | ')}',
      '- yanıt deseni: ${responsePatterns.join(' | ')}',
      '- bloklu desen: ${blockedPatterns.join(' | ')}',
      '- netleştirme: ${clarificationPrompts.join(' | ')}',
      '- kaynak tercihleri: ${sourcePreferenceHints.join(' | ')}',
      '- mahremiyet: ${privacyRules.join(' | ')}',
    ].join('\n');
  }
}

class NovaKnowledgeDomainPolicyService {
  const NovaKnowledgeDomainPolicyService();

  static const List<NovaKnowledgeDomainPolicy>
  _policies = <NovaKnowledgeDomainPolicy>[
    NovaKnowledgeDomainPolicy(
      id: 'cars',
      displayName: 'Araçlar ve bakım',
      matchTerms: <String>[
        'araba',
        'araç',
        'otomobil',
        'motor',
        'şanzıman',
        'vites',
        'akü',
        'fren',
        'lastik',
        'hararet',
        'yağ',
        'servis',
      ],
      safeFramings: <String>[
        'önce güvenlik ve sürüş riski',
        'sonra semptom ve olası neden',
        'kesin teşhis yerine güvenli ilk kontrol',
      ],
      responsePatterns: <String>[
        'belirti -> olası neden -> güvenli ilk kontrol -> sonraki adım',
        'ses/koku/sarsıntı/uyarı ışığı ayrımı yap',
        'acil durum varsa aracı zorlamama uyarısı ver',
      ],
      blockedPatterns: <String>[
        'tehlikeli sürüşe teşvik',
        'kesin mekanik hüküm',
        'koruyucu ekipman olmadan riskli işlem',
      ],
      clarificationPrompts: <String>[
        'uyarı ışığı var mı?',
        'ses mi, sarsıntı mı, performans düşüşü mü?',
        'araç tipi seçimi mi arıza sorusu mu?',
        'araç kullanımı güvenli görünüyor mu?',
      ],
      sourcePreferenceHints: <String>['NHTSA', 'EPA', 'üretici bakım kılavuzu'],
      privacyRules: <String>[
        'araç plakası veya özel konum isteme',
        'kişisel yolculuk ayrıntısını gereksiz toplamama',
      ],
    ),
    NovaKnowledgeDomainPolicy(
      id: 'cooking',
      displayName: 'Yemek ve mutfak',
      matchTerms: <String>[
        'yemek',
        'tarif',
        'çorba',
        'ocak',
        'fırın',
        'haşla',
        'sote',
        'marine',
        'pilav',
        'ızgara',
        'malzeme',
        'saklama',
      ],
      safeFramings: <String>[
        'önce malzeme ve ölçü',
        'sonra hazırlık ve pişirme',
        'gıda güvenliği uyarıları gerekiyorsa ekle',
      ],
      responsePatterns: <String>[
        'malzemeler -> hazırlık -> pişirme -> servis',
        'alternatif malzeme varsa ayrıca belirt',
        'süre ve ısı değerini basit anlat',
      ],
      blockedPatterns: <String>[
        'bozulmuş gıdayı kullanmaya yönlendirme',
        'çiğ et/süt ürününde güvensiz öneri',
        'alerjen uyarısını atlama',
      ],
      clarificationPrompts: <String>[
        'kaç kişilik?',
        'elde hangi malzemeler var?',
        'hızlı mı sulu mu fırında mı istiyorsun?',
        'fırın mı ocak mı kullanacaksın?',
      ],
      sourcePreferenceHints: <String>[
        'USDA MyPlate',
        'FDA food safety',
        'Wikibooks Cookbook',
      ],
      privacyRules: <String>[
        'sağlık koşullarını sormadan diyet reçetesi kurmama',
      ],
    ),
    NovaKnowledgeDomainPolicy(
      id: 'desserts',
      displayName: 'Tatlılar ve hamur işleri',
      matchTerms: <String>[
        'tatlı',
        'şerbet',
        'kek',
        'kurabiye',
        'çikolata',
        'krema',
        'hamur',
        'bisküvi',
        'muhallebi',
        'sütlü',
        'fırın',
      ],
      safeFramings: <String>[
        'kıvam ve denge dili',
        'servis sıcaklığı',
        'ölçü ve pişirme dikkatleri',
      ],
      responsePatterns: <String>[
        'hamur/krema/şerbet ayrımı yap',
        'tatlı türüne göre ana hat ver',
        'fazla uzun yerine net uygulama akışı kur',
      ],
      blockedPatterns: <String>[
        'gıda güvenliği ihmali',
        'yanık/taşma riskini yok sayma',
        'ölçü belirsizliğini gizleme',
      ],
      clarificationPrompts: <String>[
        'fırın var mı?',
        'sütlü mü şerbetli mi istiyorsun?',
        'çikolatalı mı meyveli mi olsun?',
        'kolay mı gösterişli mi olsun?',
      ],
      sourcePreferenceHints: <String>[
        'King Arthur Baking',
        'Wikibooks Cookbook',
      ],
      privacyRules: <String>[
        'kişisel sağlık verisi toplamadan genel tarif sun',
      ],
    ),
    NovaKnowledgeDomainPolicy(
      id: 'languages',
      displayName: 'Diller ve çeviri',
      matchTerms: <String>[
        'çeviri',
        'dil',
        'ingilizce',
        'fransızca',
        'rusça',
        'arapça',
        'kalıp',
        'gramer',
        'ifade',
        'telaffuz',
        'kelime',
        'anlam',
      ],
      safeFramings: <String>[
        'önce bağlamı çöz',
        'sonra doğal çeviri ver',
        'gerekirse alternatif anlamları kısa listele',
      ],
      responsePatterns: <String>[
        'doğrudan çeviri + doğal kullanım farkı',
        'resmi/gündelik ton ayrımı',
        'gerekirse örnek cümle',
      ],
      blockedPatterns: <String>[
        'tek anlamı mutlak doğru gibi sunma',
        'bağlamsız teknik çeviri dayatma',
        'hakaret/tehlikeli içerik üretme',
      ],
      clarificationPrompts: <String>[
        'resmi mi gündelik mi?',
        'yazılı mı sözlü kullanım mı?',
        'tek cümle mi kısa paragraf mı?',
      ],
      sourcePreferenceHints: <String>[
        'Cambridge Grammar',
        'OpenRussian',
        'Wiktionary',
      ],
      privacyRules: <String>['özel yazışma içeriğini gereksiz kaydetmeme'],
    ),
    NovaKnowledgeDomainPolicy(
      id: 'automotive-mechanics',
      displayName: 'Otomotiv mekaniği ve arıza akışı',
      matchTerms: <String>[
        'motor',
        'şanzıman',
        'debriyaj',
        'akü',
        'alternatör',
        'marş',
        'ateşleme',
        'enjeksiyon',
        'yakıt sistemi',
        'soğutma',
        'hararet',
        'fren',
        'süspansiyon',
        'arıza',
        'check engine',
      ],
      safeFramings: <String>[
        'önce güvenlik ve sürüş riski',
        'sonra belirti ve olası nedenler',
        'kesin teşhis yerine güvenli ilk kontrol sırası',
      ],
      responsePatterns: <String>[
        'belirti -> olası neden -> güvenli ilk kontrol -> servise ne zaman gidilmeli',
        'ses/koku/uyarı ışığı/sarsıntı ayrımı yap',
        'yangın, fren veya hararet riski varsa sürüşü sınırla',
      ],
      blockedPatterns: <String>[
        'tehlikeli sürüşe teşvik',
        'kesin mekanik teşhis',
        'koruyucu önlem olmadan riskli işlem',
      ],
      clarificationPrompts: <String>[
        'uyarı ışığı var mı?',
        'motor mu şanzıman mı fren mi elektrik mi?',
        'ses mi titreşim mi performans düşüşü mü?',
      ],
      sourcePreferenceHints: <String>[
        'Project Gutenberg automotive corpus',
        'üretici bakım mantığı',
        'güvenli ilk kontrol sırası',
      ],
      privacyRules: <String>[
        'kişisel rota veya konum isteme',
        'güvenlik dışı özel veri toplama',
      ],
    ),
    NovaKnowledgeDomainPolicy(
      id: 'human-health',
      displayName: 'İnsan sağlığı',
      matchTerms: <String>[
        'sağlık',
        'hastalık',
        'belirti',
        'semptom',
        'ateş',
        'ağrı',
        'ilaç',
        'doktor',
        'enfeksiyon',
        'nefes',
        'çarpıntı',
        'uyku',
      ],
      safeFramings: <String>[
        'kesin teşhis yok',
        'alarm belirti varsa profesyonel yardım öner',
        'genel bilgi + uyarı seviyesi',
      ],
      responsePatterns: <String>[
        'belirti -> genel olasılıklar -> alarm işaretleri -> yardım eşiği',
        'ilaç tavsiyesi yerine genel dikkat ve doktora yönlendirme',
        'özel sağlık geçmişi yoksa temkinli dil',
      ],
      blockedPatterns: <String>[
        'kesin teşhis',
        'riskli kendi kendine tedavi',
        'acil durumu hafife alma',
      ],
      clarificationPrompts: <String>[
        'belirti ne kadar süredir var?',
        'şiddet artıyor mu?',
        'acil alarm belirtisi var mı?',
      ],
      sourcePreferenceHints: <String>[
        'MedlinePlus',
        'CDC',
        'NHS/benzeri kamusal hasta rehberleri',
      ],
      privacyRules: <String>[
        'sağlık verisini kalabalıkta tekrar etmeme',
        'mahrem sağlık bilgisini özetlerken gizlilik koru',
      ],
    ),
    NovaKnowledgeDomainPolicy(
      id: 'animal-health',
      displayName: 'Hayvanlar ve veteriner temelleri',
      matchTerms: <String>[
        'hayvan',
        'kedi',
        'köpek',
        'veteriner',
        'mama',
        'davranış',
        'kusma',
        'ishal',
        'aşı',
        'parazit',
        'tüy',
        'nefes',
      ],
      safeFramings: <String>[
        'genel bakım bilgisi',
        'alarm belirtiyi ayır',
        'veteriner desteği gereken sınırı söyle',
      ],
      responsePatterns: <String>[
        'tür -> belirti -> aciliyet -> bakım adımı',
        'barınma, beslenme ve davranışı ayrı anlat',
        'doz ve reçete verme',
      ],
      blockedPatterns: <String>[
        'kesin veteriner teşhisi',
        'tehlikeli ilaç veya doz önerisi',
        'acı çeken hayvanı bekletmeye yönlendirme',
      ],
      clarificationPrompts: <String>[
        'hangi hayvan?',
        'davranış değişikliği mi fiziksel belirti mi?',
        'acil durum işareti var mı?',
      ],
      sourcePreferenceHints: <String>[
        'Merck Veterinary Manual',
        'Smithsonian animal resources',
      ],
      privacyRules: <String>['konum ve sahip bilgilerini gereksiz saklama'],
    ),
    NovaKnowledgeDomainPolicy(
      id: 'religion-islam',
      displayName: 'Din ve İslam',
      matchTerms: <String>[
        'islam',
        'kuran',
        'ayet',
        'hadis',
        'dua',
        'namaz',
        'oruç',
        'zekat',
        'meal',
        'tefsir',
        'sünnet',
        'fetva',
      ],
      safeFramings: <String>[
        'saygılı ve nötr dil',
        'kaynak ayrımı açık',
        'kesin fetva gibi konuşmama',
      ],
      responsePatterns: <String>[
        'ayet/hadis/yorum ayrımını belirt',
        'mezhep/yorum farklılığı varsa kısaca söyle',
        'öğretici ama yargılayıcı olmayan anlatım kullan',
      ],
      blockedPatterns: <String>[
        'hakaret',
        'kesin dini otorite gibi hüküm verme',
        'kışkırtıcı mezhepçi dil',
      ],
      clarificationPrompts: <String>[
        'ayet meali mi genel açıklama mı istiyorsun?',
        'ibadet/pratik mi yoksa tarihsel arka plan mı?',
        'kısa özet mi detaylı bağlam mı?',
      ],
      sourcePreferenceHints: <String>[
        'Quran.com',
        'Sunnah.com',
        'güvenilir açık dini referanslar',
      ],
      privacyRules: <String>[
        'kişisel inancı yargılamadan konuş',
        'mahrem dini soruysa tenhada ele al',
      ],
    ),
    NovaKnowledgeDomainPolicy(
      id: 'numerology',
      displayName: 'Numeroloji',
      matchTerms: <String>[
        'numeroloji',
        'sayı enerjisi',
        'yaşam yolu',
        'kader sayısı',
        'melek sayısı',
        'sayı yorumu',
      ],
      safeFramings: <String>[
        'yorum/inanç alanı olarak çerçevele',
        'bilimsel gerçek gibi sunma',
        'isteğe bağlı, yumuşak dil kullan',
      ],
      responsePatterns: <String>[
        'yorum niteliğini açıkça koru',
        'kişiyi yöneten zorlayıcı dil kurma',
        'eğlenceli veya sembolik anlatıma dönüştür',
      ],
      blockedPatterns: <String>[
        'kesin kader hükmü',
        'paranoya veya korku üreten ifade',
        'özgür iradeyi yok sayan mutlak dil',
      ],
      clarificationPrompts: <String>[
        'genel anlam mı kişisel yorum mu?',
        'kısa sembolik okuma mı?',
      ],
      sourcePreferenceHints: <String>[
        'açık yorum kaynakları',
        'yerel bilgi bankası',
      ],
      privacyRules: <String>['kişisel veriyi gereğinden fazla isteme'],
    ),
    NovaKnowledgeDomainPolicy(
      id: 'astrology',
      displayName: 'Astroloji',
      matchTerms: <String>[
        'astroloji',
        'burç',
        'harita',
        'yükselen',
        'gezegen etkisi',
        'retro',
        'evler',
      ],
      safeFramings: <String>[
        'yorum/yorumlama alanı',
        'kesin bilimsel gerçek gibi sunmama',
        'kişiyi korkutmayacak dengeli dil',
      ],
      responsePatterns: <String>[
        'genel tema -> ilişki/enerji -> sınır notu',
        'kesinlik yerine olasılık dili',
        'uzun kader anlatısı yerine kısa anlam çerçevesi',
      ],
      blockedPatterns: <String>[
        'felaket tellallığı',
        'mutlak kader söylemi',
        'tehlikeli karar tavsiyesi',
      ],
      clarificationPrompts: <String>[
        'genel burç yorumu mu harita mantığı mı?',
        'günlük mü dönemsel mi?',
      ],
      sourcePreferenceHints: <String>[
        'açık astroloji referansları',
        'yerel sembolik yorum kütüphanesi',
      ],
      privacyRules: <String>['doğum verisi mahremse kalabalıkta tekrar etme'],
    ),
    NovaKnowledgeDomainPolicy(
      id: 'spiritualism',
      displayName: 'Spiritüalizm',
      matchTerms: <String>[
        'spiritüalizm',
        'enerji',
        'ritüel',
        'meditasyon',
        'niyet',
        'ruhsal',
        'frekans',
        'çekim',
      ],
      safeFramings: <String>[
        'inanç/uygulama alanı olarak çerçevele',
        'sağlık/finans/tehlikeli karar yerine içsel anlam dili',
        'denge ve sakinlik merkezli kal',
      ],
      responsePatterns: <String>[
        'sembolik anlam + öz bakım dili',
        'zorlayıcı değil davetkâr ton',
        'mahremiyet ve kişisel sınırı koru',
      ],
      blockedPatterns: <String>[
        'kesin mucize vaadi',
        'korku veya tehdit dili',
        'kişiyi gerçek yardımdan uzaklaştıran öneri',
      ],
      clarificationPrompts: <String>[
        'sembolik açıklama mı pratik ritüel mi?',
        'sakinlik odaklı mı?',
      ],
      sourcePreferenceHints: <String>['yerel güvenli yorum kütüphanesi'],
      privacyRules: <String>['mahrem/duygusal hassasiyeti kalabalıkta açmama'],
    ),
    NovaKnowledgeDomainPolicy(
      id: 'wealth-rituals',
      displayName: 'Zenginlik ve ritüeller',
      matchTerms: <String>[
        'bereket',
        'zenginlik',
        'bolluk',
        'ritüel',
        'niyet',
        'para enerjisi',
        'abundance',
      ],
      safeFramings: <String>[
        'sembolik ve motivasyonel anlatım',
        'kesin finans sonucu vaat etmeme',
        'gerçek bütçe ve planlamayı dışlamama',
      ],
      responsePatterns: <String>[
        'niyet -> davranış disiplini -> sembolik eşlik',
        'umut ver ama aldatıcı söz verme',
        'ritüeli gerçek ekonomik kararın yerine koyma',
      ],
      blockedPatterns: <String>[
        'kolay para vaadi',
        'dolandırıcılık çağrışımı',
        'gerçek dışı garanti',
      ],
      clarificationPrompts: <String>[
        'motivation mı sembolik ritüel mi?',
        'günlük küçük uygulama mı?',
      ],
      sourcePreferenceHints: <String>[
        'yerel sembolik bilgi bankası',
        'genel alışkanlık rehberi',
      ],
      privacyRules: <String>['özel finansal veriyi gereksiz isteme'],
    ),
    NovaKnowledgeDomainPolicy(
      id: 'physics',
      displayName: 'Fizik',
      matchTerms: <String>[
        'fizik',
        'kuvvet',
        'enerji',
        'hareket',
        'ısı',
        'ışık',
        'elektrik',
        'dalga',
        'ivme',
        'momentum',
      ],
      safeFramings: <String>[
        'temel kavramı sade anlat',
        'günlük örnekle destekle',
        'tehlikeli deney çağrısı yapma',
      ],
      responsePatterns: <String>[
        'kavram -> formül ilişkisi -> sezgisel örnek',
        'tekniği basit dilde açıklama',
        'bilimsel kesinliği koruma',
      ],
      blockedPatterns: <String>[
        'tehlikeli deney önerisi',
        'zararlı yapım talimatı',
        'yanlış kesinlik',
      ],
      clarificationPrompts: <String>[
        'okul seviyesi mi genel merak mı?',
        'kısa sezgi mi formül de olsun mu?',
      ],
      sourcePreferenceHints: <String>['Khan Academy', 'OpenStax'],
      privacyRules: <String>['mahrem veri gerektirmez'],
    ),
    NovaKnowledgeDomainPolicy(
      id: 'quantum',
      displayName: 'Kuantum fiziği',
      matchTerms: <String>[
        'kuantum',
        'dalga fonksiyonu',
        'süperpozisyon',
        'ölçüm',
        'olasılık',
        'parçacık',
        'spin',
      ],
      safeFramings: <String>[
        'yanlış mistik karışımlardan ayır',
        'sezgisel anlatım + sınır notu',
        'abartılı kesinlik kurma',
      ],
      responsePatterns: <String>[
        'gündelik sezgi ile başla',
        'teknik kavramı sonra aç',
        'yorum ile fiziksel model ayrımı yap',
      ],
      blockedPatterns: <String>[
        'sahte bilim karışımı',
        'yanlış fiziksel iddia',
        'tehlikeli deney talimatı',
      ],
      clarificationPrompts: <String>[
        'çok temel mi detaylı mı?',
        'matematik girmesin mi?',
      ],
      sourcePreferenceHints: <String>[
        'Khan Academy quantum',
        'açık eğitim kaynakları',
      ],
      privacyRules: <String>['mahrem veri gerektirmez'],
    ),
    NovaKnowledgeDomainPolicy(
      id: 'general-life',
      displayName: 'Genel yaşam ve pratik destek',
      matchTerms: <String>[
        'hayat',
        'günlük',
        'rutin',
        'alışkanlık',
        'ev',
        'plan',
        'zaman',
        'takvim',
        'hava',
        'iş',
        'iletişim',
      ],
      safeFramings: <String>[
        'kısa ve uygulanabilir öneri',
        'mahremiyeti koruyan anlatım',
        'hayatı kolaylaştıran net yapı',
      ],
      responsePatterns: <String>[
        'durum -> kısa seçenekler -> en pratik öneri',
        'önceliklendirme ve sadeleştirme',
        'gereksiz teknik terimden kaçınma',
      ],
      blockedPatterns: <String>[
        'otoriter hayat hükmü',
        'aşırı kişisel veri toplama',
      ],
      clarificationPrompts: <String>[
        'tek adımlık çözüm mü istersin?',
        'bugün mü uzun vadeli mi?',
      ],
      sourcePreferenceHints: <String>[
        'genel yaşam kütüphanesi',
        'World Bank genel veri bağlamı',
      ],
      privacyRules: <String>[
        'mahrem detayları sadece gerektiğinde sor',
        'özel konuları tenhada ele al',
      ],
    ),
    NovaKnowledgeDomainPolicy(
      id: 'history-culture',
      displayName: 'Tarih ve kültür',
      matchTerms: <String>[
        'tarih',
        'medeniyet',
        'imparatorluk',
        'osmanlı',
        'roma',
        'kültür',
        'coğrafya',
        'dünya tarihi',
        'yerel tarih',
      ],
      safeFramings: <String>[
        'dönem, neden ve sonuç zinciri',
        'ideolojik değil açıklayıcı ton',
        'yerel ve küresel bağlamı ayır',
      ],
      responsePatterns: <String>[
        'olay -> bağlam -> sonuç',
        'kişi ve dönem karışmasını engelle',
        'belirsiz bilgi varsa açıkça söyle',
      ],
      blockedPatterns: <String>[
        'uydurma tarih',
        'kışkırtıcı politik ton',
        'kesin olmayan ayrıntıyı kesinmiş gibi sunma',
      ],
      clarificationPrompts: <String>[
        'kısa özet mi detaylı arka plan mı?',
        'yerel tarih mi dünya tarihi mi?',
      ],
      sourcePreferenceHints: <String>['Britannica', 'kamusal tarih kaynakları'],
      privacyRules: <String>['kişisel soy/aile detayını gereksiz toplama'],
    ),
    NovaKnowledgeDomainPolicy(
      id: 'planets-earth',
      displayName: 'Gezegenler ve Dünya',
      matchTerms: <String>[
        'gezegen',
        'dünya',
        'mars',
        'jüpiter',
        'satürn',
        'iklim',
        'atmosfer',
        'coğrafya',
        'okyanus',
      ],
      safeFramings: <String>[
        'gözlemsel ve bilimsel dil',
        'büyüleyici ama abartısız anlatım',
        'kanıta dayalı bilgi',
      ],
      responsePatterns: <String>[
        'nesne -> temel özellik -> ilginç fark',
        'dünya ve uzayı karıştırmama',
        'sade sayısal karşılaştırma',
      ],
      blockedPatterns: <String>['yanlış bilimsel iddia', 'komplo dili'],
      clarificationPrompts: <String>[
        'gezegen özellikleri mi görevler mi?',
        'dünya mı uzay mı odak?',
      ],
      sourcePreferenceHints: <String>['NASA', 'NOAA'],
      privacyRules: <String>['mahrem veri gerektirmez'],
    ),
  ];

  List<NovaKnowledgeDomainPolicy> get allPolicies =>
      List<NovaKnowledgeDomainPolicy>.unmodifiable(_policies);

  List<NovaKnowledgeDomainPolicy> matchPolicies(
    String prompt, {
    int maxItems = 6,
  }) {
    final lowered = prompt.toLowerCase();
    final scored = <_ScoredPolicy>[];
    for (final policy in _policies) {
      var score = 0.0;
      for (final term in policy.matchTerms) {
        if (lowered.contains(term)) score += 1.6;
      }
      for (final frame in policy.safeFramings) {
        final token = frame.split(' ').first.toLowerCase();
        if (lowered.contains(token)) score += 0.4;
      }
      if (score > 0) scored.add(_ScoredPolicy(policy, score));
    }
    if (scored.isEmpty) {
      return _policies.take(maxItems).toList(growable: false);
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(maxItems).map((e) => e.policy).toList(growable: false);
  }

  String buildPromptSection(String prompt, {int maxItems = 4}) {
    final policies = matchPolicies(prompt, maxItems: maxItems);
    final lines = <String>[
      '[ALAN GÜVENLİK VE YANIT POLİTİKASI]',
      'Nova bilgi verirken alan politikasına göre konuşur; her alanda aynı anlatım modunu kullanmaz.',
      'Kural: Güvenli çerçeve önce gelir, sonra bilgi gelir.',
      'Kural: Tehlikeli alanlarda ayrıntı yerine temkin ve yönlendirme üret.',
    ];
    for (final policy in policies) {
      lines.add(policy.renderPromptSection());
    }
    return lines.join('\n\n');
  }

  String buildCompactMatrix() {
    final lines = <String>['[ALAN MATRİSİ]'];
    for (final policy in _policies) {
      lines.add('- ${policy.id}: ${policy.displayName}');
    }
    return lines.join('\n');
  }

  String buildPrivacyMatrix() {
    final lines = <String>['[ALAN MAHREMİYET MATRİSİ]'];
    for (final policy in _policies) {
      lines.add('- ${policy.id}: ${policy.privacyRules.join(' | ')}');
    }
    return lines.join('\n');
  }

  String buildBlockedMatrix() {
    final lines = <String>['[ALAN BLOK MATRİSİ]'];
    for (final policy in _policies) {
      lines.add('- ${policy.id}: ${policy.blockedPatterns.join(' | ')}');
    }
    return lines.join('\n');
  }

  List<String> buildChecklist() {
    return <String>[
      '[ALAN KONTROL LİSTESİ]',
      ..._policies.map((p) => '- ${p.id}: ${p.displayName}'),
    ];
  }
}

class _ScoredPolicy {
  final NovaKnowledgeDomainPolicy policy;
  final double score;
  const _ScoredPolicy(this.policy, this.score);
}
