// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/self_repair/nova_runtime_health_issue.dart';
import '../memory/nova_memory_context_service.dart';
import 'nova_runtime_health_registry_service.dart';

class NovaMemoryProbeService {
  final NovaMemoryContextService memoryContextService;

  const NovaMemoryProbeService({required this.memoryContextService});

  Future<void> probe() async {
    final memories = await memoryContextService.selectRelevant(
      'nova sağlık kontrolü',
    );
    if (memories.isEmpty) {
      NovaRuntimeHealthRegistryService.instance.publish(
        const NovaRuntimeHealthIssue(
          module: 'memory',
          code: 'memory_context_empty',
          message: 'İlgili hafıza bağlamı boş döndü.',
          diagnosticCandidate: false,
        ),
      );
    }
  }
}
