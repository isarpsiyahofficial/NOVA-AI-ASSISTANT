// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaStreamingAsrState {
  final bool initialized;
  final bool running;
  final bool foregroundServiceRunning;
  final bool modelReady;
  final bool singleAuthorityConfirmed;
  final bool embeddedSherpaReady;
  final String message;
  final int partialCount;
  final int finalCount;
  final int droppedFrames;
  final String modelAssetPath;
  final String decoderAssetPath;
  final String tokenAssetPath;
  final String configAssetPath;

  const NovaStreamingAsrState({
    required this.initialized,
    required this.running,
    required this.foregroundServiceRunning,
    required this.modelReady,
    required this.singleAuthorityConfirmed,
    required this.embeddedSherpaReady,
    required this.message,
    required this.partialCount,
    required this.finalCount,
    required this.droppedFrames,
    required this.modelAssetPath,
    required this.decoderAssetPath,
    required this.tokenAssetPath,
    required this.configAssetPath,
  });

  const NovaStreamingAsrState.idle()
    : initialized = false,
      running = false,
      foregroundServiceRunning = false,
      modelReady = false,
      singleAuthorityConfirmed = true,
      embeddedSherpaReady = false,
      message = 'Streaming ASR hazır değil.',
      partialCount = 0,
      finalCount = 0,
      droppedFrames = 0,
      modelAssetPath = '',
      decoderAssetPath = '',
      tokenAssetPath = '',
      configAssetPath = '';

  Map<String, dynamic> toMap() => <String, dynamic>{
    'initialized': initialized,
    'running': running,
    'foregroundServiceRunning': foregroundServiceRunning,
    'modelReady': modelReady,
    'singleAuthorityConfirmed': singleAuthorityConfirmed,
    'embeddedSherpaReady': embeddedSherpaReady,
    'message': message,
    'partialCount': partialCount,
    'finalCount': finalCount,
    'droppedFrames': droppedFrames,
    'modelAssetPath': modelAssetPath,
    'decoderAssetPath': decoderAssetPath,
    'tokenAssetPath': tokenAssetPath,
    'configAssetPath': configAssetPath,
  };

  factory NovaStreamingAsrState.fromMap(Map<String, dynamic> map) {
    return NovaStreamingAsrState(
      initialized: map['initialized'] as bool? ?? false,
      running: map['running'] as bool? ?? false,
      foregroundServiceRunning:
          map['foregroundServiceRunning'] as bool? ?? false,
      modelReady: map['modelReady'] as bool? ?? false,
      singleAuthorityConfirmed:
          (map['singleAuthorityConfirmed'] as bool?) ?? true,
      embeddedSherpaReady: map['embeddedSherpaReady'] as bool? ?? false,
      message: (map['message'] as String? ?? '').trim(),
      partialCount: map['partialCount'] as int? ?? 0,
      finalCount: map['finalCount'] as int? ?? 0,
      droppedFrames: map['droppedFrames'] as int? ?? 0,
      modelAssetPath: (map['modelAssetPath'] as String? ?? '').trim(),
      decoderAssetPath: (map['decoderAssetPath'] as String? ?? '').trim(),
      tokenAssetPath: (map['tokenAssetPath'] as String? ?? '').trim(),
      configAssetPath: (map['configAssetPath'] as String? ?? '').trim(),
    );
  }
}
