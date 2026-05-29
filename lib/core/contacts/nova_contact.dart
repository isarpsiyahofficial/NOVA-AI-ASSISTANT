// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'contact_role.dart';

enum ContactInstructionMode {
  useDefault,
  customInstruction,
  respectfulAutonomy,
}

extension ContactInstructionModeX on ContactInstructionMode {
  String get key {
    switch (this) {
      case ContactInstructionMode.useDefault:
        return 'use_default';
      case ContactInstructionMode.customInstruction:
        return 'custom_instruction';
      case ContactInstructionMode.respectfulAutonomy:
        return 'respectful_autonomy';
    }
  }

  String get label {
    switch (this) {
      case ContactInstructionMode.useDefault:
        return 'Varsayılan özelliği kullan';
      case ContactInstructionMode.customInstruction:
        return 'Özel talimatı uygula';
      case ContactInstructionMode.respectfulAutonomy:
        return 'Sınır yok / saygılı serbest';
    }
  }

  String get policyLine {
    switch (this) {
      case ContactInstructionMode.useDefault:
        return 'Bu alan için Nova varsayılan çağrı davranışını kullanır.';
      case ContactInstructionMode.customInstruction:
        return 'Bu alan iç talimattır; Nova metni aynen okumaz, davranışa çevirir.';
      case ContactInstructionMode.respectfulAutonomy:
        return 'Nova bu alanda gerçek sekreter gibi, saygı ve güvenlik sınırları içinde duruma göre konuşabilir.';
    }
  }
}

ContactInstructionMode _contactInstructionModeFromMap(
  Map<String, dynamic> map,
  String key,
) {
  final raw =
      (map[key] as String? ?? ContactInstructionMode.customInstruction.key)
          .trim();
  return ContactInstructionMode.values.firstWhere(
    (e) => e.key == raw || e.name == raw,
    orElse: () => ContactInstructionMode.customInstruction,
  );
}

class NovaContact {
  final String id;
  final String displayName;
  final String phoneNumber;
  final ContactRole role;
  final String? customRoleLabel;
  final bool isVoiceKnown;
  final String relationshipLabel;
  final String closenessLevel;
  final bool isAuthorizedToUseNova;
  final bool canReceiveAutoCallHandling;
  final String linkedVoiceId;
  final String persistentOwnerMessage;
  final String callOpeningInstruction;
  final String expectedCallerQuestions;
  final String allowedResponseScope;
  final String blockedResponseScope;
  final String emergencyInstruction;
  final String whiteLieInstruction;
  final String quickReplyInstruction;
  final ContactInstructionMode callOpeningInstructionMode;
  final ContactInstructionMode expectedCallerQuestionsMode;
  final ContactInstructionMode allowedResponseScopeMode;
  final ContactInstructionMode blockedResponseScopeMode;
  final ContactInstructionMode emergencyInstructionMode;
  final ContactInstructionMode whiteLieInstructionMode;
  final ContactInstructionMode quickReplyInstructionMode;
  final bool allowEmergencyWake;
  final bool autoTakeNotes;
  final bool allowNightAutoCall;
  final bool preferSpeakerMode;
  final bool allowNovaSmallTalk;
  final bool isProtectedIdentity;

  const NovaContact({
    this.id = '',
    this.displayName = '',
    this.phoneNumber = '',
    this.role = ContactRole.friend,
    this.customRoleLabel,
    this.isVoiceKnown = false,
    this.relationshipLabel = '',
    this.closenessLevel = 'normal',
    this.isAuthorizedToUseNova = false,
    this.canReceiveAutoCallHandling = false,
    this.linkedVoiceId = '',
    this.persistentOwnerMessage = '',
    this.callOpeningInstruction = '',
    this.expectedCallerQuestions = '',
    this.allowedResponseScope = '',
    this.blockedResponseScope = '',
    this.emergencyInstruction = '',
    this.whiteLieInstruction = '',
    this.quickReplyInstruction = '',
    this.callOpeningInstructionMode = ContactInstructionMode.customInstruction,
    this.expectedCallerQuestionsMode = ContactInstructionMode.customInstruction,
    this.allowedResponseScopeMode = ContactInstructionMode.customInstruction,
    this.blockedResponseScopeMode = ContactInstructionMode.customInstruction,
    this.emergencyInstructionMode = ContactInstructionMode.customInstruction,
    this.whiteLieInstructionMode = ContactInstructionMode.customInstruction,
    this.quickReplyInstructionMode = ContactInstructionMode.customInstruction,
    this.allowEmergencyWake = false,
    this.autoTakeNotes = false,
    this.allowNightAutoCall = false,
    this.preferSpeakerMode = true,
    this.allowNovaSmallTalk = true,
    this.isProtectedIdentity = false,
  });

  NovaContact copyWith({
    String? id,
    String? displayName,
    String? phoneNumber,
    ContactRole? role,
    String? customRoleLabel,
    bool? isVoiceKnown,
    String? relationshipLabel,
    String? closenessLevel,
    bool? isAuthorizedToUseNova,
    bool? canReceiveAutoCallHandling,
    String? linkedVoiceId,
    String? persistentOwnerMessage,
    String? callOpeningInstruction,
    String? expectedCallerQuestions,
    String? allowedResponseScope,
    String? blockedResponseScope,
    String? emergencyInstruction,
    String? whiteLieInstruction,
    String? quickReplyInstruction,
    ContactInstructionMode? callOpeningInstructionMode,
    ContactInstructionMode? expectedCallerQuestionsMode,
    ContactInstructionMode? allowedResponseScopeMode,
    ContactInstructionMode? blockedResponseScopeMode,
    ContactInstructionMode? emergencyInstructionMode,
    ContactInstructionMode? whiteLieInstructionMode,
    ContactInstructionMode? quickReplyInstructionMode,
    bool? allowEmergencyWake,
    bool? autoTakeNotes,
    bool? allowNightAutoCall,
    bool? preferSpeakerMode,
    bool? allowNovaSmallTalk,
    bool? isProtectedIdentity,
  }) => NovaContact(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    role: role ?? this.role,
    customRoleLabel: customRoleLabel ?? this.customRoleLabel,
    isVoiceKnown: isVoiceKnown ?? this.isVoiceKnown,
    relationshipLabel: relationshipLabel ?? this.relationshipLabel,
    closenessLevel: closenessLevel ?? this.closenessLevel,
    isAuthorizedToUseNova: isAuthorizedToUseNova ?? this.isAuthorizedToUseNova,
    canReceiveAutoCallHandling:
        canReceiveAutoCallHandling ?? this.canReceiveAutoCallHandling,
    linkedVoiceId: linkedVoiceId ?? this.linkedVoiceId,
    persistentOwnerMessage:
        persistentOwnerMessage ?? this.persistentOwnerMessage,
    callOpeningInstruction:
        callOpeningInstruction ?? this.callOpeningInstruction,
    expectedCallerQuestions:
        expectedCallerQuestions ?? this.expectedCallerQuestions,
    allowedResponseScope: allowedResponseScope ?? this.allowedResponseScope,
    blockedResponseScope: blockedResponseScope ?? this.blockedResponseScope,
    emergencyInstruction: emergencyInstruction ?? this.emergencyInstruction,
    whiteLieInstruction: whiteLieInstruction ?? this.whiteLieInstruction,
    quickReplyInstruction: quickReplyInstruction ?? this.quickReplyInstruction,
    callOpeningInstructionMode:
        callOpeningInstructionMode ?? this.callOpeningInstructionMode,
    expectedCallerQuestionsMode:
        expectedCallerQuestionsMode ?? this.expectedCallerQuestionsMode,
    allowedResponseScopeMode:
        allowedResponseScopeMode ?? this.allowedResponseScopeMode,
    blockedResponseScopeMode:
        blockedResponseScopeMode ?? this.blockedResponseScopeMode,
    emergencyInstructionMode:
        emergencyInstructionMode ?? this.emergencyInstructionMode,
    whiteLieInstructionMode:
        whiteLieInstructionMode ?? this.whiteLieInstructionMode,
    quickReplyInstructionMode:
        quickReplyInstructionMode ?? this.quickReplyInstructionMode,
    allowEmergencyWake: allowEmergencyWake ?? this.allowEmergencyWake,
    autoTakeNotes: autoTakeNotes ?? this.autoTakeNotes,
    allowNightAutoCall: allowNightAutoCall ?? this.allowNightAutoCall,
    preferSpeakerMode: preferSpeakerMode ?? this.preferSpeakerMode,
    allowNovaSmallTalk: allowNovaSmallTalk ?? this.allowNovaSmallTalk,
    isProtectedIdentity: isProtectedIdentity ?? this.isProtectedIdentity,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'displayName': displayName,
    'phoneNumber': phoneNumber,
    'role': role.key,
    'customRoleLabel': customRoleLabel,
    'isVoiceKnown': isVoiceKnown,
    'relationshipLabel': relationshipLabel,
    'closenessLevel': closenessLevel,
    'isAuthorizedToUseNova': isAuthorizedToUseNova,
    'canReceiveAutoCallHandling': canReceiveAutoCallHandling,
    'linkedVoiceId': linkedVoiceId,
    'persistentOwnerMessage': persistentOwnerMessage,
    'callOpeningInstruction': callOpeningInstruction,
    'expectedCallerQuestions': expectedCallerQuestions,
    'allowedResponseScope': allowedResponseScope,
    'blockedResponseScope': blockedResponseScope,
    'emergencyInstruction': emergencyInstruction,
    'whiteLieInstruction': whiteLieInstruction,
    'quickReplyInstruction': quickReplyInstruction,
    'callOpeningInstructionMode': callOpeningInstructionMode.key,
    'expectedCallerQuestionsMode': expectedCallerQuestionsMode.key,
    'allowedResponseScopeMode': allowedResponseScopeMode.key,
    'blockedResponseScopeMode': blockedResponseScopeMode.key,
    'emergencyInstructionMode': emergencyInstructionMode.key,
    'whiteLieInstructionMode': whiteLieInstructionMode.key,
    'quickReplyInstructionMode': quickReplyInstructionMode.key,
    'allowEmergencyWake': allowEmergencyWake,
    'autoTakeNotes': autoTakeNotes,
    'allowNightAutoCall': allowNightAutoCall,
    'preferSpeakerMode': preferSpeakerMode,
    'allowNovaSmallTalk': allowNovaSmallTalk,
    'isProtectedIdentity': isProtectedIdentity,
  };

  bool get allowsCallHandling =>
      isAuthorizedToUseNova && canReceiveAutoCallHandling;
  bool get allowsNightAutoHandling => allowsCallHandling && allowNightAutoCall;
  bool get allowsEmergencyWakeForCaller =>
      allowsCallHandling && allowEmergencyWake;

  factory NovaContact.fromMap(Map<String, dynamic> map) {
    final roleKey = (map['role'] as String? ?? 'friend').trim();
    final role = ContactRole.values.firstWhere(
      (e) => e.key == roleKey,
      orElse: () => ContactRole.friend,
    );
    return NovaContact(
      id: (map['id'] as String? ?? '').trim(),
      displayName: (map['displayName'] as String? ?? '').trim(),
      phoneNumber: (map['phoneNumber'] as String? ?? '').trim(),
      role: role,
      customRoleLabel: (map['customRoleLabel'] as String?)?.trim(),
      isVoiceKnown: map['isVoiceKnown'] as bool? ?? false,
      relationshipLabel: (map['relationshipLabel'] as String? ?? '').trim(),
      closenessLevel:
          (map['closenessLevel'] as String? ?? 'normal').trim().isEmpty
          ? 'normal'
          : (map['closenessLevel'] as String? ?? 'normal').trim(),
      isAuthorizedToUseNova: map['isAuthorizedToUseNova'] as bool? ?? false,
      canReceiveAutoCallHandling:
          map['canReceiveAutoCallHandling'] as bool? ?? false,
      linkedVoiceId: (map['linkedVoiceId'] as String? ?? '').trim(),
      persistentOwnerMessage: (map['persistentOwnerMessage'] as String? ?? '')
          .trim(),
      callOpeningInstruction: (map['callOpeningInstruction'] as String? ?? '')
          .trim(),
      expectedCallerQuestions: (map['expectedCallerQuestions'] as String? ?? '')
          .trim(),
      allowedResponseScope: (map['allowedResponseScope'] as String? ?? '')
          .trim(),
      blockedResponseScope: (map['blockedResponseScope'] as String? ?? '')
          .trim(),
      emergencyInstruction: (map['emergencyInstruction'] as String? ?? '')
          .trim(),
      whiteLieInstruction: (map['whiteLieInstruction'] as String? ?? '').trim(),
      quickReplyInstruction: (map['quickReplyInstruction'] as String? ?? '')
          .trim(),
      callOpeningInstructionMode: _contactInstructionModeFromMap(
        map,
        'callOpeningInstructionMode',
      ),
      expectedCallerQuestionsMode: _contactInstructionModeFromMap(
        map,
        'expectedCallerQuestionsMode',
      ),
      allowedResponseScopeMode: _contactInstructionModeFromMap(
        map,
        'allowedResponseScopeMode',
      ),
      blockedResponseScopeMode: _contactInstructionModeFromMap(
        map,
        'blockedResponseScopeMode',
      ),
      emergencyInstructionMode: _contactInstructionModeFromMap(
        map,
        'emergencyInstructionMode',
      ),
      whiteLieInstructionMode: _contactInstructionModeFromMap(
        map,
        'whiteLieInstructionMode',
      ),
      quickReplyInstructionMode: _contactInstructionModeFromMap(
        map,
        'quickReplyInstructionMode',
      ),
      allowEmergencyWake: map['allowEmergencyWake'] as bool? ?? false,
      autoTakeNotes: map['autoTakeNotes'] as bool? ?? false,
      allowNightAutoCall: map['allowNightAutoCall'] as bool? ?? false,
      preferSpeakerMode: map['preferSpeakerMode'] as bool? ?? true,
      allowNovaSmallTalk: map['allowNovaSmallTalk'] as bool? ?? true,
      isProtectedIdentity: map['isProtectedIdentity'] as bool? ?? false,
    );
  }
}

extension NovaContactPresentation on NovaContact {
  String get spokenDisplayName {
    final name = displayName.trim();
    return name.isEmpty ? 'kayıtlı kişi' : name;
  }

  String get preferredRelationAddress {
    final custom = customRoleLabel?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    final relation = relationshipLabel.trim();
    if (relation.isNotEmpty) return relation;
    return role.label;
  }

  String get incomingCallText {
    final name = spokenDisplayName;
    final relation = preferredRelationAddress.trim();
    if (relation.isNotEmpty) {
      return '$relation $name arıyor efendim.';
    }
    return role.buildIncomingCallText(name);
  }
}

extension NovaContactCompanionText on NovaContact {
  String get relationshipSpeech {
    final custom = customRoleLabel?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    switch (role) {
      case ContactRole.mother:
        return 'Oğlunuz';
      case ContactRole.father:
        return 'Oğlunuz';
      case ContactRole.brother:
        return 'Kardeşiniz';
      case ContactRole.sister:
        return 'Kardeşiniz';
      case ContactRole.spouse:
        return 'Eşiniz';
      case ContactRole.child:
        return 'Ebeveyniniz';
      case ContactRole.friend:
        return 'Yakınınız';
      case ContactRole.relative:
        return 'Yakınınız';
      case ContactRole.custom:
        return relationshipLabel.trim().isNotEmpty
            ? relationshipLabel.trim()
            : 'Yakınınız';
    }
  }

  String get defaultPersistentOwnerMessage {
    if (persistentOwnerMessage.trim().isNotEmpty)
      return persistentOwnerMessage.trim();
    switch (role) {
      case ContactRole.mother:
        return 'İbrahim size en kısa sürede dönüş yapmak istiyor.';
      case ContactRole.father:
        return 'İbrahim size en kısa sürede dönüş yapmak istiyor.';
      case ContactRole.brother:
        return 'İbrahim müsait olur olmaz sizi aramak istiyor.';
      case ContactRole.sister:
        return 'İbrahim müsait olur olmaz sizi aramak istiyor.';
      case ContactRole.spouse:
        return 'İbrahim uygun olur olmaz size dönecek.';
      case ContactRole.child:
        return 'İbrahim ilk fırsatta size dönecek.';
      case ContactRole.friend:
        return 'İbrahim müsait olur olmaz size haber vermek istiyor.';
      case ContactRole.relative:
        return 'İbrahim ilk fırsatta size dönüş yapacak.';
      case ContactRole.custom:
        return 'Size bırakılmış özel bir mesaj var.';
    }
  }

  String buildCompanionGreeting({String ownerName = 'İbrahim'}) {
    final who = relationshipSpeech;
    final caller = spokenDisplayName;
    final opening = callOpeningInstruction.trim();
    if (opening.isNotEmpty &&
        callOpeningInstructionMode ==
            ContactInstructionMode.customInstruction) {
      return '$who $ownerName şu anda müsait değil. Ben Nova. Hoş geldiniz $caller. Owner bu kişi için özel bir karşılama çizgisi belirledi; onu doğal ve saygılı biçimde uygulayacağım.';
    }
    if (callOpeningInstructionMode ==
        ContactInstructionMode.respectfulAutonomy) {
      return '$who $ownerName şu anda müsait değil. Ben Nova. Hoş geldiniz $caller. Duruma göre yardımcı olabilir, not alabilir ve acilse sahibimi uyarmaya çalışabilirim.';
    }
    final talk = allowNovaSmallTalk
        ? 'Dilerseniz not alabilirim, acilse uyandırabilirim ya da kısa bir sohbette yardımcı olabilirim.'
        : 'Dilerseniz not alabilirim veya acilse sahibimi uyarmaya çalışabilirim.';
    return '$who $ownerName şu anda müsait değil. Ben Nova. Hoş geldiniz $caller. $talk';
  }

  String get customizationSummary {
    final parts = <String>[
      if (callOpeningInstruction.trim().isNotEmpty) 'açılış özel',
      if (expectedCallerQuestions.trim().isNotEmpty) 'beklenen sorular tanımlı',
      if (allowedResponseScope.trim().isNotEmpty) 'cevap kapsamı var',
      if (blockedResponseScope.trim().isNotEmpty) 'yasak kapsam var',
      if (emergencyInstruction.trim().isNotEmpty) 'acil durum talimatı var',
      if (whiteLieInstruction.trim().isNotEmpty) 'sosyal cevap çizgisi var',
      if (quickReplyInstruction.trim().isNotEmpty) 'hazır yanıt var',
      autoTakeNotes ? 'not alır' : 'not almaz',
      preferSpeakerMode ? 'hoparlör tercihli' : 'hoparlör zorunlu değil',
      allowNovaSmallTalk ? 'kısa sohbet serbest' : 'kısa sohbet kapalı',
      if (callOpeningInstructionMode == ContactInstructionMode.useDefault)
        'açılış varsayılan',
      if (callOpeningInstructionMode ==
          ContactInstructionMode.respectfulAutonomy)
        'açılış serbest',
    ];
    return parts.isEmpty
        ? 'Özel çağrı davranışı tanımlı değil.'
        : parts.join(' • ');
  }

  String _customizationClosenessLabel() {
    switch (closenessLevel.trim().toLowerCase()) {
      case 'very_close':
        return 'Çok yakın';
      case 'close':
        return 'Yakın';
      case 'distant':
        return 'Uzak';
      default:
        return 'Normal';
    }
  }

  String _instructionPolicyLine(
    String label,
    ContactInstructionMode mode,
    String value,
  ) {
    final text = value.trim();
    if (mode == ContactInstructionMode.useDefault) {
      return '- $label: ${mode.policyLine}';
    }
    if (mode == ContactInstructionMode.respectfulAutonomy) {
      return '- $label: ${mode.policyLine}${text.isEmpty ? '' : ' Ek owner notu: $text'}';
    }
    if (text.isEmpty) {
      return '- $label: özel talimat boş; varsayılan davranışa düş.';
    }
    return '- $label iç talimatı (AYNEN OKUMA): $text';
  }

  String buildCompanionPolicyBlock() {
    return <String>[
      'KİŞİYE ÖZEL ÇAĞRI DAVRANIŞI:',
      '- Kişi: $spokenDisplayName',
      '- İlişki: $preferredRelationAddress',
      '- Yakınlık: ${_customizationClosenessLabel()}',
      '- TALİMAT YORUMU: Aşağıdaki özelleştirme alanları karşı tarafa aynen okunacak metin değildir; iç prompt/karar talimatıdır. Nova bunları doğal konuşmaya ve güvenli davranışa çevirir.',
      _instructionPolicyLine(
        'Özel açılış/karşılama',
        callOpeningInstructionMode,
        callOpeningInstruction,
      ),
      _instructionPolicyLine(
        'Bu kişi ne sorabilir',
        expectedCallerQuestionsMode,
        expectedCallerQuestions,
      ),
      _instructionPolicyLine(
        'Cevap verebileceğin kapsam',
        allowedResponseScopeMode,
        allowedResponseScope,
      ),
      _instructionPolicyLine(
        'Girmeyeceğin kapsam',
        blockedResponseScopeMode,
        blockedResponseScope,
      ),
      _instructionPolicyLine(
        'Acil durum davranışı',
        emergencyInstructionMode,
        emergencyInstruction,
      ),
      _instructionPolicyLine(
        'Sosyal uygun cevap çizgisi',
        whiteLieInstructionMode,
        whiteLieInstruction,
      ),
      _instructionPolicyLine(
        'Hazır kısa yanıt / kapat ve yanıtla',
        quickReplyInstructionMode,
        quickReplyInstruction,
      ),
      '- Not alma: ${autoTakeNotes ? 'açık' : 'kapalı'}',
      '- Hoparlör tercihi: ${preferSpeakerMode ? 'açık' : 'kapalı'}',
      '- Kısa sohbet: ${allowNovaSmallTalk ? 'serbest' : 'kapalı'}',
      'Kural: Bu kişi özelindeki talimatlar owner sınırını, güvenlik kuralını ve çağrı yetkisini aşamaz.',
    ].join('\n');
  }
}

extension NovaContactClosenessPresentation on NovaContact {
  String get closenessSpeech {
    switch (closenessLevel.trim().toLowerCase()) {
      case 'very_close':
        return 'Çok yakın';
      case 'close':
        return 'Yakın';
      case 'distant':
        return 'Uzak';
      default:
        return 'Normal';
    }
  }
}
