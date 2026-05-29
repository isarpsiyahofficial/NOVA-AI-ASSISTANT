// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/services.dart';

import 'nova_overlay_presence_runtime_service.dart';

class NovaOverlayBridgeService {
  static const NovaOverlayPresenceRuntimeService _presenceRuntime =
      NovaOverlayPresenceRuntimeService();
  static const MethodChannel _channel = MethodChannel('nova/overlay_bridge');

  const NovaOverlayBridgeService();

  Future<void> showCloneProgress({
    required String title,
    required String status,
    required double progress,
    double? textOpacity,
    double? shellOpacity,
    String? emotionLabel,
    bool? showEmotionChip,
  }) async {
    try {
      await _channel
          .invokeMethod<dynamic>('showCloneOverlayProgress', <String, dynamic>{
            'title': title,
            'status': status,
            'progress': progress,
            if (textOpacity != null) 'textOpacity': textOpacity,
            if (shellOpacity != null) 'shellOpacity': shellOpacity,
            if (emotionLabel != null) 'emotionLabel': emotionLabel,
            if (showEmotionChip != null) 'showEmotionChip': showEmotionChip,
          });
    } catch (_) {}
  }

  Future<void> showCloneOverlayProgress({
    required String title,
    required String status,
    required double progress,
    double? textOpacity,
    double? shellOpacity,
    String? emotionLabel,
    bool? showEmotionChip,
  }) {
    return showCloneProgress(
      title: title,
      status: status,
      progress: progress,
      textOpacity: textOpacity,
      shellOpacity: shellOpacity,
      emotionLabel: emotionLabel,
      showEmotionChip: showEmotionChip,
    );
  }

  Future<void> hideCloneProgress() async {
    try {
      await _channel.invokeMethod<dynamic>('hideCloneOverlayProgress');
    } catch (_) {}
  }

  Future<void> hideCloneOverlayProgress() {
    return hideCloneProgress();
  }

  Future<void> showPresenceState({
    required String assistantName,
    required String mode,
    String emotion = 'neutral',
    double energy = 0.5,
    double speakingIntensity = 0.0,
  }) async {
    final state = _presenceRuntime.buildState(
      mode: mode,
      emotion: emotion,
      energy: energy,
      speakingIntensity: speakingIntensity,
      assistantName: assistantName,
    );
    await showCloneProgress(
      title: state.title,
      status: state.status,
      progress: state.motion,
      textOpacity: state.textOpacity,
      shellOpacity: state.shellOpacity,
      emotionLabel: state.emotionLabel,
      showEmotionChip: state.showEmotionChip,
    );
  }

  Map<String, dynamic> buildOverlayHint({
    required String assistantName,
    required String mode,
    required String emotion,
    required double energy,
    required double speakingIntensity,
  }) {
    final state = _presenceRuntime.buildState(
      mode: mode,
      emotion: emotion,
      energy: energy,
      speakingIntensity: speakingIntensity,
      assistantName: assistantName,
    );
    return <String, dynamic>{
      'title': state.title,
      'status': state.status,
      'motion': state.motion,
      'textOpacity': state.textOpacity,
      'shellOpacity': state.shellOpacity,
      'emotionLabel': state.emotionLabel,
      'showEmotionChip': state.showEmotionChip,
    };
  }

  Map<String, dynamic> buildReadableOverlayPlan(String mode) {
    final normalizedMode = mode.trim().isEmpty ? 'idle' : mode.trim();
    final prefersReadableText = normalizedMode != 'sleeping';
    return <String, dynamic>{
      'mode': normalizedMode,
      'prefersReadableText': prefersReadableText,
      'recommendedTextOpacity': prefersReadableText ? 0.92 : 0.78,
      'recommendedShellOpacity': prefersReadableText ? 0.26 : 0.18,
      'touchPassthrough': true,
    };
  }

  String buildEmotionOverlayState(String emotion) {
    switch (emotion.trim().toLowerCase()) {
      case 'warm':
      case 'caring':
        return 'overlay_warm';
      case 'urgent':
      case 'focused':
        return 'overlay_alert';
      case 'sad':
      case 'gentle':
        return 'overlay_soft';
      default:
        return 'overlay_neutral';
    }
  }
}
