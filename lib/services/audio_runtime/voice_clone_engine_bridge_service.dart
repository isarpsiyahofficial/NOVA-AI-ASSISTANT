// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/audio_runtime/voice_clone_job.dart';
import '../../core/voice_clone/cloned_voice_profile.dart';
import '../voice_clone/cloned_voice_library_service.dart';
import 'nova_native_audio_bridge_service.dart';

class VoiceCloneEngineBridgeService {
  final NovaNativeAudioBridgeService nativeAudioBridgeService;
  final ClonedVoiceLibraryService libraryService;

  const VoiceCloneEngineBridgeService({
    required this.nativeAudioBridgeService,
    required this.libraryService,
  });

  Future<Map<String, dynamic>> inspectRuntime() async {
    return nativeAudioBridgeService.getVoiceCloneRuntimeState();
  }

  Future<Map<String, dynamic>> cloneAndRegister(VoiceCloneJob job) async {
    final runtime = await nativeAudioBridgeService.getVoiceCloneRuntimeState();
    final supportsReferenceAudio = runtime['supportsReferenceAudio'] == true;
    final sherpaReady = runtime['sherpaTtsReady'] as bool? ?? false;
    if (!runtime['success']) {
      return <String, dynamic>{
        'success': false,
        'message':
            (runtime['message'] as String? ??
            'Voice clone çalışma durumu alınamadı.'),
      };
    }
    if (!sherpaReady && !supportsReferenceAudio) {
      return <String, dynamic>{
        'success': false,
        'message':
            (runtime['message'] as String? ??
            'Klon için gerekli yerel köprü hazır değil.'),
      };
    }

    final result = await nativeAudioBridgeService.createVoiceClone(job);

    final success = result['success'] as bool? ?? false;
    if (!success) {
      return <String, dynamic>{
        'success': false,
        'message': (result['message'] as String? ?? 'Klonlama başarısız.'),
      };
    }

    final profile = ClonedVoiceProfile(
      id: (result['voiceId'] as String? ?? job.jobId).trim(),
      name: (result['voiceName'] as String? ?? job.suggestedName).trim(),
      sourceType: job.sourceType,
      sourceReference: job.sourceReference,
      styleInstruction: job.styleInstruction,
      noiseReduced: job.noiseReductionPreferred,
      isFavorite: false,
      isActiveInUse: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await libraryService.addOrUpdate(profile);

    return <String, dynamic>{
      'success': true,
      'message': 'Klon ses kütüphaneye eklendi efendim.',
      'voiceId': profile.id,
    };
  }
}
