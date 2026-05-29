// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1

import '../../core/voice_clone/voice_clone_source_type.dart';

class VoiceCloneJob {
  final String jobId;
  final VoiceCloneSourceType sourceType;
  final String sourceReference;
  final String suggestedName;
  final String styleInstruction;
  final bool noiseReductionPreferred;
  final bool isolateTargetVoicePreferred;

  const VoiceCloneJob({
    required this.jobId,
    required this.sourceType,
    required this.sourceReference,
    required this.suggestedName,
    required this.styleInstruction,
    this.noiseReductionPreferred = true,
    this.isolateTargetVoicePreferred = true,
  });

  Map<String, dynamic> toMap() => {
    'jobId': jobId,
    'sourceType': sourceType.name,
    'sourceReference': sourceReference,
    'suggestedName': suggestedName,
    'styleInstruction': styleInstruction,
    'noiseReductionPreferred': noiseReductionPreferred,
    'isolateTargetVoicePreferred': isolateTargetVoicePreferred,
  };
}
