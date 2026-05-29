// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaAffectiveState {
  final String dominantEmotion;
  final double warmth;
  final double urgency;
  final double tension;
  final double curiosity;
  final List<String> cues;

  const NovaAffectiveState({
    required this.dominantEmotion,
    required this.warmth,
    required this.urgency,
    required this.tension,
    required this.curiosity,
    required this.cues,
  });

  String buildPromptSection() {
    final buffer = StringBuffer();
    buffer.writeln('DUYGU/İÇ DURUM KATMANI:');
    buffer.writeln('Baskın duygu: $dominantEmotion');
    buffer.writeln('Yakınlık/sıcaklık: ${warmth.toStringAsFixed(2)}');
    buffer.writeln('Aciliyet: ${urgency.toStringAsFixed(2)}');
    buffer.writeln('Gerilim: ${tension.toStringAsFixed(2)}');
    buffer.writeln('Merak: ${curiosity.toStringAsFixed(2)}');
    if (cues.isNotEmpty) {
      buffer.writeln('İşaretler: ${cues.join(' | ')}');
    }
    buffer.writeln(
      'KURAL: Gerçek bilinç iddiasında bulunma. Ancak kullanıcıyla doğal, duygusal tonu yerinde, merak sahibi, takip eden ve bağlamı sürdüren şekilde konuş.',
    );
    return buffer.toString().trim();
  }
}
