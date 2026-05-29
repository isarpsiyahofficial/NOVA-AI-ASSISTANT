// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class TurkishSpeechStyleService {
  const TurkishSpeechStyleService();

  String normalizeForNaturalSpeech(String text) {
    var cleaned = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return '';

    cleaned = cleaned
        .replaceAll(' efendim efendim', ' efendim')
        .replaceAll('Buyurun efendim. Buyurun efendim.', 'Buyurun efendim.')
        .replaceAll('  ', ' ')
        .trim();

    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\bAI\b', caseSensitive: false),
      (_) => 'yapay zeka',
    );

    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\bWi[- ]?Fi\b', caseSensitive: false),
      (_) => 'vayfay',
    );

    cleaned = cleaned.replaceAll('...', '…');
    cleaned = cleaned.replaceAll('?.', '?');
    cleaned = cleaned.replaceAll('!.', '!');
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([,;:])(?=\S)'),
      (m) => '${m.group(1)} ',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([.!?])(?=\S)'),
      (m) => '${m.group(1)} ',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([^.!?])\s+(ama|fakat|yalnız|ancak)\s+', caseSensitive: false),
      (m) => '${m.group(1)}. ${m.group(2)} ',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(
        r'([^.!?])\s+(sonra|ardından|bu yüzden|bu nedenle)\s+',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)}. ${m.group(2)} ',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\b(ok|okey)\b', caseSensitive: false),
      (_) => 'tamam',
    );
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleaned.length > 220 && !cleaned.contains('. ')) {
      cleaned = cleaned.replaceAllMapped(RegExp(r',\s*'), (_) => '. ');
    }

    if (cleaned.length > 140) {
      cleaned = cleaned
          .replaceAllMapped(
            RegExp(r'\s+(ve|ama|fakat|yalnız|ancak)\s+', caseSensitive: false),
            (m) => '. ${m.group(1)} ',
          )
          .replaceAllMapped(
            RegExp(
              r'\s+(çünkü|bu yüzden|bu nedenle|sonra|ardından)\s+',
              caseSensitive: false,
            ),
            (m) => '. ${m.group(1)} ',
          );
    }

    if (!RegExp(r'[.!?]$').hasMatch(cleaned)) {
      cleaned = '$cleaned.';
    }

    return cleaned;
  }

  String buildFastReply(String text) {
    final cleaned = normalizeForNaturalSpeech(text);
    if (cleaned.isEmpty) return 'Buyurun efendim.';

    final shortFriendly = _firstMeaningfulSentence(cleaned);
    if (shortFriendly.length <= 90) {
      return shortFriendly;
    }

    return '${shortFriendly.substring(0, 87).trim()}...';
  }

  String preferredLocale(String incomingLocale) {
    final locale = incomingLocale.trim().toLowerCase();
    if (locale.isEmpty) return 'tr-TR';
    if (locale == 'tr' || locale.startsWith('tr-')) return 'tr-TR';
    if (locale == 'en' || locale == 'en-us') return 'en-US';
    if (locale == 'en-gb') return 'en-GB';
    return incomingLocale.trim();
  }

  double preferredSpeechRate(String localeCode) {
    final code = localeCode.toLowerCase().trim();
    if (code.startsWith('tr')) {
      return 0.94;
    }
    return 0.96;
  }

  double preferredPitch(String localeCode) {
    final code = localeCode.toLowerCase().trim();
    if (code.startsWith('tr')) {
      return 1.03;
    }
    return 1.0;
  }

  String _firstMeaningfulSentence(String text) {
    final match = RegExp(r'^.*?[.!?]').firstMatch(text);
    if (match == null) return text;
    return match.group(0)?.trim() ?? text;
  }
}
