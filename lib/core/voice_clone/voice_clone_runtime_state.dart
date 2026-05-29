// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum VoiceCloneRuntimeStatus {
  idle,
  preparing,
  listeningExternal,
  listeningInternal,
  cleaningAudio,
  creatingClone,
  completed,
  cancelled,
  failed,
}

class VoiceCloneRuntimeState {
  final VoiceCloneRuntimeStatus status;
  final String message;
  final double progress;
  final String activeJobId;

  const VoiceCloneRuntimeState({
    required this.status,
    required this.message,
    required this.progress,
    required this.activeJobId,
  });

  const VoiceCloneRuntimeState.idle()
    : status = VoiceCloneRuntimeStatus.idle,
      message = 'Klon sistemi boşta.',
      progress = 0.0,
      activeJobId = '';

  VoiceCloneRuntimeState copyWith({
    VoiceCloneRuntimeStatus? status,
    String? message,
    double? progress,
    String? activeJobId,
  }) {
    return VoiceCloneRuntimeState(
      status: status ?? this.status,
      message: message ?? this.message,
      progress: progress ?? this.progress,
      activeJobId: activeJobId ?? this.activeJobId,
    );
  }
}
