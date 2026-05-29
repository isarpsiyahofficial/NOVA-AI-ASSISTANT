// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/self_repair/nova_capability_descriptor.dart';
import 'nova_capability_probe_service.dart';
import 'nova_self_recognition_service.dart';

class NovaCapabilityCatalogItem {
  final String capabilityId;
  final String title;
  final String humanSummary;
  final String technicalSummary;
  final bool selfRepairAllowed;
  final bool ownerPatchAllowed;
  final bool healthy;
  final String healthSummary;

  const NovaCapabilityCatalogItem({
    required this.capabilityId,
    required this.title,
    required this.humanSummary,
    required this.technicalSummary,
    required this.selfRepairAllowed,
    required this.ownerPatchAllowed,
    required this.healthy,
    required this.healthSummary,
  });

  factory NovaCapabilityCatalogItem.fromDescriptor(
    NovaCapabilityDescriptor descriptor, {
    required bool healthy,
    required String healthSummary,
  }) {
    return NovaCapabilityCatalogItem(
      capabilityId: descriptor.capabilityId,
      title: descriptor.title,
      humanSummary: descriptor.humanSummary,
      technicalSummary: descriptor.technicalSummary,
      selfRepairAllowed: descriptor.selfRepairAllowed,
      ownerPatchAllowed: descriptor.ownerPatchAllowed,
      healthy: healthy,
      healthSummary: healthSummary,
    );
  }
}

class NovaCapabilityCatalogService {
  final NovaSelfRecognitionService recognitionService;
  final NovaCapabilityProbeService probeService;

  const NovaCapabilityCatalogService({
    required this.recognitionService,
    required this.probeService,
  });

  Future<List<NovaCapabilityCatalogItem>> loadSafeCatalog() async {
    final descriptors = await recognitionService.discoverCapabilities();
    final probes = await probeService.probeAll(
      await recognitionService.manifestService.loadManifest(),
    );
    final probeMap = {for (final p in probes) p.capabilityId: p};
    return descriptors
        .map((descriptor) {
          final probe = probeMap[descriptor.capabilityId];
          return NovaCapabilityCatalogItem.fromDescriptor(
            descriptor,
            healthy: probe?.healthy ?? true,
            healthSummary: probe?.humanStatus ?? 'Özel sağlık kontrolü yok.',
          );
        })
        .toList(growable: false);
  }
}
