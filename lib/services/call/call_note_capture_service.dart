// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../call_notes/call_note_service.dart';

class CallNoteCaptureService {
  final CallNoteService noteService;

  const CallNoteCaptureService({required this.noteService});

  Future<void> captureIfNeeded({
    required bool shouldStoreNote,
    required String callerName,
    required String callerNumber,
    required String callerText,
  }) async {
    if (!shouldStoreNote) return;

    final cleaned = callerText.trim();
    if (cleaned.isEmpty) return;

    await noteService.add(
      callerName: callerName,
      callerNumber: callerNumber,
      content: cleaned,
    );
  }
}
