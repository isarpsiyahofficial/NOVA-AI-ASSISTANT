// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/system/nova_activation_decision.dart';
import '../../core/speech_runtime/nova_speech_result.dart';
import '../../services/system/nova_activation_service.dart';
import '../../services/orchestrator/nova_fast_turkish_orchestrator_service.dart';
import 'nova_brain.dart';

class NovaOrchestrator {
  final NovaBrain brain;
  final NovaActivationService activationService;
  final NovaFastTurkishOrchestratorService fastTurkishOrchestratorService;

  const NovaOrchestrator({
    required this.brain,
    required this.activationService,
    required this.fastTurkishOrchestratorService,
  });

  Future<NovaDecision?> handleVoiceInput(String input) async {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final NovaActivationDecision decision = activationService
        .evaluateVoiceInput(trimmed);

    if (!decision.shouldProcess) {
      return null;
    }

    return brain.process(trimmed);
  }

  Future<NovaSpeechResult?> handleVoiceInputAndRespond(String input) async {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final NovaActivationDecision decision = activationService
        .evaluateVoiceInput(trimmed);

    if (!decision.shouldProcess) {
      return null;
    }

    final NovaDecision response = await brain.process(trimmed);

    // Legacy NovaBrain is a compatibility shell and does not return an
    // AiResponse with SingleBrain/Gemma proof. Do not let this older path speak
    // raw strings through the fast Turkish runtime. Active voice runtime must
    // route through NovaAiService -> SingleBrainAuthority -> authorityResponse.
    final String finalText = response.fullResponse.trim();
    if (finalText.isEmpty) {
      return null;
    }

    return const NovaSpeechResult(
      success: false,
      usedFallback: false,
      message:
          'Legacy orchestrator speech disabled; route through SingleBrainAuthority authorityResponse.',
      appliedVoiceProfileId: '',
    );
  }

  NovaActivationDecision handlePriorityCall({
    required bool isAuthorizedCaller,
    required bool callHandlingEnabled,
  }) {
    return activationService.evaluatePriorityCall(
      isAuthorizedCaller: isAuthorizedCaller,
      callHandlingEnabled: callHandlingEnabled,
    );
  }
}
