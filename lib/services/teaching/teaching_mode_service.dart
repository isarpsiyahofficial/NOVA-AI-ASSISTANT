// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/teaching/taught_workflow.dart';
import 'taught_workflow_service.dart';

class TeachingModeService {
  final TaughtWorkflowService workflowService;

  const TeachingModeService({required this.workflowService});

  Future<void> teachWorkflow({
    required String title,
    required String triggerPhrase,
    required String description,
    required List<String> steps,
    String teachingSource = 'manual',
  }) async {
    final id = _buildStableId(title, triggerPhrase);
    await workflowService.addOrUpdate(
      id: id,
      title: title,
      triggerPhrase: triggerPhrase,
      description: description,
      steps: steps,
      teachingSource: teachingSource,
      isEnabled: true,
    );
  }

  Future<TaughtWorkflow?> resolveWorkflow(String input) async {
    return workflowService.findByTrigger(input);
  }

  Future<void> disableWorkflow(String id) async {
    await workflowService.disable(id);
  }

  Future<void> removeWorkflow(String id) async {
    await workflowService.remove(id);
  }

  String _buildStableId(String title, String triggerPhrase) {
    final raw =
        '${title.trim().toLowerCase()}::${triggerPhrase.trim().toLowerCase()}';
    return raw.hashCode.toUnsigned(32).toString();
  }
}
