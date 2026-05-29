// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaPauseRenderResult {
  final String renderedText;
  final int insertedBreathPoints;
  const NovaPauseRenderResult({
    required this.renderedText,
    required this.insertedBreathPoints,
  });
  String buildPromptSection() =>
      'DURAK OLUŞTURUCU: nefesNoktası=$insertedBreathPoints; örnek="$renderedText"';
}

class NovaPauseRendererService {
  const NovaPauseRendererService();

  NovaPauseRenderResult render(String raw) {
    var text = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    var count = 0;
    final before = text;
    text = text
        .replaceAllMapped(
          RegExp(
            r',\s*(ama|fakat|ancak|çünkü|çunku|yalnız|yalniz)\s+',
            caseSensitive: false,
          ),
          (m) {
            count++;
            return '. ${_cap(m.group(1) ?? '')} ';
          },
        )
        .replaceAllMapped(
          RegExp(
            r'\s+(ve sonra|sonra da|ardından|ardindan)\s+',
            caseSensitive: false,
          ),
          (m) {
            count++;
            return '. ${_cap(m.group(1) ?? '')} ';
          },
        );
    if (count == 0 && before.length > 140 && !before.contains('?')) {
      text = before.replaceFirst(
        RegExp(r'\s+(ki|çünkü|cunku|ama|fakat|ancak)\s+', caseSensitive: false),
        '. ',
      );
      if (text != before) count = 1;
    }
    return NovaPauseRenderResult(
      renderedText: text,
      insertedBreathPoints: count,
    );
  }

  String _cap(String token) =>
      token.isEmpty ? token : token[0].toUpperCase() + token.substring(1);
}
