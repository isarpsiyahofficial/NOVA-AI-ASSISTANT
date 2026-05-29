// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'nova_streaming_transcript.dart';

class NovaStreamingAsrEvent {
  final String type;
  final NovaStreamingTranscript transcript;
  final String message;
  final DateTime createdAt;

  const NovaStreamingAsrEvent({
    required this.type,
    required this.transcript,
    required this.message,
    required this.createdAt,
  });

  bool get isError => type == 'error';
  bool get isPartial => type == 'partial';
  bool get isFinal => type == 'final';

  Map<String, dynamic> toMap() => <String, dynamic>{
    'type': type,
    'transcript': transcript.toMap(),
    'message': message,
    'createdAt': createdAt.toIso8601String(),
  };

  factory NovaStreamingAsrEvent.fromMap(Map<String, dynamic> map) {
    return NovaStreamingAsrEvent(
      type: (map['type'] as String? ?? 'status').trim(),
      transcript: NovaStreamingTranscript.fromMap(
        Map<String, dynamic>.from(
          map['transcript'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      message: (map['message'] as String? ?? '').trim(),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
