// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/audio_runtime/voice_clone_job.dart';
import '../../core/voice_clone/voice_clone_source_type.dart';
import '../audio_runtime/nova_native_audio_bridge_service.dart';

class LocalVoiceCloneEngine {
  final NovaNativeAudioBridgeService nativeBridge;

  const LocalVoiceCloneEngine({required this.nativeBridge});

  Future<String> createClone({
    required String inputAudioPath,
    required VoiceCloneSourceType sourceType,
    String suggestedName = 'Asistan Klonu',
    String styleInstruction =
        'Doğal, akıcı, insan gibi konuşan Türkçe kadın sesi.',
  }) async {
    final job = VoiceCloneJob(
      jobId: DateTime.now().millisecondsSinceEpoch.toString(),
      sourceType: sourceType,
      sourceReference: inputAudioPath,
      suggestedName: suggestedName,
      styleInstruction: styleInstruction,
      noiseReductionPreferred: true,
      isolateTargetVoicePreferred: true,
    );

    final result = await nativeBridge.createVoiceClone(job);

    final success = result['success'] as bool? ?? false;
    if (!success) {
      throw Exception((result['message'] as String? ?? 'Klon oluşturulamadı.'));
    }

    final voiceId = (result['voiceId'] as String? ?? '').trim();
    if (voiceId.isEmpty) {
      throw Exception('Geçerli bir klon ses kimliği dönmedi.');
    }

    return voiceId;
  }
}
