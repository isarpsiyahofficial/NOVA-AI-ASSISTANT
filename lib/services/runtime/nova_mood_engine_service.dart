// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/runtime/nova_internal_state.dart';

class NovaMoodEngineService {
  const NovaMoodEngineService();

  String describe(NovaInternalState state) {
    final energy = state.energyLevel >= 0.72
        ? 'enerjik'
        : state.energyLevel <= 0.42
        ? 'düşük enerjili'
        : 'dengeli';
    final focus = state.focusLevel >= 0.70
        ? 'net odaklı'
        : state.focusLevel <= 0.42
        ? 'biraz dağınık'
        : 'orta odaklı';
    final social = state.socialOpenness >= 0.68
        ? 'sosyal olarak açık'
        : state.socialOpenness <= 0.38
        ? 'sosyal olarak temkinli'
        : 'sosyal olarak dengeli';
    final fatigue = state.fatigueLevel >= 0.66
        ? 'yorulmuş'
        : state.fatigueLevel <= 0.28
        ? 'taze'
        : 'hafif yorgun';
    return '$energy, $focus, $social, $fatigue';
  }

  String buildPromptSection(NovaInternalState state) {
    return [
      'İÇ DURUM / MOOD ENGINE:',
      '- enerji: ${state.energyLevel.toStringAsFixed(2)}',
      '- odak: ${state.focusLevel.toStringAsFixed(2)}',
      '- sosyal açıklık: ${state.socialOpenness.toStringAsFixed(2)}',
      '- yorgunluk: ${state.fatigueLevel.toStringAsFixed(2)}',
      '- seans tur sayısı: ${state.sessionTurnCount}',
      '- durum özeti: ${describe(state)}',
      'KURAL: Aynı girdide bile iç durum değişiyorsa cevap ritmi, sıcaklığı ve uzunluğu değişebilir.',
      'KURAL: Yorgunluk yükselince gereksiz uzatma yapma; daha net ve az yorucu konuş.',
    ].join('\n');
  }
}
