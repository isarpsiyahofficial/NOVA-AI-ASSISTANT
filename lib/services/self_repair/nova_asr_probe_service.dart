// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
// NOVA_ASR_STT_AUTHORITY_MARKER: speakerVoiceId ownerConfidence relationshipLabel routed_to_SingleBrainAuthority deterministic_bridge_dto_only.
import '../../core/self_repair/nova_runtime_health_issue.dart';
import '../asr/nova_streaming_asr_runtime_service.dart';
import 'nova_runtime_health_registry_service.dart';

class NovaAsrProbeService {
  final NovaStreamingAsrRuntimeService runtimeService;

  const NovaAsrProbeService({required this.runtimeService});

  Future<void> probe() async {
    final state = runtimeService.latestState;
    if (!state.initialized) {
      NovaRuntimeHealthRegistryService.instance.publish(
        const NovaRuntimeHealthIssue(
          module: 'asr',
          code: 'not_initialized',
          message: 'Streaming ASR henüz başlatılmadı.',
          diagnosticCandidate: true,
        ),
      );
    }
  }
}
