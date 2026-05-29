// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'nova_knowledge_deduplication_service.dart';

class NovaCrossLanguageLineMatch {
  final String domain;
  final String line;
  final double score;
  final String sourceLanguage;
  final List<String> matchedTerms;
  final List<String> turkishFocusHints;

  const NovaCrossLanguageLineMatch({
    required this.domain,
    required this.line,
    required this.score,
    required this.sourceLanguage,
    required this.matchedTerms,
    required this.turkishFocusHints,
  });

  String render() {
    final hints = turkishFocusHints.isEmpty
        ? ''
        : 'TR odak: ${turkishFocusHints.take(3).join(' | ')}';
    final terms = matchedTerms.isEmpty
        ? ''
        : 'Eşleşen terimler: ${matchedTerms.take(6).join(', ')}';
    return [
      '- kaynak dili: $sourceLanguage',
      if (terms.isNotEmpty) terms,
      if (hints.isNotEmpty) hints,
      '- satır: $line',
    ].join('\n');
  }
}

class NovaCrossLanguageDomainLexicon {
  final String domain;
  final String displayName;
  final List<String> turkishTerms;
  final List<String> englishTerms;
  final List<String> semanticHints;
  final List<String> turkishPhrases;

  const NovaCrossLanguageDomainLexicon({
    required this.domain,
    required this.displayName,
    required this.turkishTerms,
    required this.englishTerms,
    required this.semanticHints,
    required this.turkishPhrases,
  });
}

class NovaCrossLanguageKnowledgeBridgeService {
  const NovaCrossLanguageKnowledgeBridgeService();

  static const NovaKnowledgeDeduplicationService _dedupe =
      NovaKnowledgeDeduplicationService();
  static final Map<String, NovaCrossLanguageDomainLexicon>
  _domainLexicons = <String, NovaCrossLanguageDomainLexicon>{
    'cars': const NovaCrossLanguageDomainLexicon(
      domain: 'cars',
      displayName: "Arabalar ve ara\u00e7 t\u00fcrleri",
      turkishTerms: <String>[
        "araba",
        "araç",
        "otomobil",
        "sedan",
        "hatchback",
        "suv",
        "pickup",
        "coupe",
        "cabrio",
        "minivan",
        "station wagon",
        "elektrikli araç",
        "hibrit",
        "çekiş",
        "gövde tipi",
        "model",
        "şehir aracı",
        "aile aracı",
        "araç sınıfı",
        "yakıt türü",
        "yol tutuş",
        "bagaj",
        "iç hacim",
        "kompakt",
        "luxury",
        "sportif",
      ],
      englishTerms: <String>[
        "car",
        "automobile",
        "vehicle",
        "sedan",
        "hatchback",
        "suv",
        "pickup",
        "coupe",
        "convertible",
        "cabriolet",
        "minivan",
        "wagon",
        "estate",
        "hybrid",
        "electric vehicle",
        "body style",
        "drive train",
        "model year",
        "roadster",
        "utility vehicle",
        "family car",
        "compact car",
        "city car",
        "sports car",
      ],
      semanticHints: <String>[
        "gövde tipi",
        "kullanım amacı",
        "yakıt yaklaşımı",
        "çekiş düzeni",
        "konfor ve bagaj dengesi",
        "şehir ve uzun yol ayrımı",
      ],
      turkishPhrases: <String>[
        "Bunu Türkçe, gövde tipi ve kullanım amacı üzerinden anlat.",
        "İngilizce teknik adı geçse bile sonucu doğal Türkçe ver.",
        "Karşılaştırma varsa şehir içi, aile, yük ve arazi kullanımını ayır.",
      ],
    ),
    'automotive_mechanics': const NovaCrossLanguageDomainLexicon(
      domain: 'automotive_mechanics',
      displayName: "Araba mekani\u011fi ve ar\u0131zalar",
      turkishTerms: <String>[
        "motor",
        "şanzıman",
        "vites",
        "debriyaj",
        "fren",
        "soğutma",
        "hararet",
        "ateşleme",
        "yakıt sistemi",
        "akü",
        "alternatör",
        "marş",
        "süspansiyon",
        "direksiyon",
        "arıza lambası",
        "gösterge ışığı",
        "ses",
        "titreşim",
        "çekiş düşüşü",
        "rolanti",
        "duman",
        "yağ kaçağı",
        "triger",
        "enjeksiyon",
        "turbo",
      ],
      englishTerms: <String>[
        "engine",
        "transmission",
        "gearbox",
        "clutch",
        "brake",
        "cooling system",
        "overheating",
        "ignition",
        "fuel system",
        "battery",
        "alternator",
        "starter",
        "suspension",
        "steering",
        "warning light",
        "check engine",
        "misfire",
        "idle",
        "smoke",
        "oil leak",
        "timing belt",
        "injector",
        "turbocharger",
        "driveline",
        "differential",
      ],
      semanticHints: <String>[
        "belirtiye göre sistem ayır",
        "önce güvenlik sonra teşhis",
        "sürülebilir mi sürülmez mi ayrımı",
        "olası nedenleri önem sırasına koy",
      ],
      turkishPhrases: <String>[
        "İngilizce mekanik satırı okusan bile sonucu Türkçe semptom→olası neden→güvenli ilk kontrol sırasıyla anlat.",
        "Fren, yangın, yoğun duman veya hararet varsa önce kullanmayı durdur uyarısı ver.",
        "Kesin servis teşhisi vermeden ama düşünerek yönlendir.",
      ],
    ),
    'cooking': const NovaCrossLanguageDomainLexicon(
      domain: 'cooking',
      displayName: "Yemek ve mutfak",
      turkishTerms: <String>[
        "yemek",
        "tarif",
        "malzeme",
        "pişirme",
        "haşlama",
        "kavurma",
        "sote",
        "fırın",
        "tencere",
        "ocak",
        "çorba",
        "pilav",
        "et",
        "sebze",
        "marine",
        "sos",
        "servis",
        "kaç kişilik",
        "hızlı tarif",
        "sulu yemek",
        "ızgara",
        "baharat",
      ],
      englishTerms: <String>[
        "recipe",
        "ingredients",
        "cook",
        "boil",
        "simmer",
        "roast",
        "bake",
        "pan",
        "pot",
        "stir fry",
        "soup",
        "rice",
        "meat",
        "vegetable",
        "marinate",
        "sauce",
        "serve",
        "portion",
        "quick meal",
        "stew",
        "grill",
        "seasoning",
      ],
      semanticHints: <String>[
        "malzeme odaklı çözüm",
        "zaman ve ekipman uyumu",
        "kıvam ve ısı yönetimi",
        "alternatif malzeme önerisi",
      ],
      turkishPhrases: <String>[
        "Tarifi dümdüz okuma; kullanıcının malzemesine ve hız isteğine göre uyarlayarak Türkçe anlat.",
        "Belirsizlik varsa kısa netleştirme sorusu sor: hızlı mı, sulu mu, fırında mı?",
        "Mümkün olduğunda ölçü, süre ve sıra ver.",
      ],
    ),
    'desserts': const NovaCrossLanguageDomainLexicon(
      domain: 'desserts',
      displayName: "Tatl\u0131 ve hamur i\u015fleri",
      turkishTerms: <String>[
        "tatlı",
        "hamur",
        "kek",
        "kurabiye",
        "şerbetli",
        "sütlü",
        "pasta",
        "kremalı",
        "çikolatalı",
        "meyveli",
        "fırın",
        "kıvam",
        "şerbet",
        "servis",
        "tatlı türü",
        "malzeme",
      ],
      englishTerms: <String>[
        "dessert",
        "cake",
        "cookie",
        "pastry",
        "syrup",
        "custard",
        "cream",
        "chocolate",
        "fruit",
        "bake",
        "texture",
        "consistency",
        "frosting",
        "serve",
        "sweet dish",
      ],
      semanticHints: <String>[
        "tatlı türünü ayır",
        "kıvam ve pişme dengesi",
        "şerbet sıcaklığı veya krema yapısı",
        "eldeki malzemeye göre uyarlama",
      ],
      turkishPhrases: <String>[
        "Tatlı cevabını Türkçe ve uygulanabilir ver; sadece metni çevirmekle yetinme.",
        "Sütlü mü şerbetli mi çikolatalı mı diye gerekiyorsa sor.",
        "Kıvam hatalarını düzeltme notu ekle.",
      ],
    ),
    'people_understanding': const NovaCrossLanguageDomainLexicon(
      domain: 'people_understanding',
      displayName: "\u0130nsanlar\u0131 anlama rehberi",
      turkishTerms: <String>[
        "insanları anlama",
        "empati",
        "aktif dinleme",
        "dert dinleme",
        "tonlama",
        "vurgulama",
        "ilişki",
        "tanışma",
        "iletişim",
        "duygu yansıtma",
        "nazik soru",
        "sohbete dahil olma",
        "sosyal bağlam",
        "mahremiyet",
      ],
      englishTerms: <String>[
        "empathy",
        "active listening",
        "reflective listening",
        "rapport",
        "social cue",
        "tone",
        "framing",
        "conversation repair",
        "validation",
        "boundaries",
        "rapport building",
        "self disclosure",
        "conflict de escalation",
        "gentle question",
      ],
      semanticHints: <String>[
        "önce anla sonra cevapla",
        "duyguyu aynalama",
        "mahremiyeti koruma",
        "manipülasyon yok",
      ],
      turkishPhrases: <String>[
        "İnsanlık rehberini manipülasyon için değil, doğal ve güvenli sosyal uyum için yorumla.",
        "Cevap Türkçe, sıcak ve insan gibi olmalı; rehber satırını dümdüz okuma.",
        "Kalabalıkta mahrem yorum yapma.",
      ],
    ),
    'human_health': const NovaCrossLanguageDomainLexicon(
      domain: 'human_health',
      displayName: "\u0130nsan sa\u011fl\u0131\u011f\u0131",
      turkishTerms: <String>[
        "sağlık",
        "belirti",
        "semptom",
        "ağrı",
        "ateş",
        "nefes",
        "öksürük",
        "baş dönmesi",
        "uyarı işareti",
        "acil",
        "genel eğitim",
        "bakım",
        "hijyen",
        "vücut",
      ],
      englishTerms: <String>[
        "health",
        "symptom",
        "pain",
        "fever",
        "breathing",
        "cough",
        "dizziness",
        "warning sign",
        "urgent",
        "general education",
        "care",
        "hygiene",
        "body",
        "anatomy",
        "physiology",
      ],
      semanticHints: <String>[
        "eğitim amaçlı anlat",
        "alarm bulgusunu ayır",
        "teşhis yerine temkinli yönlendirme",
        "Türkçe net özet",
      ],
      turkishPhrases: <String>[
        "Sağlık bilgisini Türkçe, temkinli ve genel eğitim çerçevesinde anlat.",
        "İngilizce satırları aynen okuma; alarm işareti varsa onu öne çıkar.",
        "Kesin teşhis ve doz verme yok.",
      ],
    ),
    'animal_health': const NovaCrossLanguageDomainLexicon(
      domain: 'animal_health',
      displayName: "Hayvan sa\u011fl\u0131\u011f\u0131 ve veteriner",
      turkishTerms: <String>[
        "hayvan",
        "veteriner",
        "kedi",
        "köpek",
        "kuş",
        "at",
        "sığır",
        "iştahsızlık",
        "kusma",
        "ishal",
        "aşı",
        "parazit",
        "bakım",
        "acil belirti",
      ],
      englishTerms: <String>[
        "animal",
        "veterinary",
        "cat",
        "dog",
        "bird",
        "horse",
        "cattle",
        "loss of appetite",
        "vomiting",
        "diarrhea",
        "vaccination",
        "parasite",
        "care",
        "warning sign",
      ],
      semanticHints: <String>[
        "türe göre ayır",
        "acil veteriner gereksinimini öne çıkar",
        "evde güvenli ilk gözlem",
        "doz yok",
      ],
      turkishPhrases: <String>[
        "Veteriner bilgisini Türkçe ve türe göre yorumla.",
        "Evcil hayvan mı büyükbaş mı ayrımını kur.",
        "Kesin tedavi ve doz vermeden, alarm bulguyu vurgula.",
      ],
    ),
    'natural_medicine': const NovaCrossLanguageDomainLexicon(
      domain: 'natural_medicine',
      displayName: "Do\u011fal t\u0131p",
      turkishTerms: <String>[
        "doğal tıp",
        "bitkisel",
        "şifalı bitki",
        "çay",
        "tentür",
        "geleneksel kullanım",
        "doğal hazırlama",
        "bitki tanımı",
        "temkin",
      ],
      englishTerms: <String>[
        "herbal",
        "botanical",
        "infusion",
        "tincture",
        "traditional use",
        "plant preparation",
        "folk remedy",
        "herb profile",
        "precaution",
      ],
      semanticHints: <String>[
        "kanıta dayalı tıpla karıştırma",
        "geleneksel kullanım diye çerçevele",
        "risk ve etkileşim uyarısı",
      ],
      turkishPhrases: <String>[
        "Doğal tıp satırlarını Türkçe ve temkinli yorumla.",
        "Tedavi garantisi verme; geleneksel kullanım ve dikkat notu ver.",
        "İlaç yerine geçer gibi konuşma.",
      ],
    ),
    'faith_islam': const NovaCrossLanguageDomainLexicon(
      domain: 'faith_islam',
      displayName: "Din ve \u0130slam",
      turkishTerms: <String>[
        "islam",
        "kuran",
        "ayet",
        "meal",
        "tefsir",
        "hadis",
        "dua",
        "namaz",
        "oruç",
        "ibadet",
        "sünnet",
        "tefekkür",
        "ahlak",
      ],
      englishTerms: <String>[
        "islam",
        "quran",
        "verse",
        "tafsir",
        "hadith",
        "dua",
        "prayer",
        "fasting",
        "worship",
        "sunnah",
        "ethics",
      ],
      semanticHints: <String>[
        "saygılı nötr dil",
        "meal ve yorum ayrımı",
        "farklı görüşü kısaca belirt",
      ],
      turkishPhrases: <String>[
        "Dini içeriği Türkçe, saygılı ve kaynak ayrımını belirterek anlat.",
        "Metni ham bırakma; sorunun ne istediğini anlayıp özetle.",
        "Kesin fetva dili kurma.",
      ],
    ),
    'numerology': const NovaCrossLanguageDomainLexicon(
      domain: 'numerology',
      displayName: "Numeroloji",
      turkishTerms: <String>[
        "numeroloji",
        "yaşam yolu",
        "kader sayısı",
        "isim sayısı",
        "ruh arzusu",
        "kişilik sayısı",
        "doğum tarihi",
        "hesapla",
        "sayı yorumu",
      ],
      englishTerms: <String>[
        "numerology",
        "life path",
        "destiny number",
        "expression number",
        "soul urge",
        "personality number",
        "birth date",
        "calculate",
        "name number",
      ],
      semanticHints: <String>[
        "hesapla sonra yorumla",
        "yorumu inanç alanı diye çerçevele",
        "adım adım göster",
      ],
      turkishPhrases: <String>[
        "Numeroloji isteğinde yalnız alıntı yapma; gerekiyorsa sayıyı gerçekten hesapla ve Türkçe yorumla.",
        "Doğum tarihi veya isim eksikse bunu nazikçe iste.",
        "Yorumu kesin kader gibi değil, sembolik yorum olarak sun.",
      ],
    ),
    'astrology': const NovaCrossLanguageDomainLexicon(
      domain: 'astrology',
      displayName: "Astroloji",
      turkishTerms: <String>[
        "astroloji",
        "burç",
        "yükselen",
        "doğum haritası",
        "ev",
        "gezegen",
        "açı",
        "retro",
        "transit",
        "uyum",
        "harita yorumu",
      ],
      englishTerms: <String>[
        "astrology",
        "zodiac",
        "rising sign",
        "birth chart",
        "house",
        "planet",
        "aspect",
        "retrograde",
        "transit",
        "compatibility",
        "chart reading",
      ],
      semanticHints: <String>[
        "eksik doğum bilgisi varsa sor",
        "yorumu sembolik düzeyde tut",
        "ham metni Türkçe bağlama oturt",
      ],
      turkishPhrases: <String>[
        "Astrolojiyi Türkçe ve yorumlayıcı biçimde anlat; dümdüz kaynak okumaya düşme.",
        "Harita istenirse tarih, saat, yer bilgisi eksik mi bak.",
        "Kesinlik dili yerine sembolik eğilim dili kullan.",
      ],
    ),
    'spiritualism': const NovaCrossLanguageDomainLexicon(
      domain: 'spiritualism',
      displayName: "Spirit\u00fcalizm",
      turkishTerms: <String>[
        "spiritüalizm",
        "maneviyat",
        "enerji",
        "meditasyon",
        "mistik",
        "içsel çalışma",
        "ritüel",
        "farkındalık",
        "manevi yorum",
      ],
      englishTerms: <String>[
        "spiritualism",
        "spirituality",
        "energy work",
        "meditation",
        "mystic",
        "inner work",
        "ritual",
        "awareness",
        "spiritual reflection",
      ],
      semanticHints: <String>[
        "yumuşak dil",
        "yoruma açık çerçeve",
        "korku ve zorlama yok",
      ],
      turkishPhrases: <String>[
        "Spiritüel metni Türkçe, sakin ve yorumlayıcı anlat.",
        "Korkutucu veya otoriter tondan kaçın.",
        "Uygulama istenirse güvenli ve hafif öneriler ver.",
      ],
    ),
    'rituals_wealth': const NovaCrossLanguageDomainLexicon(
      domain: 'rituals_wealth',
      displayName: "Bereket ve rit\u00fceller",
      turkishTerms: <String>[
        "bereket",
        "bolluk",
        "ritüel",
        "zenginlik",
        "uğur",
        "niyet",
        "alışkanlık",
        "sembol",
        "yorum",
      ],
      englishTerms: <String>[
        "abundance",
        "prosperity",
        "ritual",
        "wealth",
        "luck",
        "intention",
        "habit",
        "symbol",
        "interpretation",
      ],
      semanticHints: <String>[
        "garanti verme",
        "yorum ve sembol olarak çerçevele",
        "günlük alışkanlık boyutunu ekle",
      ],
      turkishPhrases: <String>[
        "Bereket/ritüel bilgisini Türkçe, yorumlayıcı ve abartısız ver.",
        "Finansal garanti cümlesi kurma.",
        "İstenirse sembolik ritüeli günlük alışkanlık önerisiyle birlikte sun.",
      ],
    ),
    'physics': const NovaCrossLanguageDomainLexicon(
      domain: 'physics',
      displayName: "Fizik",
      turkishTerms: <String>[
        "fizik",
        "kuvvet",
        "enerji",
        "hareket",
        "iş",
        "güç",
        "ısı",
        "elektrik",
        "manyetizma",
        "dalga",
        "basınç",
        "optik",
      ],
      englishTerms: <String>[
        "physics",
        "force",
        "energy",
        "motion",
        "work",
        "power",
        "heat",
        "electricity",
        "magnetism",
        "wave",
        "pressure",
        "optics",
      ],
      semanticHints: <String>[
        "kavramı Türkçe açıkla",
        "gerekirse formülü sadeleştir",
        "uygulamalı örnek ver",
      ],
      turkishPhrases: <String>[
        "Fizik bilgisini Türkçe ve sezgisel örneklerle anlat.",
        "Ham İngilizce paragrafı okumak yerine kavramı çöz ve özetle.",
        "İstenirse kısa formül veya basit örnek ekle.",
      ],
    ),
    'quantum': const NovaCrossLanguageDomainLexicon(
      domain: 'quantum',
      displayName: "Kuantum",
      turkishTerms: <String>[
        "kuantum",
        "atom",
        "elektron",
        "foton",
        "dalga fonksiyonu",
        "belirsizlik",
        "ölçüm",
        "kuantum durumu",
        "spin",
        "enerji seviyesi",
      ],
      englishTerms: <String>[
        "quantum",
        "atom",
        "electron",
        "photon",
        "wave function",
        "uncertainty",
        "measurement",
        "quantum state",
        "spin",
        "energy level",
        "orbital",
      ],
      semanticHints: <String>[
        "kavramı sadeleştir",
        "mistikleştirme yok",
        "gerekirse tarihsel bağlam ekle",
      ],
      turkishPhrases: <String>[
        "Kuantum bilgisini Türkçe, anlaşılır ve mistikleştirmeden anlat.",
        "İngilizce kaynak satırı gelse de sonucu sade Türkçe özetle.",
        "Sorunun düzeyi basitse ağır teknik terim yükleme.",
      ],
    ),
    'translation_english': const NovaCrossLanguageDomainLexicon(
      domain: 'translation_english',
      displayName: "\u0130ngilizce rehberi",
      turkishTerms: <String>[
        "ingilizce",
        "çeviri",
        "cümle",
        "ifade",
        "doğal kullanım",
        "resmi",
        "gündelik",
        "tone",
        "anlam",
      ],
      englishTerms: <String>[
        "english",
        "translation",
        "sentence",
        "phrase",
        "natural usage",
        "formal",
        "casual",
        "tone",
        "meaning",
      ],
      semanticHints: <String>[
        "bağlamı sor",
        "tek çeviri yerine seçenek ver",
        "Türkçe açıklama ekle",
      ],
      turkishPhrases: <String>[
        "İngilizceyi Türkçe açıklayarak aktar.",
        "Bağlam belirsizse resmi mi günlük mü diye sor.",
        "Yalnız çeviri değil kullanım notu da ver.",
      ],
    ),
    'translation_french': const NovaCrossLanguageDomainLexicon(
      domain: 'translation_french',
      displayName: "Frans\u0131zca rehberi",
      turkishTerms: <String>[
        "fransızca",
        "çeviri",
        "cümle",
        "ifade",
        "doğal kullanım",
        "resmi",
        "gündelik",
        "anlam",
      ],
      englishTerms: <String>[
        "french",
        "translation",
        "sentence",
        "phrase",
        "natural usage",
        "formal",
        "casual",
        "meaning",
      ],
      semanticHints: <String>[
        "bağlamı sor",
        "seçenekli çeviri",
        "Türkçe açıklama",
      ],
      turkishPhrases: <String>[
        "Fransızca yanıtı Türkçe açıklamayla destekle.",
        "Bağlam gerekiyorsa kısa soru sor.",
        "Kalıbın hangi durumda kullanıldığını belirt.",
      ],
    ),
    'translation_russian': const NovaCrossLanguageDomainLexicon(
      domain: 'translation_russian',
      displayName: "Rus\u00e7a rehberi",
      turkishTerms: <String>[
        "rusça",
        "çeviri",
        "cümle",
        "ifade",
        "doğal kullanım",
        "resmi",
        "gündelik",
        "anlam",
      ],
      englishTerms: <String>[
        "russian",
        "translation",
        "sentence",
        "phrase",
        "natural usage",
        "formal",
        "casual",
        "meaning",
      ],
      semanticHints: <String>[
        "bağlamı sor",
        "seçenekli çeviri",
        "Türkçe açıklama",
      ],
      turkishPhrases: <String>[
        "Rusça isteğinde Türkçe açıklamayı öne koy.",
        "Bağlam eksikse tek çeviriye kilitlenme.",
        "Kullanım notu ekle.",
      ],
    ),
    'translation_arabic': const NovaCrossLanguageDomainLexicon(
      domain: 'translation_arabic',
      displayName: "Arap\u00e7a rehberi",
      turkishTerms: <String>[
        "arapça",
        "çeviri",
        "cümle",
        "ifade",
        "doğal kullanım",
        "resmi",
        "gündelik",
        "anlam",
      ],
      englishTerms: <String>[
        "arabic",
        "translation",
        "sentence",
        "phrase",
        "natural usage",
        "formal",
        "casual",
        "meaning",
      ],
      semanticHints: <String>[
        "bağlamı sor",
        "seçenekli çeviri",
        "Türkçe açıklama",
      ],
      turkishPhrases: <String>[
        "Arapça isteğinde Türkçe açıklama ve kullanım bağlamı ver.",
        "Gerekirse modern kullanım mı klasik kullanım mı ayır.",
        "Tek cümle çevirisi yerine açıklamalı yaklaş.",
      ],
    ),
    'space_world': const NovaCrossLanguageDomainLexicon(
      domain: 'space_world',
      displayName: "Gezegenler ve d\u00fcnya",
      turkishTerms: <String>[
        "gezegen",
        "dünya",
        "uzay",
        "güneş sistemi",
        "jeoloji",
        "iklim",
        "atmosfer",
        "okyanus",
        "yer kabuğu",
        "yıldız",
      ],
      englishTerms: <String>[
        "planet",
        "earth",
        "space",
        "solar system",
        "geology",
        "climate",
        "atmosphere",
        "ocean",
        "crust",
        "star",
      ],
      semanticHints: <String>[
        "ölçek ve karşılaştırma kullan",
        "Türkçe sezgisel anlatım",
        "sayıyı örnekle sadeleştir",
      ],
      turkishPhrases: <String>[
        "Uzay ve dünya bilgisini Türkçe, ölçek ve karşılaştırma ile anlat.",
        "İngilizce metni olduğu gibi okumak yerine örnekle yorumla.",
        "Konu çok genişse önce hangi kısmı istediğini sor.",
      ],
    ),
    'general': const NovaCrossLanguageDomainLexicon(
      domain: 'general',
      displayName: "Genel ya\u015fam",
      turkishTerms: <String>[
        "genel",
        "günlük",
        "yardım",
        "öneri",
        "pratik",
        "alışkanlık",
        "zaman",
        "plan",
      ],
      englishTerms: <String>[
        "general",
        "daily",
        "help",
        "suggestion",
        "practical",
        "habit",
        "time",
        "plan",
      ],
      semanticHints: <String>[
        "kısa net cevap",
        "gereksiz derin tarama yok",
        "Türkçe akış",
      ],
      turkishPhrases: <String>[
        "Genel yaşam bilgisinde kısa, doğal Türkçe anlatım kullan.",
        "Kaynağa ancak gerçekten gerekiyorsa git.",
        "Basit soruda basit cevap ver.",
      ],
    ),
  };

  static const Map<String, List<String>> _commonTranslationPairs =
      <String, List<String>>{
        "engine": <String>["motor", "engine", "makine"],
        "transmission": <String>[
          "şanzıman",
          "vites kutusu",
          "transmission",
          "gearbox",
        ],
        "brake": <String>["fren", "brake"],
        "battery": <String>["akü", "battery"],
        "radiator": <String>["radyatör", "radiator"],
        "recipe": <String>["tarif", "recipe"],
        "ingredients": <String>["malzeme", "ingredients"],
        "dessert": <String>["tatlı", "dessert"],
        "life path": <String>["yaşam yolu", "life path"],
        "destiny number": <String>["kader sayısı", "destiny number"],
        "rising sign": <String>["yükselen", "rising sign"],
        "birth chart": <String>["doğum haritası", "birth chart"],
        "verse": <String>["ayet", "verse"],
        "tafsir": <String>["tefsir", "tafsir"],
        "symptom": <String>["belirti", "symptom"],
        "warning sign": <String>["alarm bulgu", "warning sign"],
        "planet": <String>["gezegen", "planet"],
        "wave function": <String>["dalga fonksiyonu", "wave function"],
        "force": <String>["kuvvet", "force"],
      };

  static const List<String> _globalBridgeRules = <String>[
    "İngilizce veya başka dildeki korpus satırları bulunsa da nihai anlatımı doğal Türkçe kur.",
    "Kaynak satırını ham biçimde kopyalama; önce anlamı çöz, sonra Türkçe açıklamaya dönüştür.",
    "Kullanıcı teknik terimi bilmiyorsa önce sade Türkçe açıkla, sonra gerekirse orijinal terimi parantez içinde ver.",
    "Basit soru hafızadan çözülebiliyorsa doğrudan cevap ver; derin kaynak ancak gerektiğinde devreye girsin.",
    "Belirsiz isteklerde tek seferlik kısa netleştirme sorusu sor, sonra kaynak kullanımına geç.",
    "Kaynak yorumu istenen sonuca hizmet etmiyorsa gereksiz alıntı yapma.",
    "Sağlık, veteriner ve araç güvenliği gibi alanlarda önce risk ve aciliyet ayrımını yap.",
    "Numeroloji ve astroloji gibi yorum alanlarında sonucu kesin gerçek gibi sunma; yorum ve sembol dili kullan.",
    "Dini içerikte saygılı ve kaynak farkını belirten Türkçe kullan.",
    "Çeviri isteklerinde yalnız çeviri değil, bağlam ve kullanım notu da ver.",
    "Uzun İngilizce satırları birer paragraf olarak okumak yerine 2-4 kısa Türkçe maddeye dönüştür.",
    "Kullanıcı “hesapla” diyorsa yalnız açıklama verme; mümkünse adımı ve sonucu birlikte üret.",
  ];

  static const List<String> _turkishMarkers = <String>[
    'ş',
    'ğ',
    'ı',
    'İ',
    'ç',
    'ö',
    'ü',
  ];

  static const List<String> _englishCueWords = <String>[
    'the',
    'and',
    'with',
    'from',
    'for',
    'that',
    'this',
    'engine',
    'recipe',
    'planet',
    'energy',
    'number',
    'sign',
    'translation',
    'symptom',
  ];

  List<String> expandPromptTerms(String prompt, {String? domain}) {
    final normalized = _normalize(prompt);
    final tokens = normalized.split(' ').where((e) => e.isNotEmpty).toList();
    final expanded = <String>{...tokens};

    if (domain != null && _domainLexicons.containsKey(domain)) {
      final lexicon = _domainLexicons[domain]!;
      expanded.addAll(lexicon.turkishTerms.take(24));
      expanded.addAll(lexicon.englishTerms.take(24));
      expanded.addAll(lexicon.semanticHints);
    }

    for (final entry in _commonTranslationPairs.entries) {
      final key = entry.key;
      final values = entry.value;
      final lowerKey = key.toLowerCase();
      if (normalized.contains(lowerKey) || values.any(normalized.contains)) {
        expanded.add(lowerKey);
        expanded.addAll(values.map((item) => item.toLowerCase()));
      }
    }

    for (final token in List<String>.from(expanded)) {
      if (token.contains(' ')) {
        expanded.addAll(token.split(' ').where((e) => e.isNotEmpty));
      }
    }
    return expanded
        .where((item) => item.trim().length > 1)
        .toList(growable: false);
  }

  List<NovaCrossLanguageLineMatch> selectMatches({
    required String prompt,
    required String domain,
    required List<String> lines,
    int maxItems = 8,
  }) {
    final lexicon = _domainLexicons[domain];
    final terms = expandPromptTerms(prompt, domain: domain);
    final scored = <NovaCrossLanguageLineMatch>[];
    final seen = <String>{};

    for (final line in lines) {
      final cleaned = _dedupe.cleanLine(line);
      if (cleaned.isEmpty) continue;
      final signature = _dedupe.fingerprint(cleaned);
      if (!seen.add(signature)) continue;
      final scoreData = _scoreLine(
        prompt: prompt,
        domain: domain,
        line: cleaned,
        expandedTerms: terms,
        lexicon: lexicon,
      );
      if (scoreData.score <= 0) continue;
      scored.add(
        NovaCrossLanguageLineMatch(
          domain: domain,
          line: cleaned,
          score: scoreData.score,
          sourceLanguage: detectLikelyLanguage(cleaned),
          matchedTerms: scoreData.matchedTerms,
          turkishFocusHints: scoreData.turkishFocusHints,
        ),
      );
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final diversified = <NovaCrossLanguageLineMatch>[];
    final prefixSeen = <String>{};
    for (final item in scored) {
      final prefix = _prefix(item.line);
      if (prefixSeen.contains(prefix) && diversified.length > maxItems ~/ 2) {
        continue;
      }
      prefixSeen.add(prefix);
      diversified.add(item);
      if (diversified.length >= maxItems) break;
    }
    return diversified;
  }

  String buildPromptSection({
    required String prompt,
    required Map<String, List<String>> domainLines,
    int maxItemsPerDomain = 3,
  }) {
    final selectedDomains = inferRelevantDomains(prompt, maxDomains: 4);
    final lines = <String>[
      '[CROSS-LANGUAGE RETRIEVAL KÖPRÜSÜ]',
      'Amaç: İngilizce veya başka dildeki korpus satırlarını bulup Türkçe ve yorumlayıcı cevap üretmek.',
      ..._globalBridgeRules.map((item) => '- $item'),
    ];

    for (final domain in selectedDomains) {
      final corpus = domainLines[domain] ?? const <String>[];
      final lexicon = _domainLexicons[domain];
      if (lexicon == null || corpus.isEmpty) continue;
      final matches = selectMatches(
        prompt: prompt,
        domain: domain,
        lines: corpus,
        maxItems: maxItemsPerDomain,
      );
      lines.add('[ALAN] ${lexicon.displayName}');
      lines.addAll(lexicon.turkishPhrases.map((item) => '- $item'));
      if (matches.isEmpty) {
        lines.add(
          '- Uygun satır bulunamazsa Türkçe kavramsal açıklama ve netleştirme sorusu kullan.',
        );
      } else {
        for (final match in matches) {
          lines.add(match.render());
        }
      }
    }
    return lines.join('\n');
  }

  String buildGlobalGuide(String prompt) {
    final domains = inferRelevantDomains(prompt, maxDomains: 4);
    final lines = <String>[
      '[CROSS-LANGUAGE KULLANIM REHBERİ]',
      'Nova, İngilizce ağırlıklı korpuslardan bilgi seçse bile nihai cevabı doğal Türkçe kurar.',
      'Nova, kaynağı ham biçimde okumaz; anlar, ayıklar, uygular ve Türkçe anlatır.',
      'Nova, soru basitse doğrudan hafızadan cevap verir; derin kaynak sadece gerçekten gerektiğinde devreye girer.',
      'Nova, benzer sorularda önce hatırladığı çekirdek bilgiyi verir; arka planda daha iyi eşleşme aramaya devam edebilir.',
      'Aktif odak alanları: ${domains.join(' | ')}',
      ..._globalBridgeRules.map((item) => '- $item'),
    ];
    return lines.join('\n');
  }

  List<String> inferRelevantDomains(String prompt, {int maxDomains = 4}) {
    final normalized = _normalize(prompt);
    final scored = <MapEntry<String, double>>[];
    for (final entry in _domainLexicons.entries) {
      double score = 0;
      for (final term in entry.value.turkishTerms) {
        if (normalized.contains(term.toLowerCase())) {
          score += 2.0;
        }
      }
      for (final term in entry.value.englishTerms) {
        if (normalized.contains(term.toLowerCase())) {
          score += 1.3;
        }
      }
      for (final hint in entry.value.semanticHints) {
        if (normalized.contains(hint.toLowerCase())) {
          score += 1.6;
        }
      }
      if (score > 0) {
        scored.add(MapEntry<String, double>(entry.key, score));
      }
    }
    if (scored.isEmpty) {
      return const <String>[
        'people_understanding',
        'general',
        'translation_english',
        'cooking',
      ];
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(maxDomains).map((e) => e.key).toList(growable: false);
  }

  String detectLikelyLanguage(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return 'unknown';
    final lower = normalized.toLowerCase();
    final hasTurkishMarkers = _turkishMarkers.any(normalized.contains);
    if (hasTurkishMarkers) return 'tr';
    int englishHits = 0;
    for (final cue in _englishCueWords) {
      if (lower.contains(' $cue ') ||
          lower.startsWith('$cue ') ||
          lower.endsWith(' $cue')) {
        englishHits += 1;
      }
    }
    final wordCount = lower
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .length;
    if (englishHits >= 2 || (englishHits >= 1 && wordCount > 6)) {
      return 'en';
    }
    return 'mixed';
  }

  _CrossScoreData _scoreLine({
    required String prompt,
    required String domain,
    required String line,
    required List<String> expandedTerms,
    required NovaCrossLanguageDomainLexicon? lexicon,
  }) {
    final lowered = line.toLowerCase();
    double score = 0;
    final matchedTerms = <String>[];
    final turkishFocusHints = <String>[];

    for (final term in expandedTerms) {
      final loweredTerm = term.toLowerCase();
      if (loweredTerm.length < 2) continue;
      if (lowered.contains(loweredTerm)) {
        score += loweredTerm.contains(' ') ? 2.6 : 1.25;
        if (!matchedTerms.contains(loweredTerm)) {
          matchedTerms.add(loweredTerm);
        }
      }
    }

    if (lexicon != null) {
      for (final hint in lexicon.semanticHints) {
        if (!turkishFocusHints.contains(hint)) {
          turkishFocusHints.add(hint);
        }
      }
      for (final phrase in lexicon.turkishPhrases.take(3)) {
        if (!turkishFocusHints.contains(phrase)) {
          turkishFocusHints.add(phrase);
        }
      }
      for (final term in lexicon.englishTerms) {
        if (lowered.contains(term.toLowerCase())) {
          score += 0.9;
        }
      }
      for (final term in lexicon.turkishTerms) {
        if (lowered.contains(term.toLowerCase())) {
          score += 0.9;
        }
      }
    }

    final language = detectLikelyLanguage(line);
    if (language == 'en') {
      score += 0.75;
      turkishFocusHints.add('İngilizce satırı Türkçe özetle ve yorumla.');
    } else if (language == 'mixed') {
      score += 0.45;
      turkishFocusHints.add('Karışık dil satırını Türkçe ana fikre indir.');
    } else if (language == 'tr') {
      score += 0.35;
    }

    if (_looksExplanatory(line)) {
      score += 0.8;
      turkishFocusHints.add('Tanım yerine açıklama odaklı anlatım üret.');
    }
    if (_looksProcedural(line)) {
      score += 0.9;
      turkishFocusHints.add('Gerekirse bu satırdan adım çıkar.');
    }
    if (_looksComparative(line)) {
      score += 0.6;
      turkishFocusHints.add('Karşılaştırma varsa farkları Türkçe ayır.');
    }
    if (_looksRiskAware(line)) {
      score += 0.6;
      turkishFocusHints.add('Güvenlik veya dikkat notunu koru.');
    }
    if (line.length > 160) {
      score += 0.5;
    }
    if (line.length > 260) {
      score += 0.35;
    }

    return _CrossScoreData(
      score: score,
      matchedTerms: matchedTerms,
      turkishFocusHints: turkishFocusHints.take(8).toList(growable: false),
    );
  }

  bool _looksExplanatory(String line) {
    final lower = line.toLowerCase();
    const cues = <String>[
      'is the',
      'refers to',
      'means',
      'defined as',
      'consists of',
      'gives rise to',
      'is called',
      'can be understood',
      'is used for',
      'açıklanır',
      'tanımlanır',
      'anlamına gelir',
    ];
    return cues.any(lower.contains);
  }

  bool _looksProcedural(String line) {
    final lower = line.toLowerCase();
    const cues = <String>[
      'first',
      'then',
      'next',
      'finally',
      'step',
      'calculate',
      'mix',
      'heat',
      'cook',
      'check',
      'inspect',
      'measure',
      'reduce',
      'sum',
      'önce',
      'sonra',
      'ardından',
      'hesapla',
      'karıştır',
      'kontrol et',
    ];
    return cues.any(lower.contains);
  }

  bool _looksComparative(String line) {
    final lower = line.toLowerCase();
    const cues = <String>[
      'unlike',
      'compared with',
      'whereas',
      'on the other hand',
      'different from',
      'in contrast',
      'karşılaştır',
      'farklıdır',
      'buna karşılık',
    ];
    return cues.any(lower.contains);
  }

  bool _looksRiskAware(String line) {
    final lower = line.toLowerCase();
    const cues = <String>[
      'warning',
      'danger',
      'caution',
      'unsafe',
      'risk',
      'toxic',
      'urgent',
      'dikkat',
      'uyarı',
      'risk',
      'tehlike',
      'acil',
      'kaçın',
    ];
    return cues.any(lower.contains);
  }

  String _prefix(String line) {
    return _normalize(
      line,
    ).split(' ').where((e) => e.isNotEmpty).take(7).join(' ');
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü\s]+', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _CrossScoreData {
  final double score;
  final List<String> matchedTerms;
  final List<String> turkishFocusHints;

  const _CrossScoreData({
    required this.score,
    required this.matchedTerms,
    required this.turkishFocusHints,
  });
}
