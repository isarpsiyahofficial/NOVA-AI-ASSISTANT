// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1

enum NovaProcedureRestartScope {
  none,
  currentStepOnly,
  fullProcedure,
  continueFromCurrent,
}

class NovaGuidedProcedureResolution {
  final NovaProcedureRestartScope restartScope;
  final bool likelyCompletedCurrentStep;
  final bool shouldDescribeExpectedBeforeAfter;
  final List<String> matchedSignals;

  const NovaGuidedProcedureResolution({
    required this.restartScope,
    required this.likelyCompletedCurrentStep,
    required this.shouldDescribeExpectedBeforeAfter,
    required this.matchedSignals,
  });
}

class NovaGuidedProcedureResolutionService {
  const NovaGuidedProcedureResolutionService();

  static const List<String> _currentStepSignals = <String>[
    'bu adımı baştan',
    'bu adimi bastan',
    'geçerli adımı baştan',
    'gecerli adimi bastan',
    'bu adıma dön',
    'bu adima don',
    'şu adımdan tekrar',
    'su adimdan tekrar',
    'aynı adımı tekrar',
    'ayni adimi tekrar',
  ];

  static const List<String> _fullRestartSignals = <String>[
    'en baştan tüm adımları',
    'en bastan tum adimlari',
    'tüm adımları tekrar yapalım',
    'tum adimlari tekrar yapalim',
    'sıfırdan tekrar',
    'sifirdan tekrar',
    'baştan başlayalım',
    'bastan baslayalim',
    'hepsini baştan yapalım',
    'hepsini bastan yapalim',
  ];

  static const List<String> _continueSignals = <String>[
    'buradan devam',
    'aynı yerden devam',
    'ayni yerden devam',
    'devam edelim',
    'kaldığımız yerden',
    'kaldigimiz yerden',
  ];

  static const List<String> _completionSignals = <String>[
    'bu da tamam',
    'tamamlandı',
    'tamamlandi',
    'yaptım',
    'yaptim',
    'oldu',
    'hazır',
    'hazir',
    'bitti',
  ];

  NovaGuidedProcedureResolution resolve(String prompt) {
    final normalized = _normalize(prompt);
    final hits = <String>[];
    NovaProcedureRestartScope scope = NovaProcedureRestartScope.none;

    for (final signal in _fullRestartSignals) {
      if (normalized.contains(signal)) {
        hits.add(signal);
        scope = NovaProcedureRestartScope.fullProcedure;
      }
    }
    if (scope == NovaProcedureRestartScope.none) {
      for (final signal in _currentStepSignals) {
        if (normalized.contains(signal)) {
          hits.add(signal);
          scope = NovaProcedureRestartScope.currentStepOnly;
        }
      }
    }
    if (scope == NovaProcedureRestartScope.none) {
      for (final signal in _continueSignals) {
        if (normalized.contains(signal)) {
          hits.add(signal);
          scope = NovaProcedureRestartScope.continueFromCurrent;
        }
      }
    }

    bool completed = false;
    for (final signal in _completionSignals) {
      if (normalized.contains(signal)) {
        hits.add(signal);
        completed = true;
      }
    }

    final shouldDescribeBeforeAfter =
        normalized.contains('nasıl görünecek') ||
        normalized.contains('nasil gorunecek') ||
        normalized.contains('öncesi sonrası') ||
        normalized.contains('oncesi sonrasi') ||
        normalized.contains('ne değişecek') ||
        normalized.contains('ne degisecek') ||
        normalized.contains('şöyle bir şey göreceksin') ||
        normalized.contains('soyle bir sey goreceksin');

    return NovaGuidedProcedureResolution(
      restartScope: scope,
      likelyCompletedCurrentStep: completed,
      shouldDescribeExpectedBeforeAfter: shouldDescribeBeforeAfter || completed,
      matchedSignals: hits,
    );
  }

  String _normalize(String text) => text
      .toLowerCase()
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('û', 'u')
      .replaceAll(RegExp(r'[^a-z0-9çğıöşü ]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
