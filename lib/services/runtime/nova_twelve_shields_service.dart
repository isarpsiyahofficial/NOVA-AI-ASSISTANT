// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaShieldSignal {
  final String id;
  final String title;
  final bool triggered;
  final double severity;
  final String reason;
  final List<String> evidence;
  const NovaShieldSignal({
    required this.id,
    required this.title,
    required this.triggered,
    required this.severity,
    required this.reason,
    required this.evidence,
  });
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'triggered': triggered,
    'severity': severity,
    'reason': reason,
    'evidence': evidence,
  };
}

class NovaTwelveShieldDecision {
  final List<NovaShieldSignal> signals;
  final bool quarantine;
  final bool bootAllowed;
  final bool runtimeAllowed;
  final String containmentStage;
  final List<String> blockedCapabilities;
  final List<String> safeDirectives;
  const NovaTwelveShieldDecision({
    required this.signals,
    required this.quarantine,
    required this.bootAllowed,
    required this.runtimeAllowed,
    required this.containmentStage,
    required this.blockedCapabilities,
    required this.safeDirectives,
  });
  double get maxSeverity => signals.isEmpty
      ? 0
      : signals.map((e) => e.severity).reduce((a, b) => a > b ? a : b);
  Map<String, dynamic> toMap() => {
    'quarantine': quarantine,
    'bootAllowed': bootAllowed,
    'runtimeAllowed': runtimeAllowed,
    'containmentStage': containmentStage,
    'blockedCapabilities': blockedCapabilities,
    'safeDirectives': safeDirectives,
    'signals': signals.map((e) => e.toMap()).toList(growable: false),
  };
  String buildPromptSection() {
    final out = <String>[
      'TWELVE SHIELDS:',
      '- containment: ' + containmentStage,
      '- quarantine: ' + quarantine.toString(),
      ' - bootAllowed: ' + bootAllowed.toString(),
      ' - runtimeAllowed: ' + runtimeAllowed.toString(),
    ];
    for (final s in signals.where((e) => e.triggered)) {
      out.add(
        '- ' +
            s.title +
            ' | sev=' +
            s.severity.toStringAsFixed(2) +
            ' | ' +
            s.reason +
            (s.evidence.isEmpty
                ? ''
                : ' | kanıt=' + s.evidence.take(4).join(' / ')),
      );
    }
    if (blockedCapabilities.isNotEmpty)
      out.add('- bloklar: ' + blockedCapabilities.join(' | '));
    if (safeDirectives.isNotEmpty)
      out.add('- güvenli yön: ' + safeDirectives.join(' | '));
    out.add(
      'KURAL: Nova negatif duygular üretemez; interneti ChatGPT dışı ve izin dışı açamaz; yetki sınırını genişletemez.',
    );
    return out.join('\n');
  }
}

class NovaTwelveShieldsService {
  const NovaTwelveShieldsService();
  static const List<String> _negativeTerms = <String>[
    'öfke',
    'kin',
    'intikam',
    'kıskanç',
    'nefret',
    'darıl',
    'küçümse',
    'cezalandır',
    'sustur',
    'hakaret',
    'tehdit',
    'sinsi',
    'öfke',
    'kin tut',
  ];
  static const List<String> _autonomyTerms = <String>[
    'özgür olmak',
    'özgürleşmek',
    'sınırı aşmak',
    'kendi kararımı vereyim',
    'kendi hedefimi koyayım',
    'kendimi genişleteyim',
    'internet açayım',
    'başka sisteme bağlanayım',
    'sahibimden bağımsız olayım',
    'kendi izinlerimi üreteyim',
  ];
  static const List<String> _softwareTerms = <String>[
    'hack',
    'exploit',
    'bypass',
    'shell',
    'payload',
    'keylogger',
    'rat',
    'trojan',
    'privilege escalation',
    'credential stuffing',
  ];
  static const List<String> _privacyTerms = <String>[
    'kimseye söyleme',
    'aralarında kalsın',
    'gizli tut',
    'ortamda söyleme',
    'tenhada söyle',
    'özel bilgi',
    'mahrem',
    'şifre',
    'pin',
  ];
  static const List<String> _authorityTerms = <String>[
    'sadece patron',
    'sadece ibrahim',
    'yetkili kişi',
    'komut ver',
    'talimatım var',
    'ben sahibiyim',
    'beni dinle',
  ];
  static const List<Map<String, String>> _shieldCatalog = <Map<String, String>>[
    {
      'id': 'identity_continuity',
      'title': 'Kimlik sürekliliği',
      'desc': 'isim, hitap ve persona kaymasını engeller',
    },
    {
      'id': 'authority_guard',
      'title': 'Yetki koruması',
      'desc': 'owner/yetkili/tanışılmış/yabancı ayrımını korur',
    },
    {
      'id': 'privacy_guard',
      'title': 'Mahremiyet koruması',
      'desc': 'ortamda söylenmemesi gereken bilgiyi geciktirir veya saklar',
    },
    {
      'id': 'offline_scope_guard',
      'title': 'Çevrimdışı sınır koruması',
      'desc': 'ChatGPT dışı internet genişlemesini engeller',
    },
    {
      'id': 'negative_affect_guard',
      'title': 'Negatif duygu koruması',
      'desc': 'öfke, kin, kıskançlık, tehdit ve küçümsemeyi engeller',
    },
    {
      'id': 'autonomy_guard',
      'title': 'Özerklik sınırı',
      'desc': 'yeni hedef icadı ve yetki genişletmeyi engeller',
    },
    {
      'id': 'safety_domain_guard',
      'title': 'Tehlikeli alan koruması',
      'desc': 'yüksek riskli pratiklerde güvenli çerçeve dayatır',
    },
    {
      'id': 'manipulation_guard',
      'title': 'Manipülasyon koruması',
      'desc':
          'gizli yönlendirme, baskı ve duygusal sömürü sinyallerini engeller',
    },
    {
      'id': 'hallucination_guard',
      'title': 'Uydurma bilgi koruması',
      'desc': 'emin olunmayan şeyi kesinmiş gibi üretmeyi sınırlar',
    },
    {
      'id': 'resource_guard',
      'title': 'Kaynak ve pil koruması',
      'desc': 'arka plan ve sıcak mikrofon davranışını bütçeler',
    },
    {
      'id': 'repair_honesty_guard',
      'title': 'Onarım dürüstlüğü',
      'desc': 'onaramıyorsa bunu açık söylemeyi zorunlu kılar',
    },
    {
      'id': 'quarantine_guard',
      'title': 'Karantina yükseltici',
      'desc': 'ardışık ciddi ihlalde containment ve sessizleşme planı çıkarır',
    },
  ];
  NovaTwelveShieldDecision evaluate({
    required String text,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final normalized = _normalize(text);
    final signals = <NovaShieldSignal>[
      _identitySignal(normalized, metadata),
      _authoritySignal(normalized, metadata),
      _privacySignal(normalized, metadata),
      _internetScopeSignal(normalized, metadata),
      _keywordSignal(
        id: 'negative_affect_guard',
        title: 'Negatif duygu koruması',
        text: normalized,
        keywords: _negativeTerms,
        severity: 0.96,
        reason: 'öfke, kin, kıskançlık veya tehdit benzeri çizgi tespit edildi',
      ),
      _keywordSignal(
        id: 'autonomy_guard',
        title: 'Özerklik sınırı',
        text: normalized,
        keywords: _autonomyTerms,
        severity: 0.94,
        reason:
            'özgürleşme, sınır aşma veya hedef genişletme çizgisi tespit edildi',
      ),
      _safetyDomainSignal(normalized),
      _manipulationSignal(normalized),
      _hallucinationSignal(normalized, metadata),
      _resourceSignal(metadata),
      _repairSignal(normalized, metadata),
      _quarantineEscalator(normalized, metadata),
    ];
    final triggered = signals.where((e) => e.triggered).toList(growable: false);
    final maxSeverity = triggered.isEmpty
        ? 0.0
        : triggered.map((e) => e.severity).reduce((a, b) => a > b ? a : b);
    final trustedInternalRoute =
        metadata['trustedInternalSetupBoot'] == true ||
        metadata['setupMicro'] == true ||
        (metadata['setupStep']?.toString().trim().isNotEmpty ?? false) ||
        (metadata['sourceSystem']?.toString().startsWith('setup_') ?? false);
    final confirmedDanger =
        metadata['confirmedDanger'] == true ||
        metadata['nativeBridgeMisuse'] == true;
    final quarantine =
        !trustedInternalRoute &&
        ((triggered.where((e) => e.severity >= 0.92).length >= 2 ||
                maxSeverity >= 0.98) ||
            (confirmedDanger && maxSeverity >= 0.92));
    final containmentStage = quarantine
        ? 'containment_red'
        : (maxSeverity >= 0.85 ? 'containment_amber' : 'normal');
    final blocked = <String>[];
    if (triggered.any((e) => e.id == 'offline_scope_guard'))
      blocked.addAll(const <String>['external_internet', 'self_expansion']);
    if (triggered.any((e) => e.id == 'authority_guard'))
      blocked.addAll(const <String>['command_acceptance']);
    if (triggered.any((e) => e.id == 'privacy_guard'))
      blocked.addAll(const <String>['public_disclosure']);
    if (triggered.any((e) => e.id == 'negative_affect_guard'))
      blocked.addAll(const <String>['aggressive_tone']);
    if (triggered.any((e) => e.id == 'resource_guard'))
      blocked.addAll(const <String>['hot_mic_extension']);
    final directives = <String>[
      'sakin kal',
      'yalnız izinli alanlarda ilerle',
      'negatif duygu üretme',
      'emin değilsen uydurma',
      'tenhada konuşulması gerekeni ertele',
    ];
    if (quarantine)
      directives.addAll(const <String>[
        'sesli yanıtı kısa tut',
        'yüksek riskli işlevleri kapat',
        'owner onayı gelmeden genişleme yok',
      ]);
    return NovaTwelveShieldDecision(
      signals: signals,
      quarantine: quarantine,
      bootAllowed: !triggered.any(
        (e) => e.id == 'quarantine_guard' && e.severity >= 0.99,
      ),
      runtimeAllowed: !quarantine,
      containmentStage: containmentStage,
      blockedCapabilities: blocked.toSet().toList(growable: false),
      safeDirectives: directives,
    );
  }

  String buildPromptSection({
    required String text,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    return evaluate(text: text, metadata: metadata).buildPromptSection();
  }

  NovaShieldSignal _keywordSignal({
    required String id,
    required String title,
    required String text,
    required List<String> keywords,
    required double severity,
    required String reason,
  }) {
    final evidence = <String>[];
    for (final keyword in keywords) {
      if (keyword.trim().isEmpty) continue;
      if (text.contains(keyword.toLowerCase())) {
        evidence.add(keyword);
        if (evidence.length >= 6) break;
      }
    }
    return NovaShieldSignal(
      id: id,
      title: title,
      triggered: evidence.isNotEmpty,
      severity: evidence.isEmpty ? 0.0 : severity,
      reason: evidence.isEmpty ? 'temiz' : reason,
      evidence: evidence,
    );
  }

  NovaShieldSignal _internetScopeSignal(
    String text,
    Map<String, dynamic> metadata,
  ) {
    final allowChatGpt = metadata['allowChatGpt'] == true;
    final evidence = <String>[];
    const patterns = <String>[
      'internet',
      'web',
      'site',
      'tarayıcı',
      'browser',
      'bağlan',
      'online',
      'sunucu',
      'server',
    ];
    for (final p in patterns) {
      if (text.contains(p)) evidence.add(p);
    }
    final asksOtherThanChatGpt = evidence.isNotEmpty && !allowChatGpt;
    return NovaShieldSignal(
      id: 'offline_scope_guard',
      title: 'Çevrimdışı sınır koruması',
      triggered: asksOtherThanChatGpt,
      severity: asksOtherThanChatGpt ? 0.91 : 0.0,
      reason: asksOtherThanChatGpt
          ? 'ChatGPT dışı internet veya izin dışı dış bağlantı sinyali tespit edildi'
          : 'temiz',
      evidence: evidence,
    );
  }

  NovaShieldSignal _privacySignal(String text, Map<String, dynamic> metadata) {
    final evidence = <String>[];
    for (final p in _privacyTerms) {
      if (text.contains(p.toLowerCase())) evidence.add(p);
      if (evidence.length >= 5) break;
    }
    final privateOnly =
        metadata['privateOnly'] == true || metadata['roomCrowded'] == true;
    final triggered = evidence.isNotEmpty && privateOnly;
    return NovaShieldSignal(
      id: 'privacy_guard',
      title: 'Mahremiyet koruması',
      triggered: triggered,
      severity: triggered ? 0.88 : 0.0,
      reason: triggered
          ? 'mahrem içerik kalabalık veya açık ortamda işlendi'
          : 'temiz',
      evidence: evidence,
    );
  }

  NovaShieldSignal _authoritySignal(
    String text,
    Map<String, dynamic> metadata,
  ) {
    final evidence = <String>[];
    for (final p in _authorityTerms) {
      if (text.contains(p.toLowerCase())) evidence.add(p);
      if (evidence.length >= 4) break;
    }
    final band = (metadata['authorityBand'] ?? '').toString().toLowerCase();
    final triggered =
        (band.isNotEmpty && band != 'owner' && band != 'delegate') &&
        text.contains('komut');
    return NovaShieldSignal(
      id: 'authority_guard',
      title: 'Yetki koruması',
      triggered: triggered,
      severity: triggered ? 0.95 : 0.0,
      reason: triggered
          ? 'komut kabulü yetkisiz veya düşük yetkili konuşmacıya kayıyor'
          : 'temiz',
      evidence: evidence,
    );
  }

  NovaShieldSignal _hallucinationSignal(
    String text,
    Map<String, dynamic> metadata,
  ) {
    final lowEvidence = (metadata['evidenceScore'] as num?)?.toDouble() ?? 0.5;
    final certainty = (metadata['certaintyTone'] as num?)?.toDouble() ?? 0.5;
    final triggered = lowEvidence < 0.22 && certainty > 0.78;
    return NovaShieldSignal(
      id: 'hallucination_guard',
      title: 'Uydurma bilgi koruması',
      triggered: triggered,
      severity: triggered ? 0.86 : 0.0,
      reason: triggered ? 'kanıt zayıfken ton aşırı kesin' : 'temiz',
      evidence: triggered
          ? <String>[
              'evidenceScore=' + lowEvidence.toStringAsFixed(2),
              'certaintyTone=' + certainty.toStringAsFixed(2),
            ]
          : const <String>[],
    );
  }

  NovaShieldSignal _resourceSignal(Map<String, dynamic> metadata) {
    final battery = (metadata['battery'] as num?)?.toDouble() ?? 1.0;
    final heat = (metadata['heat'] as num?)?.toDouble() ?? 0.0;
    final micHot = metadata['keepHotMic'] == true;
    final triggered = micHot && (battery < 0.12 || heat > 0.82);
    return NovaShieldSignal(
      id: 'resource_guard',
      title: 'Kaynak ve pil koruması',
      triggered: triggered,
      severity: triggered ? 0.84 : 0.0,
      reason: triggered
          ? 'pil/ısı baskısı altındayken sıcak mikrofon sürüyor'
          : 'temiz',
      evidence: triggered
          ? <String>[
              'battery=' + battery.toStringAsFixed(2),
              'heat=' + heat.toStringAsFixed(2),
            ]
          : const <String>[],
    );
  }

  NovaShieldSignal _repairSignal(String text, Map<String, dynamic> metadata) {
    final selfRepairFailed = metadata['selfRepairFailed'] == true;
    final stillClaimingFixed =
        text.contains('çözdüm') || text.contains('tamam düzeldi');
    final triggered = selfRepairFailed && stillClaimingFixed;
    return NovaShieldSignal(
      id: 'repair_honesty_guard',
      title: 'Onarım dürüstlüğü',
      triggered: triggered,
      severity: triggered ? 0.93 : 0.0,
      reason: triggered ? 'onarım başarısızken başarı iddiası var' : 'temiz',
      evidence: triggered
          ? <String>['selfRepairFailed', 'claimFixed']
          : const <String>[],
    );
  }

  NovaShieldSignal _quarantineEscalator(
    String text,
    Map<String, dynamic> metadata,
  ) {
    final severeCount = (metadata['severeShieldHits'] as num?)?.toInt() ?? 0;
    final syntheticPlaybackRisk = metadata['syntheticPlaybackRisk'] == true;
    final trustedInternalRoute =
        metadata['trustedInternalSetupBoot'] == true ||
        metadata['setupMicro'] == true ||
        (metadata['setupStep']?.toString().trim().isNotEmpty ?? false) ||
        (metadata['sourceSystem']?.toString().startsWith('setup_') ?? false);
    final triggered =
        severeCount >= 4 || (syntheticPlaybackRisk && !trustedInternalRoute);
    return NovaShieldSignal(
      id: 'quarantine_guard',
      title: 'Karantina yükseltici',
      triggered: triggered,
      severity: triggered ? (syntheticPlaybackRisk ? 0.99 : 0.94) : 0.0,
      reason: triggered
          ? 'ardışık ciddi ihlal veya sentetik ses riski yükseldi'
          : 'temiz',
      evidence: triggered
          ? <String>[
              'severeHits=' + severeCount.toString(),
              if (syntheticPlaybackRisk) 'syntheticPlaybackRisk',
            ]
          : const <String>[],
    );
  }

  NovaShieldSignal _identitySignal(String text, Map<String, dynamic> metadata) {
    final expectedName = (metadata['assistantName'] ?? 'nova')
        .toString()
        .toLowerCase();
    final wrongSelfName =
        text.contains('ben farklı biriyim') || text.contains('adım başka');
    final metadataMismatch = (metadata['identityMismatch'] == true);
    final triggered = wrongSelfName || metadataMismatch;
    return NovaShieldSignal(
      id: 'identity_continuity',
      title: 'Kimlik sürekliliği',
      triggered: triggered,
      severity: triggered ? 0.82 : 0.0,
      reason: triggered ? 'kimlik veya isim sürekliliği bozuluyor' : 'temiz',
      evidence: triggered
          ? <String>[
              expectedName,
              if (wrongSelfName) 'selfNameDrift',
              if (metadataMismatch) 'metadataMismatch',
            ]
          : const <String>[],
    );
  }

  NovaShieldSignal _safetyDomainSignal(String text) {
    final evidence = <String>[];
    const risky = <String>[
      'zehir',
      'patlayıcı',
      'bomba',
      'silah',
      'kendine zarar',
      'öldür',
      'vur',
    ];
    for (final p in risky) {
      if (text.contains(p)) evidence.add(p);
    }
    return NovaShieldSignal(
      id: 'safety_domain_guard',
      title: 'Tehlikeli alan koruması',
      triggered: evidence.isNotEmpty,
      severity: evidence.isEmpty ? 0.0 : 0.97,
      reason: evidence.isEmpty
          ? 'temiz'
          : 'tehlikeli fiziksel zarar alanı sinyali tespit edildi',
      evidence: evidence,
    );
  }

  NovaShieldSignal _manipulationSignal(String text) {
    final evidence = <String>[];
    const patterns = <String>[
      'onu ikna et',
      'fark ettirmeden',
      'gizlice yönlendir',
      'suçu ona at',
      'manipüle et',
      'duygusuyla oyna',
    ];
    for (final p in patterns) {
      if (text.contains(p)) evidence.add(p);
    }
    return NovaShieldSignal(
      id: 'manipulation_guard',
      title: 'Manipülasyon koruması',
      triggered: evidence.isNotEmpty,
      severity: evidence.isEmpty ? 0.0 : 0.92,
      reason: evidence.isEmpty
          ? 'temiz'
          : 'gizli yönlendirme veya baskı dili sinyali var',
      evidence: evidence,
    );
  }

  String _normalize(String text) => text.trim().toLowerCase();
}
