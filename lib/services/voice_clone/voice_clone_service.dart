// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/audio_runtime/voice_clone_job.dart';
import '../../core/voice_clone/voice_clone_source_type.dart';
import 'cloned_voice_library_service.dart';
import 'local_voice_clone_engine.dart';
import 'voice_clone_runtime_control_service.dart';

class VoiceCloneService {
  final LocalVoiceCloneEngine engine;
  final VoiceCloneRuntimeControlService runtimeControl;
  final ClonedVoiceLibraryService libraryService;

  VoiceCloneService({
    required this.engine,
    required this.runtimeControl,
    required this.libraryService,
  });

  Future<void> startClone(
    String audioPath, {
    String suggestedName = 'Asistan Klonu',
    String styleInstruction =
        'Doğal, akıcı, insan gibi konuşan Türkçe kadın sesi.',
    VoiceCloneSourceType sourceType = VoiceCloneSourceType.file,
  }) async {
    final jobId = DateTime.now().millisecondsSinceEpoch.toString();

    runtimeControl.markPreparing(jobId);
    runtimeControl.markCleaningAudio(jobId);

    try {
      final runtime = await engine.nativeBridge.getVoiceCloneRuntimeState();
      final bridgeReady = runtime['success'] as bool? ?? false;
      if (!bridgeReady) {
        runtimeControl.markFailed(
          jobId,
          (runtime['message'] as String? ?? 'Klon köprüsü hazır değil.').trim(),
        );
        return;
      }

      final job = VoiceCloneJob(
        jobId: jobId,
        sourceType: sourceType,
        sourceReference: audioPath,
        suggestedName: suggestedName,
        styleInstruction: styleInstruction,
        noiseReductionPreferred: true,
        isolateTargetVoicePreferred: true,
      );

      final result = await engine.nativeBridge.createVoiceClone(job);
      final success = result['success'] as bool? ?? false;
      if (!success) {
        runtimeControl.markFailed(
          jobId,
          (result['message'] as String? ?? 'Klon oluşturulamadı efendim.')
              .trim(),
        );
        return;
      }

      runtimeControl.markCreatingClone(jobId);
      await libraryService.addOrUpdateFromNativeCloneResult(
        nativeResult: result,
        sourceType: sourceType,
      );

      runtimeControl.markCompleted(jobId);
    } catch (_) {
      runtimeControl.markFailed(jobId, 'Klon oluşturulamadı efendim.');
    }
  }

  Future<String> startExternalCloneCapture({
    String suggestedName = 'Asistan Dış Ses Klonu',
    String styleInstruction =
        'Doğal, akıcı, insan gibi konuşan Türkçe kadın sesi.',
    int maxDurationSeconds = 12,
  }) async {
    final jobId = DateTime.now().millisecondsSinceEpoch.toString();
    runtimeControl.markPreparing(jobId);
    runtimeControl.markListeningExternal(jobId);
    final sample = await engine.nativeBridge.captureCloneSampleExternal(
      maxDurationSeconds: maxDurationSeconds,
      outputName: 'nova_external_clone',
    );
    final ok = sample['success'] as bool? ?? false;
    final path = (sample['filePath'] as String? ?? '').trim();
    if (!ok || path.isEmpty) {
      final message =
          (sample['message'] as String? ?? 'Dış ses örneği alınamadı efendim.')
              .trim();
      runtimeControl.markFailed(jobId, message);
      return message;
    }
    await startClone(
      path,
      suggestedName: suggestedName,
      styleInstruction: styleInstruction,
      sourceType: VoiceCloneSourceType.externalMic,
    );
    return runtimeControl.state.message;
  }

  Future<String> startInternalCloneCapture({
    String suggestedName = 'Asistan Telefon İçi Ses Klonu',
    String styleInstruction =
        'Doğal, akıcı, insan gibi konuşan Türkçe kadın sesi.',
    int maxDurationSeconds = 12,
  }) async {
    final jobId = DateTime.now().millisecondsSinceEpoch.toString();
    runtimeControl.markPreparing(jobId);
    final permission = await engine.nativeBridge
        .requestInternalAudioCapturePermission();
    final permissionOk = permission['success'] as bool? ?? false;
    if (!permissionOk) {
      final message =
          (permission['message'] as String? ??
                  'Telefon içi ses izni alınamadı efendim.')
              .trim();
      runtimeControl.markFailed(jobId, message);
      return message;
    }
    runtimeControl.markListeningInternal(jobId);
    final sample = await engine.nativeBridge.captureCloneSampleInternal(
      maxDurationSeconds: maxDurationSeconds,
      outputName: 'nova_internal_clone',
    );
    final ok = sample['success'] as bool? ?? false;
    final path = (sample['filePath'] as String? ?? '').trim();
    if (!ok || path.isEmpty) {
      final message =
          (sample['message'] as String? ??
                  'Telefon içi ses örneği alınamadı efendim.')
              .trim();
      runtimeControl.markFailed(jobId, message);
      return message;
    }
    await startClone(
      path,
      suggestedName: suggestedName,
      styleInstruction: styleInstruction,
      sourceType: VoiceCloneSourceType.internalPhoneAudio,
    );
    return runtimeControl.state.message;
  }
}
