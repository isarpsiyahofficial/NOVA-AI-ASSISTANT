// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/cognition/nova_goal.dart';
import '../../core/cognition/nova_goal_state.dart';

class NovaGoalRegistryService {
  static final NovaGoalRegistryService instance = NovaGoalRegistryService._();
  NovaGoalRegistryService._();

  final List<NovaGoal> _goals = <NovaGoal>[];

  List<NovaGoal> get activeGoals => _goals
      .where((e) => e.state == NovaGoalState.active)
      .toList(growable: false);

  NovaGoal upsert({
    required String id,
    required String title,
    required String summary,
  }) {
    final index = _goals.indexWhere((e) => e.id == id);
    final next = NovaGoal(
      id: id,
      title: title,
      summary: summary,
      state: NovaGoalState.active,
      createdAt: index >= 0 ? _goals[index].createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );
    if (index >= 0) {
      _goals[index] = next;
    } else {
      _goals.add(next);
    }
    return next;
  }

  void suspend(String id) {
    final index = _goals.indexWhere((e) => e.id == id);
    if (index < 0) return;
    _goals[index] = _goals[index].copyWith(state: NovaGoalState.suspended);
  }

  String buildPromptSection() {
    if (_goals.isEmpty) return 'Aktif hedef kaydı yok.';
    return _goals
        .map((e) => '- ${e.title}: ${e.summary} [${e.state.name}]')
        .join('\n');
  }
}
