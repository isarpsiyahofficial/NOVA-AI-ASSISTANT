// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaEmotionState {
  final String dominantEmotion;
  final double intensity;
  final double stability;
  final double urgency;
  final double trustComfort;
  final double frustrationTrend;
  final double empathyNeed;
  final List<String> signals;

  const NovaEmotionState({
    required this.dominantEmotion,
    required this.intensity,
    required this.stability,
    required this.urgency,
    required this.trustComfort,
    required this.frustrationTrend,
    required this.empathyNeed,
    this.signals = const <String>[],
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'dominantEmotion': dominantEmotion,
    'intensity': intensity,
    'stability': stability,
    'urgency': urgency,
    'trustComfort': trustComfort,
    'frustrationTrend': frustrationTrend,
    'empathyNeed': empathyNeed,
    'signals': signals,
  };
}
