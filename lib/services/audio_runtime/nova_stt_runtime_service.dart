// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
// NOVA_ASR_STT_AUTHORITY_MARKER: speakerVoiceId ownerConfidence relationshipLabel routed_to_SingleBrainAuthority deterministic_bridge_dto_only.
import 'dart:async';

import '../../core/audio_runtime/nova_listening_mode.dart';
import '../../core/audio_runtime/nova_stt_result.dart';
import 'nova_listening_router_service.dart';
import '../asr/nova_streaming_asr_runtime_service.dart';
import 'nova_native_audio_bridge_service.dart';

class NovaSttRuntimeService {
  final NovaListeningRouterService listeningRouterService;
  final NovaNativeAudioBridgeService nativeAudioBridgeService;
  final NovaStreamingAsrRuntimeService streamingAsrRuntimeService;

  NovaSttRuntimeService({
    required this.listeningRouterService,
    required this.nativeAudioBridgeService,
    NovaStreamingAsrRuntimeService? streamingAsrRuntimeService,
  }) : streamingAsrRuntimeService =
           streamingAsrRuntimeService ?? NovaStreamingAsrRuntimeService();

  Future<NovaSttResult> listenForCommand({
    String targetDescription = 'Sahibin günlük komutu',
  }) async {
    final mode = await listeningRouterService.resolveNormalListeningMode();

    if (mode == NovaListeningMode.fullyShutdown) {
      return const NovaSttResult(
        success: false,
        recognizedText: '',
        detectedLocale: 'tr-TR',
        message: 'Nova tamamen uyku modunda olduğu için dinleme kapalı.',
      );
    }

    if (mode == NovaListeningMode.wakeOnlyListening) {
      return const NovaSttResult(
        success: false,
        recognizedText: '',
        detectedLocale: 'tr-TR',
        message:
            'Nova wake-only güç modunda; sürekli komut dinleme kapalı, sadece tetikleyici dinleniyor.',
      );
    }

    if (mode == NovaListeningMode.callCompanionListening) {
      return const NovaSttResult(
        success: false,
        recognizedText: '',
        detectedLocale: 'tr-TR',
        message:
            'Çağrı/companion dinleme hattı aktif; normal komut dinleme kapalı.',
      );
    }

    await streamingAsrRuntimeService.ensureInitialized();
    if (!streamingAsrRuntimeService.isStarted) {
      final started = await streamingAsrRuntimeService.start(
        owner: 'command_listen',
      );
      if (!started) {
        return const NovaSttResult(
          success: false,
          recognizedText: '',
          detectedLocale: 'tr-TR',
          message: 'Streaming Sherpa komut zinciri başlatılamadı.',
        );
      }
    }

    final completer = Completer<NovaSttResult>();
    StreamSubscription? sub;
    Timer? timer;

    Future<void> finish(NovaSttResult result) async {
      if (completer.isCompleted) return;
      timer?.cancel();
      await sub?.cancel();
      completer.complete(result);
    }

    sub = streamingAsrRuntimeService.events.listen((event) async {
      final text = event.transcript.text.trim();
      if (text.isEmpty) return;
      if (_looksLikeNovaOwnSpeech(text)) return;
      if (!event.isFinal) return;
      if (text.length < 2) return;
      await finish(
        NovaSttResult(
          success: true,
          recognizedText: text,
          detectedLocale: event.transcript.detectedLocale.trim().isEmpty
              ? 'tr-TR'
              : event.transcript.detectedLocale.trim(),
          message:
              'Streaming Sherpa final transcript alındı: $targetDescription',
        ),
      );
    });

    timer = Timer(const Duration(seconds: 12), () async {
      await finish(
        const NovaSttResult(
          success: false,
          recognizedText: '',
          detectedLocale: 'tr-TR',
          message:
              'Streaming Sherpa zincirinden güvenilir final komut alınamadı.',
        ),
      );
    });

    return completer.future;
  }

  bool _looksLikeNovaOwnSpeech(String text) {
    final normalized = text.toLowerCase().trim();
    if (normalized.isEmpty) return false;
    const ownSpeechMarkers = <String>{
      'buyurun',
      'buyurun efendim',
      'efendim',
      'hazırım efendim',
      'dinliyorum efendim',
      'tamam efendim',
    };
    return ownSpeechMarkers.contains(normalized);
  }
}
