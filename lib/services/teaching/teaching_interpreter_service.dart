// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class TeachingInterpreterResult {
  final bool isTeachingIntent;
  final String title;
  final String triggerPhrase;
  final String description;
  final List<String> steps;

  const TeachingInterpreterResult({
    required this.isTeachingIntent,
    required this.title,
    required this.triggerPhrase,
    required this.description,
    required this.steps,
  });

  const TeachingInterpreterResult.empty()
    : isTeachingIntent = false,
      title = '',
      triggerPhrase = '',
      description = '',
      steps = const <String>[];
}

class TeachingInterpreterService {
  const TeachingInterpreterService();

  TeachingInterpreterResult tryInterpret(String input) {
    final text = input.trim();
    final lower = text.toLowerCase();

    if (text.isEmpty) {
      return const TeachingInterpreterResult.empty();
    }

    if (!_looksLikeTeaching(lower)) {
      return const TeachingInterpreterResult.empty();
    }

    return TeachingInterpreterResult(
      isTeachingIntent: true,
      title: 'Öğretilen İş Akışı',
      triggerPhrase: text,
      description: 'Kullanıcının doğrudan öğrettiği iş akışı',
      steps: <String>[text],
    );
  }

  bool _looksLikeTeaching(String text) {
    return text.contains('bak bunu böyle yap') ||
        text.contains('şunu böyle yap') ||
        text.contains('bunu öğren') ||
        text.contains('bundan sonra şöyle yap') ||
        text.contains('şöyle yapacaksın') ||
        text.contains('böyle davran');
  }
}
