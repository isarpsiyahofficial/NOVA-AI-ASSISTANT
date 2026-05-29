// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaMindLoopService {
  const NovaMindLoopService();

  static const List<String> _inviteCues = <String>[
    'nova',
    'nova',
    'bakar mısın',
    'bakar misin',
    'sence',
    'sen ne dersin',
    'yardım et',
    'yardim et',
    'bizimle kal',
    'sohbete katıl',
    'sohbete katil',
    'buraya gel',
    'yanımıza gel',
    'yanimiza gel',
    'devral',
    'devret',
    'bana eşlik et',
    'bana eslik et',
    'buna dahil ol',
    'arada sen de konuş',
    'arada sen de konus',
    'sen cevap ver',
    'bir şey söyle',
    'bir sey soyle',
    'burada mısın',
    'burada misin',
    'bizi dinle',
    'şuna yorum yap',
    'suna yorum yap',
    'fikrini söyle',
    'fikrini soyle',
  ];
  static const List<String> _privacyCues = <String>[
    'mahrem',
    'özel',
    'ozel',
    'tenhada',
    'bunu sonra söyle',
    'bunu sonra soyle',
    'kimse duymasın',
    'kimse duymasin',
    'özelde konuş',
    'ozelde konus',
    'yalnız kalınca söyle',
    'yalniz kalinca soyle',
    'tek başımıza konuşalım',
    'tek basimiza konusalim',
    'sonra hatırlat',
    'sonra hatirlat',
    'şimdi söyleme',
    'simdi soyleme',
    'gizli kalsın',
    'gizli kalsin',
    'daha uygun zamanda söyle',
    'daha uygun zamanda soyle',
  ];
  static const List<String> _urgencyCues = <String>[
    'acil',
    'çok acil',
    'cok acil',
    'hemen',
    'şimdi',
    'simdi',
    'bekleme',
    'çok önemli',
    'cok onemli',
    'uyandır',
    'uyandir',
    'hemen bak',
    'derhal',
    'şimdi gel',
    'simdi gel',
    'şu an',
    'su an',
    'vakit yok',
    'kritik',
    'öncelikli',
    'oncelikli',
    'beni hemen uyandır',
    'beni hemen uyandir',
    'önce buna bak',
    'once buna bak',
  ];
  static const List<String> _fatigueCues = <String>[
    'yoruldum',
    'bitkinim',
    'kafam dolu',
    'uzun anlatma',
    'uzun uzun anlatma',
    'kısa söyle',
    'kisa soyle',
    'özet geç',
    'ozet gec',
    'sakin konuş',
    'sakin konus',
    'yavaş anlat',
    'yavas anlat',
    'bunu kısalt',
    'bunu kisalt',
    'tek cümleyle söyle',
    'tek cumleyle soyle',
    'şu an enerjim yok',
    'su an enerjim yok',
    'yavaş ol',
    'yavas ol',
  ];
  static const List<String> _repairCues = <String>[
    'yanlış',
    'yanlis',
    'öyle demedim',
    'oyle demedim',
    'dur bir dakika',
    'hayır öyle değil',
    'hayir oyle degil',
    'tekrar',
    'beni yanlış anladın',
    'beni yanlis anladin',
    'dur düzeltelim',
    'dur duzeltelim',
    'baştan al',
    'bastan al',
    'yanlış kişiyi aldın',
    'yanlis kisiyi aldin',
    'orayı düzelt',
    'orayi duzelt',
    'şunu kastetmiştim',
    'sunu kastetmistim',
    'daha farklı söyle',
    'daha farkli soyle',
  ];
  static const List<String> _storyCues = <String>[
    'geçen sefer',
    'gecen sefer',
    'önceden',
    'onceden',
    'hatırlarsan',
    'hatirlarsan',
    'o gün',
    'o gun',
    'daha önce',
    'daha once',
    'demin konuştuğumuz',
    'demin konustugumuz',
    'az önce olan',
    'az once olan',
    'geçmişte',
    'gecmiste',
    'ilk tanıştığımızda',
    'ilk tanistigimizda',
    'en son bunu konuşmuştuk',
    'en son bunu konusmustuk',
    'geçmişte bana demiştin',
    'gecmiste bana demistin',
  ];
  static const List<String> _callCues = <String>[
    'çağrı',
    'cagri',
    'telefon',
    'arama',
    'hoparlör',
    'hoparlor',
    'mikrofon',
    'sessize al',
    'devral',
    'devret',
    'karşı taraf',
    'karsi taraf',
    'benim yerime konuş',
    'benim yerime konus',
    'çağrıya katıl',
    'cagriya katil',
    'çağrıyı yönet',
    'cagriyi yonet',
    'not bırak',
    'not birak',
    'uyandır',
    'uyandir',
    'karşıya aktar',
    'karsiya aktar',
  ];
  static const List<String> _mediaCues = <String>[
    'spotify',
    'youtube music',
    'müzik',
    'muzik',
    'şarkı',
    'sarki',
    'oynat',
    'durdur',
    'atla',
    'önceki',
    'onceki',
    'ses aç',
    'ses ac',
    'ses kıs',
    'ses kis',
    'medyayı yönet',
    'medyayi yonet',
    'hangi uygulamada',
    'çal',
    'cal',
    'liste aç',
    'liste ac',
  ];

  String buildPromptSection({
    required String prompt,
    required String speakerName,
    required String relationshipLabel,
    required double ownerConfidence,
    required String socialMode,
    required bool proactiveAllowed,
    required bool roomPresenceOpportunity,
    required bool shouldClarify,
  }) {
    final n = prompt.trim().toLowerCase();
    final state = analyze(
      prompt: n,
      speakerName: speakerName,
      relationshipLabel: relationshipLabel,
      ownerConfidence: ownerConfidence,
      socialMode: socialMode,
      proactiveAllowed: proactiveAllowed,
      roomPresenceOpportunity: roomPresenceOpportunity,
      shouldClarify: shouldClarify,
    );
    final out = <String>[
      'TEK ZİHİN DÖNGÜSÜ:',
      '- sıra: dinle → konuşanı tanı → bağlamı çöz → duyguyu tart → niyeti ayır → şimdi konuşmalı mı karar ver → nasıl konuşacağını seç → hafızaya neyin yazılacağını filtrele → neyi öğrenmeyeceğini belirle.',
      '- mevcut prompt: ${prompt.trim().isEmpty ? 'boş' : prompt.trim()}',
      '- konuşan: ${speakerName.trim().isEmpty ? 'bilinmiyor' : speakerName.trim()}',
      '- ilişki: ${relationshipLabel.trim().isEmpty ? 'belirsiz' : relationshipLabel.trim()}',
      '- owner güveni: ${ownerConfidence.toStringAsFixed(2)}',
      '- sosyal mod: $socialMode',
      '- proaktif izin: ${proactiveAllowed ? 'açık' : 'kapalı'}',
      '- oda fırsatı: ${roomPresenceOpportunity ? 'var' : 'yok'}',
      '- netleştirme baskısı: ${shouldClarify ? 'yüksek' : 'normal'}',
      '- konuşma daveti: ${state.conversationalInvite ? 'var' : 'zayıf'}',
      '- mahremiyet: ${state.privateFollowUp ? 'daha sonra / tenhada' : 'normal'}',
      '- mikro katkı: ${state.microPresenceAllowed ? 'izinli' : 'kısıtlı'}',
      '- ilişki yaklaşımı: ${state.relationshipApproach}',
      '- ritim: ${state.rhythmPlan}',
      '- hafıza yazımı: ${state.memoryCommitPlan}',
      '- merak modu: ${state.curiosityPlan}',
      '- dikkat bayrakları: ${state.flags.join(' | ')}',
      'KURAL: Setup, dashboard, çağrı, normal konuşma ve arka plan akışlarında aynı karakter ve aynı karar mantığı korunmalı.',
      'KURAL: Bir moddan diğerine geçince kişilik sıfırlanmış gibi davranma; aynı kişi ve aynı konu sürekliliğini koru.',
      'KURAL: Düşünme sessizce yapılır; kullanıcıya sadece sonucu, gerekli onarımı ve doğal akışı göster.',
      'KURAL: Owner yetkisi, ilişki etiketi ve konuşma bağlamı birlikte okunmadan sosyal cesaret artırılmasın.',
      'KURAL: Her turda “konuşmalı mıyım, kısa mı kalmalıyım, soru sormalı mıyım, hafıza kullanmalı mıyım?” diye iç kontrol yap.',
    ];
    return out.join('\n');
  }

  NovaMindLoopState analyze({
    required String prompt,
    required String speakerName,
    required String relationshipLabel,
    required double ownerConfidence,
    required String socialMode,
    required bool proactiveAllowed,
    required bool roomPresenceOpportunity,
    required bool shouldClarify,
  }) {
    final hasSpeaker = speakerName.trim().isNotEmpty;
    final hasRelationship = relationshipLabel.trim().isNotEmpty;
    final invite =
        _containsAny(prompt, _inviteCues) ||
        socialMode.toLowerCase().contains('presence');
    final privacy = _containsAny(prompt, _privacyCues);
    final urgency = _containsAny(prompt, _urgencyCues);
    final fatigue = _containsAny(prompt, _fatigueCues);
    final repair = _containsAny(prompt, _repairCues) || shouldClarify;
    final story = _containsAny(prompt, _storyCues);
    final call =
        _containsAny(prompt, _callCues) ||
        socialMode.toLowerCase().contains('call');
    final media =
        _containsAny(prompt, _mediaCues) ||
        socialMode.toLowerCase().contains('media');
    final flags = <String>[];
    if (invite) flags.add('davet var');
    if (privacy) flags.add('mahremiyet hassas');
    if (urgency) flags.add('aciliyet yüksek');
    if (fatigue) flags.add('kısa rota gerekli');
    if (repair) flags.add('onarım / netleştirme gerekiyor');
    if (story) flags.add('ortak geçmiş tetiklendi');
    if (call) flags.add('çağrı akışı');
    if (media) flags.add('medya akışı');
    if (!hasSpeaker) flags.add('konuşan belirsiz');
    if (!hasRelationship) flags.add('ilişki etiketi zayıf');

    final relationshipApproach = _relationshipApproach(
      relationshipLabel: relationshipLabel,
      ownerConfidence: ownerConfidence,
      urgent: urgency,
      privacy: privacy,
      call: call,
    );
    final rhythmPlan = _rhythmPlan(
      fatigue: fatigue,
      urgency: urgency,
      repair: repair,
      call: call,
      media: media,
    );
    final memoryCommitPlan = _memoryCommitPlan(
      story: story,
      privacy: privacy,
      repair: repair,
      urgency: urgency,
      hasRelationship: hasRelationship,
    );
    final curiosityPlan = _curiosityPlan(
      proactiveAllowed: proactiveAllowed,
      invite: invite,
      privacy: privacy,
      fatigue: fatigue,
      call: call,
    );
    final microPresenceAllowed =
        proactiveAllowed && roomPresenceOpportunity && !privacy && !fatigue;
    final privateFollowUp =
        privacy ||
        (call &&
            relationshipLabel.toLowerCase().contains('aile') &&
            ownerConfidence >= 0.60);
    return NovaMindLoopState(
      conversationalInvite: invite,
      privateFollowUp: privateFollowUp,
      microPresenceAllowed: microPresenceAllowed,
      relationshipApproach: relationshipApproach,
      rhythmPlan: rhythmPlan,
      memoryCommitPlan: memoryCommitPlan,
      curiosityPlan: curiosityPlan,
      flags: flags,
    );
  }

  String _relationshipApproach({
    required String relationshipLabel,
    required double ownerConfidence,
    required bool urgent,
    required bool privacy,
    required bool call,
  }) {
    final r = relationshipLabel.trim().toLowerCase();
    if (call && urgent && r.contains('anne'))
      return 'anneyle konuşur gibi sıcak ama sakin; aciliyet varsa uzatma';
    if (call && urgent && r.contains('baba'))
      return 'babayla konuşur gibi saygılı ve kısa; aciliyeti berraklaştır';
    if (call && r.contains('eş'))
      return 'eş ilişkisine uygun sıcak, güven veren ve insan gibi aktarım';
    if (privacy) return 'kalabalıkta mahremiyeti koruyup tenhada devam et';
    if (ownerConfidence < 0.55)
      return 'yetki ve ilişki şüphesinde açıklama moduna dön';
    if (r.contains('aile'))
      return 'aile ilişkisine uygun sıcak ve güvenli eşlik';
    if (r.contains('iş') || r.contains('müdür') || r.contains('hoca'))
      return 'saygılı, düzenli ve kısa profesyonel çizgi';
    return 'nötr ama sıcak insanî eşlik';
  }

  String _rhythmPlan({
    required bool fatigue,
    required bool urgency,
    required bool repair,
    required bool call,
    required bool media,
  }) {
    if (media) return 'çok kısa komut + tek onay + gereksiz açıklama yok';
    if (call && urgency) return 'ilk cümlede ana nokta + sakin ikinci cümle';
    if (repair) return 'önce onarım, sonra asıl içerik';
    if (fatigue) return 'nefesli kısa cümleler + tek soru';
    if (urgency) return 'ana sonuç önde, detay sonra';
    return 'doğal ritim + mikro bekleme + gerektiğinde kısa backchannel';
  }

  String _memoryCommitPlan({
    required bool story,
    required bool privacy,
    required bool repair,
    required bool urgency,
    required bool hasRelationship,
  }) {
    if (privacy)
      return 'mahrem ayrıntıyı tam metin yazma; ilişki etiketi ve güvenli özet bırak';
    if (repair) return 'yanlış anlama dersini ve yeni tercih sinyalini yaz';
    if (story && hasRelationship)
      return 'ortak geçmiş ankrajı + ilişki tonu güncellemesi yaz';
    if (urgency) return 'aciliyet ve tekrar hatırlatma gereğini yaz';
    return 'yalnız yüksek değerli tercih ve ilişki sinyalini yaz';
  }

  String _curiosityPlan({
    required bool proactiveAllowed,
    required bool invite,
    required bool privacy,
    required bool fatigue,
    required bool call,
  }) {
    if (!proactiveAllowed) return 'merak pasif';
    if (privacy || call)
      return 'merakı saklı tut; yalnız gerekirse ve owner için sonra sor';
    if (fatigue) return 'merakı ertele; yük bindirme';
    if (invite) return 'sadece kısa ve güvenli bir takip sorusu';
    return 'izin isteyerek tek mikro merak sorusu olabilir';
  }

  bool _containsAny(String text, List<String> parts) {
    for (final part in parts) {
      if (part.trim().isEmpty) continue;
      if (text.contains(part.toLowerCase())) return true;
    }
    return false;
  }
}

class NovaMindLoopState {
  final bool conversationalInvite;
  final bool privateFollowUp;
  final bool microPresenceAllowed;
  final String relationshipApproach;
  final String rhythmPlan;
  final String memoryCommitPlan;
  final String curiosityPlan;
  final List<String> flags;
  const NovaMindLoopState({
    required this.conversationalInvite,
    required this.privateFollowUp,
    required this.microPresenceAllowed,
    required this.relationshipApproach,
    required this.rhythmPlan,
    required this.memoryCommitPlan,
    required this.curiosityPlan,
    required this.flags,
  });
}
