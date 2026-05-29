// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/runtime/nova_identity_rollout_models.dart';
import 'nova_layer_binding_registry_service.dart';

class NovaCapabilityAuditService {
  final NovaLayerBindingRegistryService registryService;

  const NovaCapabilityAuditService({
    this.registryService = const NovaLayerBindingRegistryService(),
  });

  Future<NovaCapabilityAuditReport> audit() async {
    final layerGroups = registryService.groupedLayers();
    final capabilityFlags = registryService.capabilityFlags();
    final adaptedFiles = NovaLayerBindingRegistryService.allRelevantLayerFiles;
    final bindingGroups = <String, List<String>>{
      'contract_consumers': NovaLayerBindingRegistryService.contractConsumers,
      'identity_consumers': NovaLayerBindingRegistryService.identityConsumers,
      'voice_continuity_consumers':
          NovaLayerBindingRegistryService.voiceContinuityConsumers,
      'acoustic_consumers': NovaLayerBindingRegistryService.acousticConsumers,
    };

    return NovaCapabilityAuditReport(
      capabilities: capabilityFlags,
      layerGroups: layerGroups,
      adaptedFiles: adaptedFiles,
      bindingGroups: bindingGroups,
      repositoryDartFileCount:
          NovaLayerBindingRegistryService.repositoryDartFileCount,
    );
  }

  Map<String, dynamic> auditCoverageSummary() {
    final layerGroups = registryService.groupedLayers();
    final capabilities = registryService.capabilityFlags();
    final totalLayers = layerGroups.values.fold<int>(0, (a, b) => a + b.length);
    final enabled = capabilities.values.where((e) => e == true).length;
    final disabled = capabilities.length - enabled;
    return <String, dynamic>{
      'groupCount': layerGroups.length,
      'totalLayers': totalLayers,
      'capabilityCount': capabilities.length,
      'enabledCount': enabled,
      'disabledCount': disabled,
      'repositoryDartFileCount':
          NovaLayerBindingRegistryService.repositoryDartFileCount,
      'bindingGroups': <String, int>{
        'contract_consumers':
            NovaLayerBindingRegistryService.contractConsumers.length,
        'identity_consumers':
            NovaLayerBindingRegistryService.identityConsumers.length,
        'voice_continuity_consumers':
            NovaLayerBindingRegistryService.voiceContinuityConsumers.length,
        'acoustic_consumers':
            NovaLayerBindingRegistryService.acousticConsumers.length,
      },
    };
  }
}
