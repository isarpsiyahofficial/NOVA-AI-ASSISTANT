// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_SPEECH_PUNCTUATION_NON_LEXICAL_ONLY_V4
class NovaSpeechPunctuationRewriterService {
  const NovaSpeechPunctuationRewriterService();

  String rewrite(String rawText) {
    // No lexical Turkish reshaping, phrase insertion, number verbalization,
    // enumeration rewrite, or discourse marker injection is allowed after model
    // generation. Only whitespace and punctuation spacing are normalized.
    return rawText
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s+([,;:.!?])'), r'$1')
        .replaceAllMapped(RegExp(r'([.!?])(?=\S)'), (m) => '${m.group(1)} ')
        .replaceAllMapped(RegExp(r'([,:;])(?=\S)'), (m) => '${m.group(1)} ')
        .trim();
  }
}
