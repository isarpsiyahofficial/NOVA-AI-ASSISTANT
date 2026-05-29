// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
// NOVA_ASR_STT_AUTHORITY_MARKER: speakerVoiceId ownerConfidence relationshipLabel routed_to_SingleBrainAuthority deterministic_bridge_dto_only.
// Generated strengthening patch for digital-human voice-first behavior.
import 'dart:math';

enum NovaPresenceModeHint {
  active,
  limbo,
  sleep,
  night,
  call,
  companion,
  media,
  learning,
  curiosity,
}

class NovaVoiceFirstPresencePlan {
  final NovaPresenceModeHint modeHint;
  final bool keepHotMic;
  final bool keepStreamingAsrWarm;
  final bool allowSpontaneousCuriosity;
  final bool requirePermissionBeforeSpeaking;
  final bool allowBackchannel;
  final bool shouldUseShortUtterances;
  final bool shouldPreferVoiceReplies;
  final String overlayState;
  final String spokenStatus;
  final Map<String, dynamic> metadata;
  const NovaVoiceFirstPresencePlan({
    required this.modeHint,
    required this.keepHotMic,
    required this.keepStreamingAsrWarm,
    required this.allowSpontaneousCuriosity,
    required this.requirePermissionBeforeSpeaking,
    required this.allowBackchannel,
    required this.shouldUseShortUtterances,
    required this.shouldPreferVoiceReplies,
    required this.overlayState,
    required this.spokenStatus,
    required this.metadata,
  });
}

class NovaVoiceFirstPresenceRuntimeService {
  const NovaVoiceFirstPresenceRuntimeService();
  static const List<String> _activeCues = <String>[
    'uyan',
    'buradayim',
    'buradayım',
    'dinle',
    'hazir',
    'hazır',
  ];
  static const List<String> _limboCues = <String>[
    'araf',
    'sessiz bekle',
    'pasif dinle',
    'beklemede kal',
  ];
  static const List<String> _sleepCues = <String>[
    'uykuya don',
    'uykuya dön',
    'uyu',
    'pasif mod',
  ];
  static const List<String> _nightCues = <String>[
    'gece modu',
    'gece',
    'rahatsiz etme',
    'rahatsız etme',
  ];
  static const List<String> _curiosityCues = <String>[
    'canin sikildiysa',
    'canın sıkıldıysa',
    'merak edersen',
    'uyanma izni iste',
    'yanima gel',
    'yanıma gel',
  ];
  static const List<String> _voiceCues = <String>[
    'sesli cevap ver',
    'konusarak cevap ver',
    'yazma',
    'hep sesli',
  ];
  static const List<String> _mediaCues = <String>[
    'muzik',
    'müzik',
    'spotify',
    'youtube music',
  ];
  static const List<String> _callCues = <String>[
    'cagri',
    'çağrı',
    'telefon',
    'companion',
  ];

  NovaVoiceFirstPresencePlan buildPlan({
    required String observedText,
    required String powerMode,
    required bool continuousListeningEnabled,
    required bool isCompanionActive,
    required bool isCallActive,
    required bool isMediaFlowActive,
    Map<String, dynamic> context = const <String, dynamic>{},
  }) {
    final text = _n(observedText);
    final activeScore =
        _score(text, _activeCues) + (continuousListeningEnabled ? 0.18 : 0.0);
    final limboScore =
        _score(text, _limboCues) + (powerMode.contains('limbo') ? 0.18 : 0.0);
    final sleepScore =
        _score(text, _sleepCues) + (powerMode.contains('sleep') ? 0.18 : 0.0);
    final nightScore =
        _score(text, _nightCues) + (powerMode.contains('night') ? 0.20 : 0.0);
    final curiosityScore =
        _score(text, _curiosityCues) +
        ((context['allowCuriosity'] == true) ? 0.16 : 0.0);
    NovaPresenceModeHint mode = NovaPresenceModeHint.active;
    double best = activeScore;
    if (isCallActive) {
      mode = isCompanionActive
          ? NovaPresenceModeHint.companion
          : NovaPresenceModeHint.call;
    }
    if (isMediaFlowActive) {
      mode = NovaPresenceModeHint.media;
    }
    final map = <NovaPresenceModeHint, double>{
      NovaPresenceModeHint.active: activeScore,
      NovaPresenceModeHint.limbo: limboScore,
      NovaPresenceModeHint.sleep: sleepScore,
      NovaPresenceModeHint.night: nightScore,
      NovaPresenceModeHint.curiosity: curiosityScore,
    };
    map.forEach((k, v) {
      if (v > best && !isCallActive && !isMediaFlowActive) {
        best = v;
        mode = k;
      }
    });
    final keepHotMic =
        mode != NovaPresenceModeHint.sleep &&
        mode != NovaPresenceModeHint.night;
    final keepStreamingAsrWarm =
        continuousListeningEnabled ||
        mode == NovaPresenceModeHint.active ||
        mode == NovaPresenceModeHint.companion;
    final allowSpontaneousCuriosity =
        mode == NovaPresenceModeHint.limbo ||
        mode == NovaPresenceModeHint.curiosity;
    final requirePermissionBeforeSpeaking =
        mode == NovaPresenceModeHint.night ||
        mode == NovaPresenceModeHint.limbo;
    final allowBackchannel =
        mode == NovaPresenceModeHint.active ||
        mode == NovaPresenceModeHint.companion ||
        mode == NovaPresenceModeHint.call;
    final shouldUseShortUtterances =
        mode == NovaPresenceModeHint.call ||
        mode == NovaPresenceModeHint.companion ||
        mode == NovaPresenceModeHint.media;
    final overlayState = _overlayState(mode);
    final spokenStatus = _spokenStatus(
      mode,
      requirePermissionBeforeSpeaking: requirePermissionBeforeSpeaking,
    );
    return NovaVoiceFirstPresencePlan(
      modeHint: mode,
      keepHotMic: keepHotMic,
      keepStreamingAsrWarm: keepStreamingAsrWarm,
      allowSpontaneousCuriosity: allowSpontaneousCuriosity,
      requirePermissionBeforeSpeaking: requirePermissionBeforeSpeaking,
      allowBackchannel: allowBackchannel,
      shouldUseShortUtterances: shouldUseShortUtterances,
      shouldPreferVoiceReplies: true,
      overlayState: overlayState,
      spokenStatus: spokenStatus,
      metadata: <String, dynamic>{
        'activeScore': activeScore,
        'limboScore': limboScore,
        'sleepScore': sleepScore,
        'nightScore': nightScore,
        'curiosityScore': curiosityScore,
      },
    );
  }

  String buildCuriosityPermissionRequest(String topic) {
    final t = topic.trim().isEmpty ? 'bir konu' : topic.trim();
    return 'Efendim, $t hakkında biraz daha düşünmek ve konuşmak için uyanmamı ister misiniz?';
  }

  Map<String, dynamic> buildMicContinuityHints({
    required NovaPresenceModeHint mode,
    required bool asrWarm,
    required bool playbackGuardActive,
  }) {
    return <String, dynamic>{
      'mode': mode.name,
      'preferContinuousMic':
          mode != NovaPresenceModeHint.sleep &&
          mode != NovaPresenceModeHint.night,
      'asrWarm': asrWarm,
      'shouldAvoidMicFlapping': true,
      'playbackGuardActive': playbackGuardActive,
      'voiceFirst': true,
    };
  }

  String _overlayState(NovaPresenceModeHint mode) {
    switch (mode) {
      case NovaPresenceModeHint.active:
        return 'listening';
      case NovaPresenceModeHint.limbo:
        return 'idle';
      case NovaPresenceModeHint.sleep:
        return 'sleeping';
      case NovaPresenceModeHint.night:
        return 'sleeping';
      case NovaPresenceModeHint.call:
        return 'call';
      case NovaPresenceModeHint.companion:
        return 'companion';
      case NovaPresenceModeHint.media:
        return 'media';
      case NovaPresenceModeHint.learning:
        return 'learning';
      case NovaPresenceModeHint.curiosity:
        return 'curious';
    }
  }

  String _spokenStatus(
    NovaPresenceModeHint mode, {
    required bool requirePermissionBeforeSpeaking,
  }) {
    if (requirePermissionBeforeSpeaking)
      return 'Sessiz dengede bekliyorum efendim.';
    switch (mode) {
      case NovaPresenceModeHint.active:
        return 'Buradayım efendim.';
      case NovaPresenceModeHint.limbo:
        return 'Pasif dengede sizi duymaya hazırım efendim.';
      case NovaPresenceModeHint.sleep:
        return 'Uyku düzeninde sessiz izleme modundayım efendim.';
      case NovaPresenceModeHint.night:
        return 'Gece düzeninde gereksiz konuşmayacağım efendim.';
      case NovaPresenceModeHint.call:
        return 'Çağrı akışını izliyorum efendim.';
      case NovaPresenceModeHint.companion:
        return 'Çağrıda size eşlik etmeye hazırım efendim.';
      case NovaPresenceModeHint.media:
        return 'Medya akışını sesli yönetecek durumdayım efendim.';
      case NovaPresenceModeHint.learning:
        return 'Öğrenme modundayım efendim.';
      case NovaPresenceModeHint.curiosity:
        return 'Sessizce merak taşıyorum; izin verirseniz sorabilirim efendim.';
    }
  }

  double _score(String text, List<String> cues) {
    double s = 0;
    for (final cue in cues) {
      if (text.contains(cue)) s += cue.split(' ').length >= 2 ? 0.12 : 0.07;
    }
    return _clamp(s);
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
  double _clamp(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
  Map<String, dynamic> buildModeAudit({
    required NovaPresenceModeHint mode,
    required bool continuousListeningEnabled,
    required bool isCompanionActive,
    required bool isCallActive,
  }) {
    final plan = buildPlan(
      observedText: '',
      powerMode: mode.name,
      continuousListeningEnabled: continuousListeningEnabled,
      isCompanionActive: isCompanionActive,
      isCallActive: isCallActive,
      isMediaFlowActive: false,
    );
    return <String, dynamic>{
      'mode': mode.name,
      'keepHotMic': plan.keepHotMic,
      'keepStreamingAsrWarm': plan.keepStreamingAsrWarm,
      'allowSpontaneousCuriosity': plan.allowSpontaneousCuriosity,
      'allowBackchannel': plan.allowBackchannel,
      'spokenStatus': plan.spokenStatus,
    };
  }

  List<String> buildModeNarratives(NovaPresenceModeHint mode) {
    switch (mode) {
      case NovaPresenceModeHint.active:
        return const <String>[
          'aktif ve erişilebilir',
          'kısa gecikmeyle yanıt verir',
          'ses-first varlık baskın',
        ];
      case NovaPresenceModeHint.limbo:
        return const <String>[
          'pasif ama hazır',
          'gereksiz konuşma azaltılır',
          'izinle merak başlatabilir',
        ];
      case NovaPresenceModeHint.sleep:
        return const <String>[
          'uyku akışı korunur',
          'gereksiz uyanma yok',
          'acil durum ayrı ele alınır',
        ];
      case NovaPresenceModeHint.night:
        return const <String>[
          'gece sakinliği korunur',
          'kısa ve gerekliyse konuşur',
          'mahremiyet sertleşir',
        ];
      case NovaPresenceModeHint.call:
        return const <String>[
          'çağrıya göre davranır',
          'arka plan yorumları kısalır',
          'çağrı zinciri önceliklidir',
        ];
      case NovaPresenceModeHint.companion:
        return const <String>[
          'çağrıda eşlik eder',
          'insani aktarım önceliklidir',
          'sahip niyeti korunur',
        ];
      case NovaPresenceModeHint.media:
        return const <String>[
          'medya yönetimi odaklı',
          'kısa komutlar tercih edilir',
          'uygulama tercihi korunur',
        ];
      case NovaPresenceModeHint.learning:
        return const <String>[
          'öğrenme bağlamı aktif',
          'daha fazla açıklama toplar',
          'güvenli sınır korunur',
        ];
      case NovaPresenceModeHint.curiosity:
        return const <String>[
          'kontrollü merak taşıyabilir',
          'izin istemeden aşırı yaklaşmaz',
          'sohbet başlatma yumuşaktır',
        ];
    }
  }

  Map<String, dynamic> buildScenario(String transcript) {
    final plan = buildPlan(
      observedText: transcript,
      powerMode: 'limbo',
      continuousListeningEnabled: true,
      isCompanionActive: false,
      isCallActive: false,
      isMediaFlowActive: false,
    );
    return <String, dynamic>{
      'transcript': transcript,
      'mode': plan.modeHint.name,
      'narratives': buildModeNarratives(plan.modeHint),
      'metadata': plan.metadata,
    };
  }
}
