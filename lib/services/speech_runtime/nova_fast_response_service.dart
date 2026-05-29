// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/speech_runtime/nova_speech_request.dart';
import '../../core/speech_runtime/nova_speech_result.dart';
import '../../core/ai/ai_response.dart';
import 'nova_speech_runtime_service.dart';

class NovaFastResponseService {
  final NovaSpeechRuntimeService speechRuntimeService;

  const NovaFastResponseService({required this.speechRuntimeService});

  Future<NovaSpeechResult> speakFast({
    required String text,
    String localeCode = 'tr-TR',
    bool interruptCurrentSpeech = true,
    String authoritySource = 'fast_response_operational',
    bool allowOperationalSpeech = false,
    bool singleBrainApproved = false,
    AiResponse? authorityResponse,
  }) async {
    return speechRuntimeService.speak(
      NovaSpeechRequest(
        text: text,
        localeCode: localeCode,
        highPriority: true,
        interruptCurrentSpeech: interruptCurrentSpeech,
        allowFallback: false,
        authoritySource: authoritySource,
        allowOperationalSpeech: allowOperationalSpeech,
        singleBrainApproved: singleBrainApproved,
        authorityResponse: authorityResponse,
      ),
    );
  }
}
