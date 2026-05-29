// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/audio_runtime/audio_capture_request.dart';
import '../../core/audio_runtime/nova_listening_mode.dart';
import '../../core/audio_runtime/nova_stt_result.dart';
import '../../core/voice_clone/voice_clone_source_type.dart';
import 'nova_listening_router_service.dart';
import 'nova_native_audio_bridge_service.dart';

class VoiceCloneCaptureRuntimeService {
  final NovaListeningRouterService listeningRouterService;
  final NovaNativeAudioBridgeService nativeAudioBridgeService;

  const VoiceCloneCaptureRuntimeService({
    required this.listeningRouterService,
    required this.nativeAudioBridgeService,
  });

  Future<NovaSttResult> listenForCloneTarget({
    required VoiceCloneSourceType sourceType,
    required String targetDescription,
  }) async {
    final mode = await listeningRouterService.resolveCloneListeningMode(
      sourceType,
    );

    if (mode == NovaListeningMode.fullyShutdown) {
      return const NovaSttResult(
        success: false,
        recognizedText: '',
        detectedLocale: 'tr-TR',
        message: 'Nova tamamen uyku modunda olduğu için klon dinleme kapalı.',
      );
    }

    if (!listeningRouterService.isCloneSpecificListening(mode)) {
      return NovaSttResult(
        success: false,
        recognizedText: '',
        detectedLocale: 'tr-TR',
        message: listeningRouterService.denyReasonForCloneBlocked(sourceType),
      );
    }

    return nativeAudioBridgeService.transcribeCloneListening(
      AudioCaptureRequest(
        mode: mode,
        maxDurationSeconds: 20,
        noiseReductionPreferred: true,
        isolateTargetVoicePreferred: true,
        targetDescription: targetDescription,
      ),
    );
  }
}
