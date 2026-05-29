// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/runtime/nova_affective_state.dart';
import '../../core/runtime/nova_internal_state.dart';
import '../../core/runtime/nova_thinking_models.dart';
import '../cognition/nova_emotion_engine_service.dart';

class NovaAffectiveStateService {
  final NovaEmotionEngineService _emotionEngineService;

  const NovaAffectiveStateService({
    NovaEmotionEngineService emotionEngineService =
        const NovaEmotionEngineService(),
  }) : _emotionEngineService = emotionEngineService;

  Future<NovaAffectiveState> analyze(
    String input, {
    required NovaThinkingSnapshot thinking,
    required NovaInternalState internalState,
  }) async {
    final emotion = await _emotionEngineService.analyze(input);
    final cues = <String>[...emotion.signals];
    if (thinking.shouldAskClarifyingQuestion) {
      cues.add('netleştirme ihtiyacı');
    }
    return NovaAffectiveState(
      dominantEmotion: emotion.dominantEmotion,
      warmth:
          (internalState.ownerCloseness +
                  emotion.trustComfort * 0.32 +
                  emotion.empathyNeed * 0.22)
              .clamp(0.0, 1.0),
      urgency:
          (emotion.urgency +
                  (thinking.intent == NovaInteractionIntent.command
                      ? 0.18
                      : 0.0))
              .clamp(0.0, 1.0),
      tension: (emotion.frustrationTrend * 0.65 + emotion.intensity * 0.22)
          .clamp(0.0, 1.0),
      curiosity: switch (thinking.curiosityLevel) {
        NovaCuriosityLevel.low => 0.28,
        NovaCuriosityLevel.medium => 0.56,
        NovaCuriosityLevel.high => 0.82,
      },
      cues: cues,
    );
  }
}
