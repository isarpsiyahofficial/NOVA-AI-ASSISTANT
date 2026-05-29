// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaMediaDialoguePlan {
  final bool handled;
  final bool needsAppChoice;
  final bool shouldAskDashboardPreference;
  final bool shouldStayVoiceFirst;
  final String spokenResponse;
  final String normalizedQuery;
  final String preferredTarget;
  final Map<String, dynamic> metadata;

  const NovaMediaDialoguePlan({
    required this.handled,
    required this.needsAppChoice,
    required this.shouldAskDashboardPreference,
    required this.shouldStayVoiceFirst,
    String spokenResponse = '',
    required this.normalizedQuery,
    required this.preferredTarget,
    required this.metadata,
  }) : spokenResponse = '';
}

class NovaMediaDialogueOrchestratorService {
  const NovaMediaDialogueOrchestratorService();

  NovaMediaDialoguePlan plan({
    required String raw,
    required String preferredPackage,
    Map<String, dynamic> context = const <String, dynamic>{},
  }) {
    final text = _normalize(raw);
    if (text.isEmpty) {
      return const NovaMediaDialoguePlan(
        handled: false,
        needsAppChoice: false,
        shouldAskDashboardPreference: false,
        shouldStayVoiceFirst: true,
        spokenResponse: '',
        normalizedQuery: '',
        preferredTarget: '',
        metadata: <String, dynamic>{},
      );
    }

    final target = _resolveTarget(text, preferredPackage);
    final query = _extractQuery(text);
    final asksSearch = query.isNotEmpty;
    final needsChoice = target.isEmpty && asksSearch;
    // Media dialogue returns structured state only; no final speech.

    return NovaMediaDialoguePlan(
      handled: true,
      needsAppChoice: needsChoice,
      shouldAskDashboardPreference: needsChoice,
      shouldStayVoiceFirst: true,
      spokenResponse: '',
      normalizedQuery: query,
      preferredTarget: target,
      metadata: <String, dynamic>{
        'query': query,
        'target': target,
        'asksSearch': asksSearch,
      },
    );
  }

  Map<String, dynamic> buildDialogueAudit(String raw) {
    final plan = this.plan(raw: raw, preferredPackage: '');
    return <String, dynamic>{
      'handled': plan.handled,
      'needsAppChoice': plan.needsAppChoice,
      'shouldAskDashboardPreference': plan.shouldAskDashboardPreference,
      'shouldStayVoiceFirst': plan.shouldStayVoiceFirst,
      'normalizedQuery': plan.normalizedQuery,
      'preferredTarget': plan.preferredTarget,
    };
  }

  String buildVoiceFirstResponse({
    required String appLabel,
    required String query,
  }) {
    final q = query.trim();
    if (q.isEmpty) {
      return '$appLabel üzerinden ne açmamı istediğinizi biraz daha net söyleyebilir misiniz efendim?';
    }
    return '$appLabel üzerinden $q için uygun medya akışını hazırlıyorum efendim.';
  }

  List<String> buildAppChoiceHint(String query) {
    return <String>[
      'Sorgu: ${query.trim()}',
      'Spotify veya YouTube Music tercih edilebilir.',
      'Dashboard tercihi varsa ona saygı duyulur.',
      'Belirsizlik varsa önce kullanıcıdan kısa seçim alınır.',
    ];
  }

  String _resolveTarget(String text, String preferred) {
    if (text.contains('spotify')) return 'com.spotify.music';
    if (text.contains('youtube music')) {
      return 'com.google.android.apps.youtube.music';
    }
    return preferred.trim();
  }

  String _label(String target) {
    switch (target) {
      case 'com.spotify.music':
        return 'Spotify';
      case 'com.google.android.apps.youtube.music':
        return 'YouTube Music';
      default:
        return 'medya uygulaması';
    }
  }

  String _extractQuery(String text) {
    final patterns = <RegExp>[
      RegExp(r'(?:ac|aç|cal|çal|oynat)\s+(.+)$'),
      RegExp(r'(?:ara|bul)\s+(.+)$'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return (match.group(1) ?? '').trim();
      }
    }
    return '';
  }

  String _buildActionSpeech(String text, String target) {
    if (text.contains('duraklat') || text.contains('pause')) {
      return '${_label(target)} için duraklatmayı denerim efendim.';
    }
    if (text.contains('devam')) {
      return '${_label(target)} için devam ettirmeyi denerim efendim.';
    }
    if (text.contains('sonraki')) {
      return '${_label(target)} için sonraki içeriğe geçmeyi denerim efendim.';
    }
    if (text.contains('önceki') || text.contains('onceki')) {
      return '${_label(target)} için önceki içeriğe dönmeyi denerim efendim.';
    }
    return '${_label(target)} için sesli yönlendirme hazırlıyorum efendim.';
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ı', 'i')
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
