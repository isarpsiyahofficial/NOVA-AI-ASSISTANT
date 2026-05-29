// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'nova_listening_mode.dart';

class AudioCaptureRequest {
  final NovaListeningMode mode;
  final int maxDurationSeconds;
  final bool noiseReductionPreferred;
  final bool isolateTargetVoicePreferred;
  final String targetDescription;

  const AudioCaptureRequest({
    required this.mode,
    this.maxDurationSeconds = 20,
    this.noiseReductionPreferred = true,
    this.isolateTargetVoicePreferred = true,
    this.targetDescription = '',
  });

  AudioCaptureRequest copyWith({
    NovaListeningMode? mode,
    int? maxDurationSeconds,
    bool? noiseReductionPreferred,
    bool? isolateTargetVoicePreferred,
    String? targetDescription,
  }) {
    return AudioCaptureRequest(
      mode: mode ?? this.mode,
      maxDurationSeconds: maxDurationSeconds ?? this.maxDurationSeconds,
      noiseReductionPreferred:
          noiseReductionPreferred ?? this.noiseReductionPreferred,
      isolateTargetVoicePreferred:
          isolateTargetVoicePreferred ?? this.isolateTargetVoicePreferred,
      targetDescription: targetDescription ?? this.targetDescription,
    );
  }
}
