// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../runtime/nova_turkish_emphasis_resolver_service.dart';
import '../runtime/nova_emotion_to_prosody_mapper_service.dart';
import '../runtime/nova_turkish_prosody_planner_service.dart';
import '../../core/tts/nova_prosody_plan.dart';

class NovaProsodyPlannerService {
  const NovaProsodyPlannerService();

  static const NovaTurkishEmphasisResolverService _emphasisResolver =
      NovaTurkishEmphasisResolverService();
  static const NovaEmotionToProsodyMapperService _emotionMapper =
      NovaEmotionToProsodyMapperService();
  static const NovaTurkishProsodyPlannerService _turkishProsodyPlanner =
      NovaTurkishProsodyPlannerService();

  NovaProsodyPlan plan(
    String text, {
    required double baseSpeechRate,
    required double basePitch,
  }) {
    final lower = text.toLowerCase();
    final emphasisResolution = _emphasisResolver.resolve(text);
    var rate = baseSpeechRate;
    var pitch = basePitch;
    var shortPauseMs = 90.0;
    var mediumPauseMs = 180.0;
    var emphasis = 0.0;
    var emotionalTone = 'neutral';
    var shortFormPreferred = false;

    final emotional = _containsAny(lower, const [
      'üzgün',
      'zor',
      'yorucu',
      'kırıcı',
      'uzgun',
      'bunaldım',
      'bunaldim',
      'moralim bozuk',
    ]);
    final urgent = _containsAny(lower, const [
      'hemen',
      'acil',
      'şimdi',
      'simdi',
      'çabuk',
      'cabuk',
    ]);
    final positive = _containsAny(lower, const [
      'harika',
      'güzel',
      'super',
      'süper',
      'sevindim',
      'mükemmel',
      'mukemmel',
    ]);
    final technical = _containsAny(lower, const [
      'önce',
      'ilk olarak',
      'adım',
      'madde',
      'teknik',
      'kontrol',
      'kritik',
    ]);
    final repair = _containsAny(lower, const [
      'yanlış anlamak istemem',
      'şunu mu',
      'yanlış anladıysam',
    ]);
    final gentleBackchannel = _containsAny(lower, const [
      'anladım',
      'tamam',
      'hmm',
      'bir saniye',
    ]);

    if (emotional) {
      rate = (rate * 0.91).clamp(0.50, 0.72);
      pitch = (pitch * 0.99).clamp(0.94, 1.06);
      shortPauseMs = 125;
      mediumPauseMs = 250;
      emotionalTone = 'soft_supportive';
      shortFormPreferred = true;
    }

    if (urgent) {
      rate = (rate * 1.05).clamp(0.52, 0.78);
      pitch = (pitch * 1.01).clamp(0.94, 1.08);
      shortPauseMs = 70;
      mediumPauseMs = 145;
      shortFormPreferred = true;
      emotionalTone = 'urgent_clear';
    }

    if (positive) {
      pitch = (pitch * 1.04).clamp(0.94, 1.09);
      rate = (rate * 1.01).clamp(0.52, 0.76);
      emphasis += 0.04;
      emotionalTone = 'warm_positive';
    }

    if (technical) {
      emphasis += 0.10;
      shortPauseMs += 15;
      mediumPauseMs += 25;
      emotionalTone = emotionalTone == 'neutral'
          ? 'structured_clear'
          : emotionalTone;
    }

    if (repair) {
      rate = (rate * 0.95).clamp(0.50, 0.74);
      shortPauseMs += 20;
      mediumPauseMs += 30;
      emotionalTone = emotionalTone == 'neutral'
          ? 'repair_gentle'
          : emotionalTone;
      shortFormPreferred = true;
    }

    if (gentleBackchannel) {
      shortPauseMs += 10;
      emphasis += 0.03;
    }

    if (text.contains('?')) {
      rate = (rate * 0.97).clamp(0.50, 0.74);
      pitch = (pitch * 1.04).clamp(0.94, 1.09);
      emphasis += 0.05;
    }

    if (text.contains(',') || text.contains(';') || text.contains(':')) {
      shortPauseMs += 18;
      mediumPauseMs += 28;
    }

    if (text.length > 260) {
      rate = (rate * 0.96).clamp(0.50, 0.74);
      shortPauseMs += 12;
      mediumPauseMs += 18;
    }

    final emotionMapping = _emotionMapper.map(emotionalTone);
    final turkishPlan = _turkishProsodyPlanner.plan(
      raw: text,
      emotionalTone: emotionalTone,
      contourHint: emphasisResolution.contourHint,
      shortFormPreferred: shortFormPreferred,
    );

    rate = (rate * turkishPlan.rateMultiplier).clamp(0.48, 0.80);
    pitch = (pitch * turkishPlan.pitchMultiplier).clamp(0.92, 1.10);
    shortPauseMs = (shortPauseMs + turkishPlan.shortPauseMs) / 2;
    mediumPauseMs = (mediumPauseMs + turkishPlan.mediumPauseMs) / 2;
    final combinedTone =
        '${emotionMapping.speakingTemperature}/${turkishPlan.emotionalColor}/${emphasisResolution.contourHint}';

    return NovaProsodyPlan(
      speechRate: rate,
      pitch: pitch,
      shortPauseMs: shortPauseMs,
      mediumPauseMs: mediumPauseMs,
      emphasis:
          (emphasis +
                  (emphasisResolution.emphasisWords.isNotEmpty ? 0.04 : 0.0))
              .clamp(0.0, 0.25),
      emotionalTone: combinedTone,
      shortFormPreferred: shortFormPreferred,
    );
  }

  bool _containsAny(String text, List<String> parts) {
    for (final part in parts) {
      if (text.contains(part)) return true;
    }
    return false;
  }
}
