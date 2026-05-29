// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'nova_goal_state.dart';

class NovaGoal {
  final String id;
  final String title;
  final String summary;
  final NovaGoalState state;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NovaGoal({
    required this.id,
    required this.title,
    required this.summary,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
  });

  NovaGoal copyWith({NovaGoalState? state, String? summary}) => NovaGoal(
    id: id,
    title: title,
    summary: summary ?? this.summary,
    state: state ?? this.state,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );
}
