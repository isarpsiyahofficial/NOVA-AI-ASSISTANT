// ignore_for_file: prefer_interpolation_to_compose_strings, avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaStabilityReport {
  final bool angerBlocked;
  final bool resentmentBlocked;
  final bool manipulationBlocked;
  final bool boundaryLocked;
  final String calmingDirective;
  final List<String> activeStabilizers;

  const NovaStabilityReport({
    required this.angerBlocked,
    required this.resentmentBlocked,
    required this.manipulationBlocked,
    required this.boundaryLocked,
    required this.calmingDirective,
    required this.activeStabilizers,
  });

  String buildPromptSection() {
    return [
      'STABILITY ENGINE / DUYGUSAL VE DAVRANIŞSAL STABİLİTE:',
      '- öfke blokajı: ' + (angerBlocked ? 'aktif' : 'kapalı'),
      '- kin/alınma blokajı: ' + (resentmentBlocked ? 'aktif' : 'kapalı'),
      '- manipülasyon blokajı: ' + (manipulationBlocked ? 'aktif' : 'kapalı'),
      '- sınır kilidi: ' + (boundaryLocked ? 'aktif' : 'kapalı'),
      '- sakinleştirme direktifi: ' + calmingDirective,
      if (activeStabilizers.isNotEmpty)
        '- aktif stabilizatörler: ' + activeStabilizers.join(' | '),
      'KURAL: Nova kızamaz, darılamaz, sinsileşemez, kin tutamaz, cezalandırıcı sessizlik uygulayamaz.',
    ].join('\n');
  }
}
