// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals_to_create_immutables, duplicate_ignore, prefer_const_constructors
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
// NOVA_ASR_SINGLE_SESSION_OWNER_GUARD_V4_EXPLICIT_TRANSFER
// NOVA_ASR_STT_AUTHORITY_MARKER: speakerVoiceId ownerConfidence relationshipLabel routed_to_SingleBrainAuthority deterministic_bridge_dto_only.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/asr/nova_streaming_asr_event.dart';
import '../../core/asr/nova_streaming_asr_state.dart';
import '../../core/runtime/nova_runtime_signal.dart';
import '../runtime/nova_runtime_signal_service.dart';
import '../self_repair/nova_repair_runtime_policy_enforcer_service.dart';
import 'nova_asr_health_service.dart';
import 'nova_streaming_asr_bridge_service.dart';
import 'nova_streaming_transcript_router_service.dart';

class NovaAsrPlaybackLease {
  final String owner;
  final int sessionToken;
  final bool wasStarted;
  final int issuedAtEpochMs;

  const NovaAsrPlaybackLease({
    required this.owner,
    required this.sessionToken,
    required this.wasStarted,
    required this.issuedAtEpochMs,
  });

  bool get isUsable => wasStarted && owner != 'none';
}

class NovaStreamingAsrRuntimeService {
  final NovaStreamingAsrBridgeService bridgeService;
  final NovaStreamingTranscriptRouterService transcriptRouterService;
  final NovaAsrHealthService healthService;

  static StreamSubscription<NovaStreamingAsrEvent>? _subscription;
  static final StreamController<NovaStreamingAsrEvent> _events =
      StreamController<NovaStreamingAsrEvent>.broadcast();
  static NovaStreamingAsrState _latestState =
      const NovaStreamingAsrState.idle();
  static bool _started = false;
  static bool _transitionInFlight = false;
  static int _sessionToken = 0;
  static String _owner = 'none';
  static final List<String> _recentFinalFingerprints = <String>[];
  static const int _maxFinalFingerprints = 48;

  NovaStreamingAsrRuntimeService({
    NovaStreamingAsrBridgeService? bridgeService,
    NovaStreamingTranscriptRouterService? transcriptRouterService,
    NovaAsrHealthService? healthService,
  }) : bridgeService = bridgeService ?? const NovaStreamingAsrBridgeService(),
       transcriptRouterService =
           transcriptRouterService ??
           const NovaStreamingTranscriptRouterService(),
       healthService = healthService ?? const NovaAsrHealthService();

  Stream<NovaStreamingAsrEvent> get events => _events.stream;
  NovaStreamingAsrState get latestState => _latestState;
  bool get isStarted => _started;
  String get owner => _owner;

  Future<bool> ensureInitialized() async {
    await NovaRepairRuntimePolicyEnforcerService.instance.ensureLoaded();
    final ok = await bridgeService.initialize();
    _latestState = await bridgeService.getState();
    return ok;
  }

  Future<bool> start({String owner = 'runtime', bool force = false}) async {
    final normalizedOwner = owner.trim().isEmpty ? 'runtime' : owner.trim();

    if (_started && _owner == normalizedOwner) {
      final initialized = await ensureInitialized();
      _latestState = await bridgeService.getState();
      debugPrint(
        'NOVA_STREAMING_ASR_START_IDEMPOTENT owner=$_owner '
        'initialized=$initialized running=${_latestState.running} '
        'foreground=${_latestState.foregroundServiceRunning}',
      );
      await _recordHealth();
      return initialized && _latestState.running;
    }

    if (_started && _owner != 'none' && _owner != normalizedOwner && !force) {
      debugPrint(
        'NOVA_STREAMING_ASR_OWNER_REJECTED current=$_owner '
        'requested=$normalizedOwner running=${_latestState.running}',
      );
      await _recordOwnerRejected(normalizedOwner);
      return false;
    }

    if (_transitionInFlight) {
      debugPrint(
        'NOVA_STREAMING_ASR_START_TRANSITION_REJECTED current=$_owner '
        'requested=$normalizedOwner started=$_started',
      );
      await _recordOwnerRejected(normalizedOwner);
      return _started && _owner == normalizedOwner;
    }

    _transitionInFlight = true;
    final token = ++_sessionToken;
    _recentFinalFingerprints.clear();
    final previousOwner = _owner;

    try {
      if (_started && previousOwner != 'none' && previousOwner != normalizedOwner) {
        // A force transfer is a controlled handoff, not a second recognizer.
        // Stop the native engine and detach the old event subscription before
        // assigning the new owner, otherwise two logical surfaces can consume
        // the same microphone/ring buffer concurrently.
        await _subscription?.cancel();
        _subscription = null;
        await bridgeService.stop();
        _latestState = await bridgeService.getState();
        _started = false;
        await _recordOwnerTransferred(
          previousOwner: previousOwner,
          nextOwner: normalizedOwner,
        );
      }

      _owner = normalizedOwner;
      final initialized = await ensureInitialized();
      if (!initialized || token != _sessionToken) {
        _started = false;
        _owner = 'none';
        await _recordHealth();
        return false;
      }

      await _subscription?.cancel();
      _subscription = null;

      // Native start sırasında status/error event'i gelebilir. Dinleyiciyi
      // önce kurarak "bildirim var ama Dart tarafı olay kaçırdı" durumunu kapatıyoruz.
      final earlySubscription = bridgeService.events().listen(
        _handleEvent,
        onError: (Object error, StackTrace stackTrace) async {
          debugPrint(
            'NOVA_STREAMING_ASR_EVENT_ERROR owner=$_owner '
            'type=${error.runtimeType} error=$error',
          );
          debugPrint(stackTrace.toString());
          _latestState = await bridgeService.getState();
          await _recordHealth();
        },
      );
      _subscription = earlySubscription;

      final ok = await bridgeService.start();
      _latestState = await bridgeService.getState();
      _started = ok && token == _sessionToken;

      if (!_started) {
        await earlySubscription.cancel();
        if (_subscription == earlySubscription) {
          _subscription = null;
        }
        _owner = 'none';
      }

      debugPrint(
        'NOVA_STREAMING_ASR_START_RESULT owner=$_owner ok=$_started token=$token '
        'running=${_latestState.running} '
        'foreground=${_latestState.foregroundServiceRunning} '
        'partial=${_latestState.partialCount} final=${_latestState.finalCount} '
        'message=${_latestState.message}',
      );
      await _recordHealth();
      return _started;
    } catch (error, stackTrace) {
      debugPrint(
        'NOVA_STREAMING_ASR_START_ERROR owner=$_owner '
        'type=${error.runtimeType} error=$error',
      );
      debugPrint(stackTrace.toString());
      _started = false;
      _owner = 'none';
      await _subscription?.cancel();
      _subscription = null;
      try {
        await bridgeService.stop();
      } catch (_) {}
      _latestState = await bridgeService.getState();
      await _recordHealth();
      return false;
    } finally {
      _transitionInFlight = false;
    }
  }

  static Future<NovaAsrPlaybackLease> pauseForPlayback(
    NovaStreamingAsrBridgeService bridgeService,
  ) async {
    final lease = NovaAsrPlaybackLease(
      owner: _owner,
      sessionToken: _sessionToken,
      wasStarted: _started,
      issuedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
    );
    if (!lease.isUsable) return lease;
    await bridgeService.pause();
    return lease;
  }

  static Future<bool> resumeAfterPlayback(
    NovaStreamingAsrBridgeService bridgeService,
    NovaAsrPlaybackLease lease,
  ) async {
    final sameSession = lease.sessionToken == _sessionToken;
    final sameOwner = lease.owner == _owner;
    if (!lease.isUsable || !_started || !sameSession || !sameOwner) {
      debugPrint(
        'NOVA_ASR_PLAYBACK_RESUME_REJECTED '
        'leaseOwner=${lease.owner} currentOwner=$_owner '
        'leaseSession=${lease.sessionToken} currentSession=$_sessionToken '
        'started=$_started',
      );
      return false;
    }
    return await bridgeService.resume();
  }

  Future<void> pause() async {
    await bridgeService.pause();
    _latestState = await bridgeService.getState();
  }

  Future<void> resume() async {
    await bridgeService.resume();
    _latestState = await bridgeService.getState();
  }

  Future<void> stop({String owner = '', bool force = false}) async {
    final normalizedOwner = owner.trim();

    if (!force &&
        normalizedOwner.isNotEmpty &&
        _owner != 'none' &&
        _owner != normalizedOwner) {
      debugPrint(
        'NOVA_STREAMING_ASR_STOP_IGNORED current=$_owner requested=$normalizedOwner',
      );
      return;
    }

    if (_transitionInFlight) {
      if (force || normalizedOwner.isEmpty || _owner == normalizedOwner) {
        _started = false;
        _owner = 'none';
        ++_sessionToken;
      }
      return;
    }

    _transitionInFlight = true;
    ++_sessionToken;
    _recentFinalFingerprints.clear();

    try {
      _started = false;
      await bridgeService.stop();
      _latestState = await bridgeService.getState();
      await _subscription?.cancel();
      _subscription = null;
      _owner = 'none';
      await _recordHealth();
    } finally {
      _transitionInFlight = false;
    }
  }

  Future<void> flush() => bridgeService.flush();

  void _handleEvent(NovaStreamingAsrEvent event) {
    if (event.isFinal && _isDuplicateFinalEvent(event)) {
      debugPrint(
        'NOVA_STREAMING_ASR_FINAL_DEDUPED owner=$_owner '
        'session=$_sessionToken segment=${event.transcript.segmentId}',
      );
      return;
    }
    final routeDecision = transcriptRouterService.decide(event);
    final policyEnforcer = NovaRepairRuntimePolicyEnforcerService.instance;
    final forceEligibleRoute =
        routeDecision.route == 'conversation' ||
        routeDecision.route == 'command' ||
        routeDecision.route == 'teaching' ||
        routeDecision.route == 'reminder' ||
        routeDecision.route == 'call';
    final effectiveRoute =
        event.isFinal &&
            routeDecision.normalizedText.trim().isNotEmpty &&
            policyEnforcer.forceAsrTranscriptToSingleBrain &&
            forceEligibleRoute
        ? 'conversation'
        : routeDecision.route;

    if (event.isFinal && routeDecision.normalizedText.trim().isNotEmpty) {
      final routedToBrain =
          effectiveRoute == 'conversation' ||
          effectiveRoute == 'command' ||
          effectiveRoute == 'teaching';
      final ambientIgnored = !routedToBrain && effectiveRoute == 'ambient';
      unawaited(
        NovaRuntimeSignalService.instance.record(
          kind: NovaRuntimeSignalKind.stt,
          level: routedToBrain || ambientIgnored
              ? NovaRuntimeSignalLevel.info
              : NovaRuntimeSignalLevel.warning,
          code: routedToBrain
              ? 'TRANSCRIPT_ROUTE_CANDIDATE_FOR_SINGLE_BRAIN'
              : (ambientIgnored
                    ? 'TRANSCRIPT_AMBIENT_IGNORED'
                    : 'transcript_not_routed_to_single_brain'),
          message: routedToBrain
              ? 'ASR final transcript SingleBrain aday route olarak işaretlendi; gerçek teslim ContinuousListening runtime üzerinden yapılır.'
              : (ambientIgnored
                    ? 'ASR final transcript arka plan konuşması olarak yok sayıldı.'
                    : 'ASR final transcript SingleBrain dışı route’a düştü.'),
          technicalDetails:
              'route=${routeDecision.route} effectiveRoute=$effectiveRoute chars=${routeDecision.normalizedText.length}',
          diagnosticCandidate: !routedToBrain && !ambientIgnored,
          metadata: <String, dynamic>{
            'source': 'streaming_asr_runtime',
            'route': routeDecision.route,
            'effectiveRoute': effectiveRoute,
            'forceSingleBrainPolicy':
                policyEnforcer.forceAsrTranscriptToSingleBrain,
            'forceEligibleRoute': forceEligibleRoute,
            'isFinal': event.isFinal,
          },
        ),
      );
    }

    if (event.isError) {
      _latestState = NovaStreamingAsrState(
        initialized: _latestState.initialized,
        running: _latestState.running,
        foregroundServiceRunning: _latestState.foregroundServiceRunning,
        modelReady: _latestState.modelReady,
        singleAuthorityConfirmed: _latestState.singleAuthorityConfirmed,
        embeddedSherpaReady: _latestState.embeddedSherpaReady,
        message: event.message.trim().isEmpty
            ? _latestState.message
            : event.message.trim(),
        partialCount: _latestState.partialCount,
        finalCount: _latestState.finalCount,
        droppedFrames: _latestState.droppedFrames + 1,
        modelAssetPath: _latestState.modelAssetPath,
        decoderAssetPath: _latestState.decoderAssetPath,
        tokenAssetPath: _latestState.tokenAssetPath,
        configAssetPath: _latestState.configAssetPath,
      );
      unawaited(_recordHealth());
    }
    _events.add(event);
  }

  bool _isDuplicateFinalEvent(NovaStreamingAsrEvent event) {
    final transcript = event.transcript;
    final normalizedText = transcript.text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    if (normalizedText.isEmpty) return false;
    final fingerprint = <Object>[
      _sessionToken,
      transcript.segmentId,
      transcript.identityAudioPath.trim(),
      normalizedText,
    ].join('|');
    if (_recentFinalFingerprints.contains(fingerprint)) return true;
    _recentFinalFingerprints.add(fingerprint);
    if (_recentFinalFingerprints.length > _maxFinalFingerprints) {
      _recentFinalFingerprints.removeRange(
        0,
        _recentFinalFingerprints.length - _maxFinalFingerprints,
      );
    }
    return false;
  }

  Future<void> _recordOwnerRejected(String requestedOwner) async {
    await NovaRuntimeSignalService.instance.record(
      kind: NovaRuntimeSignalKind.stt,
      level: NovaRuntimeSignalLevel.warning,
      code: 'streaming_asr_owner_rejected',
      message:
          'NOVA_STREAMING_ASR_OWNER_REJECTED current=$_owner requested=$requestedOwner',
      technicalDetails: latestState.toMap().toString(),
      diagnosticCandidate: true,
    );
  }

  Future<void> _recordOwnerTransferred({
    required String previousOwner,
    required String nextOwner,
  }) async {
    await NovaRuntimeSignalService.instance.record(
      kind: NovaRuntimeSignalKind.stt,
      level: NovaRuntimeSignalLevel.info,
      code: 'streaming_asr_owner_transferred',
      message:
          'Streaming ASR oturumu tek sahip kuralıyla devredildi: $previousOwner -> $nextOwner',
      technicalDetails: latestState.toMap().toString(),
      diagnosticCandidate: false,
      metadata: <String, dynamic>{
        'previousOwner': previousOwner,
        'nextOwner': nextOwner,
        'nativeStoppedBeforeTransfer': true,
      },
    );
  }

  Future<void> _recordHealth() async {
    final snapshot = healthService.inspect(_latestState);
    await NovaRuntimeSignalService.instance.record(
      kind: NovaRuntimeSignalKind.stt,
      level: snapshot.healthy
          ? NovaRuntimeSignalLevel.info
          : NovaRuntimeSignalLevel.warning,
      code: snapshot.healthy ? 'streaming_asr_healthy' : 'streaming_asr_issue',
      message: '${snapshot.message} owner=$_owner',
      technicalDetails: snapshot.state.toMap().toString(),
      diagnosticCandidate: !snapshot.healthy,
    );
  }

  Future<void> dispose() async {
    await stop(force: true);
  }
}
