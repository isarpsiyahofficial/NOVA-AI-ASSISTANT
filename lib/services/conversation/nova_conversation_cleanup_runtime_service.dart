// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:async';

import 'nova_conversation_session_service.dart';

class NovaConversationCleanupRuntimeService {
  final NovaConversationSessionService sessionService;

  Timer? _timer;

  NovaConversationCleanupRuntimeService({required this.sessionService});

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 30), (_) async {
      await sessionService.cleanupExpired();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
