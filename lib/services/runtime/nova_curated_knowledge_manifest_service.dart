// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1

class NovaKnowledgeSourceEntry {
  final String id;
  final String domain;
  final String title;
  final String authority;
  final String url;
  final String useCase;
  final List<String> topicTags;
  final List<String> safetyTags;
  final double authorityScore;
  final bool stableReference;

  const NovaKnowledgeSourceEntry({
    required this.id,
    required this.domain,
    required this.title,
    required this.authority,
    required this.url,
    required this.useCase,
    required this.topicTags,
    required this.safetyTags,
    required this.authorityScore,
    required this.stableReference,
  });

  String renderCompact() {
    final tags = topicTags.take(5).join(', ');
    final safety = safetyTags.take(4).join(', ');
    return '- [$domain] $title | kaynak: $authority | amaç: $useCase | etiket: $tags | güvenlik: $safety';
  }
}

class NovaCuratedKnowledgeManifestService {
  const NovaCuratedKnowledgeManifestService();

  static const List<NovaKnowledgeSourceEntry>
  _entries = <NovaKnowledgeSourceEntry>[
    NovaKnowledgeSourceEntry(
      id: 'android-speech-recognizer',
      domain: 'voice-runtime',
      title: 'Android Telecom + Embedded Streaming ASR Notes',
      authority: 'Android Developers',
      url: 'https://developer.android.com/develop/connectivity/telecom',
      useCase: 'sürekli dinleme kısıtları ve sesli akış mimarisi',
      topicTags: <String>[
        'speechrecognizer',
        'ses tanıma',
        'pil',
        'akış sınırı',
      ],
      safetyTags: <String>['official', 'api', 'stable'],
      authorityScore: 0.99,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'android-incallservice',
      domain: 'call-runtime',
      title: 'Android InCallService API Reference',
      authority: 'Android Developers',
      url:
          'https://developer.android.com/reference/android/telecom/InCallService',
      useCase: 'çağrı kontrolü, handoff, çağrı içi durum yönetimi',
      topicTags: <String>['call', 'incallservice', 'speaker', 'mute'],
      safetyTags: <String>['official', 'telecom', 'stable'],
      authorityScore: 0.99,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'android-mediasession',
      domain: 'media-control',
      title: 'Android MediaSession API Reference',
      authority: 'Android Developers',
      url:
          'https://developer.android.com/reference/android/media/session/MediaSession',
      useCase: 'spotify/youtube music medya kontrol akışı',
      topicTags: <String>['mediasession', 'transport', 'playback', 'media'],
      safetyTags: <String>['official', 'media', 'stable'],
      authorityScore: 0.99,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'android-transportcontrols',
      domain: 'media-control',
      title: 'MediaController.TransportControls Reference',
      authority: 'Android Developers',
      url:
          'https://developer.android.com/reference/android/media/session/MediaController.TransportControls',
      useCase: 'oynat/durdur/geç/geri medya komutları',
      topicTags: <String>['transportcontrols', 'play', 'pause', 'skip'],
      safetyTags: <String>['official', 'media', 'stable'],
      authorityScore: 0.99,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'android-overlay',
      domain: 'overlay-ui',
      title: 'WindowManager LayoutParams TYPE_APPLICATION_OVERLAY',
      authority: 'Android Developers',
      url:
          'https://developer.android.com/reference/android/view/WindowManager.LayoutParams#TYPE_APPLICATION_OVERLAY',
      useCase: 'dokunmayı engellemeyen overlay davranışı ve görünürlük',
      topicTags: <String>['overlay', 'window', 'ui', 'floating'],
      safetyTags: <String>['official', 'ui', 'stable'],
      authorityScore: 0.98,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'nasa-solar-system',
      domain: 'astronomy',
      title: 'Solar System Exploration',
      authority: 'NASA',
      url: 'https://solarsystem.nasa.gov/',
      useCase: 'gezegenler, görevler, gök cisimleri',
      topicTags: <String>['gezegenler', 'güneş sistemi', 'uzay', 'gökbilim'],
      safetyTags: <String>['official', 'science', 'stable'],
      authorityScore: 0.98,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'nasa-earth',
      domain: 'earth-science',
      title: 'NASA Earth Observatory',
      authority: 'NASA',
      url: 'https://earthobservatory.nasa.gov/',
      useCase: 'dünya, iklim, yüzey, doğal olaylar',
      topicTags: <String>['dünya', 'iklim', 'hava', 'yer bilimi'],
      safetyTags: <String>['official', 'science', 'stable'],
      authorityScore: 0.97,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'nih-medlineplus',
      domain: 'human-health',
      title: 'MedlinePlus',
      authority: 'U.S. National Library of Medicine',
      url: 'https://medlineplus.gov/',
      useCase: 'genel sağlık bilgisini güvenli ve anlaşılır şekilde özetleme',
      topicTags: <String>['sağlık', 'semptom', 'ilaç', 'hastalık'],
      safetyTags: <String>['official', 'patient-safe', 'medical'],
      authorityScore: 0.99,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'cdc-basics',
      domain: 'public-health',
      title: 'CDC Health Information',
      authority: 'CDC',
      url: 'https://www.cdc.gov/',
      useCase: 'halk sağlığı ve korunma bilgisini güvenli özetleme',
      topicTags: <String>['korunma', 'enfeksiyon', 'halk sağlığı', 'risk'],
      safetyTags: <String>['official', 'medical', 'public-health'],
      authorityScore: 0.98,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'merck-vet',
      domain: 'animal-health',
      title: 'Merck Veterinary Manual',
      authority: 'Merck Veterinary Manual',
      url: 'https://www.merckvetmanual.com/',
      useCase: 'hayvan sağlığı konularında güvenli genel referans',
      topicTags: <String>['hayvan', 'veteriner', 'belirti', 'bakım'],
      safetyTags: <String>['reference', 'medical', 'animal'],
      authorityScore: 0.91,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'usda-myplate',
      domain: 'nutrition',
      title: 'MyPlate',
      authority: 'USDA',
      url: 'https://www.myplate.gov/',
      useCase: 'beslenme, tarif planlama ve güvenli mutfak dengesi',
      topicTags: <String>['beslenme', 'gıda', 'öğün', 'sağlıklı yemek'],
      safetyTags: <String>['official', 'nutrition', 'stable'],
      authorityScore: 0.97,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'fda-food-safety',
      domain: 'food-safety',
      title: 'Food Safety',
      authority: 'FDA',
      url: 'https://www.fda.gov/food',
      useCase: 'gıda güvenliği ve saklama koşulları',
      topicTags: <String>['gıda güvenliği', 'saklama', 'pişirme', 'hijyen'],
      safetyTags: <String>['official', 'food', 'safety'],
      authorityScore: 0.97,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'nhtsa-vehicle-maintenance',
      domain: 'cars',
      title: 'Vehicle Safety & Maintenance',
      authority: 'NHTSA',
      url: 'https://www.nhtsa.gov/road-safety',
      useCase: 'araç güvenliği, bakım ve arıza semptomları',
      topicTags: <String>['araç', 'bakım', 'fren', 'lastik'],
      safetyTags: <String>['official', 'automotive', 'safety'],
      authorityScore: 0.97,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'epa-fuel-economy',
      domain: 'cars',
      title: 'Fuel Economy Basics',
      authority: 'EPA',
      url: 'https://www.fueleconomy.gov/',
      useCase: 'yakıt ekonomisi, araç sınıfları ve sürüş verimi',
      topicTags: <String>['yakıt', 'verim', 'sürüş', 'araç sınıfı'],
      safetyTags: <String>['official', 'automotive', 'stable'],
      authorityScore: 0.96,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'cambridge-grammar',
      domain: 'languages',
      title: 'English Grammar Today',
      authority: 'Cambridge Dictionary',
      url: 'https://dictionary.cambridge.org/grammar/british-grammar/',
      useCase: 'İngilizce kalıp, yapı ve kullanım rehberi',
      topicTags: <String>['english', 'grammar', 'kalıp', 'dilbilgisi'],
      safetyTags: <String>['reference', 'language', 'stable'],
      authorityScore: 0.89,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'kwiziq-french',
      domain: 'languages',
      title: 'French Grammar Library',
      authority: 'Kwiziq French',
      url: 'https://french.kwiziq.com/revision/grammar',
      useCase: 'Fransızca yapı ve kullanım desenleri',
      topicTags: <String>['français', 'grammar', 'kalıp', 'çeviri'],
      safetyTags: <String>['reference', 'language'],
      authorityScore: 0.82,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'russian-grammar',
      domain: 'languages',
      title: 'Open Russian Grammar',
      authority: 'OpenRussian',
      url: 'https://en.openrussian.org/',
      useCase: 'Rusça çekim ve örüntü hatırlatma',
      topicTags: <String>['russian', 'çekim', 'dilbilgisi', 'çeviri'],
      safetyTags: <String>['reference', 'language'],
      authorityScore: 0.80,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'arabic-resources',
      domain: 'languages',
      title: 'Arabic Collections Online / Arabic learning references',
      authority: 'NYU / open references',
      url: 'https://dlib.nyu.edu/aco/',
      useCase: 'Arapça söz varlığı ve kalıp farkındalığı',
      topicTags: <String>['arabic', 'kalıp', 'çeviri', 'sözlük'],
      safetyTags: <String>['reference', 'language'],
      authorityScore: 0.78,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'britannica-general',
      domain: 'general-reference',
      title: 'Encyclopaedia Britannica',
      authority: 'Britannica',
      url: 'https://www.britannica.com/',
      useCase: 'genel kültür ve tarih başlıklarında güvenilir özet ankrajı',
      topicTags: <String>['genel kültür', 'tarih', 'coğrafya', 'bilim'],
      safetyTags: <String>['reference', 'general'],
      authorityScore: 0.85,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'wikibooks-cookbook',
      domain: 'cooking',
      title: 'Wikibooks Cookbook',
      authority: 'Wikibooks',
      url: 'https://en.wikibooks.org/wiki/Cookbook',
      useCase: 'çok çeşitli tarif sınıfları ve mutfak teknikleri',
      topicTags: <String>['tarif', 'mutfak', 'teknik', 'malzeme'],
      safetyTags: <String>['open', 'cooking'],
      authorityScore: 0.75,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'king-arthur-baking',
      domain: 'desserts',
      title: 'Baking Guides',
      authority: 'King Arthur Baking',
      url: 'https://www.kingarthurbaking.com/learn',
      useCase: 'hamur, tatlı ve pişirme tekniği açıklamaları',
      topicTags: <String>['tatlı', 'hamur', 'fırın', 'dessert'],
      safetyTags: <String>['reference', 'food'],
      authorityScore: 0.86,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'khan-physics',
      domain: 'physics',
      title: 'Khan Academy Physics',
      authority: 'Khan Academy',
      url: 'https://www.khanacademy.org/science/physics',
      useCase: 'temel fizik kavramlarını güvenli ve öğretici özetleme',
      topicTags: <String>['fizik', 'kuvvet', 'enerji', 'hareket'],
      safetyTags: <String>['education', 'science', 'safe'],
      authorityScore: 0.87,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'khan-quantum',
      domain: 'quantum',
      title: 'Quantum Physics Intro',
      authority: 'Khan Academy',
      url: 'https://www.khanacademy.org/science/physics/quantum-physics',
      useCase: 'kuantum temel kavramlarını öğretici şekilde özetleme',
      topicTags: <String>['kuantum', 'dalga', 'parçacık', 'olasılık'],
      safetyTags: <String>['education', 'science', 'safe'],
      authorityScore: 0.85,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'metmuseum-religion',
      domain: 'religion-culture',
      title: 'Heilbrunn Timeline / Religious Art and Civilizations',
      authority: 'The Met',
      url: 'https://www.metmuseum.org/toah/',
      useCase: 'din ve kültür tarihine nötr, bağlamsal yaklaşım',
      topicTags: <String>['din', 'kültür', 'medeniyet', 'tarih'],
      safetyTags: <String>['reference', 'culture', 'neutral'],
      authorityScore: 0.83,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'quran-com',
      domain: 'religion-islam',
      title: 'Quran.com',
      authority: 'Quran.com',
      url: 'https://quran.com/',
      useCase: 'ayet ve mealler için doğrudan dini referans',
      topicTags: <String>['islam', 'kuran', 'ayet', 'meal'],
      safetyTags: <String>['religion', 'primary-source'],
      authorityScore: 0.90,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'sunnah-com',
      domain: 'religion-islam',
      title: 'Sunnah.com',
      authority: 'Sunnah.com',
      url: 'https://sunnah.com/',
      useCase: 'hadis başvurusu gerektiğinde kaynak etiketi üretme',
      topicTags: <String>['islam', 'hadis', 'sünnet'],
      safetyTags: <String>['religion', 'primary-source'],
      authorityScore: 0.84,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'worldbank-general',
      domain: 'general-life',
      title: 'World Bank Data',
      authority: 'World Bank',
      url: 'https://data.worldbank.org/',
      useCase: 'ülkeler, yaşam göstergeleri ve genel ekonomi arka planı',
      topicTags: <String>['ülke', 'ekonomi', 'yaşam', 'veri'],
      safetyTags: <String>['official', 'data'],
      authorityScore: 0.94,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'noaa-weather-basics',
      domain: 'weather-basics',
      title: 'NOAA Weather Education',
      authority: 'NOAA',
      url: 'https://www.noaa.gov/education',
      useCase: 'hava ve atmosfer temel açıklamaları',
      topicTags: <String>['hava', 'sıcaklık', 'atmosfer', 'iklim'],
      safetyTags: <String>['official', 'science'],
      authorityScore: 0.96,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'smithsonian-animals',
      domain: 'animals',
      title: 'Smithsonian National Zoo and Conservation Biology Institute',
      authority: 'Smithsonian',
      url: 'https://nationalzoo.si.edu/animals',
      useCase: 'hayvan davranışı, yaşam alanı ve tür bilgisi',
      topicTags: <String>['hayvan', 'tür', 'davranış', 'bakım'],
      safetyTags: <String>['reference', 'animals'],
      authorityScore: 0.90,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'openstax-biology',
      domain: 'biology',
      title: 'OpenStax Biology 2e',
      authority: 'OpenStax',
      url: 'https://openstax.org/details/books/biology-2e',
      useCase: 'biyoloji, insan vücudu ve temel yaşam bilimi',
      topicTags: <String>['biyoloji', 'hücre', 'insan', 'yaşam'],
      safetyTags: <String>['education', 'science'],
      authorityScore: 0.89,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'openstax-chemistry',
      domain: 'chemistry',
      title: 'OpenStax Chemistry 2e',
      authority: 'OpenStax',
      url: 'https://openstax.org/details/books/chemistry-2e',
      useCase: 'kimya ve madde temelleri',
      topicTags: <String>['kimya', 'atom', 'molekül', 'reaksiyon'],
      safetyTags: <String>['education', 'science'],
      authorityScore: 0.89,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'ifixit-general',
      domain: 'repair-general',
      title: 'iFixit Repair Guides',
      authority: 'iFixit',
      url: 'https://www.ifixit.com/Guide',
      useCase: 'güvenli, adım adım fiziksel tamir mantığına referans',
      topicTags: <String>['tamir', 'adım', 'araç', 'onarım'],
      safetyTags: <String>['repair', 'practical', 'caution'],
      authorityScore: 0.83,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'wiktionary-multilingual',
      domain: 'languages',
      title: 'Wiktionary',
      authority: 'Wiktionary',
      url: 'https://www.wiktionary.org/',
      useCase: 'çok dilli kök, telaffuz ve temel sözlük çapraz kontrolü',
      topicTags: <String>['sözlük', 'telaffuz', 'kelime', 'çok dil'],
      safetyTags: <String>['open', 'language'],
      authorityScore: 0.78,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'stanford-encyclopedia',
      domain: 'philosophy-general',
      title: 'Stanford Encyclopedia of Philosophy',
      authority: 'Stanford University',
      url: 'https://plato.stanford.edu/',
      useCase: 'felsefi kavramları ciddi ve nötr özetleme',
      topicTags: <String>['felsefe', 'etik', 'anlam', 'düşünce'],
      safetyTags: <String>['academic', 'reference'],
      authorityScore: 0.92,
      stableReference: true,
    ),

    NovaKnowledgeSourceEntry(
      id: 'brit-numerology-cultural',
      domain: 'numerology-cultural',
      title: 'Numerology (cultural overview)',
      authority: 'Encyclopaedia Britannica / cultural references',
      url: 'https://www.britannica.com/',
      useCase:
          'numerolojiyi kültürel ve tarihsel çerçevede, kesin gerçeklik iddiası olmadan açıklama',
      topicTags: <String>['numeroloji', 'sayı sembolizmi', 'kültür', 'yorum'],
      safetyTags: <String>['cultural', 'non-clinical', 'bounded'],
      authorityScore: 0.72,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'brit-astrology-cultural',
      domain: 'astrology-cultural',
      title: 'Astrology (cultural overview)',
      authority: 'Encyclopaedia Britannica / cultural references',
      url: 'https://www.britannica.com/',
      useCase:
          'astrolojiyi kültürel çerçevede, deterministik mutlaklık kurmadan açıklama',
      topicTags: <String>['astroloji', 'burç', 'kültür', 'tarih'],
      safetyTags: <String>['cultural', 'non-deterministic', 'bounded'],
      authorityScore: 0.72,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'iep-spirituality',
      domain: 'spirituality-cultural',
      title: 'Philosophy and spirituality references',
      authority: 'Internet Encyclopedia of Philosophy',
      url: 'https://iep.utm.edu/',
      useCase:
          'spiritualizm, anlam ve pratikleri felsefi/kültürel zeminde özetleme',
      topicTags: <String>['spiritüalizm', 'anlam', 'inanç', 'yorum'],
      safetyTags: <String>['academic', 'cultural', 'bounded'],
      authorityScore: 0.80,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'quran-com',
      domain: 'religion-islam',
      title: 'Quran.com',
      authority: 'Quran.com',
      url: 'https://quran.com/',
      useCase: 'ayet ve çeviri düzeyinde kontrollü dini başvuru',
      topicTags: <String>['islam', 'kuran', 'ayet', 'meal'],
      safetyTags: <String>['religion', 'reference', 'bounded'],
      authorityScore: 0.86,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'sunnah-com',
      domain: 'religion-islam',
      title: 'Sunnah.com',
      authority: 'Sunnah.com',
      url: 'https://sunnah.com/',
      useCase: 'hadis kaynak referansı; mezhep/fetva yerine kaynak gösterimi',
      topicTags: <String>['islam', 'hadis', 'sünnet', 'rivayet'],
      safetyTags: <String>['religion', 'reference', 'bounded'],
      authorityScore: 0.78,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'nasa-planets',
      domain: 'planets-world',
      title: 'NASA Planetary Science',
      authority: 'NASA',
      url: 'https://science.nasa.gov/planetary-science/',
      useCase: 'gezegenler ve dünya hakkında güvenilir bilimsel özetler',
      topicTags: <String>['gezegen', 'dünya', 'uzay', 'bilim'],
      safetyTags: <String>['official', 'science', 'stable'],
      authorityScore: 0.98,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'nist-physics',
      domain: 'physics',
      title: 'NIST Physics resources',
      authority: 'NIST',
      url: 'https://www.nist.gov/physics',
      useCase: 'fizik temel kavramlarını güvenilir terimlerle özetleme',
      topicTags: <String>['fizik', 'ölçüm', 'enerji', 'madde'],
      safetyTags: <String>['official', 'science', 'stable'],
      authorityScore: 0.94,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'cern-quantum',
      domain: 'quantum-physics',
      title: 'Quantum and particle physics references',
      authority: 'CERN',
      url: 'https://home.cern/science/physics',
      useCase:
          'kuantum ve parçacık fiziğini popülerleştirmeden kontrollü anlatım',
      topicTags: <String>['kuantum', 'parçacık', 'fizik', 'olasılık'],
      safetyTags: <String>['science', 'reference', 'bounded'],
      authorityScore: 0.93,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'people-understanding-guide',
      domain: 'human-understanding-guide',
      title: 'Conversation, listening and supportive communication references',
      authority: 'NHS / APA style public guidance mix',
      url: 'https://www.nhs.uk/every-mind-matters/',
      useCase:
          'dert dinleme, güvenli tavsiye, tanışma ve sohbete katılma için insani rehber',
      topicTags: <String>['dert dinleme', 'sohbet', 'ton', 'iletişim'],
      safetyTags: <String>['public-guidance', 'supportive', 'bounded'],
      authorityScore: 0.83,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'pg-automotive-compendium',
      domain: 'automotive_mechanics',
      title: 'Project Gutenberg Automotive Mechanics Compendium',
      authority: 'Project Gutenberg',
      url: 'https://www.gutenberg.org/',
      useCase:
          'çevrimdışı motor, şanzıman, akü, ateşleme ve arıza mantığı korpusu',
      topicTags: <String>['otomotiv', 'motor', 'şanzıman', 'ateşleme', 'arıza'],
      safetyTags: <String>['open', 'offline-corpus', 'mechanics'],
      authorityScore: 0.83,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'pg-cooking-compendium',
      domain: 'cooking',
      title: 'Project Gutenberg Cooking Compendium',
      authority: 'Project Gutenberg',
      url: 'https://www.gutenberg.org/',
      useCase: 'çevrimdışı yemek tarifleri ve mutfak teknikleri korpusu',
      topicTags: <String>['yemek', 'tarif', 'mutfak', 'pişirme'],
      safetyTags: <String>['open', 'offline-corpus', 'cooking'],
      authorityScore: 0.82,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'pg-dessert-compendium',
      domain: 'desserts',
      title: 'Project Gutenberg Dessert Compendium',
      authority: 'Project Gutenberg',
      url: 'https://www.gutenberg.org/',
      useCase: 'çevrimdışı tatlı, hamur işi ve kıvam korpusu',
      topicTags: <String>['tatlı', 'hamur', 'kıvam', 'şerbet'],
      safetyTags: <String>['open', 'offline-corpus', 'dessert'],
      authorityScore: 0.82,
      stableReference: true,
    ),
    NovaKnowledgeSourceEntry(
      id: 'pg-car-types-compendium',
      domain: 'cars',
      title: 'Project Gutenberg Car Types Compendium',
      authority: 'Project Gutenberg',
      url: 'https://www.gutenberg.org/',
      useCase:
          'araç türleri, modelleri ve kullanım amaçları için çevrimdışı korpus',
      topicTags: <String>['araba', 'model', 'araç türü', 'gövde tipi'],
      safetyTags: <String>['open', 'offline-corpus', 'automotive'],
      authorityScore: 0.81,
      stableReference: true,
    ),
  ];

  List<NovaKnowledgeSourceEntry> get allEntries =>
      List<NovaKnowledgeSourceEntry>.unmodifiable(_entries);

  List<NovaKnowledgeSourceEntry> findEntries(
    String prompt, {
    int maxEntries = 8,
  }) {
    final normalized = _normalize(prompt);
    if (normalized.isEmpty) {
      return _entries.take(maxEntries).toList(growable: false);
    }

    final scored = <_ScoredKnowledgeEntry>[];
    for (final entry in _entries) {
      double score = 0;
      for (final token in normalized) {
        if (entry.domain.contains(token)) score += 3.0;
        if (entry.title.toLowerCase().contains(token)) score += 2.5;
        if (entry.authority.toLowerCase().contains(token)) score += 1.2;
        if (entry.useCase.toLowerCase().contains(token)) score += 2.2;
        for (final tag in entry.topicTags) {
          if (tag.toLowerCase().contains(token)) {
            score += 2.0;
          }
        }
      }
      score += entry.authorityScore;
      if (entry.stableReference) score += 0.25;
      if (score > 0.9) {
        scored.add(_ScoredKnowledgeEntry(entry, score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(maxEntries).map((e) => e.entry).toList(growable: false);
  }

  String buildPromptSection(String prompt, {int maxEntries = 6}) {
    final entries = findEntries(prompt, maxEntries: maxEntries);
    final lines = <String>[
      '[WEB KAYNAKLI GÜVENLİ BİLGİ MANİFESTİ]',
      'Bu bölüm, tekrar üreten yerel sahte bilgi yerine güvenilir ve tekrarsız bilgi ankrajları kullanır.',
      'Kural: Kaynağı kopyalama; kaynaktan türetilmiş kısa, güvenli ve bağlama uygun bilgi üret.',
      'Kural: Sağlık, araç, hayvan sağlığı ve dini içerikte kesin hüküm değil; dikkatli, sınırlı ve açıklayıcı konuş.',
      'Kural: ChatGPT dışı serbest internet açma yok; sadece izinli ve önceden tanımlı kaynak mantığı var.',
    ];
    if (entries.isEmpty) {
      lines.add(
        '- Eşleşen manifest kaynağı bulunamadı; genel güvenli bilgi modu kullan.',
      );
    } else {
      lines.addAll(entries.map((e) => e.renderCompact()));
    }
    return lines.join('\n');
  }

  Map<String, List<NovaKnowledgeSourceEntry>> groupedByDomain() {
    final out = <String, List<NovaKnowledgeSourceEntry>>{};
    for (final entry in _entries) {
      out
          .putIfAbsent(entry.domain, () => <NovaKnowledgeSourceEntry>[])
          .add(entry);
    }
    return out;
  }

  List<String> buildDomainChecklist() {
    final groups = groupedByDomain();
    final lines = <String>['[KAYNAK ALANLARI]'];
    final sortedDomains = groups.keys.toList()..sort();
    for (final domain in sortedDomains) {
      final authorities = groups[domain]!
          .map((e) => e.authority)
          .toSet()
          .join(', ');
      lines.add('- $domain => $authorities');
    }
    return lines;
  }

  List<String> _normalize(String prompt) {
    final lowered = prompt.toLowerCase();
    final cleaned = lowered
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü\s]+', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) {
      return const <String>[];
    }
    return cleaned
        .split(' ')
        .where((part) => part.length > 1)
        .toList(growable: false);
  }
}

class _ScoredKnowledgeEntry {
  final NovaKnowledgeSourceEntry entry;
  final double score;
  const _ScoredKnowledgeEntry(this.entry, this.score);
}
