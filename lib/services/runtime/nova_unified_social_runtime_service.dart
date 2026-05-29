// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:async';
import 'dart:math';

import '../../core/identity/voice_access_decision.dart';
import '../../core/runtime/nova_affective_state.dart';
import '../../core/runtime/nova_internal_state.dart';
import '../../core/runtime/nova_shared_world_state.dart';
import 'nova_speaker_graph_engine_service.dart';

enum NovaUnifiedRuntimeEventType {
  voiceInput,
  authorizedPrompt,
  unauthorizedPrompt,
  callState,
  companionState,
  overlayState,
  learningSignal,
  memoryCommit,
  selfRepairSignal,
  benchmarkSample,
}

class NovaUnifiedRuntimeEvent {
  final NovaUnifiedRuntimeEventType type;
  final DateTime at;
  final String text;
  final Map<String, dynamic> payload;

  const NovaUnifiedRuntimeEvent({
    required this.type,
    required this.at,
    required this.text,
    this.payload = const <String, dynamic>{},
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'type': type.name,
    'at': at.toIso8601String(),
    'text': text,
    'payload': payload,
  };
}

class NovaUnifiedArbitrationDecision {
  final String selectedMode;
  final bool shouldSpeak;
  final bool shouldListen;
  final bool shouldBackchannel;
  final bool shouldTakeCall;
  final bool shouldHandCallToUser;
  final bool shouldPersistMemory;
  final bool shouldAskPermission;
  final String reason;
  final Map<String, dynamic> metadata;

  const NovaUnifiedArbitrationDecision({
    required this.selectedMode,
    required this.shouldSpeak,
    required this.shouldListen,
    required this.shouldBackchannel,
    required this.shouldTakeCall,
    required this.shouldHandCallToUser,
    required this.shouldPersistMemory,
    required this.shouldAskPermission,
    required this.reason,
    this.metadata = const <String, dynamic>{},
  });
}

class NovaUnifiedRuntimeSnapshot {
  final NovaInternalState internalState;
  final NovaAffectiveState affectiveState;
  final NovaSharedWorldState worldState;
  final NovaSpeakerGraphSnapshot speakerGraph;
  final NovaUnifiedArbitrationDecision lastDecision;
  final List<NovaUnifiedRuntimeEvent> recentEvents;
  final DateTime updatedAt;

  const NovaUnifiedRuntimeSnapshot({
    required this.internalState,
    required this.affectiveState,
    required this.worldState,
    required this.speakerGraph,
    required this.lastDecision,
    required this.recentEvents,
    required this.updatedAt,
  });

  factory NovaUnifiedRuntimeSnapshot.initial() {
    return NovaUnifiedRuntimeSnapshot(
      internalState: NovaInternalState.initial(),
      affectiveState: const NovaAffectiveState(
        dominantEmotion: 'calm',
        warmth: 0.66,
        urgency: 0.14,
        tension: 0.10,
        curiosity: 0.32,
        cues: <String>[],
      ),
      worldState: NovaSharedWorldState.initial(),
      speakerGraph: NovaSpeakerGraphSnapshot.initial(),
      lastDecision: const NovaUnifiedArbitrationDecision(
        selectedMode: 'idle',
        shouldSpeak: false,
        shouldListen: true,
        shouldBackchannel: false,
        shouldTakeCall: false,
        shouldHandCallToUser: false,
        shouldPersistMemory: false,
        shouldAskPermission: false,
        reason: 'başlangıç',
      ),
      recentEvents: const <NovaUnifiedRuntimeEvent>[],
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'internalState': internalState.toMap(),
    'affectiveState': <String, dynamic>{
      'dominantEmotion': affectiveState.dominantEmotion,
      'warmth': affectiveState.warmth,
      'urgency': affectiveState.urgency,
      'tension': affectiveState.tension,
      'curiosity': affectiveState.curiosity,
      'cues': affectiveState.cues,
    },
    'worldState': worldState.toMap(),
    'speakerGraph': speakerGraph.toMap(),
    'lastDecision': <String, dynamic>{
      'selectedMode': lastDecision.selectedMode,
      'shouldSpeak': lastDecision.shouldSpeak,
      'shouldListen': lastDecision.shouldListen,
      'shouldBackchannel': lastDecision.shouldBackchannel,
      'shouldTakeCall': lastDecision.shouldTakeCall,
      'shouldHandCallToUser': lastDecision.shouldHandCallToUser,
      'shouldPersistMemory': lastDecision.shouldPersistMemory,
      'shouldAskPermission': lastDecision.shouldAskPermission,
      'reason': lastDecision.reason,
      'metadata': lastDecision.metadata,
    },
    'recentEvents': recentEvents.map((e) => e.toMap()).toList(growable: false),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class NovaUnifiedSocialRuntimeService {
  final NovaSpeakerGraphEngineService speakerGraphEngineService;
  final StreamController<NovaUnifiedRuntimeSnapshot> _controller =
      StreamController<NovaUnifiedRuntimeSnapshot>.broadcast();

  NovaUnifiedRuntimeSnapshot _snapshot = NovaUnifiedRuntimeSnapshot.initial();

  NovaUnifiedSocialRuntimeService({
    NovaSpeakerGraphEngineService? speakerGraphEngineService,
  }) : speakerGraphEngineService =
           speakerGraphEngineService ?? const NovaSpeakerGraphEngineService();

  Stream<NovaUnifiedRuntimeSnapshot> get stream => _controller.stream;
  NovaUnifiedRuntimeSnapshot get snapshot => _snapshot;

  void dispose() {
    _controller.close();
  }

  NovaUnifiedRuntimeSnapshot ingestVoiceInput({
    required String transcript,
    required VoiceAccessLevel? accessLevel,
    required String speakerVoiceId,
    required String speakerName,
    required String relationLabel,
    required bool addressedNova,
    required bool containsCommand,
    required bool activeCall,
    required bool companionActive,
    bool syntheticPlaybackGuarded = false,
  }) {
    final observation = NovaSpeakerGraphObservation(
      voiceId: speakerVoiceId.trim(),
      displayName: speakerName.trim(),
      relationLabel: relationLabel.trim(),
      band: speakerGraphEngineService.bandForLevel(accessLevel),
      similarity: _similarityHeuristic(transcript, accessLevel),
      addressedNova: addressedNova,
      containsCommand: containsCommand,
      commandPriority: containsCommand,
      activeCall: activeCall,
      companionActive: companionActive,
      syntheticPlaybackGuarded: syntheticPlaybackGuarded,
      transcript: transcript,
      observedAt: DateTime.now(),
      metadata: <String, dynamic>{'accessLevel': accessLevel?.name ?? 'none'},
    );

    final speakerGraph = observation.voiceId.isEmpty
        ? _snapshot.speakerGraph
        : speakerGraphEngineService.ingest(
            snapshot: _snapshot.speakerGraph,
            observation: observation,
          );
    final decision = speakerGraphEngineService.decide(
      snapshot: speakerGraph,
      transcript: transcript,
      containsCommand: containsCommand,
      activeCall: activeCall,
      companionActive: companionActive,
    );
    final internal = _evolveInternalState(
      state: _snapshot.internalState,
      transcript: transcript,
      containsCommand: containsCommand,
      accessLevel: accessLevel,
      activeCall: activeCall,
      companionActive: companionActive,
    );
    final affective = _deriveAffectiveState(
      transcript,
      activeCall: activeCall,
      companionActive: companionActive,
    );
    final world = _evolveWorldState(
      _snapshot.worldState,
      transcript,
      relationLabel: relationLabel,
      activeCall: activeCall,
    );
    final arbitration = _arbitrate(
      transcript: transcript,
      decision: decision,
      internalState: internal,
      affectiveState: affective,
      activeCall: activeCall,
      companionActive: companionActive,
      containsCommand: containsCommand,
    );
    final event = NovaUnifiedRuntimeEvent(
      type: NovaUnifiedRuntimeEventType.voiceInput,
      at: DateTime.now(),
      text: transcript,
      payload: <String, dynamic>{
        'decision': decision.metadata,
        'mode': arbitration.selectedMode,
        'allowCommand': decision.allowCommand,
        'allowConversation': decision.allowConversation,
      },
    );
    return _commit(
      internalState: internal,
      affectiveState: affective,
      worldState: world,
      speakerGraph: speakerGraph,
      decision: arbitration,
      event: event,
    );
  }

  NovaUnifiedRuntimeSnapshot ingestCallState({
    required String stateLabel,
    required String number,
    required bool ringing,
    required bool active,
    required bool companionActive,
    required bool speakerOn,
    required bool muted,
  }) {
    final event = NovaUnifiedRuntimeEvent(
      type: NovaUnifiedRuntimeEventType.callState,
      at: DateTime.now(),
      text: stateLabel,
      payload: <String, dynamic>{
        'number': number,
        'ringing': ringing,
        'active': active,
        'companionActive': companionActive,
        'speakerOn': speakerOn,
        'muted': muted,
      },
    );
    final world = _snapshot.worldState.copyWith(
      ambientMode: active
          ? 'call'
          : (ringing ? 'ringing' : _snapshot.worldState.ambientMode),
      userMode: companionActive ? 'companion' : _snapshot.worldState.userMode,
      continuityThread: _buildContinuityThread(
        _snapshot.worldState.continuityThread,
        active
            ? 'Çağrı aktif; normal UX korunurken Nova yalnız izinli zincirde eşlik ediyor.'
            : (ringing
                  ? 'Çağrı çalıyor; sınırlı whitelist ve role-stack hazır.'
                  : 'Çağrı kapanmış olabilir.'),
      ),
      updatedAt: DateTime.now(),
    );
    final arbitration = _arbitrate(
      transcript: stateLabel,
      decision: _snapshot.speakerGraph.nodes.isEmpty
          ? const NovaSpeakerGraphDecision(
              chosenVoiceId: '',
              chosenDisplayName: '',
              chosenRelationLabel: '',
              chosenBand: NovaSpeakerGraphBand.unknown,
              allowCommand: false,
              allowConversation: true,
              ownerDominated: false,
              needsOwnerApprovalForNewPerson: false,
              shouldSoftReject: false,
              confidence: 0.2,
              spokenResponse: '',
              reasons: <String>['call state fallback'],
            )
          : speakerGraphEngineService.decide(
              snapshot: _snapshot.speakerGraph,
              transcript: stateLabel,
              containsCommand: false,
              activeCall: active,
              companionActive: companionActive,
            ),
      internalState: _snapshot.internalState,
      affectiveState: _snapshot.affectiveState,
      activeCall: active || ringing,
      companionActive: companionActive,
      containsCommand: false,
    );
    return _commit(
      internalState: _snapshot.internalState,
      affectiveState: _snapshot.affectiveState,
      worldState: world,
      speakerGraph: _snapshot.speakerGraph,
      decision: arbitration,
      event: event,
    );
  }

  NovaUnifiedRuntimeSnapshot ingestLearningSignal({
    required String prompt,
    required bool persistent,
    required bool temporary,
    required bool explicitTeaching,
    required String domain,
    required double importance,
  }) {
    final cues = <String>[
      if (persistent) 'kalıcı',
      if (temporary) 'geçici',
      if (explicitTeaching) 'öğretim',
      domain,
    ];
    final affective = NovaAffectiveState(
      dominantEmotion: _snapshot.affectiveState.dominantEmotion,
      warmth: _snapshot.affectiveState.warmth,
      urgency: max(_snapshot.affectiveState.urgency, importance * 0.45),
      tension: _snapshot.affectiveState.tension,
      curiosity: _clamp01(
        _snapshot.affectiveState.curiosity + (explicitTeaching ? 0.08 : 0.02),
      ),
      cues: <String>{
        ..._snapshot.affectiveState.cues,
        ...cues,
      }.take(12).toList(growable: false),
    );
    final event = NovaUnifiedRuntimeEvent(
      type: NovaUnifiedRuntimeEventType.learningSignal,
      at: DateTime.now(),
      text: prompt,
      payload: <String, dynamic>{
        'persistent': persistent,
        'temporary': temporary,
        'explicitTeaching': explicitTeaching,
        'domain': domain,
        'importance': importance,
      },
    );
    final arbitration = NovaUnifiedArbitrationDecision(
      selectedMode: explicitTeaching
          ? 'learning'
          : _snapshot.lastDecision.selectedMode,
      shouldSpeak: false,
      shouldListen: true,
      shouldBackchannel: true,
      shouldTakeCall: false,
      shouldHandCallToUser: false,
      shouldPersistMemory: persistent || temporary || explicitTeaching,
      shouldAskPermission: false,
      reason: explicitTeaching ? 'öğretim sinyali' : 'öğrenme sinyali',
      metadata: <String, dynamic>{'domain': domain, 'importance': importance},
    );
    return _commit(
      internalState: _snapshot.internalState,
      affectiveState: affective,
      worldState: _snapshot.worldState,
      speakerGraph: _snapshot.speakerGraph,
      decision: arbitration,
      event: event,
    );
  }

  Map<String, dynamic> buildPromptMetadata() {
    return <String, dynamic>{
      'internalState': _snapshot.internalState.toMap(),
      'affectiveState': <String, dynamic>{
        'dominantEmotion': _snapshot.affectiveState.dominantEmotion,
        'warmth': _snapshot.affectiveState.warmth,
        'urgency': _snapshot.affectiveState.urgency,
        'tension': _snapshot.affectiveState.tension,
        'curiosity': _snapshot.affectiveState.curiosity,
        'cues': _snapshot.affectiveState.cues,
      },
      'worldState': _snapshot.worldState.toMap(),
      'speakerGraphSummary': speakerGraphEngineService.buildAuthorityHints(
        snapshot: _snapshot.speakerGraph,
        transcript: _snapshot.recentEvents.isEmpty
            ? ''
            : _snapshot.recentEvents.first.text,
        containsCommand:
            _snapshot.lastDecision.metadata['containsCommand'] == true,
        activeCall: _snapshot.lastDecision.metadata['activeCall'] == true,
        companionActive:
            _snapshot.lastDecision.metadata['companionActive'] == true,
      ),
      'lastDecision': <String, dynamic>{
        'selectedMode': _snapshot.lastDecision.selectedMode,
        'shouldSpeak': _snapshot.lastDecision.shouldSpeak,
        'shouldListen': _snapshot.lastDecision.shouldListen,
        'shouldBackchannel': _snapshot.lastDecision.shouldBackchannel,
        'shouldTakeCall': _snapshot.lastDecision.shouldTakeCall,
        'shouldHandCallToUser': _snapshot.lastDecision.shouldHandCallToUser,
        'shouldPersistMemory': _snapshot.lastDecision.shouldPersistMemory,
        'shouldAskPermission': _snapshot.lastDecision.shouldAskPermission,
        'reason': _snapshot.lastDecision.reason,
      },
      'coverageBands': buildCoverageBands(),
    };
  }

  Map<String, dynamic> buildCoverageBands() {
    final recent = _snapshot.recentEvents;
    final modes = recent.map((e) => e.type.name).toSet();
    return <String, dynamic>{
      'unifiedSocialRuntime': true,
      'eventBusConnected': recent.isNotEmpty,
      'worldStateTracking': _snapshot.worldState.continuityThread.isNotEmpty,
      'speakerGraphTracking': _snapshot.speakerGraph.nodes.isNotEmpty,
      'callAwareness': modes.contains(
        NovaUnifiedRuntimeEventType.callState.name,
      ),
      'learningAwareness': modes.contains(
        NovaUnifiedRuntimeEventType.learningSignal.name,
      ),
      'memoryAware':
          _snapshot.lastDecision.shouldPersistMemory ||
          recent.any((e) => e.type == NovaUnifiedRuntimeEventType.memoryCommit),
      'recentEventCount': recent.length,
    };
  }

  NovaUnifiedRuntimeSnapshot _commit({
    required NovaInternalState internalState,
    required NovaAffectiveState affectiveState,
    required NovaSharedWorldState worldState,
    required NovaSpeakerGraphSnapshot speakerGraph,
    required NovaUnifiedArbitrationDecision decision,
    required NovaUnifiedRuntimeEvent event,
  }) {
    final recent = <NovaUnifiedRuntimeEvent>[
      event,
      ..._snapshot.recentEvents,
    ].take(28).toList(growable: false);
    _snapshot = NovaUnifiedRuntimeSnapshot(
      internalState: internalState,
      affectiveState: affectiveState,
      worldState: worldState,
      speakerGraph: speakerGraph,
      lastDecision: decision,
      recentEvents: recent,
      updatedAt: DateTime.now(),
    );
    if (!_controller.isClosed) {
      _controller.add(_snapshot);
    }
    return _snapshot;
  }

  NovaInternalState _evolveInternalState({
    required NovaInternalState state,
    required String transcript,
    required bool containsCommand,
    required VoiceAccessLevel? accessLevel,
    required bool activeCall,
    required bool companionActive,
  }) {
    final normalized = _normalize(transcript);
    final tokenCount = normalized.split(' ').where((e) => e.isNotEmpty).length;
    final focusBoost = containsCommand ? 0.10 : (tokenCount >= 7 ? 0.05 : 0.01);
    final driveBoost =
        normalized.contains('neden') ||
            normalized.contains('niye') ||
            normalized.contains('nasıl')
        ? 0.07
        : 0.02;
    final closeness = accessLevel == VoiceAccessLevel.owner
        ? 1.0
        : accessLevel == VoiceAccessLevel.authorizedGuest
        ? 0.78
        : accessLevel == VoiceAccessLevel.familiar
        ? 0.58
        : accessLevel == VoiceAccessLevel.knownButUnauthorized
        ? 0.42
        : 0.26;
    return state.copyWith(
      energyLevel: _clamp01(
        (state.energyLevel * 0.88) + (activeCall ? 0.08 : 0.04),
      ),
      focusLevel: _clamp01((state.focusLevel * 0.82) + focusBoost),
      socialOpenness: _clamp01(
        (state.socialOpenness * 0.82) + (companionActive ? 0.09 : 0.04),
      ),
      fatigueLevel: _clamp01(
        (state.fatigueLevel * 0.90) + (activeCall ? 0.05 : 0.02),
      ),
      conversationDrive: _clamp01(
        (state.conversationDrive * 0.86) + driveBoost,
      ),
      ownerCloseness: closeness,
      ownerMode: accessLevel == VoiceAccessLevel.owner,
      authorizedMode: accessLevel == VoiceAccessLevel.authorizedGuest,
      speakingRegister: _resolveRegister(
        accessLevel: accessLevel,
        activeCall: activeCall,
        companionActive: companionActive,
      ),
      lastOpenLoops: _mergeOpenLoops(state.lastOpenLoops, transcript),
      sessionTurnCount: state.sessionTurnCount + 1,
    );
  }

  NovaAffectiveState _deriveAffectiveState(
    String transcript, {
    required bool activeCall,
    required bool companionActive,
  }) {
    final normalized = _normalize(transcript);
    final warmth =
        0.45 +
        (_containsAny(normalized, const <String>[
              'tesekkur',
              'saol',
              'iyi',
              'guzel',
              'harika',
            ])
            ? 0.22
            : 0) +
        (companionActive ? 0.06 : 0);
    final urgency =
        0.08 +
        (_containsAny(normalized, const <String>[
              'acil',
              'hemen',
              'simdi',
              'uyandir',
              'yardim',
            ])
            ? 0.48
            : 0) +
        (activeCall ? 0.10 : 0);
    final tension =
        0.08 +
        (_containsAny(normalized, const <String>[
              'yanlis',
              'bekle',
              'sinir',
              'gergin',
              'ofke',
              'korku',
            ])
            ? 0.34
            : 0);
    final curiosity =
        0.14 +
        (_containsAny(normalized, const <String>[
              'neden',
              'niye',
              'nasil',
              'sence',
              'merak',
            ])
            ? 0.36
            : 0);
    final dominantEmotion = urgency > 0.50
        ? 'urgent'
        : tension > 0.34
        ? 'tense'
        : warmth > 0.62
        ? 'warm'
        : curiosity > 0.40
        ? 'curious'
        : 'calm';
    final cues = <String>[
      if (dominantEmotion == 'urgent') 'aciliyet',
      if (dominantEmotion == 'tense') 'gerilim',
      if (dominantEmotion == 'warm') 'yakınlık',
      if (dominantEmotion == 'curious') 'merak',
      if (activeCall) 'çağrı',
      if (companionActive) 'companion',
    ];
    return NovaAffectiveState(
      dominantEmotion: dominantEmotion,
      warmth: _clamp01(warmth),
      urgency: _clamp01(urgency),
      tension: _clamp01(tension),
      curiosity: _clamp01(curiosity),
      cues: cues,
    );
  }

  NovaSharedWorldState _evolveWorldState(
    NovaSharedWorldState world,
    String transcript, {
    required String relationLabel,
    required bool activeCall,
  }) {
    final topics = _extractTopics(transcript);
    final repeated = <String>[
      ...world.repeatedTopics,
      ...topics,
    ].toSet().take(12).toList(growable: false);
    final unfinished = <String>{
      ...world.unfinishedItems,
      ..._extractUnfinished(transcript),
    }.take(8).toList(growable: false);
    final ambient = activeCall
        ? 'call'
        : (topics.contains('muzik') ? 'media' : world.ambientMode);
    return world.copyWith(
      userMode: relationLabel.trim().isEmpty
          ? world.userMode
          : relationLabel.trim(),
      ambientMode: ambient,
      repeatedTopics: repeated,
      unfinishedItems: unfinished,
      continuityThread: _buildContinuityThread(
        world.continuityThread,
        transcript,
      ),
      updatedAt: DateTime.now(),
    );
  }

  NovaUnifiedArbitrationDecision _arbitrate({
    required String transcript,
    required NovaSpeakerGraphDecision decision,
    required NovaInternalState internalState,
    required NovaAffectiveState affectiveState,
    required bool activeCall,
    required bool companionActive,
    required bool containsCommand,
  }) {
    final normalized = _normalize(transcript);
    final shouldBackchannel =
        !containsCommand &&
        internalState.socialOpenness >= 0.44 &&
        !_containsAny(normalized, const <String>['dur', 'bekle', 'sus']);
    final shouldSpeak =
        decision.allowConversation &&
        (decision.allowCommand ||
            affectiveState.urgency > 0.28 ||
            _containsAny(normalized, const <String>[
              'nasilsin',
              'orada misin',
              'duyuyor musun',
              'yardim',
            ]));
    final shouldTakeCall =
        activeCall &&
        companionActive &&
        decision.allowCommand &&
        _containsAny(normalized, const <String>[
          'devral',
          'sen konus',
          'sen konuş',
          'cevapla',
        ]);
    final shouldHandCallToUser =
        activeCall &&
        _containsAny(normalized, const <String>[
          'bana ver',
          'ben konus',
          'ben konuş',
          'devret',
        ]);
    final shouldPersistMemory =
        affectiveState.urgency > 0.40 ||
        _containsAny(normalized, const <String>[
          'unutma',
          'hatirla',
          'not',
          'kural',
          'bundan sonra',
        ]);
    final shouldAskPermission = !decision.allowCommand && containsCommand;
    final mode = shouldTakeCall
        ? 'call_takeover'
        : shouldHandCallToUser
        ? 'handoff_to_user'
        : activeCall
        ? 'call'
        : companionActive
        ? 'companion'
        : containsCommand
        ? 'command'
        : 'conversation';
    return NovaUnifiedArbitrationDecision(
      selectedMode: mode,
      shouldSpeak: shouldSpeak,
      shouldListen: true,
      shouldBackchannel: shouldBackchannel,
      shouldTakeCall: shouldTakeCall,
      shouldHandCallToUser: shouldHandCallToUser,
      shouldPersistMemory: shouldPersistMemory,
      shouldAskPermission: shouldAskPermission,
      reason: _buildDecisionReason(mode, decision, affectiveState),
      metadata: <String, dynamic>{
        'containsCommand': containsCommand,
        'activeCall': activeCall,
        'companionActive': companionActive,
        'dominantEmotion': affectiveState.dominantEmotion,
      },
    );
  }

  String _buildDecisionReason(
    String mode,
    NovaSpeakerGraphDecision decision,
    NovaAffectiveState affectiveState,
  ) {
    return '$mode | speaker=${decision.chosenBand.name} | emotion=${affectiveState.dominantEmotion} | confidence=${decision.confidence.toStringAsFixed(2)}';
  }

  double _similarityHeuristic(
    String transcript,
    VoiceAccessLevel? accessLevel,
  ) {
    final normalized = _normalize(transcript);
    final base = accessLevel == VoiceAccessLevel.owner
        ? 0.92
        : accessLevel == VoiceAccessLevel.authorizedGuest
        ? 0.84
        : accessLevel == VoiceAccessLevel.familiar
        ? 0.74
        : accessLevel == VoiceAccessLevel.knownButUnauthorized
        ? 0.62
        : 0.36;
    final richness = min(
      0.08,
      normalized.split(' ').where((e) => e.isNotEmpty).length / 120,
    );
    return _clamp01(base + richness);
  }

  List<String> _mergeOpenLoops(List<String> existing, String transcript) {
    final candidate = _extractUnfinished(transcript);
    return <String>{...existing, ...candidate}.take(8).toList(growable: false);
  }

  List<String> _extractUnfinished(String transcript) {
    final normalized = _normalize(transcript);
    final results = <String>[];
    if (_containsAny(normalized, const <String>[
      'sonra',
      'daha sonra',
      'unutma',
      'yarin',
      'yarın',
    ])) {
      results.add(transcript.trim());
    }
    if (_containsAny(normalized, const <String>[
      'bir sey daha',
      'bir şey daha',
      'ayrica',
      'ayrıca',
    ])) {
      results.add('ek bağlam: ${transcript.trim()}');
    }
    return results.take(3).toList(growable: false);
  }

  List<String> _extractTopics(String transcript) {
    final normalized = _normalize(transcript);
    final stop = <String>{
      've',
      'ile',
      'ama',
      'bana',
      'beni',
      'icin',
      'için',
      'nova',
      'bir',
      'şey',
      'sey',
    };
    final tokens = normalized
        .split(' ')
        .where((e) => e.length >= 4 && !stop.contains(e))
        .toList(growable: false);
    return tokens.take(6).toList(growable: false);
  }

  String _buildContinuityThread(String existing, String transcript) {
    final trimmed = transcript.trim();
    if (trimmed.isEmpty) return existing;
    final pieces = <String>[
      existing.trim(),
      trimmed,
    ].where((e) => e.isNotEmpty).toList(growable: false);
    return pieces.take(3).join(' → ');
  }

  String _resolveRegister({
    required VoiceAccessLevel? accessLevel,
    required bool activeCall,
    required bool companionActive,
  }) {
    if (activeCall && companionActive) return 'call_companion';
    if (activeCall) return 'call';
    switch (accessLevel) {
      case VoiceAccessLevel.owner:
        return 'warm_owner';
      case VoiceAccessLevel.authorizedGuest:
        return 'trusted_delegate';
      case VoiceAccessLevel.familiar:
        return 'warm_social';
      case VoiceAccessLevel.knownButUnauthorized:
        return 'social_boundaried';
      case VoiceAccessLevel.denied:
      case null:
        return 'neutral_guarded';
    }
  }

  bool _containsAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) return true;
    }
    return false;
  }

  String _normalize(String raw) {
    return raw
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
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _clamp01(double value) {
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }
}
