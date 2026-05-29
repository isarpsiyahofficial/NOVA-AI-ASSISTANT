// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/cognition/nova_topic_thread.dart';

class NovaTopicThreadService {
  static final NovaTopicThreadService instance = NovaTopicThreadService._();
  NovaTopicThreadService._();

  final List<NovaTopicThread> _threads = <NovaTopicThread>[];

  void rememberTurn({
    required String threadId,
    required String title,
    required String turn,
  }) {
    final index = _threads.indexWhere((e) => e.id == threadId);
    if (index < 0) {
      _threads.add(
        NovaTopicThread(
          id: threadId,
          title: title,
          recentTurns: <String>[turn],
          updatedAt: DateTime.now(),
        ),
      );
      return;
    }
    final recent = <String>[..._threads[index].recentTurns, turn];
    final clipped = recent.length <= 8
        ? recent
        : recent.sublist(recent.length - 8);
    _threads[index] = NovaTopicThread(
      id: threadId,
      title: title,
      recentTurns: clipped,
      updatedAt: DateTime.now(),
    );
  }

  String buildPromptSection() {
    if (_threads.isEmpty) return 'Aktif konu izi yok.';
    final latest =
        (_threads.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)))
            .take(4);
    return latest
        .map((e) => '- ${e.title}: ${e.recentTurns.join(' | ')}')
        .join('\n');
  }
}
