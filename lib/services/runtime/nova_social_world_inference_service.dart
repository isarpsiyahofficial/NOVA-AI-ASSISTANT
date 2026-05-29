// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaSocialWorldInference {
  final String privacyLevel;
  final String relationHeat;
  final String likelyMentalState;
  final String safeNextAction;
  final List<String> cues;

  const NovaSocialWorldInference({
    required this.privacyLevel,
    required this.relationHeat,
    required this.likelyMentalState,
    required this.safeNextAction,
    required this.cues,
  });

  String buildPromptSection() => [
    'SOSYAL DÜNYA ÇIKARIMI:',
    '- mahremiyet: $privacyLevel',
    '- ilişki ısısı: $relationHeat',
    '- muhtemel zihinsel durum: $likelyMentalState',
    '- güvenli sonraki adım: $safeNextAction',
    if (cues.isNotEmpty) '- ipuçları: ${cues.join(' | ')}',
    'KURAL: birinin bir şey sakladığını düşünsen bile bunu kalabalıkta açma; gerekiyorsa owner ile daha sonra ve tenhada paylaş.',
  ].join('\n');
}

class NovaSocialWorldInferenceService {
  const NovaSocialWorldInferenceService();

  static const List<String> _fragileCues = <String>[
    'çekinerek',
    'tereddüt',
    'boğuk ses',
    'kırılmış',
    'kırgın',
    'ağlamaklı',
    'utanarak',
    'mahcup',
    'gergin',
    'titrek',
  ];
  static const List<String> _urgentCues = <String>[
    'acil',
    'hemen',
    'uyandır',
    'bekleme',
    'şimdi',
    'ivedi',
    'gecikmeden',
  ];
  static const List<String> _familyCues = <String>[
    'anne',
    'babam',
    'abim',
    'eşim',
    'canım annem',
    'aile',
    'kardeşim',
    'eş',
  ];
  static const List<String> _privateCues = <String>[
    'özel',
    'kimse duymasın',
    'arada kalsın',
    'tenhada',
    'yalnızken',
    'gizli',
  ];
  static const List<String> _deceptiveCues = <String>[
    'tam değil',
    'saklıyor',
    'kaçamak',
    'geçiştirdi',
    'bir şey var',
    'üstü kapalı',
  ];
  static const List<String> _warmCues = <String>[
    'canım',
    'tatlım',
    'özledim',
    'iyi ki',
    'sevindim',
    'sağ ol',
    'teşekkür ederim',
  ];
  static const List<String> _coldCues = <String>[
    'kısa kes',
    'uzatma',
    'boşver',
    'istemiyorum',
    'sonra',
    'karışma',
    'sus',
  ];

  NovaSocialWorldInference analyze({
    required String text,
    String relationshipLabel = '',
    bool crowdedRoom = false,
  }) {
    final normalized = text.trim().toLowerCase();
    final relation = relationshipLabel.trim().toLowerCase();
    final cues = <String>[];

    final fragile = _containsAny(normalized, _fragileCues);
    final urgent = _containsAny(normalized, _urgentCues);
    final family =
        _containsAny(normalized, _familyCues) ||
        _containsAny(relation, _familyCues);
    final private = crowdedRoom || _containsAny(normalized, _privateCues);
    final deceptive = _containsAny(normalized, _deceptiveCues);
    final warm = _containsAny(normalized, _warmCues);
    final cold = _containsAny(normalized, _coldCues);

    if (fragile) cues.add('kırılganlık');
    if (urgent) cues.add('aciliyet');
    if (family) cues.add('aile bağı');
    if (private) cues.add('mahremiyet');
    if (deceptive) cues.add('örtük gerilim');
    if (warm) cues.add('sıcak ilişki');
    if (cold) cues.add('mesafe isteği');

    final privacyLevel = private
        ? 'yüksek'
        : (family ? 'orta-yüksek' : 'normal');
    final relationHeat = family
        ? (warm ? 'çok sıcak' : 'sıcak')
        : (cold ? 'mesafeli' : (warm ? 'yakınlaşmaya açık' : 'nötr'));
    final likelyMentalState = urgent
        ? 'zaman baskısı ve yüksek odak'
        : fragile
        ? 'duygusal kırılganlık veya destek ihtiyacı'
        : deceptive
        ? 'tam açmadığı bir gerilim olabilir'
        : warm
        ? 'iş birliğine açık'
        : cold
        ? 'sınır isteyen ve kısa akış isteyen mod'
        : 'nötr';
    final safeNextAction = private
        ? 'detayı tenhaya ertele, burada yalnız çekirdek cümleyi kullan'
        : urgent
        ? 'ana sonucu öne al, ayrıntıyı sonra ver'
        : fragile
        ? 'çözümden önce alan aç ve tonu yumuşat'
        : cold
        ? 'fazla üzerine gitmeden kısa ve saygılı kal'
        : 'ölçülü doğal eşlik';

    return NovaSocialWorldInference(
      privacyLevel: privacyLevel,
      relationHeat: relationHeat,
      likelyMentalState: likelyMentalState,
      safeNextAction: safeNextAction,
      cues: cues,
    );
  }

  String buildPromptSection({
    required String text,
    String relationshipLabel = '',
    bool crowdedRoom = false,
  }) {
    return analyze(
      text: text,
      relationshipLabel: relationshipLabel,
      crowdedRoom: crowdedRoom,
    ).buildPromptSection();
  }

  Map<String, dynamic> buildDebugMap({
    required String text,
    String relationshipLabel = '',
    bool crowdedRoom = false,
  }) {
    final inference = analyze(
      text: text,
      relationshipLabel: relationshipLabel,
      crowdedRoom: crowdedRoom,
    );
    return <String, dynamic>{
      'privacyLevel': inference.privacyLevel,
      'relationHeat': inference.relationHeat,
      'likelyMentalState': inference.likelyMentalState,
      'safeNextAction': inference.safeNextAction,
      'cues': inference.cues,
    };
  }

  bool _containsAny(String text, List<String> cues) {
    for (final cue in cues) {
      final normalized = cue.trim().toLowerCase();
      if (normalized.isEmpty) continue;
      if (text.contains(normalized)) return true;
    }
    return false;
  }
}
