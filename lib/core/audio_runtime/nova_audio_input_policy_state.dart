// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaAudioInputPolicyState {
  final bool listeningPrepared;
  final bool keepMediaPlaybackUntouched;
  final bool keepNormalAudioMode;
  final String message;

  const NovaAudioInputPolicyState({
    required this.listeningPrepared,
    required this.keepMediaPlaybackUntouched,
    required this.keepNormalAudioMode,
    required this.message,
  });

  const NovaAudioInputPolicyState.idle()
    : listeningPrepared = false,
      keepMediaPlaybackUntouched = true,
      keepNormalAudioMode = true,
      message = 'Hazır';

  NovaAudioInputPolicyState copyWith({
    bool? listeningPrepared,
    bool? keepMediaPlaybackUntouched,
    bool? keepNormalAudioMode,
    String? message,
  }) {
    return NovaAudioInputPolicyState(
      listeningPrepared: listeningPrepared ?? this.listeningPrepared,
      keepMediaPlaybackUntouched:
          keepMediaPlaybackUntouched ?? this.keepMediaPlaybackUntouched,
      keepNormalAudioMode: keepNormalAudioMode ?? this.keepNormalAudioMode,
      message: message ?? this.message,
    );
  }
}
