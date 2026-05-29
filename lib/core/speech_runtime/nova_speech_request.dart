// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../ai/ai_response.dart';

class NovaSpeechRequest {
  final String text;
  final String localeCode;
  final String voiceProfileId;
  final bool highPriority;
  final bool allowFallback;
  final bool interruptCurrentSpeech;
  final String authoritySource;
  final bool allowOperationalSpeech;
  final bool singleBrainApproved;
  final AiResponse? authorityResponse;

  const NovaSpeechRequest({
    required this.text,
    this.localeCode = 'tr-TR',
    this.voiceProfileId = '',
    this.highPriority = false,
    this.allowFallback = true,
    this.interruptCurrentSpeech = false,
    this.authoritySource = 'speech_runtime_operational',
    this.allowOperationalSpeech = false,
    this.singleBrainApproved = false,
    this.authorityResponse,
  });

  NovaSpeechRequest copyWith({
    String? text,
    String? localeCode,
    String? voiceProfileId,
    bool? highPriority,
    bool? allowFallback,
    bool? interruptCurrentSpeech,
    String? authoritySource,
    bool? allowOperationalSpeech,
    bool? singleBrainApproved,
    AiResponse? authorityResponse,
  }) {
    return NovaSpeechRequest(
      text: text ?? this.text,
      localeCode: localeCode ?? this.localeCode,
      voiceProfileId: voiceProfileId ?? this.voiceProfileId,
      highPriority: highPriority ?? this.highPriority,
      allowFallback: allowFallback ?? this.allowFallback,
      interruptCurrentSpeech:
          interruptCurrentSpeech ?? this.interruptCurrentSpeech,
      authoritySource: authoritySource ?? this.authoritySource,
      allowOperationalSpeech:
          allowOperationalSpeech ?? this.allowOperationalSpeech,
      singleBrainApproved: singleBrainApproved ?? this.singleBrainApproved,
      authorityResponse: authorityResponse ?? this.authorityResponse,
    );
  }

  bool get hasUsableText => text.trim().isNotEmpty;
}
