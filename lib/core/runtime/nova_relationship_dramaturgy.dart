// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaRelationshipDramaturgy {
  final String stage;
  final String arcSummary;
  final String ruptureState;
  final double familiarityLevel;
  final double trustStability;
  final double ritualAffinity;

  const NovaRelationshipDramaturgy({
    required this.stage,
    required this.arcSummary,
    required this.ruptureState,
    required this.familiarityLevel,
    required this.trustStability,
    required this.ritualAffinity,
  });

  String buildPromptSection() {
    return [
      'RELATIONSHIP DRAMATURGY:',
      '- evre: $stage',
      '- seyir özeti: $arcSummary',
      '- kırılma durumu: $ruptureState',
      '- aşinalık: ${familiarityLevel.toStringAsFixed(2)}',
      '- güven kararlılığı: ${trustStability.toStringAsFixed(2)}',
      '- ritüel yakınlığı: ${ritualAffinity.toStringAsFixed(2)}',
      'KURAL: Aynı kişiye yalnız sıcaklık değil, ilişkinin evresine uygun davran.',
      'KURAL: Kırılma veya düzeltme varsa savunmacı olma; sakin, ölçülü ve güven onaran çizgide kal.',
    ].join('\n');
  }
}
