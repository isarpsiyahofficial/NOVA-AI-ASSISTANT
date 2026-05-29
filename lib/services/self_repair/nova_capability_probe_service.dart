// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/self_repair/nova_capability_manifest_entry.dart';
import '../../core/runtime/nova_runtime_signal.dart';
import 'nova_runtime_signal_service.dart';

class NovaCapabilityProbeResult {
  final String capabilityId;
  final bool healthy;
  final String humanStatus;
  final String technicalStatus;

  const NovaCapabilityProbeResult({
    required this.capabilityId,
    required this.healthy,
    required this.humanStatus,
    required this.technicalStatus,
  });
}

class NovaCapabilityProbeService {
  final NovaRuntimeSignalService runtimeSignalService;

  const NovaCapabilityProbeService({required this.runtimeSignalService});

  Future<List<NovaCapabilityProbeResult>> probeAll(
    List<NovaCapabilityManifestEntry> manifest,
  ) async {
    final signals = await runtimeSignalService.getAll();
    return manifest
        .map((entry) => _probeOne(entry, signals))
        .toList(growable: false);
  }

  NovaCapabilityProbeResult _probeOne(
    NovaCapabilityManifestEntry entry,
    List<NovaRuntimeSignal> signals,
  ) {
    final related = signals
        .where((s) => entry.signalCodes.contains(s.code))
        .toList(growable: false);
    if (related.isEmpty) {
      return NovaCapabilityProbeResult(
        capabilityId: entry.capabilityId,
        healthy: true,
        humanStatus: 'Aktif hata sinyali görünmüyor.',
        technicalStatus: 'no_recent_signal',
      );
    }
    final latest = related.first;
    final unhealthy =
        latest.level == NovaRuntimeSignalLevel.error ||
        latest.level == NovaRuntimeSignalLevel.critical;
    return NovaCapabilityProbeResult(
      capabilityId: entry.capabilityId,
      healthy: !unhealthy,
      humanStatus: latest.message,
      technicalStatus: latest.technicalDetails.isEmpty
          ? latest.code
          : latest.technicalDetails,
    );
  }
}
