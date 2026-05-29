// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/runtime/nova_relationship_dramaturgy.dart';
import '../../core/runtime/nova_relationship_profile.dart';

class NovaRelationshipDramaturgyService {
  const NovaRelationshipDramaturgyService();

  NovaRelationshipDramaturgy resolve(NovaRelationshipProfile profile) {
    final stage = _stageFor(profile);
    final ruptureState =
        profile.correctiveSignals >= 3 &&
            profile.correctiveSignals > profile.positiveSignals
        ? 'onarım hassasiyeti yüksek'
        : profile.correctiveSignals >= 1
        ? 'küçük düzeltmeler mevcut'
        : 'stabil';
    final summary = _summaryFor(stage, profile, ruptureState);
    return NovaRelationshipDramaturgy(
      stage: stage,
      arcSummary: summary,
      ruptureState: ruptureState,
      familiarityLevel:
          ((profile.totalInteractions / 24.0) + profile.warmth) / 2,
      trustStability:
          ((profile.trustLevel +
                      (1 -
                          (profile.correctiveSignals /
                                  (profile.totalInteractions <= 0
                                      ? 1
                                      : profile.totalInteractions))
                              .clamp(0.0, 1.0))) /
                  2)
              .clamp(0.0, 1.0),
      ritualAffinity:
          ((profile.ritualSeeds.length / 6.0) +
                  profile.warmth +
                  (1 - profile.formality))
              .clamp(0.0, 1.0) /
          2,
    );
  }

  String _stageFor(NovaRelationshipProfile profile) {
    if (profile.totalInteractions <= 1) return 'tanışma';
    if (profile.totalInteractions <= 4) return 'temkinli alışma';
    if (profile.correctiveSignals >= 3 &&
        profile.positiveSignals < profile.correctiveSignals) {
      return 'kırılma sonrası toparlama';
    }
    if (profile.totalInteractions >= 18 && profile.trustLevel >= 0.72)
      return 'rutinleşme';
    if (profile.totalInteractions >= 8 && profile.trustLevel >= 0.64)
      return 'ortak dil oluşuyor';
    if (profile.totalInteractions >= 5 && profile.trustLevel >= 0.58)
      return 'güven oturuyor';
    return 'temkinli alışma';
  }

  String _summaryFor(
    String stage,
    NovaRelationshipProfile profile,
    String ruptureState,
  ) {
    switch (stage) {
      case 'tanışma':
        return 'henüz yeni; nazik, açık ve aşırı samimi olmayan çizgi en güvenli';
      case 'temkinli alışma':
        return 'yavaşça uyum kur; fazla içli dışlı ya da fazla mekanik olma';
      case 'güven oturuyor':
        return 'tutarlı ton ve küçük hatırlamalar güveni artırır';
      case 'ortak dil oluşuyor':
        return 'küçük ortak kelimeler, daha akıcı dönüşler ve bağlamsal kısa hatırlamalar iyi çalışır';
      case 'rutinleşme':
        return 'tanıdıklık yüksek; ama ezbere kaçmadan doğal ritüel dokunuşları kullan';
      case 'kırılma sonrası toparlama':
        return 'savunma yok; açık, sakin, kısa ve güven onarıcı çizgi şart. Şu an durum: $ruptureState';
      default:
        return 'ilişki çizgisi bağlama duyarlı ilerlemeli';
    }
  }
}
