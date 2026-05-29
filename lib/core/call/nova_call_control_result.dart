// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaCallControlResult {
  final bool success;
  final String message;
  final bool isSpeakerOn;
  final bool isMuted;

  const NovaCallControlResult({
    required this.success,
    required this.message,
    this.isSpeakerOn = false,
    this.isMuted = false,
  });

  factory NovaCallControlResult.fromMap(Map<String, dynamic> map) {
    return NovaCallControlResult(
      success: map['success'] as bool? ?? false,
      message: (map['message'] as String? ?? '').trim(),
      isSpeakerOn: map['isSpeakerOn'] as bool? ?? false,
      isMuted: map['isMuted'] as bool? ?? false,
    );
  }

  factory NovaCallControlResult.failure(String message) {
    return NovaCallControlResult(success: false, message: message);
  }
}
