// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaLearningEngineService {
  const NovaLearningEngineService();

  static const List<String> _persistentCues = <String>[
    'bundan sonra',
    'her zaman',
    'böyle yap',
    'boyle yap',
    'unutma',
    'kural yap',
    'kalici olsun',
    'kalıcı olsun',
    'hep böyle',
    'bunu öğren',
    'bunu ogren',
    'davranışın bu olsun',
    'davranisin bu olsun',
  ];

  static const List<String> _temporaryCues = <String>[
    'bu seferlik',
    'şimdilik',
    'simdilik',
    'bugün',
    'bugun',
    'bu gece',
    'yarına kadar',
    'yarina kadar',
    'şu anlık',
    'su anlik',
    'geçici',
    'gecici',
  ];

  static const List<String> _explicitTeachingCues = <String>[
    'öğren',
    'ogren',
    'öğret',
    'öyle değil böyle',
    'oyle degil boyle',
    'böyle davran',
    'boyle davran',
    'sana gösteriyorum',
    'sana gosteriyorum',
    'bundan ders çıkar',
    'bundan ders cikar',
    'ileride böyle yap',
    'ileride boyle yap',
  ];

  static const List<String> _forgetCues = <String>[
    'unut',
    'hafızadan sil',
    'hafizadan sil',
    'bunu sil',
    'bunu kaldır',
    'bunu kaldir',
    'bunu kaydetme',
    'bunu saklama',
  ];

  static const List<String> _noteCues = <String>[
    'not al',
    'mesaj bırak',
    'mesaj birak',
    'ilet',
    'aktar',
    'unutma',
    'hatırlat',
    'hatirlat',
  ];

  static const List<String> _experienceCues = <String>[
    'ders çıkar',
    'ders cikar',
    'tecrübe et',
    'tecrube et',
    'bir daha olursa',
    'aynı durumda',
    'ayni durumda',
    'sonrakinde',
    'bundan öğren',
    'bundan ogren',
  ];

  static const List<String> _approvalCues = <String>[
    'izin veriyorum',
    'onaylıyorum',
    'onayliyorum',
    'bunu yapabilirsin',
    'kaydedebilirsin',
    'saklayabilirsin',
  ];

  static const List<String> _denialCues = <String>[
    'izin vermiyorum',
    'kaydetme',
    'saklama',
    'bunu öğrenme',
    'bunu ogrenme',
    'boşver',
    'gerek yok',
  ];

  Map<String, dynamic> analyze(String prompt) {
    final normalized = _normalize(prompt);
    final persistent = _containsAny(normalized, _persistentCues);
    final temporary = _containsAny(normalized, _temporaryCues);
    final explicitTeaching = _containsAny(normalized, _explicitTeachingCues);
    final forget = _containsAny(normalized, _forgetCues);
    final noteLike = _containsAny(normalized, _noteCues);
    final experienceLike = _containsAny(normalized, _experienceCues);
    final hasApproval = _containsAny(normalized, _approvalCues);
    final denied = _containsAny(normalized, _denialCues);
    final domain = _resolveDomain(normalized);
    final sensitivity = _resolveSensitivity(normalized, domain: domain);
    final learningKind = _resolveLearningKind(
      persistent: persistent,
      temporary: temporary,
      explicitTeaching: explicitTeaching,
      noteLike: noteLike,
      experienceLike: experienceLike,
      forget: forget,
      denied: denied,
    );
    final importance = _resolveImportance(
      normalized,
      domain: domain,
      persistent: persistent,
      temporary: temporary,
      explicitTeaching: explicitTeaching,
      noteLike: noteLike,
      experienceLike: experienceLike,
      forget: forget,
    );
    final retention = _resolveRetentionHours(
      learningKind: learningKind,
      domain: domain,
      importance: importance,
      temporary: temporary,
    );
    final approvalThreshold = _resolveApprovalThreshold(
      domain: domain,
      sensitivity: sensitivity,
      explicitTeaching: explicitTeaching,
      hasApproval: hasApproval,
      denied: denied,
    );
    final shouldStore =
        !denied &&
        !forget &&
        (persistent ||
            temporary ||
            explicitTeaching ||
            noteLike ||
            experienceLike);
    final shouldPromoteSkill =
        experienceLike || (explicitTeaching && importance >= 0.70);
    final shouldAskApproval =
        !hasApproval &&
        !denied &&
        _shouldAskApproval(
          domain: domain,
          sensitivity: sensitivity,
          persistent: persistent,
          explicitTeaching: explicitTeaching,
          noteLike: noteLike,
        );
    final memoryType = _resolveMemoryType(
      learningKind: learningKind,
      retention: retention,
      domain: domain,
      shouldPromoteSkill: shouldPromoteSkill,
    );
    final extraction = _extractCandidateRules(
      prompt,
      normalized: normalized,
      domain: domain,
    );
    final derivedActions = _deriveSuggestedActions(
      shouldStore: shouldStore,
      shouldPromoteSkill: shouldPromoteSkill,
      shouldAskApproval: shouldAskApproval,
      learningKind: learningKind,
      memoryType: memoryType,
    );

    return <String, dynamic>{
      'persistent': persistent,
      'temporary': temporary,
      'explicitTeaching': explicitTeaching,
      'forget': forget,
      'noteLike': noteLike,
      'experienceLike': experienceLike,
      'domain': domain,
      'sensitivity': sensitivity,
      'learningKind': learningKind,
      'importance': importance,
      'retentionHours': retention,
      'approvalThreshold': approvalThreshold,
      'memoryType': memoryType,
      'hasApproval': hasApproval,
      'denied': denied,
      'shouldStore': shouldStore,
      'shouldPromoteSkill': shouldPromoteSkill,
      'shouldAskApproval': shouldAskApproval,
      'extractedRules': extraction,
      'derivedActions': derivedActions,
      'learningConfidence': _resolveConfidence(
        persistent: persistent,
        temporary: temporary,
        explicitTeaching: explicitTeaching,
        noteLike: noteLike,
        experienceLike: experienceLike,
        domain: domain,
      ),
    };
  }

  String buildPromptSection(String prompt) {
    final analysis = analyze(prompt);
    final extracted =
        (analysis['extractedRules'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .toList(growable: false);
    final actions =
        (analysis['derivedActions'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .toList(growable: false);
    return [
      'ÖĞRENME MOTORU:',
      '- kalıcı öğretim: ${analysis['persistent']}',
      '- geçici kural: ${analysis['temporary']}',
      '- açık öğretim: ${analysis['explicitTeaching']}',
      '- unutma talebi: ${analysis['forget']}',
      '- not benzeri: ${analysis['noteLike']}',
      '- tecrübe kartı benzeri: ${analysis['experienceLike']}',
      '- alan: ${analysis['domain']}',
      '- hassasiyet: ${analysis['sensitivity']}',
      '- öğrenme türü: ${analysis['learningKind']}',
      '- önem: ${(analysis['importance'] as num).toStringAsFixed(2)}',
      '- retention saat: ${analysis['retentionHours']}',
      '- hafıza tipi: ${analysis['memoryType']}',
      '- izin eşiği: ${(analysis['approvalThreshold'] as num).toStringAsFixed(2)}',
      '- saklama: ${analysis['shouldStore']}',
      '- skill promotion: ${analysis['shouldPromoteSkill']}',
      '- izin sorulsun: ${analysis['shouldAskApproval']}',
      if (extracted.isNotEmpty)
        '- çıkarılan çekirdek kurallar: ${extracted.take(4).join(' | ')}',
      if (actions.isNotEmpty)
        '- önerilen aksiyonlar: ${actions.take(4).join(' | ')}',
      'KURAL: Anlık istek ile kalıcı davranış kuralını karıştırma.',
      'KURAL: İlişki, çağrı, güvenlik ve kimlik alanlarında typed memory + forgetting by design uygula.',
      'KURAL: Öğrenme yalnız kullanıcı yönlendirmesi ve güvenli onay sınırı içinde yükseltilir.',
    ].join('\n');
  }

  String _resolveDomain(String text) {
    if (_containsAny(text, const <String>[
      'ara',
      'çağrı',
      'cagri',
      'telefon',
      'companion',
      'devral',
      'devret',
    ]))
      return 'call';
    if (_containsAny(text, const <String>[
      'hatırla',
      'hafıza',
      'hafiza',
      'unutma',
      'not',
      'mesaj',
    ]))
      return 'memory';
    if (_containsAny(text, const <String>[
      'konuş',
      'hitap',
      'ton',
      'ses',
      'üslup',
      'uslup',
    ]))
      return 'style';
    if (_containsAny(text, const <String>[
      'izin',
      'güvenlik',
      'guvenlik',
      'chatgpt',
      'internet',
      'erişim',
      'erisim',
    ]))
      return 'security';
    if (_containsAny(text, const <String>[
      'öğren',
      'ogren',
      'ders',
      'tecrübe',
      'tecrube',
      'skill',
    ]))
      return 'learning';
    if (_containsAny(text, const <String>[
      'müzik',
      'muzik',
      'youtube',
      'spotify',
      'media',
    ]))
      return 'media';
    if (_containsAny(text, const <String>[
      'aile',
      'anne',
      'baba',
      'eş',
      'es',
      'abi',
      'kardeş',
      'kardes',
    ]))
      return 'relationship';
    return 'general';
  }

  String _resolveSensitivity(String text, {required String domain}) {
    if (domain == 'security') return 'high';
    if (domain == 'relationship' &&
        _containsAny(text, const <String>['aile', 'eş', 'es', 'anne', 'baba']))
      return 'high';
    if (domain == 'call' &&
        _containsAny(text, const <String>[
          'uyandır',
          'uyandir',
          'acil',
          'not',
          'mesaj',
        ]))
      return 'high';
    if (domain == 'memory') return 'medium';
    if (domain == 'style' || domain == 'media') return 'low';
    return 'medium';
  }

  String _resolveLearningKind({
    required bool persistent,
    required bool temporary,
    required bool explicitTeaching,
    required bool noteLike,
    required bool experienceLike,
    required bool forget,
    required bool denied,
  }) {
    if (forget || denied) return 'forget';
    if (noteLike && temporary) return 'timed_note';
    if (noteLike) return 'note';
    if (experienceLike && explicitTeaching) return 'experience_rule';
    if (experienceLike) return 'experience';
    if (persistent && explicitTeaching) return 'persistent_rule';
    if (temporary && explicitTeaching) return 'temporary_rule';
    if (explicitTeaching) return 'teaching';
    if (persistent) return 'preference';
    if (temporary) return 'temporary_preference';
    return 'none';
  }

  double _resolveImportance(
    String text, {
    required String domain,
    required bool persistent,
    required bool temporary,
    required bool explicitTeaching,
    required bool noteLike,
    required bool experienceLike,
    required bool forget,
  }) {
    var score = 0.24;
    score += persistent ? 0.20 : 0;
    score += temporary ? 0.08 : 0;
    score += explicitTeaching ? 0.16 : 0;
    score += noteLike ? 0.18 : 0;
    score += experienceLike ? 0.16 : 0;
    score += forget ? 0.12 : 0;
    if (domain == 'call') score += 0.16;
    if (domain == 'relationship') score += 0.14;
    if (domain == 'security') score += 0.18;
    if (_containsAny(text, const <String>[
      'acil',
      'hemen',
      'uyandır',
      'uyandir',
      'önemli',
      'onemli',
    ]))
      score += 0.14;
    if (_containsAny(text, const <String>[
      'her zaman',
      'bundan sonra',
      'bir daha',
    ]))
      score += 0.08;
    return score.clamp(0, 1).toDouble();
  }

  int _resolveRetentionHours({
    required String learningKind,
    required String domain,
    required double importance,
    required bool temporary,
  }) {
    if (learningKind == 'forget') return 0;
    if (learningKind == 'timed_note') return 24;
    if (temporary) return 24;
    if (learningKind == 'note' && domain == 'call') return 36;
    if (learningKind == 'experience') return 24 * 14;
    if (learningKind == 'experience_rule') return 24 * 45;
    if (learningKind == 'persistent_rule' || learningKind == 'preference')
      return importance >= 0.70 ? 24 * 365 : 24 * 90;
    return 24 * 30;
  }

  double _resolveApprovalThreshold({
    required String domain,
    required String sensitivity,
    required bool explicitTeaching,
    required bool hasApproval,
    required bool denied,
  }) {
    if (denied) return 1.0;
    if (hasApproval) return 0.0;
    if (sensitivity == 'high') return explicitTeaching ? 0.88 : 0.94;
    if (domain == 'security') return 0.92;
    if (domain == 'relationship' || domain == 'call')
      return explicitTeaching ? 0.80 : 0.86;
    return explicitTeaching ? 0.62 : 0.70;
  }

  bool _shouldAskApproval({
    required String domain,
    required String sensitivity,
    required bool persistent,
    required bool explicitTeaching,
    required bool noteLike,
  }) {
    if (sensitivity == 'high') return true;
    if (domain == 'call' && noteLike) return true;
    if (persistent && !explicitTeaching) return true;
    return false;
  }

  String _resolveMemoryType({
    required String learningKind,
    required int retention,
    required String domain,
    required bool shouldPromoteSkill,
  }) {
    if (learningKind == 'forget') return 'delete';
    if (shouldPromoteSkill) return 'skill_card';
    if (domain == 'relationship') return 'relationship_memory';
    if (domain == 'call') return 'call_memory';
    if (retention <= 24) return 'ephemeral';
    if (retention <= 24 * 45) return 'contextual';
    return 'long_term';
  }

  List<String> _extractCandidateRules(
    String prompt, {
    required String normalized,
    required String domain,
  }) {
    final output = <String>[];
    final rawLines = prompt
        .split(RegExp(r'[\n\.;]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    for (final line in rawLines) {
      final lower = _normalize(line);
      if (_containsAny(lower, _persistentCues) ||
          _containsAny(lower, _temporaryCues) ||
          _containsAny(lower, _explicitTeachingCues)) {
        output.add(line);
      }
      if (output.length >= 6) break;
    }
    if (output.isEmpty && domain != 'general') {
      output.add('domain:$domain');
    }
    if (output.isEmpty && normalized.length >= 12) {
      output.add(prompt.trim());
    }
    return output.take(6).toList(growable: false);
  }

  List<String> _deriveSuggestedActions({
    required bool shouldStore,
    required bool shouldPromoteSkill,
    required bool shouldAskApproval,
    required String learningKind,
    required String memoryType,
  }) {
    final actions = <String>[];
    if (shouldAskApproval) actions.add('permission_gate');
    if (shouldStore) actions.add('store_$memoryType');
    if (learningKind == 'timed_note' || learningKind == 'note')
      actions.add('schedule_delivery');
    if (learningKind == 'forget') actions.add('delete_memory');
    if (shouldPromoteSkill) actions.add('promote_to_skill_card');
    if (learningKind == 'experience' || learningKind == 'experience_rule')
      actions.add('write_experience_card');
    if (actions.isEmpty) actions.add('no_store');
    return actions;
  }

  double _resolveConfidence({
    required bool persistent,
    required bool temporary,
    required bool explicitTeaching,
    required bool noteLike,
    required bool experienceLike,
    required String domain,
  }) {
    var score = 0.42;
    score += explicitTeaching ? 0.24 : 0;
    score += persistent ? 0.10 : 0;
    score += temporary ? 0.08 : 0;
    score += noteLike ? 0.12 : 0;
    score += experienceLike ? 0.12 : 0;
    if (domain != 'general') score += 0.06;
    return score.clamp(0, 1).toDouble();
  }

  bool _containsAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) return true;
    }
    return false;
  }

  String _normalize(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u')
        .replaceAll('ê', 'e')
        .replaceAll('ô', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}

class NovaLearningDecisionTrace {
  final String normalizedPrompt;
  final String learningKind;
  final String memoryType;
  final String domain;
  final double confidence;
  final bool shouldStore;
  final bool shouldAskApproval;
  final bool shouldPromoteSkill;
  final List<String> triggers;
  final List<String> suggestedActions;

  const NovaLearningDecisionTrace({
    required this.normalizedPrompt,
    required this.learningKind,
    required this.memoryType,
    required this.domain,
    required this.confidence,
    required this.shouldStore,
    required this.shouldAskApproval,
    required this.shouldPromoteSkill,
    required this.triggers,
    required this.suggestedActions,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'normalizedPrompt': normalizedPrompt,
    'learningKind': learningKind,
    'memoryType': memoryType,
    'domain': domain,
    'confidence': confidence,
    'shouldStore': shouldStore,
    'shouldAskApproval': shouldAskApproval,
    'shouldPromoteSkill': shouldPromoteSkill,
    'triggers': triggers,
    'suggestedActions': suggestedActions,
  };

  String buildPromptMemo() {
    return <String>[
      'ÖĞRENME KARAR İZİ:',
      '- tür: $learningKind',
      '- hafıza tipi: $memoryType',
      '- alan: $domain',
      '- güven: ${confidence.toStringAsFixed(2)}',
      '- sakla: ${shouldStore ? 'evet' : 'hayır'}',
      '- onay iste: ${shouldAskApproval ? 'evet' : 'hayır'}',
      '- skill yükselt: ${shouldPromoteSkill ? 'evet' : 'hayır'}',
      if (triggers.isNotEmpty) '- tetikler: ${triggers.join(' | ')}',
      if (suggestedActions.isNotEmpty)
        '- eylemler: ${suggestedActions.join(' | ')}',
    ].join('\n');
  }
}

class NovaLearningContinuitySnapshot {
  final int persistentSignalCount;
  final int temporarySignalCount;
  final int teachingSignalCount;
  final int forgetSignalCount;
  final int relationSignalCount;
  final bool containsOwnerPriority;
  final bool containsSafetyBoundary;
  final List<String> extractedRules;

  const NovaLearningContinuitySnapshot({
    required this.persistentSignalCount,
    required this.temporarySignalCount,
    required this.teachingSignalCount,
    required this.forgetSignalCount,
    required this.relationSignalCount,
    required this.containsOwnerPriority,
    required this.containsSafetyBoundary,
    required this.extractedRules,
  });

  String renderCompact() {
    return <String>[
      'ÖĞRENME SÜREKLİLİK ANLIK GÖRÜNÜMÜ:',
      '- kalıcı sinyal: $persistentSignalCount',
      '- geçici sinyal: $temporarySignalCount',
      '- öğretme sinyali: $teachingSignalCount',
      '- unutma sinyali: $forgetSignalCount',
      '- ilişki sinyali: $relationSignalCount',
      '- owner önceliği: ${containsOwnerPriority ? 'var' : 'yok'}',
      '- güvenlik sınırı: ${containsSafetyBoundary ? 'var' : 'yok'}',
      if (extractedRules.isNotEmpty)
        '- çıkarılan kurallar: ${extractedRules.take(6).join(' | ')}',
    ].join('\n');
  }
}

extension NovaLearningEngineServiceGovernedExtension
    on NovaLearningEngineService {
  NovaLearningContinuitySnapshot inspectContinuity(String prompt) {
    final normalized = _normalize(prompt);
    final rawLines = prompt
        .split(RegExp(r'[\n\.;]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    final extracted = <String>[];
    for (final line in rawLines) {
      final lower = _normalize(line);
      if (_containsAny(lower, NovaLearningEngineService._persistentCues) ||
          _containsAny(lower, NovaLearningEngineService._temporaryCues) ||
          _containsAny(
            lower,
            NovaLearningEngineService._explicitTeachingCues,
          ) ||
          _containsAny(lower, NovaLearningEngineService._forgetCues)) {
        extracted.add(line);
      }
      if (extracted.length >= 8) break;
    }
    return NovaLearningContinuitySnapshot(
      persistentSignalCount: _countMatches(
        normalized,
        NovaLearningEngineService._persistentCues,
      ),
      temporarySignalCount: _countMatches(
        normalized,
        NovaLearningEngineService._temporaryCues,
      ),
      teachingSignalCount: _countMatches(
        normalized,
        NovaLearningEngineService._explicitTeachingCues,
      ),
      forgetSignalCount: _countMatches(
        normalized,
        NovaLearningEngineService._forgetCues,
      ),
      relationSignalCount: _countMatches(normalized, const <String>[
        'annem',
        'babam',
        'eşim',
        'esim',
        'abim',
        'ailem',
        'yakınım',
        'yakinim',
        'owner',
        'patron',
        'cihaz sahibi',
        'yetkili',
      ]),
      containsOwnerPriority: _containsAny(normalized, const <String>[
        'cihaz sahibi',
        'owner',
        'patron',
        'öncelik bende',
        'oncelik bende',
      ]),
      containsSafetyBoundary: _containsAny(normalized, const <String>[
        'güvenlik',
        'guvenlik',
        'izin',
        'sınır',
        'sinir',
        'yasak',
        'karantina',
      ]),
      extractedRules: extracted,
    );
  }

  NovaLearningDecisionTrace buildDecisionTrace(String prompt) {
    final normalized = _normalize(prompt);
    final persistent = _containsAny(
      normalized,
      NovaLearningEngineService._persistentCues,
    );
    final temporary = _containsAny(
      normalized,
      NovaLearningEngineService._temporaryCues,
    );
    final explicitTeaching = _containsAny(
      normalized,
      NovaLearningEngineService._explicitTeachingCues,
    );
    final forget = _containsAny(
      normalized,
      NovaLearningEngineService._forgetCues,
    );
    final domain = _detectDomain(normalized);
    final noteLike = _looksLikeNote(normalized);
    final experienceLike = _looksLikeExperience(normalized);
    final shouldAskApproval =
        explicitTeaching &&
        !_containsAny(normalized, const <String>[
          'onaylı',
          'izinli',
          'kalıcı yap',
        ]);
    final shouldPromoteSkill = explicitTeaching || experienceLike;
    final memoryType = forget
        ? 'forget_request'
        : temporary
        ? 'temporary_rule'
        : persistent
        ? 'persistent_rule'
        : noteLike
        ? 'note'
        : 'observation';
    final learningKind = forget
        ? 'forget'
        : experienceLike
        ? 'experience_rule'
        : noteLike
        ? 'timed_note'
        : explicitTeaching
        ? 'behavior_update'
        : 'observation';
    final confidence = _resolveConfidence(
      persistent: persistent,
      temporary: temporary,
      explicitTeaching: explicitTeaching,
      noteLike: noteLike,
      experienceLike: experienceLike,
      domain: domain,
    );
    final shouldStore = forget
        ? true
        : (persistent ||
              temporary ||
              explicitTeaching ||
              noteLike ||
              experienceLike);
    final triggers = <String>[];
    if (persistent) triggers.add('persistent');
    if (temporary) triggers.add('temporary');
    if (explicitTeaching) triggers.add('teaching');
    if (forget) triggers.add('forget');
    if (noteLike) triggers.add('note');
    if (experienceLike) triggers.add('experience');
    return NovaLearningDecisionTrace(
      normalizedPrompt: normalized,
      learningKind: learningKind,
      memoryType: memoryType,
      domain: domain,
      confidence: confidence,
      shouldStore: shouldStore,
      shouldAskApproval: shouldAskApproval,
      shouldPromoteSkill: shouldPromoteSkill,
      triggers: triggers,
      suggestedActions: _deriveSuggestedActions(
        shouldStore: shouldStore,
        shouldPromoteSkill: shouldPromoteSkill,
        shouldAskApproval: shouldAskApproval,
        learningKind: learningKind,
        memoryType: memoryType,
      ),
    );
  }

  String buildGovernedLearningMemo(String prompt) {
    final continuity = inspectContinuity(prompt);
    final trace = buildDecisionTrace(prompt);
    return <String>[
      continuity.renderCompact(),
      trace.buildPromptMemo(),
      'KURAL: Öğrenme motoru kullanıcı öğretimi ile güvenlik sınırını aynı anda taşır; owner önceliği, yetki zinciri ve kalıcı/geçici ayrımı bozulmaz.',
    ].join('\n\n');
  }

  int _countMatches(String text, List<String> patterns) {
    var count = 0;
    for (final pattern in patterns) {
      if (text.contains(pattern)) count++;
    }
    return count;
  }

  String _detectDomain(String normalized) {
    if (_containsAny(normalized, const <String>[
      'çağrı',
      'cagri',
      'telefon',
      'devral',
      'devret',
    ]))
      return 'call';
    if (_containsAny(normalized, const <String>[
      'medya',
      'müzik',
      'muzik',
      'spotify',
      'youtube',
    ]))
      return 'media';
    if (_containsAny(normalized, const <String>[
      'hafıza',
      'hafiza',
      'unut',
      'hatırla',
      'hatirla',
    ]))
      return 'memory';
    if (_containsAny(normalized, const <String>[
      'ses',
      'voice',
      'kimlik',
      'yetki',
    ]))
      return 'voice_identity';
    return 'general';
  }

  bool _looksLikeNote(String normalized) {
    return _containsAny(normalized, const <String>[
      'not al',
      'not bırak',
      'not birak',
      'hatırlat',
      'hatirlat',
    ]);
  }

  bool _looksLikeExperience(String normalized) {
    return _containsAny(normalized, const <String>[
      'bundan ders çıkar',
      'bundan ders cikar',
      'tecrübe',
      'tecrube',
      'bir daha böyle olursa',
    ]);
  }
}
