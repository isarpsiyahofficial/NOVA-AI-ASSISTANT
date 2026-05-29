// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/conversation/nova_conversation_state_snapshot.dart';
import 'nova_conversation_focus_service.dart';

class NovaConversationStateMachineService {
  final NovaConversationFocusService _focusService;

  const NovaConversationStateMachineService({
    NovaConversationFocusService focusService =
        const NovaConversationFocusService(),
  }) : _focusService = focusService;

  Future<NovaConversationStateSnapshot> build({
    required String latestPrompt,
  }) async {
    final items = await _focusService.getAll();
    if (items.isEmpty) {
      return const NovaConversationStateSnapshot();
    }

    final normalizedPrompt = latestPrompt.trim().toLowerCase();
    final active = items.first;
    final paused = items.where((e) => e.paused).toList(growable: false);
    final sensitive = items.firstWhere(
      (e) =>
          e.learningRelevant ||
          e.explicitlyPersistent ||
          _looksSensitive(e.summary),
      orElse: () => active,
    );
    final awaitingUser = items.firstWhere(
      (e) => _looksAwaitingUser(e.summary),
      orElse: () => active,
    );
    final unfinished = items.firstWhere(
      (e) => _looksUnfinished(e.summary) || e.paused,
      orElse: () => active,
    );
    final actingTopic = normalizedPrompt.isEmpty
        ? active.title
        : latestPrompt.trim();
    final returnTopic = _resolveReturnTopic(
      normalizedPrompt: normalizedPrompt,
      activeTitle: active.title,
      pausedTitles: paused.map((e) => e.title).toList(growable: false),
      unfinishedTitle: unfinished.title,
      awaitingUserTitle: awaitingUser.title,
    );

    return NovaConversationStateSnapshot(
      activeTopic: active.title,
      pendingTopic: paused.isNotEmpty ? paused.first.title : '',
      unfinishedTopic: unfinished.summary,
      sensitiveTopic: sensitive.title,
      awaitingUserTopic: _looksAwaitingUser(awaitingUser.summary)
          ? awaitingUser.title
          : '',
      actingTopic: actingTopic,
      returnTopic: returnTopic,
    );
  }

  String _resolveReturnTopic({
    required String normalizedPrompt,
    required String activeTitle,
    required List<String> pausedTitles,
    required String unfinishedTitle,
    required String awaitingUserTitle,
  }) {
    if (_looksLikeInterruption(normalizedPrompt) &&
        activeTitle.trim().isNotEmpty) {
      return activeTitle;
    }
    for (final title in pausedTitles) {
      if (title.trim().isNotEmpty && title != awaitingUserTitle) {
        return title;
      }
    }
    if (unfinishedTitle.trim().isNotEmpty &&
        unfinishedTitle != awaitingUserTitle) {
      return unfinishedTitle;
    }
    if (activeTitle.trim().isNotEmpty && activeTitle != awaitingUserTitle) {
      return activeTitle;
    }
    return '';
  }

  bool _looksAwaitingUser(String text) {
    final normalized = text.toLowerCase();
    return normalized.contains('?') ||
        normalized.contains('netleştir') ||
        normalized.contains('netlestir') ||
        normalized.contains('teyit') ||
        normalized.contains('bekleniyor') ||
        normalized.contains('cevap bekliyor') ||
        normalized.contains('hangisini istersin') ||
        normalized.contains('hangisini istersiniz');
  }

  bool _looksUnfinished(String text) {
    final normalized = text.toLowerCase();
    return normalized.contains('devam') ||
        normalized.contains('yarım') ||
        normalized.contains('yarim') ||
        normalized.contains('sonra dön') ||
        normalized.contains('sonra don') ||
        normalized.contains('bitmedi') ||
        normalized.contains('geri dön') ||
        normalized.contains('geri don');
  }

  bool _looksSensitive(String text) {
    final normalized = text.toLowerCase();
    return normalized.contains('üzgün') ||
        normalized.contains('uzgun') ||
        normalized.contains('dert') ||
        normalized.contains('kaygı') ||
        normalized.contains('kaygi') ||
        normalized.contains('hassas') ||
        normalized.contains('kırgın') ||
        normalized.contains('kirgin');
  }

  bool _looksLikeInterruption(String prompt) {
    if (prompt.isEmpty) return false;
    return prompt.contains('bir de') ||
        prompt.contains('şunu da') ||
        prompt.contains('sunu da') ||
        prompt.contains('önce bunu') ||
        prompt.contains('once bunu') ||
        prompt.contains('arada') ||
        prompt.contains('bu arada') ||
        prompt.contains('şunu hallet') ||
        prompt.contains('sunu hallet');
  }
}
