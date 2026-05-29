// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'nova_emotion_to_prosody_mapper_service.dart';
import 'nova_turkish_prosody_planner_service.dart';

class NovaEmotionProsodyFusion {
  final String emotionalTone;
  final String contour;
  final double rateMultiplier;
  final double pitchMultiplier;
  final int shortPauseMs;
  final int mediumPauseMs;

  const NovaEmotionProsodyFusion({
    required this.emotionalTone,
    required this.contour,
    required this.rateMultiplier,
    required this.pitchMultiplier,
    required this.shortPauseMs,
    required this.mediumPauseMs,
  });

  String buildPromptSection() =>
      'DUYGU+PROSODİ FÜZYONU: ton=' +
      emotionalTone +
      '; kontur=' +
      contour +
      '; hızX=' +
      rateMultiplier.toStringAsFixed(2) +
      '; pitchX=' +
      pitchMultiplier.toStringAsFixed(2) +
      '; kısa=' +
      shortPauseMs.toString() +
      '; orta=' +
      mediumPauseMs.toString();
}

class NovaEmotionProsodyFuserService {
  const NovaEmotionProsodyFuserService();

  static const NovaEmotionToProsodyMapperService _mapper =
      NovaEmotionToProsodyMapperService();
  static const NovaTurkishProsodyPlannerService _planner =
      NovaTurkishProsodyPlannerService();

  NovaEmotionProsodyFusion fuse({
    required String raw,
    required String dominantEmotion,
    required bool shortFormPreferred,
  }) {
    final mapped = _mapper.map(dominantEmotion, prompt: raw);
    final planned = _planner.plan(
      raw: raw,
      emotionalTone: mapped.emotionalTone,
      contourHint: mapped.contourHint,
      shortFormPreferred: shortFormPreferred,
    );
    return NovaEmotionProsodyFusion(
      emotionalTone: planned.emotionalColor,
      contour: planned.contour,
      rateMultiplier: planned.rateMultiplier,
      pitchMultiplier: planned.pitchMultiplier,
      shortPauseMs: planned.shortPauseMs,
      mediumPauseMs: planned.mediumPauseMs,
    );
  }
}
