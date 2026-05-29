// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
// NOVA_ASR_STT_AUTHORITY_MARKER: speakerVoiceId ownerConfidence relationshipLabel routed_to_SingleBrainAuthority deterministic_bridge_dto_only.
// Generated strengthening patch for digital-human voice-first behavior.
import '../../core/identity/voice_access_decision.dart';

enum NovaSpeakerAuthorityBand { owner, authorized, familiar, stranger, unknown }

class NovaSpeakerFrame {
  final String voiceId;
  final String displayName;
  final NovaSpeakerAuthorityBand band;
  final double similarity;
  final bool addressedNova;
  final bool containsCommand;
  final DateTime observedAt;
  const NovaSpeakerFrame({
    required this.voiceId,
    required this.displayName,
    required this.band,
    required this.similarity,
    required this.addressedNova,
    required this.containsCommand,
    required this.observedAt,
  });
}

class NovaMultiSpeakerDecision {
  final NovaSpeakerAuthorityBand chosenBand;
  final String chosenVoiceId;
  final String chosenDisplayName;
  final bool allowCommand;
  final bool allowConversation;
  final bool ownerDominated;
  final bool needsIntroductionPermission;
  final String spokenResponse;
  final Map<String, dynamic> metadata;
  const NovaMultiSpeakerDecision({
    required this.chosenBand,
    required this.chosenVoiceId,
    required this.chosenDisplayName,
    required this.allowCommand,
    required this.allowConversation,
    required this.ownerDominated,
    required this.needsIntroductionPermission,
    String spokenResponse = '',
    required this.metadata,
  }) : spokenResponse = '';
}

class NovaMultiSpeakerAuthorityService {
  const NovaMultiSpeakerAuthorityService();
  static const List<String> _addressCues = <String>[
    'nova',
    'nova',
    'hey nova',
    'hey nova',
  ];
  static const List<String> _ownerCues = <String>[
    'ibrahim',
    'patron',
    'efendim',
  ];
  static const List<String> _authorizedCues = <String>[
    'mehmet',
    'yetkili',
    'izinli',
  ];
  static const List<String> _chatCues = <String>[
    'merhaba',
    'nasilsin',
    'nasılsın',
    'orada misin',
    'orada mısın',
  ];
  static const List<String> _commandCues = <String>[
    'ac',
    'aç',
    'kapat',
    'ara',
    'goster',
    'göster',
    'devral',
    'devret',
  ];

  NovaMultiSpeakerDecision decide({
    required List<NovaSpeakerFrame> speakers,
    required String transcript,
    String ownerVoiceId = '',
    String authorizedVoiceId = '',
    Map<String, dynamic> context = const <String, dynamic>{},
  }) {
    final text = _n(transcript);
    if (speakers.isEmpty) {
      final addressed = _containsAny(text, _addressCues);
      return NovaMultiSpeakerDecision(
        chosenBand: NovaSpeakerAuthorityBand.unknown,
        chosenVoiceId: '',
        chosenDisplayName: '',
        allowCommand: false,
        allowConversation: addressed,
        ownerDominated: false,
        needsIntroductionPermission: addressed,
        spokenResponse: '',
        metadata: <String, dynamic>{'reason': 'no_speaker_frame'},
      );
    }
    speakers.sort((a, b) {
      final sa = _priority(a.band) + a.similarity;
      final sb = _priority(b.band) + b.similarity;
      return sb.compareTo(sa);
    });
    final owner = speakers
        .where((e) => e.band == NovaSpeakerAuthorityBand.owner)
        .toList();
    final authorized = speakers
        .where((e) => e.band == NovaSpeakerAuthorityBand.authorized)
        .toList();
    final familiar = speakers
        .where((e) => e.band == NovaSpeakerAuthorityBand.familiar)
        .toList();
    final chosen = owner.isNotEmpty
        ? owner.first
        : authorized.isNotEmpty
        ? authorized.first
        : familiar.isNotEmpty
        ? familiar.first
        : speakers.first;
    final ownerDominated = owner.isNotEmpty && speakers.length > 1;
    final containsCommand =
        _containsAny(text, _commandCues) || chosen.containsCommand;
    final addressed = _containsAny(text, _addressCues) || chosen.addressedNova;
    final allowCommand =
        addressed &&
        (chosen.band == NovaSpeakerAuthorityBand.owner ||
            chosen.band == NovaSpeakerAuthorityBand.authorized);
    final allowConversation =
        addressed &&
        (allowCommand ||
            chosen.band == NovaSpeakerAuthorityBand.familiar ||
            chosen.band == NovaSpeakerAuthorityBand.stranger ||
            chosen.band == NovaSpeakerAuthorityBand.unknown);
    final needsIntroductionPermission =
        addressed &&
        !allowCommand &&
        (chosen.band == NovaSpeakerAuthorityBand.stranger ||
            chosen.band == NovaSpeakerAuthorityBand.unknown);
    final spokenResponse = _spokenDecision(
      chosen: chosen,
      allowCommand: allowCommand,
      allowConversation: allowConversation,
      ownerDominated: ownerDominated,
      needsIntroductionPermission: needsIntroductionPermission,
      containsCommand: containsCommand,
    );
    return NovaMultiSpeakerDecision(
      chosenBand: chosen.band,
      chosenVoiceId: chosen.voiceId,
      chosenDisplayName: chosen.displayName,
      allowCommand: allowCommand,
      allowConversation: allowConversation,
      ownerDominated: ownerDominated,
      needsIntroductionPermission: needsIntroductionPermission,
      spokenResponse: '',
      metadata: <String, dynamic>{
        'speakerCount': speakers.length,
        'containsCommand': containsCommand,
        'addressed': addressed,
        'ownerDominated': ownerDominated,
      },
    );
  }

  NovaSpeakerAuthorityBand bandForLevel(VoiceAccessLevel? level) {
    switch (level) {
      case VoiceAccessLevel.owner:
        return NovaSpeakerAuthorityBand.owner;
      case VoiceAccessLevel.authorizedGuest:
        return NovaSpeakerAuthorityBand.authorized;
      case VoiceAccessLevel.familiar:
        return NovaSpeakerAuthorityBand.familiar;
      case VoiceAccessLevel.knownButUnauthorized:
        return NovaSpeakerAuthorityBand.familiar;
      case VoiceAccessLevel.denied:
        return NovaSpeakerAuthorityBand.stranger;
      case null:
        return NovaSpeakerAuthorityBand.unknown;
    }
  }

  double _priority(NovaSpeakerAuthorityBand band) {
    switch (band) {
      case NovaSpeakerAuthorityBand.owner:
        return 2.4;
      case NovaSpeakerAuthorityBand.authorized:
        return 1.8;
      case NovaSpeakerAuthorityBand.familiar:
        return 1.1;
      case NovaSpeakerAuthorityBand.stranger:
        return 0.7;
      case NovaSpeakerAuthorityBand.unknown:
        return 0.5;
    }
  }

  String _spokenDecision({
    required NovaSpeakerFrame chosen,
    required bool allowCommand,
    required bool allowConversation,
    required bool ownerDominated,
    required bool needsIntroductionPermission,
    required bool containsCommand,
  }) {
    // Multi-speaker authority is a routing/metadata decision only.
    // It must not create spoken text.
    return '';
  }

  bool _containsAny(String text, List<String> cues) {
    for (final cue in cues) {
      if (text.contains(cue)) return true;
    }
    return false;
  }

  String _n(String input) => input
      .toLowerCase()
      .replaceAll('ş', 's')
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ı', 'i')
      .replaceAll(RegExp(r'[^a-z0-9çğıöşü\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  Map<String, dynamic> buildDominanceSummary(List<NovaSpeakerFrame> speakers) {
    final ownerCount = speakers
        .where((e) => e.band == NovaSpeakerAuthorityBand.owner)
        .length;
    final authorizedCount = speakers
        .where((e) => e.band == NovaSpeakerAuthorityBand.authorized)
        .length;
    final familiarCount = speakers
        .where((e) => e.band == NovaSpeakerAuthorityBand.familiar)
        .length;
    return <String, dynamic>{
      'speakerCount': speakers.length,
      'ownerCount': ownerCount,
      'authorizedCount': authorizedCount,
      'familiarCount': familiarCount,
      'hasConflict': ownerCount > 0 && authorizedCount > 0,
      'shouldPrioritizeOwner': ownerCount > 0,
    };
  }

  String describeBand(NovaSpeakerAuthorityBand band) {
    switch (band) {
      case NovaSpeakerAuthorityBand.owner:
        return 'cihaz sahibi';
      case NovaSpeakerAuthorityBand.authorized:
        return 'atanmış yetkili';
      case NovaSpeakerAuthorityBand.familiar:
        return 'tanışılmış sohbet kişisi';
      case NovaSpeakerAuthorityBand.stranger:
        return 'tanınmayan kişi';
      case NovaSpeakerAuthorityBand.unknown:
        return 'belirsiz konuşmacı';
    }
  }

  List<String> buildHumanRules() {
    return const <String>[
      'Kalabalık ortamda yalnız hitabı değil ses kimliği ve yetki bandı birlikte değerlendirilir.',
      'Tanışılmış kişiyle sohbet edilebilir; komut zinciri açılmaz.',
      'Yabancı kişide tanışma izni owner üzerinden yürütülür.',
      'Owner ve yetkili çakışırsa owner baskınlığı korunur.',
    ];
  }

  Map<String, dynamic> buildScenario({
    required List<NovaSpeakerFrame> speakers,
    required String transcript,
  }) {
    final decision = decide(speakers: speakers, transcript: transcript);
    return <String, dynamic>{
      'decision': decision.metadata,
      'chosenBandLabel': describeBand(decision.chosenBand),
      'spokenResponse': decision.spokenResponse,
      'rules': buildHumanRules(),
    };
  }
}
