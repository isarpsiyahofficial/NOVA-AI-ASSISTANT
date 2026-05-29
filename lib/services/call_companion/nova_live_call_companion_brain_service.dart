// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
// NOVA_ASR_STT_AUTHORITY_MARKER: speakerVoiceId ownerConfidence relationshipLabel routed_to_SingleBrainAuthority deterministic_bridge_dto_only.
// Generated strengthening patch for digital-human voice-first behavior.
import 'dart:math';

enum NovaCompanionHandoffIntent {
  none,
  joinConversation,
  takeOver,
  handBack,
  stayNearby,
  summarizeForOwner,
  answerOnBehalf,
  relayOnly,
}

enum NovaCompanionUrgencyBand { low, medium, high, wakeOwner }

class NovaCompanionDirectiveAnalysis {
  final NovaCompanionHandoffIntent handoffIntent;
  final NovaCompanionUrgencyBand urgencyBand;
  final bool mentionsCompanion;
  final bool voiceFirst;
  final bool shouldJoinLive;
  final bool shouldTakeOver;
  final bool shouldHandBack;
  final bool shouldRelayVerbatim;
  final bool shouldRelayWithMeaning;
  final bool shouldAskClarifyingQuestion;
  final bool shouldUseSpeakerphone;
  final bool shouldMuteOwnerMic;
  final bool shouldKeepListeningForOverride;
  final bool shouldPreserveCallContext;
  final String extractedInstruction;
  final String suggestedReply;
  final List<String> matchedCues;
  final Map<String, double> scores;

  const NovaCompanionDirectiveAnalysis({
    required this.handoffIntent,
    required this.urgencyBand,
    required this.mentionsCompanion,
    required this.voiceFirst,
    required this.shouldJoinLive,
    required this.shouldTakeOver,
    required this.shouldHandBack,
    required this.shouldRelayVerbatim,
    required this.shouldRelayWithMeaning,
    required this.shouldAskClarifyingQuestion,
    required this.shouldUseSpeakerphone,
    required this.shouldMuteOwnerMic,
    required this.shouldKeepListeningForOverride,
    required this.shouldPreserveCallContext,
    required this.extractedInstruction,
    required this.suggestedReply,
    required this.matchedCues,
    required this.scores,
  });
}

class NovaCompanionRemoteTurnAnalysis {
  final String dominantEmotion;
  final double urgency;
  final double warmth;
  final double conflict;
  final double fear;
  final double sadness;
  final double formality;
  final bool requestsWake;
  final bool requestsOwner;
  final bool containsImportantNote;
  final bool soundsFamilyLike;
  final bool soundsEscalating;
  final List<String> matchedSignals;
  final Map<String, double> scores;

  const NovaCompanionRemoteTurnAnalysis({
    required this.dominantEmotion,
    required this.urgency,
    required this.warmth,
    required this.conflict,
    required this.fear,
    required this.sadness,
    required this.formality,
    required this.requestsWake,
    required this.requestsOwner,
    required this.containsImportantNote,
    required this.soundsFamilyLike,
    required this.soundsEscalating,
    required this.matchedSignals,
    required this.scores,
  });
}

class NovaCompanionReplyPlan {
  final String stance;
  final String opening;
  final String body;
  final String closing;
  final bool shouldJoinLive;
  final bool shouldTakeOver;
  final bool shouldHandBack;
  final bool shouldWakeOwner;
  final bool shouldStoreNote;
  final bool shouldAskPermissionToWake;
  final bool shouldAskForTimeWindow;
  final bool shouldKeepSpeakerOn;
  final bool shouldKeepMicMuted;
  final bool shouldOfferSummaryToOwner;
  final List<String> reasons;
  final Map<String, dynamic> metadata;

  const NovaCompanionReplyPlan({
    required this.stance,
    required this.opening,
    required this.body,
    required this.closing,
    required this.shouldJoinLive,
    required this.shouldTakeOver,
    required this.shouldHandBack,
    required this.shouldWakeOwner,
    required this.shouldStoreNote,
    required this.shouldAskPermissionToWake,
    required this.shouldAskForTimeWindow,
    required this.shouldKeepSpeakerOn,
    required this.shouldKeepMicMuted,
    required this.shouldOfferSummaryToOwner,
    required this.reasons,
    required this.metadata,
  });

  String get spokenText => '';

  Map<String, dynamic> toStructuredContext() => <String, dynamic>{
    'stance': stance,
    'shouldJoinLive': shouldJoinLive,
    'shouldTakeOver': shouldTakeOver,
    'shouldHandBack': shouldHandBack,
    'shouldWakeOwner': shouldWakeOwner,
    'shouldStoreNote': shouldStoreNote,
    'shouldAskPermissionToWake': shouldAskPermissionToWake,
    'shouldAskForTimeWindow': shouldAskForTimeWindow,
    'shouldKeepSpeakerOn': shouldKeepSpeakerOn,
    'shouldKeepMicMuted': shouldKeepMicMuted,
    'shouldOfferSummaryToOwner': shouldOfferSummaryToOwner,
    'reasons': reasons,
    'metadata': metadata,
  };
}

class NovaLiveCallCompanionBrainService {
  const NovaLiveCallCompanionBrainService();

  static const List<String> _joinCues = <String>[
    'nova buraya gel',
    'buraya gel',
    'sohbete katil',
    'sohbete katıl',
    'bize katil',
    'bize katıl',
    'sohbete gir',
    'yardim et',
    'yardım et',
  ];

  static const List<String> _takeOverCues = <String>[
    'sohbeti devral',
    'devral',
    'benim icin konus',
    'benim için konuş',
    'telefonu sen ac',
    'telefonu sen aç',
    'sen konus',
    'sen konuş',
    'hoparlore ver ve konus',
    'hoparlöre ver ve konuş',
  ];

  static const List<String> _handBackCues = <String>[
    'sohbeti devret',
    'devret',
    'bana birak',
    'bana bırak',
    'beni bagla',
    'beni bağla',
    'mikrofonu bana ver',
    'ben devralayim',
    'ben devralayım',
  ];

  static const List<String> _wakeCues = <String>[
    'uyandir',
    'uyandır',
    'hemen uyandir',
    'hemen uyandır',
    'acil uyandir',
    'acil uyandır',
    'haber ver',
    'uyansin',
    'uyansın',
  ];

  static const List<String> _relayMeaningCues = <String>[
    'soyledigimi acikla',
    'söylediğimi açıkla',
    'detaylandir',
    'detaylandır',
    'insan gibi aktar',
    'anlamiyla aktar',
    'anlamıyla aktar',
    'duzgun aktar',
    'nazikce anlat',
    'nazikçe anlat',
  ];

  static const List<String> _relayVerbatimCues = <String>[
    'aynen soyle',
    'aynen söyle',
    'kelimesi kelimesine',
    'sozcugu sozcugune',
    'sözcüğü sözcüğüne',
    'bunu de',
    'bunu söyle',
  ];

  static const List<String> _speakerCues = <String>[
    'hoparlore ver',
    'hoparlöre ver',
    'hoparloru ac',
    'hoparlörü aç',
    'dis ses',
    'dış ses',
  ];

  static const List<String> _muteCues = <String>[
    'mikrofonu kapat',
    'beni sustur',
    'beni sessize al',
    'beni mute et',
    'yalniz sen konus',
    'yalnız sen konuş',
  ];

  static const List<String> _overrideCues = <String>[
    'beni dinle',
    'beni de duy',
    'beni duyarsan devret',
    'override',
    'devral dersem',
  ];

  static const List<String> _familyWarmthCues = <String>[
    'anne',
    'annem',
    'baba',
    'babam',
    'esim',
    'eşim',
    'canim',
    'canım',
    'abim',
    'kardesim',
    'kardeşim',
  ];

  static const List<String> _urgencyCues = <String>[
    'acil',
    'hemen',
    'simdi',
    'şimdi',
    'bekleyemez',
    'bekleyemem',
    'hayati',
    'hayati',
    'panik',
    'yardim',
    'yardım',
    'cok onemli',
    'çok önemli',
  ];

  static const List<String> _noteCues = <String>[
    'not birak',
    'not bırak',
    'mesaj birak',
    'mesaj bırak',
    'ilet',
    'haber ver',
    'unutma',
    'hatirlat',
    'hatırlat',
  ];

  static const List<String> _conflictCues = <String>[
    'sinirli',
    'kizgin',
    'kızgın',
    'ofkeli',
    'öfkeliyim',
    'yeter',
    'rezalet',
    'sacmalik',
    'saçmalık',
    'bekletme',
  ];

  static const List<String> _fearCues = <String>[
    'korkuyorum',
    'endiseliyim',
    'endişeliyim',
    'panik',
    'tedirginim',
    'gerginim',
  ];

  static const List<String> _sadCues = <String>[
    'uzgunum',
    'üzgünüm',
    'kötüyüm',
    'yalnizim',
    'yalnızım',
    'moralim bozuk',
  ];

  static const List<String> _warmCues = <String>[
    'musaitsen',
    'müsaitsen',
    'rica etsem',
    'uygunsa',
    'canim',
    'canım',
    'tatlim',
    'tatlım',
    'güzelce',
  ];

  static const List<String> _formalCues = <String>[
    'müsait olunca',
    'uygun oldugunda',
    'uygun olduğunda',
    'sayin',
    'sayın',
    'rica ederim',
    'lutfen',
    'lütfen',
  ];

  static const List<String> _ownerRequestCues = <String>[
    'ibrahimle gorusebilir miyim',
    'ibrahimle görüşebilir miyim',
    'patronunla gorusebilir miyim',
    'kendisiyle gorusebilir miyim',
    'onu uyandir',
    'onu uyandır',
  ];

  NovaCompanionDirectiveAnalysis analyzeOwnerDirective(
    String raw, {
    Map<String, dynamic> context = const <String, dynamic>{},
  }) {
    final text = _n(raw);
    final matched = <String>[];
    final scores = <String, double>{
      'join': _cueScore(text, _joinCues, matched, 'join'),
      'takeOver': _cueScore(text, _takeOverCues, matched, 'takeOver'),
      'handBack': _cueScore(text, _handBackCues, matched, 'handBack'),
      'wake': _cueScore(text, _wakeCues, matched, 'wake'),
      'relayMeaning': _cueScore(
        text,
        _relayMeaningCues,
        matched,
        'relayMeaning',
      ),
      'relayVerbatim': _cueScore(
        text,
        _relayVerbatimCues,
        matched,
        'relayVerbatim',
      ),
      'speaker': _cueScore(text, _speakerCues, matched, 'speaker'),
      'mute': _cueScore(text, _muteCues, matched, 'mute'),
      'override': _cueScore(text, _overrideCues, matched, 'override'),
      'urgency': _cueScore(text, _urgencyCues, matched, 'urgency'),
      'note': _cueScore(text, _noteCues, matched, 'note'),
    };
    final mentionsCompanion = text.contains('nova') || text.contains('nova');
    final shouldTakeOver =
        scores['takeOver']! >= 0.22 ||
        (mentionsCompanion && text.contains('konus'));
    final shouldHandBack = scores['handBack']! >= 0.20;
    final shouldJoinLive = scores['join']! >= 0.16 || shouldTakeOver;
    final shouldRelayVerbatim =
        scores['relayVerbatim']! > scores['relayMeaning']! &&
        scores['relayVerbatim']! >= 0.15;
    final shouldRelayWithMeaning =
        scores['relayMeaning']! >= scores['relayVerbatim']! ||
        text.contains('insan gibi');
    final shouldUseSpeakerphone = scores['speaker']! >= 0.14 || shouldTakeOver;
    final shouldMuteOwnerMic = scores['mute']! >= 0.14 || shouldTakeOver;
    final shouldAskClarifyingQuestion =
        !shouldHandBack &&
        !shouldTakeOver &&
        text.contains('söyle') &&
        _extractInstruction(text).isEmpty;
    final urgencyScore = _clamp(
      scores['urgency']! +
          scores['wake']! * 0.7 +
          (text.contains('acil') ? 0.12 : 0),
    );
    final urgencyBand = urgencyScore >= 0.65
        ? NovaCompanionUrgencyBand.wakeOwner
        : urgencyScore >= 0.38
        ? NovaCompanionUrgencyBand.high
        : urgencyScore >= 0.18
        ? NovaCompanionUrgencyBand.medium
        : NovaCompanionUrgencyBand.low;
    final handoffIntent = shouldHandBack
        ? NovaCompanionHandoffIntent.handBack
        : shouldTakeOver
        ? NovaCompanionHandoffIntent.takeOver
        : shouldJoinLive
        ? NovaCompanionHandoffIntent.joinConversation
        : NovaCompanionHandoffIntent.none;
    final suggestedReply = shouldHandBack
        ? 'Kontrolü size bırakıyorum efendim.'
        : shouldTakeOver
        ? 'Çağrıya katılıp konuşmayı devralıyorum efendim.'
        : shouldJoinLive
        ? 'Çağrıya katılıyorum efendim, gerektiğinde devralabilirim.'
        : shouldAskClarifyingQuestion
        ? 'Ne söylememi istediğinizi bir cümle daha net duymam gerekiyor efendim.'
        : 'Çağrıyı dinleyip uygun anda destek verebilirim efendim.';
    return NovaCompanionDirectiveAnalysis(
      handoffIntent: handoffIntent,
      urgencyBand: urgencyBand,
      mentionsCompanion: mentionsCompanion,
      voiceFirst: true,
      shouldJoinLive: shouldJoinLive,
      shouldTakeOver: shouldTakeOver,
      shouldHandBack: shouldHandBack,
      shouldRelayVerbatim: shouldRelayVerbatim,
      shouldRelayWithMeaning: shouldRelayWithMeaning,
      shouldAskClarifyingQuestion: shouldAskClarifyingQuestion,
      shouldUseSpeakerphone: shouldUseSpeakerphone,
      shouldMuteOwnerMic: shouldMuteOwnerMic,
      shouldKeepListeningForOverride: true,
      shouldPreserveCallContext: true,
      extractedInstruction: _extractInstruction(text),
      suggestedReply: suggestedReply,
      matchedCues: matched,
      scores: scores,
    );
  }

  NovaCompanionRemoteTurnAnalysis analyzeRemoteTurn(
    String raw, {
    String knownRelation = '',
    Map<String, dynamic> context = const <String, dynamic>{},
  }) {
    final text = _n(raw);
    final matched = <String>[];
    final urgency = _clamp(
      _cueScore(text, _urgencyCues, matched, 'urgency') +
          (RegExp(r'!|\?\?').hasMatch(text) ? 0.08 : 0),
    );
    final conflict = _clamp(
      _cueScore(text, _conflictCues, matched, 'conflict'),
    );
    final fear = _clamp(_cueScore(text, _fearCues, matched, 'fear'));
    final sadness = _clamp(_cueScore(text, _sadCues, matched, 'sadness'));
    final warmth = _clamp(
      _cueScore(text, _warmCues, matched, 'warmth') +
          _relationWarmthBoost(knownRelation),
    );
    final formality = _clamp(
      _cueScore(text, _formalCues, matched, 'formality'),
    );
    final ownerNeed = _clamp(
      _cueScore(text, _ownerRequestCues, matched, 'ownerNeed'),
    );
    final noteScore = _clamp(_cueScore(text, _noteCues, matched, 'note'));
    final requestsWake =
        _cueScore(text, _wakeCues, matched, 'wake') >= 0.15 ||
        (urgency >= 0.45 && ownerNeed >= 0.12);
    final requestsOwner = ownerNeed >= 0.12 || text.contains('ibrahim');
    final containsImportantNote =
        noteScore >= 0.15 ||
        text.contains('unutma') ||
        text.contains('hatirlat');
    final soundsFamilyLike =
        _cueScore(text, _familyWarmthCues, matched, 'family') >= 0.15 ||
        knownRelation.trim().isNotEmpty;
    final soundsEscalating =
        urgency >= 0.45 || conflict >= 0.35 || fear >= 0.30;
    final dominantEmotion = _dominantEmotion({
      'urgent': urgency,
      'angry': conflict,
      'fearful': fear,
      'sad': sadness,
      'warm': warmth,
      'formal': formality,
    });
    return NovaCompanionRemoteTurnAnalysis(
      dominantEmotion: dominantEmotion,
      urgency: urgency,
      warmth: warmth,
      conflict: conflict,
      fear: fear,
      sadness: sadness,
      formality: formality,
      requestsWake: requestsWake,
      requestsOwner: requestsOwner,
      containsImportantNote: containsImportantNote,
      soundsFamilyLike: soundsFamilyLike,
      soundsEscalating: soundsEscalating,
      matchedSignals: matched,
      scores: <String, double>{
        'urgency': urgency,
        'warmth': warmth,
        'conflict': conflict,
        'fear': fear,
        'sadness': sadness,
        'formality': formality,
        'ownerNeed': ownerNeed,
        'note': noteScore,
      },
    );
  }

  NovaCompanionReplyPlan buildReplyPlan({
    required NovaCompanionDirectiveAnalysis directive,
    required NovaCompanionRemoteTurnAnalysis remote,
    required String ownerName,
    required String callerName,
    required String relationLabel,
    String ownerAlias = 'patronum',
    String explicitInstruction = '',
  }) {
    final reasons = <String>[];
    final String ownerRef = relationLabel.trim().isEmpty
        ? ownerAlias
        : relationLabel.trim();
    if (directive.shouldTakeOver) reasons.add('owner_takeover_requested');
    if (directive.shouldHandBack) reasons.add('owner_handback_requested');
    if (remote.requestsWake) reasons.add('remote_requested_wake');
    if (remote.containsImportantNote) reasons.add('important_note_detected');
    if (remote.soundsFamilyLike) reasons.add('family_like_context');
    if (remote.soundsEscalating) reasons.add('escalation_detected');

    final shouldWakeOwner =
        directive.urgencyBand == NovaCompanionUrgencyBand.wakeOwner ||
        remote.requestsWake ||
        (remote.requestsOwner && remote.urgency >= 0.52);
    final shouldStoreNote =
        remote.containsImportantNote || explicitInstruction.trim().isNotEmpty;
    final shouldAskPermissionToWake =
        remote.requestsOwner && !shouldWakeOwner && remote.urgency < 0.52;
    final shouldAskForTimeWindow =
        remote.requestsOwner && !shouldWakeOwner && remote.formality >= 0.18;

    // V4 detox: companion planning may compute structured decisions, but it must
    // not produce deterministic final speech. The caller must route the
    // structured plan through the AI/CoreTurn final response path.
    const opening = '';
    const body = '';
    const closing = '';

    return NovaCompanionReplyPlan(
      stance: remote.dominantEmotion,
      opening: opening,
      body: body,
      closing: closing,
      shouldJoinLive: directive.shouldJoinLive,
      shouldTakeOver: directive.shouldTakeOver,
      shouldHandBack: directive.shouldHandBack,
      shouldWakeOwner: shouldWakeOwner,
      shouldStoreNote: shouldStoreNote,
      shouldAskPermissionToWake: shouldAskPermissionToWake,
      shouldAskForTimeWindow: shouldAskForTimeWindow,
      shouldKeepSpeakerOn: directive.shouldUseSpeakerphone,
      shouldKeepMicMuted: directive.shouldMuteOwnerMic,
      shouldOfferSummaryToOwner: true,
      reasons: reasons,
      metadata: <String, dynamic>{
        'callerName': callerName,
        'relationLabel': relationLabel,
        'dominantEmotion': remote.dominantEmotion,
        'ownerAlias': ownerRef,
        'voiceFirst': directive.voiceFirst,
        'meaningRelay': directive.shouldRelayWithMeaning,
        'verbatimRelay': directive.shouldRelayVerbatim,
      },
    );
  }

  static const List<String> _apologyPhrases = <String>[];

  static const List<String> _empathyPhrases = <String>[];

  static const List<String> _familyPhrases = <String>[];

  static const List<String> _formalPhrases = <String>[];

  static const List<String> _wakePhrases = <String>[];

  static const List<String> _notePhrases = <String>[];

  String buildOwnerSummary({
    required String callerName,
    required String relationLabel,
    required String transcript,
    required NovaCompanionRemoteTurnAnalysis remote,
  }) {
    final prefix = relationLabel.trim().isEmpty
        ? callerName
        : '$callerName ($relationLabel)';
    final mood = remote.dominantEmotion;
    final importance = remote.requestsWake
        ? 'uyandırma seviyesi'
        : remote.containsImportantNote
        ? 'önemli not'
        : 'normal';
    final compact = transcript.trim().replaceAll(RegExp(r'\s+'), ' ');
    return '$prefix aradı; duygu=$mood; önem=$importance; özet=$compact';
  }

  String buildDeliveryReminderLine({
    required String callerName,
    required NovaCompanionRemoteTurnAnalysis remote,
  }) {
    // V4 detox: delivery reminders are structured call state, not deterministic
    // spoken lines. Final user-facing speech must be generated by the AI turn.
    return '';
  }

  Map<String, dynamic> buildCompanionRuntimeHints({
    required NovaCompanionDirectiveAnalysis directive,
    required NovaCompanionRemoteTurnAnalysis remote,
    required String activeMode,
  }) {
    return <String, dynamic>{
      'mode': activeMode,
      'joinLiveConversation': directive.shouldJoinLive,
      'takeOverConversation': directive.shouldTakeOver,
      'handBackConversation': directive.shouldHandBack,
      'keepSpeakerOn': directive.shouldUseSpeakerphone,
      'keepOwnerMicMuted': directive.shouldMuteOwnerMic,
      'listenForOverride': directive.shouldKeepListeningForOverride,
      'callerEmotion': remote.dominantEmotion,
      'callerUrgency': remote.urgency,
      'callerNeedsWake': remote.requestsWake,
      'callerRequestedOwner': remote.requestsOwner,
      'noteImportance': remote.containsImportantNote,
    };
  }

  String _openingForRemote({
    required NovaCompanionRemoteTurnAnalysis remote,
    required String callerName,
    required String relationLabel,
    required String ownerAlias,
  }) {
    return '';
  }

  String _bodyForRemote({
    required NovaCompanionRemoteTurnAnalysis remote,
    required NovaCompanionDirectiveAnalysis directive,
    required String ownerName,
    required String callerName,
    required String ownerAlias,
    required String explicitInstruction,
  }) {
    return '';
  }

  String _closingForRemote({
    required NovaCompanionRemoteTurnAnalysis remote,
    required bool shouldWakeOwner,
    required bool shouldAskPermissionToWake,
  }) {
    return '';
  }

  double _relationWarmthBoost(String relation) {
    final r = _n(relation);
    if (r.contains('anne') ||
        r.contains('baba') ||
        r.contains('eş') ||
        r.contains('es'))
      return 0.14;
    if (r.contains('abi') ||
        r.contains('abla') ||
        r.contains('kardeş') ||
        r.contains('kardes'))
      return 0.10;
    return 0.0;
  }

  String _dominantEmotion(Map<String, double> scores) {
    String label = 'neutral';
    double best = 0;
    scores.forEach((k, v) {
      if (v > best) {
        best = v;
        label = k;
      }
    });
    return best < 0.16 ? 'neutral' : label;
  }

  String _extractInstruction(String text) {
    final patterns = <RegExp>[
      RegExp(r'şunları söyle[: ]+(.+)$'),
      RegExp(r'sunlari soyle[: ]+(.+)$'),
      RegExp(r'bunu söyle[: ]+(.+)$'),
      RegExp(r'bunu soyle[: ]+(.+)$'),
      RegExp(r'de ki[: ]+(.+)$'),
      RegExp(r'deki[: ]+(.+)$'),
      RegExp(r'ilet[: ]+(.+)$'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return (match.group(1) ?? '').trim();
      }
    }
    return '';
  }

  double _cueScore(
    String text,
    List<String> cues,
    List<String> matched,
    String tag,
  ) {
    if (text.isEmpty) return 0.0;
    double score = 0.0;
    for (final cue in cues) {
      if (text.contains(cue)) {
        matched.add('$tag:$cue');
        score += cue.split(' ').length >= 2 ? 0.12 : 0.07;
      }
    }
    return _clamp(score);
  }

  String _pick(List<String> values, double seed) {
    if (values.isEmpty) return '';
    final index = (seed * 1000).round().abs() % values.length;
    return values[index];
  }

  String _n(String input) {
    return input
        .toLowerCase()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ı', 'i')
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _clamp(double value) => value < 0 ? 0 : (value > 1 ? 1 : value);

  String scenarioTemplate1(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 1');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate2(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 2');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate3(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 3');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate4(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 4');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate5(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 5');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate6(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 6');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate7(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 7');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate8(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 8');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate9(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 9');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate10(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 10');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate11(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 11');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate12(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 12');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate13(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 13');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate14(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 14');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate15(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 15');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate16(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 16');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate17(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 17');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate18(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 18');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate19(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 19');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate20(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 20');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate21(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 21');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate22(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 22');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate23(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 23');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate24(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 24');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate25(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 25');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate26(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 26');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate27(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 27');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate28(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 28');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate29(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 29');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate30(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 30');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate31(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 31');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate32(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 32');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate33(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 33');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate34(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 34');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate35(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 35');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate36(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 36');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate37(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 37');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate38(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 38');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate39(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 39');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate40(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 40');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate41(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 41');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate42(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 42');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate43(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 43');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate44(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 44');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate45(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 45');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate46(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 46');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate47(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 47');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate48(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 48');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate49(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 49');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate50(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 50');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate51(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 51');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate52(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 52');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate53(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 53');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate54(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 54');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate55(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 55');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate56(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 56');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate57(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 57');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate58(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 58');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate59(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 59');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }

  String scenarioTemplate60(String callerName, String ownerAlias) {
    final remote = analyzeRemoteTurn('merhaba 60');
    final directive = analyzeOwnerDirective('nova sohbete katil');
    final plan = buildReplyPlan(
      directive: directive,
      remote: remote,
      ownerName: ownerAlias,
      callerName: callerName,
      relationLabel: '',
      explicitInstruction: '',
    );
    return '';
  }
}
