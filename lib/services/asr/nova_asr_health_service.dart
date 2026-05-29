// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
// NOVA_ASR_STT_AUTHORITY_MARKER: speakerVoiceId ownerConfidence relationshipLabel routed_to_SingleBrainAuthority deterministic_bridge_dto_only.
import '../../core/asr/nova_streaming_asr_state.dart';

class NovaAsrHealthSnapshot {
  final bool healthy;
  final String message;
  final NovaStreamingAsrState state;

  const NovaAsrHealthSnapshot({
    required this.healthy,
    required this.message,
    required this.state,
  });
}

class NovaAsrHealthService {
  const NovaAsrHealthService();

  NovaAsrHealthSnapshot inspect(NovaStreamingAsrState state) {
    final normalizedMessage = state.message.toLowerCase();
    final modelPath = state.modelAssetPath.toLowerCase();
    final decoderPath = state.decoderAssetPath.toLowerCase();
    final configPath = state.configAssetPath.toLowerCase();
    final tokenPath = state.tokenAssetPath.toLowerCase();
    final looksLikeWhisperBase =
        modelPath.contains('encoder.onnx') &&
        decoderPath.contains('decoder.onnx') &&
        configPath.contains('config.json') &&
        tokenPath.contains('tokens.txt');

    if (!state.initialized) {
      return NovaAsrHealthSnapshot(
        healthy: false,
        message: 'Streaming ASR başlatılmamış.',
        state: state,
      );
    }
    if (!state.modelReady || !state.embeddedSherpaReady) {
      return NovaAsrHealthSnapshot(
        healthy: false,
        message: 'ASR tek otorite embedded Sherpa moduna kilitlenemedi.',
        state: state,
      );
    }
    if (state.droppedFrames > 24) {
      return NovaAsrHealthSnapshot(
        healthy: false,
        message: 'ASR buffer taşması tespit edildi.',
        state: state,
      );
    }
    if (state.modelReady &&
        (normalizedMessage.contains('başlatılamadı') ||
            normalizedMessage.contains('hata'))) {
      return NovaAsrHealthSnapshot(
        healthy: false,
        message:
            'Model var ancak embedded Sherpa warmup/runtime aşamasında sorun görülüyor.',
        state: state,
      );
    }

    final healthy = state.modelReady && state.embeddedSherpaReady;
    final message = state.message.trim().isNotEmpty
        ? state.message.trim()
        : looksLikeWhisperBase
        ? 'Streaming ASR sağlıklı görünüyor. Embedded Whisperbase/Sherpa encoder+decoder zinciri hazır.'
        : state.embeddedSherpaReady
        ? 'Streaming ASR sağlıklı görünüyor. Embedded Sherpa hazır.'
        : 'Streaming ASR tek zincir olarak doğrulanmadı.';

    return NovaAsrHealthSnapshot(
      healthy: healthy,
      message: message,
      state: state,
    );
  }
}
