// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/services.dart';
import 'nova_voice_identity_bridge_service.dart';

class NovaRecordedSampleResult {
  final bool success;
  final String filePath;
  final String message;
  const NovaRecordedSampleResult({
    required this.success,
    required this.filePath,
    required this.message,
  });
}

class NovaVoiceIdentityRuntimeService {
  static const MethodChannel _audioChannel = MethodChannel(
    'nova/native_audio_bridge',
  );
  final NovaVoiceIdentityBridgeService bridgeService;
  const NovaVoiceIdentityRuntimeService({required this.bridgeService});
  Future<NovaRecordedSampleResult> captureExternalSample({
    int maxDurationSeconds = 6,
    String outputName = 'nova_voice_identity',
  }) async {
    try {
      final raw = await _audioChannel.invokeMethod<dynamic>(
        'captureCloneSampleExternal',
        {'maxDurationSeconds': maxDurationSeconds, 'outputName': outputName},
      );
      final map = raw is Map
          ? Map<String, dynamic>.from(raw)
          : const <String, dynamic>{};
      return NovaRecordedSampleResult(
        success: map['success'] as bool? ?? false,
        filePath: (map['filePath'] as String? ?? '').trim(),
        message: (map['message'] as String? ?? 'Ses örneği alınamadı.').trim(),
      );
    } on PlatformException catch (e) {
      return NovaRecordedSampleResult(
        success: false,
        filePath: '',
        message: e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Ses örneği alınırken platform hatası oluştu.',
      );
    } catch (_) {
      return const NovaRecordedSampleResult(
        success: false,
        filePath: '',
        message: 'Ses örneği alınırken beklenmeyen hata oluştu.',
      );
    }
  }

  Future<NovaVoiceEnrollResult> enrollFromFreshExternalSample({
    required String voiceId,
    required String displayName,
    int maxDurationSeconds = 6,
    String outputName = 'nova_voice_enroll',
  }) async {
    final sample = await captureExternalSample(
      maxDurationSeconds: maxDurationSeconds,
      outputName: outputName,
    );
    if (!sample.success || sample.filePath.trim().isEmpty) {
      return NovaVoiceEnrollResult(
        success: false,
        voiceId: voiceId.trim(),
        displayName: displayName.trim(),
        message: sample.message,
        embeddingSize: 0,
      );
    }
    return bridgeService.enrollVoiceprintFromFile(
      voiceId: voiceId,
      displayName: displayName,
      audioPath: sample.filePath,
    );
  }

  Future<NovaVoiceIdentifyResult> identifyFromFreshExternalSample({
    int maxDurationSeconds = 4,
    String outputName = 'nova_voice_identify',
    double minSimilarity = 0.64,
  }) async {
    final sample = await captureExternalSample(
      maxDurationSeconds: maxDurationSeconds,
      outputName: outputName,
    );
    if (!sample.success || sample.filePath.trim().isEmpty) {
      return NovaVoiceIdentifyResult(
        success: false,
        matched: false,
        voiceId: '',
        displayName: '',
        similarity: 0,
        message: sample.message,
        embeddingSize: 0,
      );
    }
    return bridgeService.identifyVoiceFromFile(
      audioPath: sample.filePath,
      minSimilarity: minSimilarity,
    );
  }
}
