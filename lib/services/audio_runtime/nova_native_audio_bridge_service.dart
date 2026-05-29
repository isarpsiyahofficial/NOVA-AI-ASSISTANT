// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/services.dart';

import '../../core/audio_runtime/audio_capture_request.dart';
import '../../core/audio_runtime/nova_stt_result.dart';
import '../../core/audio_runtime/voice_clone_job.dart';
import '../../core/runtime/nova_runtime_signal.dart';
import '../runtime/nova_runtime_signal_service.dart';

class NovaNativeAudioBridgeService {
  static const MethodChannel _audioChannel = MethodChannel(
    'nova/native_audio_bridge',
  );

  static const MethodChannel _projectionChannel = MethodChannel(
    'nova/projection_bridge',
  );

  static const MethodChannel _sherpaTtsChannel = MethodChannel(
    'nova/xtts_bridge',
  );

  const NovaNativeAudioBridgeService();

  Future<bool> isSherpaTtsReady() async {
    try {
      final result = await _sherpaTtsChannel.invokeMethod<bool>('isXttsReady');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isXttsReady() async {
    try {
      final result = await _sherpaTtsChannel.invokeMethod<bool>('isXttsReady');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> warmupSherpaTts({String preferredModelKey = ''}) async {
    try {
      final result = await _sherpaTtsChannel.invokeMethod<bool>(
        'warmupXtts',
        <String, dynamic>{'preferredModelKey': preferredModelKey},
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> warmupXtts({String preferredModelKey = ''}) async {
    try {
      final result = await _sherpaTtsChannel.invokeMethod<bool>(
        'warmupXtts',
        <String, dynamic>{'preferredModelKey': preferredModelKey},
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getSherpaTtsCapabilities() async {
    try {
      final raw = await _sherpaTtsChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getXttsCapabilities',
      );
      final map = Map<String, dynamic>.from(raw ?? const <String, dynamic>{});
      return <String, dynamic>{...map, 'engineName': 'Sherpa TTS'};
    } catch (_) {
      return <String, dynamic>{
        'ready': false,
        'engineName': 'Sherpa TTS',
        'supportsSpeakerId': false,
        'supportsReferenceAudio': false,
        'availableModels': const <String>[],
        'message': 'Sherpa TTS capability bilgisi alınamadı.',
      };
    }
  }

  Future<Map<String, dynamic>> getXttsCapabilities() async {
    try {
      final raw = await _sherpaTtsChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getXttsCapabilities',
      );
      return Map<String, dynamic>.from(raw ?? const <String, dynamic>{});
    } catch (_) {
      return <String, dynamic>{
        'ready': false,
        'supportsSpeakerId': false,
        'supportsReferenceAudio': false,
        'availableModels': const <String>[],
        'message': 'XTTS capability bilgisi alınamadı.',
      };
    }
  }

  Future<bool> speakWithSherpaTts({
    required String text,
    String language = 'tr',
    String speakerPath = '',
  }) async {
    try {
      final result = await _sherpaTtsChannel.invokeMethod<bool>(
        'speakWithXtts',
        <String, dynamic>{
          'text': text,
          'language': language,
          'speakerPath': speakerPath,
        },
      );

      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> speakWithXtts({
    required String text,
    String language = 'tr',
    String speakerPath = '',
  }) async {
    try {
      final result = await _sherpaTtsChannel.invokeMethod<bool>(
        'speakWithXtts',
        <String, dynamic>{
          'text': text,
          'language': language,
          'speakerPath': speakerPath,
        },
      );

      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> stopSherpaTts() async {
    try {
      await _sherpaTtsChannel.invokeMethod('stopXtts');
    } catch (_) {}
  }

  Future<void> stopXtts() async {
    try {
      await _sherpaTtsChannel.invokeMethod('stopXtts');
    } catch (_) {}
  }

  Future<NovaSttResult> decodeStreamingSnapshot(
    AudioCaptureRequest request,
  ) async {
    try {
      final result = await _audioChannel.invokeMethod<Map<dynamic, dynamic>>(
        'decodeStreamingSnapshot',
        <String, dynamic>{
          'mode': request.mode.name,
          'maxDurationSeconds': request.maxDurationSeconds,
          'noiseReductionPreferred': request.noiseReductionPreferred,
          'isolateTargetVoicePreferred': request.isolateTargetVoicePreferred,
          'targetDescription': request.targetDescription,
        },
      );

      final map = Map<String, dynamic>.from(
        result ?? const <String, dynamic>{},
      );

      return NovaSttResult(
        success: map['success'] as bool? ?? false,
        recognizedText: (map['recognizedText'] as String? ?? '').trim(),
        detectedLocale: (map['detectedLocale'] as String? ?? 'tr-TR').trim(),
        message: (map['message'] as String? ?? '').trim(),
      );
    } catch (_) {
      await NovaRuntimeSignalService.instance.record(
        kind: NovaRuntimeSignalKind.stt,
        level: NovaRuntimeSignalLevel.error,
        code: 'stt_unavailable',
        message: 'Native ses köprüsü şu an kullanılamıyor.',
        technicalDetails: 'decodeStreamingSnapshot invoke failed',
        diagnosticCandidate: true,
      );

      return const NovaSttResult(
        success: false,
        recognizedText: '',
        detectedLocale: 'tr-TR',
        message: 'Native ses köprüsü şu an kullanılamıyor.',
      );
    }
  }

  Future<Map<String, dynamic>> beginPassiveListening() async {
    return _mapCall('beginPassiveListening');
  }

  Future<Map<String, dynamic>> endPassiveListening() async {
    return _mapCall('endPassiveListening');
  }

  Future<Map<String, dynamic>> beginCallCompanionListening() async {
    return _mapCall('beginCallCompanionListening');
  }

  Future<Map<String, dynamic>> endCallCompanionListening() async {
    return _mapCall('endCallCompanionListening');
  }

  Future<Map<String, dynamic>> endListeningSession() async {
    return _mapCall('endListeningSession');
  }

  Future<Map<String, dynamic>> preparePassiveListening() async {
    return beginPassiveListening();
  }

  Future<Map<String, dynamic>> finishPassiveListening() async {
    return endPassiveListening();
  }

  Future<Map<String, dynamic>> prepareCallCompanionListening() async {
    return beginCallCompanionListening();
  }

  Future<Map<String, dynamic>> finishCallCompanionListening() async {
    return endCallCompanionListening();
  }

  Future<bool> ensureStreamingAsrReady() async {
    try {
      final result = await _audioChannel.invokeMethod<Map<dynamic, dynamic>>(
        'ensureStreamingAsrReady',
      );
      final map = Map<String, dynamic>.from(
        result ?? const <String, dynamic>{},
      );
      return map['success'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getStreamingAsrExecutiveState() async {
    try {
      final result = await _audioChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getStreamingAsrExecutiveState',
      );
      return Map<String, dynamic>.from(result ?? const <String, dynamic>{});
    } catch (_) {
      return <String, dynamic>{
        'success': false,
        'message': 'Streaming ASR yürütücü durumu alınamadı.',
      };
    }
  }

  Future<Map<String, dynamic>> prewarmContinuousListeningSession({
    int holdForMs = 120000,
  }) async {
    try {
      final result = await _audioChannel.invokeMethod<Map<dynamic, dynamic>>(
        'prewarmContinuousListeningSession',
        <String, dynamic>{'holdForMs': holdForMs},
      );
      return Map<String, dynamic>.from(result ?? const <String, dynamic>{});
    } catch (_) {
      return <String, dynamic>{
        'success': false,
        'message': 'Sürekli dinleme oturumu ısıtılamadı.',
      };
    }
  }

  Future<Map<String, dynamic>> releaseContinuousListeningSession() async {
    return _mapCall('releaseContinuousListeningSession');
  }

  Future<Map<String, dynamic>> getContinuousListeningSessionState() async {
    return _mapCall('getContinuousListeningSessionState');
  }

  Future<Map<String, dynamic>> startStreamingVoiceGate() async {
    return _mapCall('startStreamingVoiceGate');
  }

  Future<Map<String, dynamic>> stopStreamingVoiceGate() async {
    return _mapCall('stopStreamingVoiceGate');
  }

  Future<Map<String, dynamic>> getStreamingVoiceGateState() async {
    return _mapCall('getStreamingVoiceGateState');
  }

  Future<Map<String, dynamic>> requestInternalAudioCapturePermission() async {
    try {
      final result = await _projectionChannel
          .invokeMethod<Map<dynamic, dynamic>>(
            'requestInternalAudioCapturePermission',
          );
      return Map<String, dynamic>.from(result ?? const <String, dynamic>{});
    } catch (_) {
      return <String, dynamic>{
        'success': false,
        'message': 'Telefon içi ses izni istenemedi.',
      };
    }
  }

  Future<Map<String, dynamic>> clearInternalAudioCapturePermission() async {
    try {
      final result = await _projectionChannel
          .invokeMethod<Map<dynamic, dynamic>>(
            'clearInternalAudioCapturePermission',
          );
      return Map<String, dynamic>.from(result ?? const <String, dynamic>{});
    } catch (_) {
      return <String, dynamic>{
        'success': false,
        'message': 'Telefon içi ses izni temizlenemedi.',
      };
    }
  }

  Future<Map<String, dynamic>> captureCloneSampleExternal({
    required int maxDurationSeconds,
    required String outputName,
  }) async {
    try {
      final result = await _audioChannel.invokeMethod<Map<dynamic, dynamic>>(
        'captureCloneSampleExternal',
        <String, dynamic>{
          'maxDurationSeconds': maxDurationSeconds,
          'outputName': outputName,
        },
      );

      return Map<String, dynamic>.from(result ?? const <String, dynamic>{});
    } catch (_) {
      return <String, dynamic>{
        'success': false,
        'filePath': '',
        'message': 'Dış ses örneği alınamadı.',
      };
    }
  }

  Future<Map<String, dynamic>> captureCloneSampleInternal({
    required int maxDurationSeconds,
    required String outputName,
  }) async {
    try {
      final result = await _audioChannel.invokeMethod<Map<dynamic, dynamic>>(
        'captureCloneSampleInternal',
        <String, dynamic>{
          'maxDurationSeconds': maxDurationSeconds,
          'outputName': outputName,
        },
      );

      return Map<String, dynamic>.from(result ?? const <String, dynamic>{});
    } catch (_) {
      return <String, dynamic>{
        'success': false,
        'filePath': '',
        'message': 'Telefon içi ses örneği alınamadı.',
      };
    }
  }

  Future<Map<String, dynamic>> getAudioInputPolicyState() async {
    return _mapCall('getAudioInputPolicyState');
  }

  Future<Map<String, dynamic>> getVoiceCloneRuntimeState() async {
    try {
      final tts = await getSherpaTtsCapabilities();
      final projection = await getAudioInputPolicyState();
      final sherpaReady = tts['ready'] == true;
      final supportsReferenceAudio =
          sherpaReady || tts['supportsReferenceAudio'] == true;
      return <String, dynamic>{
        'success': true,
        'sherpaTtsReady': sherpaReady,
        'availableModels': tts['availableModels'] ?? const <String>[],
        'supportsReferenceAudio': supportsReferenceAudio,
        'supportsSpeakerId': tts['supportsSpeakerId'] == true,
        'audioPolicy': projection,
        'message': sherpaReady
            ? 'Voice clone çalışma durumu toplandı.'
            : 'Referans-ses fallback hazır. Tam sentez modeli hazır olmasa da klon profili oluşturulabilir.',
      };
    } catch (_) {
      return <String, dynamic>{
        'success': false,
        'sherpaTtsReady': false,
        'availableModels': const <String>[],
        'supportsReferenceAudio': false,
        'supportsSpeakerId': false,
        'message': 'Voice clone çalışma durumu alınamadı.',
      };
    }
  }

  Future<Map<String, dynamic>> createVoiceClone(VoiceCloneJob job) async {
    try {
      final result = await _audioChannel.invokeMethod<Map<dynamic, dynamic>>(
        'createVoiceClone',
        job.toMap(),
      );

      return Map<String, dynamic>.from(result ?? const <String, dynamic>{});
    } catch (_) {
      return <String, dynamic>{
        'success': false,
        'message': 'Voice clone motoru şu an kullanılamıyor.',
      };
    }
  }

  Future<NovaSttResult> transcribeCloneListening(AudioCaptureRequest request) {
    return decodeStreamingSnapshot(request);
  }

  Future<Map<String, dynamic>> _mapCall(String method) async {
    try {
      final result = await _audioChannel.invokeMethod<Map<dynamic, dynamic>>(
        method,
      );
      return Map<String, dynamic>.from(result ?? const <String, dynamic>{});
    } catch (_) {
      return <String, dynamic>{
        'success': false,
        'message': 'Native ses politikası işlemi başarısız oldu.',
      };
    }
  }
}
