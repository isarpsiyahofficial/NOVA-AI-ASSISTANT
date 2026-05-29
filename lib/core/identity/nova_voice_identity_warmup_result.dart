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

  bool get hasAuthorizedMatch =>
      success && matched && voiceId.trim().isNotEmpty;
}

class NovaVoiceCountResult {
  final bool success;
  final int count;
  final String message;

  const NovaVoiceCountResult({
    required this.success,
    required this.count,
    required this.message,
  });
}

class NovaVoiceDeleteResult {
  final bool success;
  final String message;

  const NovaVoiceDeleteResult({required this.success, required this.message});
}

class NovaVoiceIdentityBridgeService {
  static const MethodChannel _channel = MethodChannel(
    'nova/voice_identity_bridge',
  );

  const NovaVoiceIdentityBridgeService();

  Future<NovaVoiceIdentityWarmupResult> warmup() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('warmupVoiceIdentity');
      final map = _normalizeMap(raw);

      return NovaVoiceIdentityWarmupResult(
        success: map['success'] as bool? ?? false,
        message:
            (map['message'] as String? ?? 'Ses kimliği motoru yanıt vermedi.')
                .trim(),
      );
    } on PlatformException catch (e) {
      return NovaVoiceIdentityWarmupResult(
        success: false,
        message: e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Ses kimliği motoru başlatılırken platform hatası oluştu.',
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
          .invokeMethod<dynamic>('enrollVoiceprintFromFile', <String, dynamic>{
            'voiceId': voiceId.trim(),
            'displayName': displayName.trim(),
            'audioPath': audioPath.trim(),
          });

      final map = _normalizeMap(raw);

      return NovaVoiceEnrollResult(
        success: map['success'] as bool? ?? false,
        voiceId: (map['voiceId'] as String? ?? '').trim(),
        displayName: (map['displayName'] as String? ?? '').trim(),
        message:
            (map['message'] as String? ?? 'Voiceprint kayıt sonucu alınamadı.')
                .trim(),
        embeddingSize: _asInt(map['embeddingSize']),
      );
    } on PlatformException catch (e) {
      return NovaVoiceEnrollResult(
        success: false,
        voiceId: voiceId.trim(),
        displayName: displayName.trim(),
        message: e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Voiceprint kaydı sırasında platform hatası oluştu.',
        embeddingSize: 0,
      );
    } catch (_) {
      return NovaVoiceEnrollResult(
        success: false,
        voiceId: voiceId.trim(),
        displayName: displayName.trim(),
        message: 'Voiceprint kaydı sırasında beklenmeyen hata oluştu.',
        embeddingSize: 0,
      );
    }
  }

  Future<NovaVoiceIdentifyResult> identifyVoiceFromFile({
    required String audioPath,
    double minSimilarity = 0.72,
  }) async {
    try {
      final raw = await _channel.invokeMethod<dynamic>(
        'identifyVoiceFromFile',
        <String, dynamic>{
          'audioPath': audioPath.trim(),
          'minSimilarity': minSimilarity,
        },
      );

      final map = _normalizeMap(raw);

      return NovaVoiceIdentifyResult(
        success: map['success'] as bool? ?? false,
        matched: map['matched'] as bool? ?? false,
        voiceId: (map['voiceId'] as String? ?? '').trim(),
        displayName: (map['displayName'] as String? ?? '').trim(),
        similarity: _asDouble(map['similarity']),
        message: (map['message'] as String? ?? 'Ses eşleşme sonucu alınamadı.')
            .trim(),
        embeddingSize: _asInt(map['embeddingSize']),
      );
    } on PlatformException catch (e) {
      return NovaVoiceIdentifyResult(
        success: false,
        matched: false,
        voiceId: '',
        displayName: '',
        similarity: 0,
        message: e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Ses eşleşmesi sırasında platform hatası oluştu.',
        embeddingSize: 0,
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

  Future<NovaVoiceDeleteResult> removeVoiceprint({
    required String voiceId,
  }) async {
    try {
      final raw = await _channel.invokeMethod<dynamic>(
        'removeVoiceprint',
        <String, dynamic>{'voiceId': voiceId.trim()},
      );

      final map = _normalizeMap(raw);

      return NovaVoiceDeleteResult(
        success: map['success'] as bool? ?? false,
        message:
            (map['message'] as String? ?? 'Voiceprint silme sonucu alınamadı.')
                .trim(),
      );
    } on PlatformException catch (e) {
      return NovaVoiceDeleteResult(
        success: false,
        message: e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Voiceprint silinirken platform hatası oluştu.',
      );
    } catch (_) {
      return const NovaVoiceDeleteResult(
        success: false,
        message: 'Voiceprint silinirken beklenmeyen hata oluştu.',
      );
    }
  }

  Future<NovaVoiceDeleteResult> clearAllVoiceprints() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('clearAllVoiceprints');
      final map = _normalizeMap(raw);

      return NovaVoiceDeleteResult(
        success: map['success'] as bool? ?? false,
        message:
            (map['message'] as String? ??
                    'Voiceprint temizleme sonucu alınamadı.')
                .trim(),
      );
    } on PlatformException catch (e) {
      return NovaVoiceDeleteResult(
        success: false,
        message: e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Voiceprint temizlenirken platform hatası oluştu.',
      );
    } catch (_) {
      return const NovaVoiceDeleteResult(
        success: false,
        message: 'Voiceprint temizlenirken beklenmeyen hata oluştu.',
      );
    }
  }

  Future<NovaVoiceCountResult> getRegisteredVoiceCount() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>(
        'getRegisteredVoiceCount',
      );
      final map = _normalizeMap(raw);

      return NovaVoiceCountResult(
        success: map['success'] as bool? ?? false,
        count: _asInt(map['count']),
        message: (map['message'] as String? ?? 'Kayıtlı ses sayısı alınamadı.')
            .trim(),
      );
    } on PlatformException catch (e) {
      return NovaVoiceCountResult(
        success: false,
        count: 0,
        message: e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Kayıtlı ses sayısı alınırken platform hatası oluştu.',
      );
    } catch (_) {
      return const NovaVoiceCountResult(
        success: false,
        count: 0,
        message: 'Kayıtlı ses sayısı alınırken beklenmeyen hata oluştu.',
      );
    }
  }

  Map<String, dynamic> _normalizeMap(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const <String, dynamic>{};
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0;
    return 0;
  }
}
