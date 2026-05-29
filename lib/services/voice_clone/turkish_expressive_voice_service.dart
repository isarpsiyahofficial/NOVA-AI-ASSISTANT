// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class TurkishExpressiveVoiceService {
  const TurkishExpressiveVoiceService();

  String refine(String text) {
    var clean = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) return clean;

    clean = clean
        .replaceAll(' efendim efendim', ' efendim')
        .replaceAll('..', '.')
        .replaceAll('!.', '!')
        .replaceAll('?.', '?')
        .replaceAll(' ,', ',')
        .replaceAll(' .', '.')
        .replaceAll(' !', '!')
        .replaceAll(' ?', '?')
        .replaceAll(' :', ':');

    clean = clean.replaceAllMapped(
      RegExp(r'([.!?])(?=\S)'),
      (m) => '${m.group(1)} ',
    );

    clean = clean.replaceAllMapped(
      RegExp(
        r'\b(tabii|tamam|anladım|haklısınız|haklısın|üzgünüm|sevindim|merak etmeyin|merak etme)\b',
        caseSensitive: false,
      ),
      (m) {
        final value = m.group(0) ?? '';
        if (value.isEmpty) return value;
        return value[0].toUpperCase() + value.substring(1);
      },
    );

    if (!RegExp(r'[.!?]$').hasMatch(clean)) {
      clean = '$clean.';
    }

    clean = clean
        .replaceAll('Efendim, efendim', 'Efendim')
        .replaceAll('Patron, patron', 'Patron')
        .replaceAll(RegExp(r'\bşey yani\b', caseSensitive: false), 'şöyle')
        .replaceAll(RegExp(r'\btamam da\b', caseSensitive: false), 'Tamam da')
        .replaceAll(RegExp(r'\biyi ya\b', caseSensitive: false), 'İyi ya')
        .replaceAll(RegExp(r'\bhım\b', caseSensitive: false), 'hımm')
        .replaceAll(RegExp(r'\bama ama\b', caseSensitive: false), 'ama')
        .replaceAll(RegExp(r'\bve ve\b', caseSensitive: false), 've')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return clean;
  }
}
