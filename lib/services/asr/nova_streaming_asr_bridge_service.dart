// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
// NOVA_ASR_STT_AUTHORITY_MARKER: speakerVoiceId ownerConfidence relationshipLabel routed_to_SingleBrainAuthority deterministic_bridge_dto_only.
import 'dart:async';

import 'package:flutter/services.dart';

import '../../core/asr/nova_streaming_asr_event.dart';
import '../../core/asr/nova_streaming_asr_state.dart';

class NovaStreamingAsrBridgeService {
  static const MethodChannel _methodChannel = MethodChannel(
    'nova/streaming_asr_bridge',
  );
  static const EventChannel _eventChannel = EventChannel(
    'nova/streaming_asr_bridge/events',
  );

  const NovaStreamingAsrBridgeService();

  Stream<NovaStreamingAsrEvent> events() {
    return _eventChannel.receiveBroadcastStream().map((dynamic event) {
      return NovaStreamingAsrEvent.fromMap(
        Map<String, dynamic>.from(event as Map? ?? const <String, dynamic>{}),
      );
    });
  }

  Future<bool> initialize() async {
    try {
      final raw = await _methodChannel.invokeMethod<bool>(
        'initializeStreamingAsr',
      );
      return raw ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> start({bool startForegroundService = true}) async {
    try {
      final raw = await _methodChannel.invokeMethod<bool>(
        'startStreamingAsr',
        <String, dynamic>{'startForegroundService': startForegroundService},
      );
      return raw ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> pause() async {
    try {
      return await _methodChannel.invokeMethod<bool>('pauseStreamingAsr') ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resume() async {
    try {
      return await _methodChannel.invokeMethod<bool>('resumeStreamingAsr') ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> stop() async {
    try {
      return await _methodChannel.invokeMethod<bool>('stopStreamingAsr') ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> flush() async {
    try {
      return await _methodChannel.invokeMethod<bool>('flushStreamingAsr') ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearBuffer() async {
    try {
      return await _methodChannel.invokeMethod<bool>(
            'clearStreamingAsrBuffer',
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<NovaStreamingAsrState> getState() async {
    try {
      final raw = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getStreamingAsrState',
      );
      return NovaStreamingAsrState.fromMap(
        Map<String, dynamic>.from(raw ?? const <String, dynamic>{}),
      );
    } catch (_) {
      return const NovaStreamingAsrState.idle();
    }
  }
}
