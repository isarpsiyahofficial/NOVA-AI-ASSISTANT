// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/services.dart';

class NovaVoiceIdentityWarmupResult {
  final bool success;
  final String message;
  const NovaVoiceIdentityWarmupResult({
    required this.success,
    required this.message,
  });
}

class NovaVoiceEnrollResult {
  final bool success;
  final String voiceId;
  final String displayName;
  final String message;
  final int embeddingSize;
  const NovaVoiceEnrollResult({
    required this.success,
    required this.voiceId,
    required this.displayName,
    required this.message,
    required this.embeddingSize,
  });
}

class NovaVoiceIdentifyResult {
  final bool success;
  final bool matched;
  final String voiceId;
  final String displayName;
  final double similarity;
  final String message;
  final int embeddingSize;
  const NovaVoiceIdentifyResult({
    required this.success,
    required this.matched,
    required this.voiceId,
    required this.displayName,
    required this.similarity,
    required this.message,
    required this.embeddingSize,
  });
}

class NovaVoiceIdentityBridgeService {
  static const MethodChannel _channel = MethodChannel(
    'nova/voice_identity_bridge',
  );
  const NovaVoiceIdentityBridgeService();
  Future<NovaVoiceIdentityWarmupResult> warmup() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('warmupVoiceIdentity');
      final map = raw is Map
          ? Map<String, dynamic>.from(raw)
          : const <String, dynamic>{};
      return NovaVoiceIdentityWarmupResult(
        success: map['success'] as bool? ?? false,
        message:
            (map['message'] as String? ?? 'Ses kimliği motoru yanıt vermedi.')
                .trim(),
      );
    } catch (_) {
      return const NovaVoiceIdentityWarmupResult(
        success: false,
        message: 'Ses kimliği motoru başlatılırken beklenmeyen hata oluştu.',
      );
    }
  }

  Future<NovaVoiceEnrollResult> enrollVoiceprintFromFile({
    required String voiceId,
    required String displayName,
    required String audioPath,
  }) async {
    try {
      final raw = await _channel
          .invokeMethod<dynamic>('enrollVoiceprintFromFile', {
            'voiceId': voiceId.trim(),
            'displayName': displayName.trim(),
            'audioPath': audioPath.trim(),
          });
      final map = raw is Map
          ? Map<String, dynamic>.from(raw)
          : const <String, dynamic>{};
      return NovaVoiceEnrollResult(
        success: map['success'] as bool? ?? false,
        voiceId: (map['voiceId'] as String? ?? '').trim(),
        displayName: (map['displayName'] as String? ?? '').trim(),
        message: (map['message'] as String? ?? '').trim(),
        embeddingSize: (map['embeddingSize'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return NovaVoiceEnrollResult(
        success: false,
        voiceId: voiceId,
        displayName: displayName,
        message: 'Voiceprint kaydı sırasında beklenmeyen hata oluştu.',
        embeddingSize: 0,
      );
    }
  }

  Future<NovaVoiceIdentifyResult> identifyVoiceFromFile({
    required String audioPath,
    double minSimilarity = 0.64,
  }) async {
    try {
      final raw = await _channel.invokeMethod<dynamic>(
        'identifyVoiceFromFile',
        {'audioPath': audioPath.trim(), 'minSimilarity': minSimilarity},
      );
      final map = raw is Map
          ? Map<String, dynamic>.from(raw)
          : const <String, dynamic>{};
      return NovaVoiceIdentifyResult(
        success: map['success'] as bool? ?? false,
        matched: map['matched'] as bool? ?? false,
        voiceId: (map['voiceId'] as String? ?? '').trim(),
        displayName: (map['displayName'] as String? ?? '').trim(),
        similarity: (map['similarity'] as num?)?.toDouble() ?? 0,
        message: (map['message'] as String? ?? '').trim(),
        embeddingSize: (map['embeddingSize'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return const NovaVoiceIdentifyResult(
        success: false,
        matched: false,
        voiceId: '',
        displayName: '',
        similarity: 0,
        message: 'Ses eşleşmesi sırasında beklenmeyen hata oluştu.',
        embeddingSize: 0,
      );
    }
  }
}
