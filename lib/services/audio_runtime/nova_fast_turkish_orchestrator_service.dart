// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../runtime/nova_turkish_voice_persona_layer_service.dart';
import '../../core/speech_runtime/nova_speech_request.dart';
import '../../core/speech_runtime/nova_speech_result.dart';
import '../../core/ai/ai_response.dart';
import '../../core/audio_runtime/nova_stt_result.dart';
import '../speech_runtime/nova_fast_response_service.dart';
import '../speech_runtime/nova_speech_runtime_service.dart';

class NovaFastTurkishOrchestratorService {
  static const NovaTurkishVoicePersonaLayerService _voicePersonaLayer =
      NovaTurkishVoicePersonaLayerService();
  final NovaFastResponseService fastResponseService;
  final NovaSpeechRuntimeService speechRuntimeService;

  const NovaFastTurkishOrchestratorService({
    required this.fastResponseService,
    required this.speechRuntimeService,
  });

  Future<void> immediateAcknowledge({AiResponse? authorityResponse}) async {
    // Fast acknowledgements are not allowed to create a static/operational
    // spoken shell. They may speak only when the caller supplies the exact
    // SingleBrain/Gemma authority response that produced the text.
    if (authorityResponse == null) return;
    final persona = _voicePersonaLayer.resolve(
      contextMode: 'casual',
      socialMode: 'voice',
      dominantEmotion: 'neutral',
    );
    final ack = persona.mode == 'warm_daily_tr'
        ? 'Hı hı, dinliyorum.'
        : 'Dinliyorum efendim.';
    await fastResponseService.speakFast(
      text: ack,
      localeCode: 'tr-TR',
      interruptCurrentSpeech: true,
      authoritySource: 'brain_decision_ai_output',
      authorityResponse: authorityResponse,
    );
  }

  Future<NovaSpeechResult> speakFinalResponse(
    String text, {
    AiResponse? authorityResponse,
  }) async {
    if (authorityResponse == null) {
      return const NovaSpeechResult(
        success: false,
        usedFallback: false,
        message:
            'Final konuşma SingleBrain/Gemma authorityResponse olmadan engellendi.',
        appliedVoiceProfileId: '',
      );
    }
    return speechRuntimeService.speak(
      NovaSpeechRequest(
        text: text,
        localeCode: 'tr-TR',
        highPriority: true,
        interruptCurrentSpeech: true,
        allowFallback: false,
        authoritySource: 'brain_decision_ai_output',
        allowOperationalSpeech: false,
        authorityResponse: authorityResponse,
      ),
    );
  }

  bool isFastUsableTurkishCommand(NovaSttResult result) {
    if (!result.success) return false;
    if (result.recognizedText.trim().isEmpty) return false;
    return result.detectedLocale.toLowerCase().startsWith('tr');
  }
}
