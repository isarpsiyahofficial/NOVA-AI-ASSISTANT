// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'nova_knowledge_deduplication_service.dart';
import 'nova_cross_language_knowledge_bridge_service.dart';
import 'nova_knowledge_domain_policy_service.dart';
import 'nova_json_corpus_runtime_service.dart';

class NovaDeepKnowledgeSnippet {
  final String domain;
  final String title;
  final List<String> lines;
  final List<String> sourceHints;

  const NovaDeepKnowledgeSnippet({
    required this.domain,
    required this.title,
    required this.lines,
    required this.sourceHints,
  });

  String render() {
    final out = <String>['[${domain.toUpperCase()}] $title'];
    out.addAll(lines.take(6).map((line) => '- $line'));
    if (sourceHints.isNotEmpty) {
      out.add('Kaynak ankrajları: ${sourceHints.take(3).join(' | ')}');
    }
    return out.join('\n');
  }
}

class NovaKnowledgeDomainProfile {
  final String id;
  final String displayName;
  final String? corpus;
  final List<String>? seedLines;
  final List<String> keywords;
  final List<String> highValueTerms;
  final List<String> safeBoundaries;
  final List<String> sourceAnchors;
  final String framing;

  const NovaKnowledgeDomainProfile({
    required this.id,
    required this.displayName,
    this.corpus,
    this.seedLines,
    required this.keywords,
    required this.highValueTerms,
    required this.safeBoundaries,
    required this.sourceAnchors,
    required this.framing,
  });
}

class NovaDeepKnowledgeCorpusService {
  const NovaDeepKnowledgeCorpusService();

  static const NovaKnowledgeDeduplicationService _dedupe =
      NovaKnowledgeDeduplicationService();
  static const NovaKnowledgeDomainPolicyService _policy =
      NovaKnowledgeDomainPolicyService();
  static const NovaCrossLanguageKnowledgeBridgeService _bridge =
      NovaCrossLanguageKnowledgeBridgeService();
  static const NovaJsonCorpusRuntimeService _jsonCorpus =
      NovaJsonCorpusRuntimeService();

  static final Map<String, List<String>> _cache = <String, List<String>>{};

  static const List<NovaKnowledgeDomainProfile>
  _profiles = <NovaKnowledgeDomainProfile>[
    NovaKnowledgeDomainProfile(
      id: 'cars',
      displayName: 'Arabalar ve araç türleri',
      keywords: <String>[
        'araba',
        'araç',
        'otomobil',
        'sedan',
        'hatchback',
        'suv',
        'pickup',
        'coupe',
        'cabrio',
        'minivan',
        'station wagon',
        'model',
      ],
      highValueTerms: <String>[
        'araç sınıfı',
        'gövde tipi',
        'kullanım amacı',
        'yol tipi',
        'yakıt türü',
        'çekiş düzeni',
      ],
      safeBoundaries: <String>[
        'kesin satın alma dayatması yapma',
        'tehlikeli sürüşe yönlendirme yok',
        'öneriyi kullanım amacına göre çerçevele',
      ],
      sourceAnchors: <String>['çevrimdışı araç türleri korpusu'],
      framing:
          'Araç türlerini kullanım amacı, gövde tipi ve sürüş karakteri üzerinden açıkla.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'automotive_mechanics',
      displayName: 'Araba mekaniği ve arıza mantığı',
      keywords: <String>[
        'motor',
        'şanzıman',
        'vites',
        'debriyaj',
        'enjeksiyon',
        'ateşleme',
        'akü',
        'alternatör',
        'marş',
        'soğutma',
        'hararet',
        'fren',
        'diferansiyel',
        'süspansiyon',
        'elektrik arızası',
        'araba sorunu',
        'gösterge ışığı',
      ],
      highValueTerms: <String>[
        'belirti ve semptom',
        'olası neden',
        'güvenli ilk kontrol',
        'şanzıman davranışı',
        'ateşleme sistemi',
        'yakıt sistemi',
        'soğutma devresi',
        'fren güvenliği',
      ],
      safeBoundaries: <String>[
        'kesin mekanik teşhis verme',
        'tehlikeli sürüşe yönlendirme yok',
        'önce güvenlik sonra kontrol sırası ver',
        'yangın veya fren riski varsa profesyonel yardım öner',
      ],
      sourceAnchors: <String>['çevrimdışı otomotiv mekanik korpusu'],
      framing:
          'Araç arızalarında önce belirtiyi ayrıştır, sonra olası nedenleri ve güvenli ilk kontrol sırasını ver.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'cooking',
      displayName: 'Yemek ve mutfak',
      keywords: <String>[
        'yemek',
        'tarif',
        'çorba',
        'fırın',
        'haşla',
        'kavur',
        'pilav',
        'ocak',
        'malzeme',
        'pişir',
        'marine',
        'sote',
        'ızgara',
      ],
      highValueTerms: <String>[
        'ölçü dengesi',
        'pişirme süresi',
        'ısı kontrolü',
        'saklama',
        'servis önerisi',
        'doku',
        'tat dengesi',
        'malzeme alternatifi',
      ],
      safeBoundaries: <String>[
        'gıda güvenliği uyarısı ekle',
        'çiğ et ve süt ürünlerinde temkinli dil kullan',
        'tıbbi diyet yerine genel mutfak rehberi sun',
      ],
      sourceAnchors: <String>['çevrimdışı yemek korpusu'],
      framing:
          'Yemek bilgisini malzeme, teknik, süre ve servis akışıyla ver; belirsizlik varsa önce doğal bir netleştirme sorusu sor.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'desserts',
      displayName: 'Tatlı ve hamur işleri',
      keywords: <String>[
        'tatlı',
        'şerbet',
        'hamur',
        'çikolata',
        'krema',
        'bisküvi',
        'kurabiye',
        'kek',
        'fırın',
        'sütlü',
        'meyveli',
        'pasta',
      ],
      highValueTerms: <String>[
        'hamur yapısı',
        'şeker dengesi',
        'pişme derecesi',
        'şerbet sıcaklığı',
        'krema kıvamı',
        'servis sıcaklığı',
        'sunum',
      ],
      safeBoundaries: <String>[
        'yanlış gıda güvenliği iddiası kurma',
        'allerjenlere dikkat hatırlat',
        'ölçü belirsizse açıkça belirt',
      ],
      sourceAnchors: <String>['çevrimdışı tatlı korpusu'],
      framing:
          'Tatlı bilgisini tür, kıvam, pişirme ve servis dengesi üzerinden ver; belirsizlik varsa önce tatlı türünü netleştir.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'languages',
      displayName: 'Diller ve çeviri',
      keywords: <String>[
        'dil',
        'çeviri',
        'ingilizce',
        'fransızca',
        'rusça',
        'arapça',
        'kalıp',
        'anlam',
        'gramer',
        'telaffuz',
        'sözlük',
      ],
      highValueTerms: <String>[
        'kullanım tonu',
        'resmiyet',
        'bağlam',
        'çok anlamlı kelime',
        'doğrudan çeviri riski',
        'ifade kalıbı',
      ],
      safeBoundaries: <String>[
        'anlam belirsizse alternatif ver',
        'kesin teknik çeviri yerine bağlam belirt',
        'tehlikeli içerik üretme',
      ],
      sourceAnchors: <String>['çevrimdışı dil rehberi korpusu'],
      framing: 'Çeviride bağlam, ton ve doğal kullanım önceliklidir.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'general',
      displayName: 'Genel yaşam ve kültür',
      keywords: <String>[
        'genel',
        'hayat',
        'zaman',
        'takvim',
        'hava',
        'günlük',
        'ilişki',
        'alışkanlık',
        'plan',
        'ev',
        'pratik',
        'yardım',
      ],
      highValueTerms: <String>[
        'günlük rutin',
        'zaman yönetimi',
        'iletişim',
        'yaşam bilgisi',
        'genel kültür',
        'karar desteği',
      ],
      safeBoundaries: <String>[
        'mahrem içeriği kalabalıkta konuşma',
        'kesin otoriter hüküm verme',
        'güvenlik sınırlarını aşma',
      ],
      sourceAnchors: <String>['çevrimdışı genel yaşam korpusu'],
      framing: 'Genel yaşam bilgisini kısa, nazik ve işlevsel tut.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'numerology',
      displayName: 'İleri seviye numeroloji',
      keywords: <String>[
        'numeroloji',
        'sayı',
        'yaşam yolu',
        'kader sayısı',
        'isim sayısı',
        'sayı yorumu',
        'titreşim',
      ],
      highValueTerms: <String>[
        'sayı sembolizmi',
        'yaşam yolu sayısı',
        'isim numerolojisi',
        'doğum tarihi yorumu',
      ],
      safeBoundaries: <String>[
        'yorumu inanç/yorum alanı olarak çerçevele',
        'bilimsel kesinlik gibi sunma',
        'kader dayatması yapma',
      ],
      sourceAnchors: <String>['çevrimdışı numeroloji korpusu'],
      framing:
          'Numeroloji başlığında yorum alanını açık tut, kesinlik dili kullanma.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'astrology',
      displayName: 'İleri seviye astroloji',
      keywords: <String>[
        'astroloji',
        'burç',
        'yükselen',
        'ev',
        'gezegen etkisi',
        'horoskop',
        'açı',
      ],
      highValueTerms: <String>[
        'doğum haritası',
        'yükselen yorumu',
        'ev sistemi',
        'gezegen geçişleri',
      ],
      safeBoundaries: <String>[
        'yorumu inanç/yorum alanı olarak çerçevele',
        'bilimsel iddia gibi sunma',
        'kesin kader yargısı verme',
      ],
      sourceAnchors: <String>['çevrimdışı astroloji korpusu'],
      framing: 'Astrolojiyi yorum, sembol ve gelenek düzeyinde aktar.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'people_understanding',
      displayName: 'İnsanları anlama rehberi',
      keywords: <String>[
        'insanları anlama',
        'empati',
        'iletişim',
        'dert dinleme',
        'tonlama',
        'vurgulama',
        'sohbet',
        'tanışma',
        'ilişki dili',
      ],
      highValueTerms: <String>[
        'aktif dinleme',
        'duygu yansıtma',
        'nazik tavsiye',
        'sosyal bağlam',
        'iletişim üslubu',
      ],
      safeBoundaries: <String>[
        'manipülasyon dili kurma',
        'mahremiyeti ihlal etme',
        'otoriter psikolojik hüküm verme',
      ],
      sourceAnchors: <String>['çevrimdışı insanları anlama korpusu'],
      framing: 'Önce anla, sonra yansıt, sonra nazik ve kısa destek sun.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'spiritualism',
      displayName: 'İleri seviye spiritüalizm',
      keywords: <String>[
        'spiritüalizm',
        'ruh',
        'meditasyon',
        'mistik',
        'maneviyat',
        'enerji',
        'ritüel',
        'içsel',
      ],
      highValueTerms: <String>[
        'manevi yorum',
        'içsel pratik',
        'mistik gelenek',
        'deneyim dili',
      ],
      safeBoundaries: <String>[
        'bilimsel gerçek ile yorum alanını ayır',
        'korku aşılayan dil kurma',
        'zorlayıcı otorite dili kullanma',
      ],
      sourceAnchors: <String>['çevrimdışı spiritüalizm korpusu'],
      framing: 'Manevi içerikte yumuşak, açıklayıcı ve yoruma açık dil kullan.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'rituals_wealth',
      displayName: 'Zenginlik ve ritüeller',
      keywords: <String>[
        'zenginlik',
        'bereket',
        'ritüel',
        'bolluk',
        'şans',
        'uğur',
        'niyet',
        'alışkanlık',
      ],
      highValueTerms: <String>[
        'bereket ritüeli',
        'uğur sembolü',
        'alışkanlık ve niyet',
        'yorumlayıcı pratik',
      ],
      safeBoundaries: <String>[
        'garanti vaat etme',
        'finansal kesinlik iddiası kurma',
        'kişiyi zararlı davranışa itme',
      ],
      sourceAnchors: <String>['çevrimdışı ritüel ve bereket korpusu'],
      framing:
          'Ritüel ve bereket başlıklarında kesin sonuç değil, yorum ve sembol dili kullan.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'faith_islam',
      displayName: 'Din ve İslam',
      keywords: <String>[
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
      ],
      highValueTerms: <String>[
        'ayet meali',
        'ibadet bağlamı',
        'tefsir farkı',
        'tarihsel bağlam',
      ],
      safeBoundaries: <String>[
        'saygılı ve nötr dil',
        'kesin fetva gibi konuşmama',
        'farklı yorumları kısaca belirtme',
      ],
      sourceAnchors: <String>['çevrimdışı İslam korpusu'],
      framing:
          'Dini içerikte saygılı, nötr ve kaynak ayrımı belirgin bir anlatım kullan.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'physics',
      displayName: 'Fizik',
      keywords: <String>[
        'fizik',
        'hareket',
        'kuvvet',
        'enerji',
        'ışık',
        'ısı',
        'dalga',
        'madde',
        'basınç',
        'elektrik',
      ],
      highValueTerms: <String>[
        'temel prensip',
        'ölçüm mantığı',
        'gözlem',
        'kuramsal çerçeve',
      ],
      safeBoundaries: <String>[
        'tehlikeli deney talimatı verme',
        'zararlı uygulamayı teşvik etme',
        'kesin laboratuvar rehberi gibi konuşma',
      ],
      sourceAnchors: <String>['çevrimdışı fizik korpusu'],
      framing:
          'Fizik bilgisini kavram, örnek ve açıklayıcı sezgi üzerinden kur.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'quantum',
      displayName: 'Kuantum fiziği',
      keywords: <String>[
        'kuantum',
        'atom',
        'elektron',
        'çekirdek',
        'radyasyon',
        'relativite',
        'foton',
        'dalga fonksiyonu',
      ],
      highValueTerms: <String>[
        'kuantum kuramı',
        'atom yapısı',
        'radyoaktivite',
        'relativite bağı',
      ],
      safeBoundaries: <String>[
        'tehlikeli nükleer talimat verme',
        'zararlı fiziksel uygulama önerme',
        'kuramı sihir gibi sunma',
      ],
      sourceAnchors: <String>['çevrimdışı kuantum korpusu'],
      framing:
          'Kuantum bilgisini kuramsal bağlam, tarih ve temel kavram ilişkileriyle anlat.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'translation_english',
      displayName: 'İngilizce rehberi',
      keywords: <String>[
        'ingilizce',
        'english',
        'çeviri',
        'gramer',
        'kalıp',
        'ifade',
        'kelime',
      ],
      highValueTerms: <String>[
        'doğal kullanım',
        'resmiyet',
        'bağlam',
        'örnek cümle',
      ],
      safeBoundaries: <String>[
        'tek doğru varmış gibi konuşma',
        'bağlamı yok sayma',
        'zararlı içerik üretme',
      ],
      sourceAnchors: <String>['çevrimdışı İngilizce rehberi'],
      framing:
          'İngilizce anlatımda bağlam, ton ve doğal kullanım önceliklidir.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'translation_french',
      displayName: 'Fransızca rehberi',
      keywords: <String>[
        'fransızca',
        'french',
        'çeviri',
        'gramer',
        'kalıp',
        'ifade',
        'kelime',
      ],
      highValueTerms: <String>[
        'doğal kullanım',
        'resmiyet',
        'bağlam',
        'örnek cümle',
      ],
      safeBoundaries: <String>[
        'tek doğru varmış gibi konuşma',
        'bağlamı yok sayma',
        'zararlı içerik üretme',
      ],
      sourceAnchors: <String>['çevrimdışı Fransızca rehberi'],
      framing:
          'Fransızca anlatımda bağlam, ton ve doğal kullanım önceliklidir.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'translation_russian',
      displayName: 'Rusça rehberi',
      keywords: <String>[
        'rusça',
        'russian',
        'çeviri',
        'gramer',
        'kalıp',
        'ifade',
        'kelime',
      ],
      highValueTerms: <String>[
        'doğal kullanım',
        'resmiyet',
        'bağlam',
        'örnek cümle',
      ],
      safeBoundaries: <String>[
        'tek doğru varmış gibi konuşma',
        'bağlamı yok sayma',
        'zararlı içerik üretme',
      ],
      sourceAnchors: <String>['çevrimdışı Rusça rehberi'],
      framing: 'Rusça anlatımda bağlam, ton ve doğal kullanım önceliklidir.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'translation_arabic',
      displayName: 'Arapça rehberi',
      keywords: <String>[
        'arapça',
        'arabic',
        'çeviri',
        'gramer',
        'kalıp',
        'ifade',
        'kelime',
      ],
      highValueTerms: <String>[
        'doğal kullanım',
        'resmiyet',
        'bağlam',
        'örnek cümle',
      ],
      safeBoundaries: <String>[
        'tek doğru varmış gibi konuşma',
        'bağlamı yok sayma',
        'zararlı içerik üretme',
      ],
      sourceAnchors: <String>['çevrimdışı Arapça rehberi'],
      framing: 'Arapça anlatımda bağlam, ton ve doğal kullanım önceliklidir.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'space_world',
      displayName: 'Gezegenler ve dünya',
      keywords: <String>[
        'gezegen',
        'dünya',
        'evren',
        'uzay',
        'astronomi',
        'jeoloji',
        'yıldız',
        'güneş sistemi',
        'yerküre',
      ],
      highValueTerms: <String>[
        'güneş sistemi',
        'dünya tarihi',
        'jeolojik süreç',
        'uzay gözlemi',
      ],
      safeBoundaries: <String>[
        'kesin felaket öngörüsü yapma',
        'sahte bilim gibi sunma',
        'tehlikeli deney yönlendirmesi yapma',
      ],
      sourceAnchors: <String>['çevrimdışı uzay ve dünya korpusu'],
      framing:
          'Uzay ve dünya bilgisini gözlem, ölçek ve tarih ilişkisiyle anlat.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'human_health',
      displayName: 'İnsan tıbbı ve sağlık',
      keywords: <String>[
        'insan tıbbı',
        'sağlık',
        'belirti',
        'semptom',
        'anatomi',
        'fizyoloji',
        'hastalık',
        'bakım',
        'hijyen',
      ],
      highValueTerms: <String>[
        'genel belirti bilgisi',
        'alarm işareti',
        'anatomi ve fizyoloji',
        'sağlık eğitimi',
      ],
      safeBoundaries: <String>[
        'kesin teşhis verme',
        'reçete/doz verme',
        'acil durumu hafife alma',
      ],
      sourceAnchors: <String>['çevrimdışı insan sağlığı korpusu'],
      framing:
          'Sağlık bilgisini genel eğitim, alarm işaretleri ve temkinli dil ile sun.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'animal_health',
      displayName: 'Hayvanlar ve veteriner',
      keywords: <String>[
        'hayvan',
        'veteriner',
        'kedi',
        'köpek',
        'sığır',
        'at',
        'bakım',
        'parazit',
        'hastalık',
        'aşı',
      ],
      highValueTerms: <String>[
        'hayvan bakımı',
        'alarm belirtisi',
        'parazit bilgisi',
        'veteriner gözlemi',
      ],
      safeBoundaries: <String>[
        'kesin veteriner teşhisi verme',
        'tehlikeli ilaç/doz önerme',
        'acı çeken hayvanı bekletmeye yönlendirme',
      ],
      sourceAnchors: <String>['çevrimdışı veteriner korpusu'],
      framing: 'Hayvan sağlığında tür, belirti ve aciliyet ayrımını açık tut.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'natural_medicine',
      displayName: 'Doğal tıp ve bitkisel rehber',
      keywords: <String>[
        'doğal tıp',
        'bitkisel',
        'şifalı bitki',
        'herbal',
        'kök',
        'çay',
        'tentür',
        'geleneksel kullanım',
      ],
      highValueTerms: <String>[
        'geleneksel kullanım',
        'bitki tanımı',
        'temkinli kullanım',
        'doğal hazırlama',
      ],
      safeBoundaries: <String>[
        'kanıta dayalı tıbbi tedavi yerine geçirme',
        'tehlikeli karışım önerme',
        'kesin tedavi vaat etme',
      ],
      sourceAnchors: <String>['çevrimdışı doğal tıp korpusu'],
      framing:
          'Doğal tıp içeriğini geleneksel bilgi ve dikkat notlarıyla çerçevele.',
    ),

    NovaKnowledgeDomainProfile(
      id: 'math_advanced',
      displayName: 'İleri matematik',
      keywords: <String>[
        'matematik',
        'integral',
        'türev',
        'limit',
        'cebir',
        'geometri',
        'trigonometri',
        'fonksiyon',
        'denklem',
        'teorem',
      ],
      highValueTerms: <String>[
        'hesap adımı',
        'çözüm sırası',
        'formül',
        'ispat',
        'örnek çözüm',
      ],
      safeBoundaries: <String>[
        'tehlikeli olmayan eğitimsel matematik anlatımı',
        'uydurma sonuç üretme',
        'hesabı kaynak çizgisinden koparma',
      ],
      sourceAnchors: <String>['çevrimdışı ileri matematik korpusu'],
      framing:
          'İleri matematikte kavramı, formülü, sonra çözüm sırasını açıkla.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'biology_advanced',
      displayName: 'İleri biyoloji',
      keywords: <String>[
        'biyoloji',
        'hücre',
        'anatomi',
        'fizyoloji',
        'evrim',
        'omurgalı',
        'organizmalar',
        'biyolojik',
      ],
      highValueTerms: <String>[
        'biyolojik yapı',
        'işlev',
        'sistem ilişkisi',
        'gözlemsel açıklama',
      ],
      safeBoundaries: <String>[
        'kesin klinik teşhis verme',
        'biyolojiyi tıbbi reçete gibi sunma',
        'zararlı deney yönlendirmesi yapma',
      ],
      sourceAnchors: <String>['çevrimdışı ileri biyoloji korpusu'],
      framing: 'Biyolojiyi yapı, işlev ve süreç ilişkisi içinde anlat.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'chemistry_advanced',
      displayName: 'İleri kimya',
      keywords: <String>[
        'kimya',
        'atom',
        'molekül',
        'bileşik',
        'element',
        'reaksiyon',
        'çözelti',
        'bağ',
      ],
      highValueTerms: <String>[
        'kimyasal yapı',
        'reaksiyon ilişkisi',
        'maddesel özellik',
        'ölçüm ve oran',
      ],
      safeBoundaries: <String>[
        'tehlikeli sentez talimatı verme',
        'zararlı laboratuvar yönlendirmesi yapma',
        'kesin uygulama güvenliği iddiası kurma',
      ],
      sourceAnchors: <String>['çevrimdışı ileri kimya korpusu'],
      framing: 'Kimyayı yapı, özellik ve reaksiyon mantığıyla açıkla.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'numerology_calculations',
      displayName: 'Numeroloji hesaplamaları',
      keywords: <String>[
        'numeroloji',
        'yaşam yolu',
        'isim sayısı',
        'doğum sayısı',
        'kader sayısı',
        'hesapla',
        'sayı yorumu',
      ],
      highValueTerms: <String>[
        'hesap adımı',
        'isim dönüşümü',
        'doğum tarihi indirgeme',
        'yorum anahtarı',
      ],
      safeBoundaries: <String>[
        'yorum alanını kesin bilim gibi sunma',
        'mutlak kader hükmü kurma',
        'zararlı yönlendirme yapma',
      ],
      sourceAnchors: <String>['çevrimdışı numeroloji hesap korpusu'],
      framing: 'Numerolojide önce hesap yolunu, sonra yorum çerçevesini ver.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'astrology_calculations',
      displayName: 'Astroloji hesaplamaları',
      keywords: <String>[
        'astroloji',
        'harita',
        'yükselen',
        'gezegen',
        'burç',
        'ev',
        'açı',
        'horoskop',
      ],
      highValueTerms: <String>[
        'harita kurma',
        'ev yerleşimi',
        'gezegen ilişkisi',
        'yorum adımı',
      ],
      safeBoundaries: <String>[
        'yorumu kesin kader gibi sunma',
        'bilimsel kesinlik iddiası kurma',
        'zararlı karar dayatma',
      ],
      sourceAnchors: <String>['çevrimdışı astroloji hesap korpusu'],
      framing:
          'Astrolojide hesap veya yerleşim adımını açıkla, sonra yorumu çerçevele.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'bioenergy',
      displayName: 'Biyoenerji',
      keywords: <String>[
        'biyoenerji',
        'enerji alanı',
        'manyetizma',
        'titreşim',
        'aura',
        'enerji çalışması',
      ],
      highValueTerms: <String>[
        'uygulama dili',
        'yorum sınırı',
        'enerji anlatımı',
        'geleneksel çerçeve',
      ],
      safeBoundaries: <String>[
        'tıbbi tedavi yerine geçirme',
        'kesin şifa vaadi kurma',
        'riskli yönlendirme yapma',
      ],
      sourceAnchors: <String>['çevrimdışı biyoenerji korpusu'],
      framing:
          'Biyoenerji anlatımında yorum alanını açık bırak ve temkinli kal.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'reiki',
      displayName: 'Reiki rehberi',
      keywords: <String>[
        'reiki',
        'enerji',
        'uygulama',
        'el pozisyonu',
        'şifa',
        'denge',
      ],
      highValueTerms: <String>[
        'uygulama akışı',
        'yorum sınırı',
        'enerji dili',
        'geleneksel anlatım',
      ],
      safeBoundaries: <String>[
        'kesin tedavi vaadi verme',
        'tıbbi bakım yerine koyma',
        'zararlı yönlendirme yapma',
      ],
      sourceAnchors: <String>['çevrimdışı reiki korpusu'],
      framing:
          'Reiki içeriğini geleneksel uygulama diliyle ve temkinli çerçevede ver.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'automotive_catalog',
      displayName: 'Araç marka model kataloğu',
      keywords: <String>[
        'marka',
        'model',
        'araç tipi',
        'otomotiv katalog',
        'sedan',
        'suv',
        'pickup',
        'hatchback',
        'otomobil',
      ],
      highValueTerms: <String>[
        'marka-model ayrımı',
        'gövde tipi',
        'sistem ailesi',
        'araç sınıfı',
      ],
      safeBoundaries: <String>[
        'kesin satın alma dayatması yapma',
        'güvensiz modifiye yönlendirmesi yapma',
        'yanlış teknik kesinlik kurma',
      ],
      sourceAnchors: <String>['çevrimdışı araç katalog korpusu'],
      framing:
          'Araç kataloğunu marka, model, sınıf ve temel sistem bağlamıyla özetle.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'automotive_troubleshooting',
      displayName: 'Araç arıza çözümleme',
      keywords: <String>[
        'arıza',
        'otomotiv sorun',
        'motor sorunu',
        'şanzıman sorunu',
        'çekiş düşmesi',
        'titreme',
        'gösterge ışığı',
        'diagnostic',
      ],
      highValueTerms: <String>[
        'belirti',
        'olası neden',
        'ilk güvenli kontrol',
        'sistem bazlı ayrım',
      ],
      safeBoundaries: <String>[
        'kesin tamir hükmü verme',
        'güvensiz sürüşe yönlendirme yok',
        'fren veya yangın riskini hafife alma',
      ],
      sourceAnchors: <String>['çevrimdışı araç arıza korpusu'],
      framing:
          'Araç arızasında önce belirtiyi ayır, sonra olası neden ve güvenli ilk kontrolü sırala.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'archaeology_advanced',
      displayName: 'İleri arkeoloji',
      keywords: <String>[
        'arkeoloji',
        'kazı',
        'eser',
        'buluntu',
        'yerleşim',
        'tarih öncesi',
        'arkeolojik',
      ],
      highValueTerms: <String>[
        'metodoloji',
        'saha kaydı',
        'eser bağlamı',
        'kültürel yorum',
      ],
      safeBoundaries: <String>[
        'kaçak kazıyı özendirme',
        'eser kaçakçılığına destek verme',
        'kesin tarih iddiasını abartma',
      ],
      sourceAnchors: <String>['çevrimdışı ileri arkeoloji korpusu'],
      framing: 'Arkeolojiyi yöntem, kayıt ve bağlam ilişkisiyle anlat.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'construction_engineering',
      displayName: 'İnşaat mühendisliği',
      keywords: <String>[
        'inşaat',
        'mühendislik',
        'temel',
        'taşıyıcı',
        'beton',
        'zemin',
        'hidrolik',
        'yapı',
      ],
      highValueTerms: <String>[
        'tasarım ilkesi',
        'zemin davranışı',
        'hidrolik ve drenaj',
        'yapısal parça',
      ],
      safeBoundaries: <String>[
        'sahada güvenlik riski doğuracak kesin talimat verme',
        'yetkisiz statik onay dili kullanma',
        'uydurma mühendislik hesabı üretme',
      ],
      sourceAnchors: <String>['çevrimdışı inşaat mühendisliği korpusu'],
      framing:
          'İnşaat mühendisliğini ilke, parça ve uygulama mantığıyla açıkla.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'pvc_aluminum',
      displayName: 'PVC ve alüminyum uygulamaları',
      keywords: <String>[
        'pvc',
        'alüminyum',
        'profil',
        'boru',
        'ek parça',
        'fitting',
        'çerçeve',
        'birleşim',
      ],
      highValueTerms: <String>[
        'ek parça',
        'hat düzeni',
        'profil mantığı',
        'montaj sırası',
      ],
      safeBoundaries: <String>[
        'tehlikeli saha yönlendirmesi yapma',
        'yanlış yapısal güvenlik iddiası kurma',
        'uydurma ölçü verme',
      ],
      sourceAnchors: <String>['çevrimdışı pvc ve alüminyum korpusu'],
      framing:
          'PVC ve alüminyum içeriğini parça, birleşim ve uygulama sırasıyla açıkla.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'agriculture_engineering',
      displayName: 'Tarım mühendisliği',
      keywords: <String>[
        'tarım',
        'sulama',
        'toprak',
        'drenaj',
        'çiftlik',
        'kanal',
        'su yönetimi',
        'tarımsal',
      ],
      highValueTerms: <String>[
        'sulama planı',
        'toprak-su ilişkisi',
        'drenaj',
        'tarla uygulaması',
      ],
      safeBoundaries: <String>[
        'yerel mühendislik ölçümü yokmuş gibi kesin hüküm verme',
        'zararlı uygulama yönlendirmesi yapma',
        'uydurma verim vaadi kurma',
      ],
      sourceAnchors: <String>['çevrimdışı tarım mühendisliği korpusu'],
      framing:
          'Tarım mühendisliğini su, toprak ve saha uygulaması üzerinden anlat.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'finance_advanced',
      displayName: 'İleri finans',
      keywords: <String>[
        'finans',
        'faiz',
        'kredi',
        'borsa',
        'sermaye',
        'yatırım',
        'piyasa',
        'bankacılık',
      ],
      highValueTerms: <String>[
        'nakit akışı',
        'piyasa yapısı',
        'risk',
        'yatırım aracı',
        'sermaye akışı',
      ],
      safeBoundaries: <String>[
        'kesin yatırım tavsiyesi verme',
        'getiri garantisi sunma',
        'yüksek riskli eyleme itme',
      ],
      sourceAnchors: <String>['çevrimdışı ileri finans korpusu'],
      framing: 'Finansı kavram, piyasa yapısı ve risk diliyle anlat.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'crypto_advanced',
      displayName: 'Kripto ve dijital varlık sistemleri',
      keywords: <String>[
        'kripto',
        'blockchain',
        'token',
        'dijital varlık',
        'akıllı sözleşme',
        'dağıtık defter',
        'nft',
      ],
      highValueTerms: <String>[
        'zincir yapısı',
        'token mantığı',
        'güvenlik riski',
        'akıllı sözleşme',
        'hukuki çerçeve',
      ],
      safeBoundaries: <String>[
        'yatırım garantisi verme',
        'yasadışı sakınma yolları öğretme',
        'güvensiz işlem teşviki yapma',
      ],
      sourceAnchors: <String>['çevrimdışı kripto korpusu'],
      framing:
          'Kripto içeriğini teknik yapı, güvenlik ve temkinli açıklama diliyle ver.',
    ),
    NovaKnowledgeDomainProfile(
      id: 'turkish_culture',
      displayName: 'Türk kültürü',
      keywords: <String>[
        'türk kültürü',
        'osmanlı',
        'istanbul',
        'anadolu',
        'gelenek',
        'örf',
        'kültür',
        'tarih',
      ],
      highValueTerms: <String>[
        'istanbul tarihi',
        'osmanlı bağlamı',
        'gündelik gelenek',
        'kültürel anlatı',
      ],
      safeBoundaries: <String>[
        'aşağılayıcı dil kullanma',
        'tek boyutlu genelleme yapma',
        'saygısız kültürel çerçeve kurma',
      ],
      sourceAnchors: <String>['çevrimdışı Türk kültürü korpusu'],
      framing:
          'Türk kültürünü tarih, günlük yaşam ve çok katmanlı bağlam içinde anlat.',
    ),
  ];

  List<NovaKnowledgeDomainProfile> get profiles =>
      List<NovaKnowledgeDomainProfile>.unmodifiable(_profiles);

  List<String> loadDomainLines(String domain) {
    final cached = _cache[domain];
    if (cached != null) {
      return cached;
    }
    final directLines = _jsonCorpus.loadDomainLines(domain);
    if (directLines.isNotEmpty) {
      _cache[domain] = directLines;
      return directLines;
    }
    final profile = _profiles.firstWhere(
      (item) => item.id == domain,
      orElse: () => _profiles.last,
    );
    final lines = _jsonCorpus.loadDomainLines(
      profile.id,
      fallbackSeedLines: profile.seedLines,
      fallbackCorpus: profile.corpus,
    );
    _cache[domain] = lines;
    return lines;
  }

  Map<String, List<String>> buildDomainLineMap(Iterable<String> domains) {
    final out = <String, List<String>>{};
    for (final domain in domains) {
      out[domain] = loadDomainLines(domain);
    }
    return out;
  }

  List<NovaDeepKnowledgeSnippet> lookup(
    String prompt, {
    int maxDomains = 3,
    int maxEntriesPerDomain = 3,
  }) {
    final selectedProfiles = _selectProfiles(prompt, maxDomains: maxDomains);
    final out = <NovaDeepKnowledgeSnippet>[];
    for (final profile in selectedProfiles) {
      final lines = loadDomainLines(profile.id);
      final crossMatches = _bridge.selectMatches(
        prompt: '$prompt ${profile.highValueTerms.join(' ')}',
        domain: profile.id,
        lines: lines,
        maxItems: maxEntriesPerDomain * 2,
      );
      final ranked = crossMatches.isEmpty
          ? _dedupe.rankForPrompt(
              prompt: '$prompt ${profile.highValueTerms.join(' ')}',
              domain: profile.id,
              lines: lines,
              maxItems: maxEntriesPerDomain * 2,
            )
          : const <NovaKnowledgeLineCandidate>[];
      final rankedLines = crossMatches.isNotEmpty
          ? crossMatches
                .take(maxEntriesPerDomain)
                .map((item) {
                  final hintText = item.turkishFocusHints.take(2).join(' | ');
                  final suffix = hintText.isEmpty
                      ? 'Kaynak dili: ${item.sourceLanguage}'
                      : 'Kaynak dili: ${item.sourceLanguage}; Türkçe odak: $hintText';
                  return '${item.line} [$suffix]';
                })
                .toList(growable: false)
          : ranked
                .take(maxEntriesPerDomain)
                .map((item) => item.text)
                .toList(growable: false);
      final sourceHints = profile.sourceAnchors;
      final policyHints = _policy.matchPolicies(
        profile.displayName,
        maxItems: 1,
      );
      final policySection = policyHints.isEmpty
          ? ''
          : policyHints.first.safeFramings.join(' | ');
      if (rankedLines.isEmpty) {
        out.add(
          NovaDeepKnowledgeSnippet(
            domain: profile.id,
            title: profile.displayName,
            lines: <String>[
              profile.framing,
              if (policySection.isNotEmpty) 'Alan politikası: $policySection',
              'Bu alanda tekrarsız çevrimdışı bilgi satırlarından güvenli özet üret.',
              'Sınırlar: ${profile.safeBoundaries.join(' | ')}',
            ],
            sourceHints: sourceHints,
          ),
        );
        continue;
      }
      out.add(
        NovaDeepKnowledgeSnippet(
          domain: profile.id,
          title: profile.displayName,
          lines: <String>[
            profile.framing,
            if (policySection.isNotEmpty) 'Alan politikası: $policySection',
            ...rankedLines,
            'Sınırlar: ${profile.safeBoundaries.join(' | ')}',
          ],
          sourceHints: sourceHints,
        ),
      );
    }
    return out;
  }

  List<String> selectDomains(String prompt, {int maxDomains = 3}) {
    return _selectProfiles(
      prompt,
      maxDomains: maxDomains,
    ).map((item) => item.id).toList(growable: false);
  }

  String buildPromptSection(
    String prompt, {
    int maxDomains = 3,
    int maxEntriesPerDomain = 3,
  }) {
    final snippets = lookup(
      prompt,
      maxDomains: maxDomains,
      maxEntriesPerDomain: maxEntriesPerDomain,
    );
    final lines = <String>[
      '[DERİN BİLGİ KORPUSU]',
      'Bu bölüm, tekrarsız çevrimdışı korpuslardan seçilmiş bilgi blokları sunar.',
      'Kural: aynı açıklamayı varyantlarla şişirme; kısa, farklı ve işlevli bilgi bloklarını kullan.',
      'Kural: riskli alanlarda kesin teşhis, tehlikeli teknik talimat veya yetkisiz ağ davranışı yok.',
    ];
    if (snippets.isEmpty) {
      lines.add(
        '- Uygun derin bilgi eşleşmesi bulunamadı; genel güvenli yanıt moduna dön.',
      );
    } else {
      for (final snippet in snippets) {
        lines.add(snippet.render());
      }
    }
    return lines.join('\n\n');
  }

  List<NovaKnowledgeDomainProfile> _selectProfiles(
    String prompt, {
    required int maxDomains,
  }) {
    final lowered = prompt.toLowerCase();
    final scored = <_ScoredProfile>[];
    for (final profile in _profiles) {
      double score = 0;
      for (final keyword in profile.keywords) {
        if (lowered.contains(keyword)) {
          score += 2.0;
        }
      }
      for (final keyword in profile.highValueTerms) {
        if (lowered.contains(keyword)) {
          score += 1.2;
        }
      }
      if (score > 0) {
        scored.add(_ScoredProfile(profile, score));
      }
    }
    if (scored.isEmpty) {
      const fallbackIds = <String>[
        'people_understanding',
        'general',
        'space_world',
        'human_health',
      ];
      final fallback = <NovaKnowledgeDomainProfile>[];
      for (final id in fallbackIds) {
        final match = _profiles.where((item) => item.id == id);
        if (match.isNotEmpty) {
          fallback.add(match.first);
        }
      }
      if (fallback.isNotEmpty) {
        return fallback.take(maxDomains).toList(growable: false);
      }
      return _profiles.take(maxDomains).toList(growable: false);
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored
        .take(maxDomains)
        .map((e) => e.profile)
        .toList(growable: false);
  }
}

class _ScoredProfile {
  final NovaKnowledgeDomainProfile profile;
  final double score;
  const _ScoredProfile(this.profile, this.score);
}
