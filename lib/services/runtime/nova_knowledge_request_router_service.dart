// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'nova_guided_procedure_resolution_service.dart';

enum NovaKnowledgeRequestMode {
  generalConversation,
  targetedRetrieval,
  deepResearch,
  learnTopic,
  problemSolve,
  domainDiagnosis,
  guidedProcedure,
}

class NovaKnowledgeRequestRoute {
  final NovaKnowledgeRequestMode mode;
  final double confidence;
  final List<String> matchedPhrases;
  final bool shouldUseDeepCorpus;
  final bool shouldDiagnoseDomainFirst;
  final bool shouldUseGuidedSteps;
  final bool shouldOfferOverviewFirst;

  const NovaKnowledgeRequestRoute({
    required this.mode,
    required this.confidence,
    required this.matchedPhrases,
    required this.shouldUseDeepCorpus,
    required this.shouldDiagnoseDomainFirst,
    required this.shouldUseGuidedSteps,
    required this.shouldOfferOverviewFirst,
  });
}

class NovaKnowledgeRequestRouterService {
  const NovaKnowledgeRequestRouterService();

  static const NovaGuidedProcedureResolutionService _guidedProcedure =
      NovaGuidedProcedureResolutionService();

  static const Map<NovaKnowledgeRequestMode, List<String>> _phrases =
      <NovaKnowledgeRequestMode, List<String>>{
        NovaKnowledgeRequestMode.deepResearch: <String>[
          'derin araştır',
          'derin arastir',
          'kaynaklarında ara',
          'kaynaklarinda ara',
          'kaynaklarında araştır',
          'kaynaklarinda arastir',
          'detaylı araştır',
          'detayli arastir',
          'kaynaklarımı tara',
          'korpusunda ara',
        ],
        NovaKnowledgeRequestMode.learnTopic: <String>[
          'benim için öğren',
          'benim icin ogren',
          'şunu öğren',
          'sunu ogren',
          'öğren ve kaydet',
          'ogren ve kaydet',
          'bu konuyu öğren',
          'bu konuyu ogren',
          'öğrenmeni istiyorum',
          'ogrenmeni istiyorum',
        ],
        NovaKnowledgeRequestMode.problemSolve: <String>[
          'nasıl çözerim',
          'nasil cozerim',
          'nasıl çözebilirim',
          'nasil cozebilirim',
          'problemim var',
          'sorunum var',
          'çözüm bul',
          'cozum bul',
          'bunu nasıl hallederim',
          'bunu nasil hallederim',
        ],
        NovaKnowledgeRequestMode.domainDiagnosis: <String>[
          'hangi mesele olduğunu bilmiyorum',
          'hangi mesele oldugunu bilmiyorum',
          'hangi alana ait olduğunu bul',
          'hangi alana ait oldugunu bul',
          'sorunun ne olduğunu bul',
          'sorunun ne oldugunu bul',
          'ne olduğunu bilmiyorum',
          'ne oldugunu bilmiyorum',
          'hangi konuda olduğunu anlamıyorum',
        ],
        NovaKnowledgeRequestMode.guidedProcedure: <String>[
          'adım adım',
          'adim adim',
          'birlikte çözelim',
          'birlikte cozelim',
          'benimle ilerle',
          'rehberlik et',
          'rehberlik eder misin',
          'önce tüm adımları anlat',
          'once tum adimlari anlat',
        ],
        NovaKnowledgeRequestMode.targetedRetrieval: <String>[
          'ara',
          'bul',
          'göster',
          'goster',
          'bak',
          'incele',
          'kontrol et',
          'özetle',
          'ozetle',
        ],
      };

  NovaKnowledgeRequestRoute route(String prompt) {
    final normalized = _normalize(prompt);
    if (normalized.isEmpty) {
      return const NovaKnowledgeRequestRoute(
        mode: NovaKnowledgeRequestMode.generalConversation,
        confidence: 0.0,
        matchedPhrases: <String>[],
        shouldUseDeepCorpus: false,
        shouldDiagnoseDomainFirst: false,
        shouldUseGuidedSteps: false,
        shouldOfferOverviewFirst: false,
      );
    }

    NovaKnowledgeRequestMode bestMode =
        NovaKnowledgeRequestMode.generalConversation;
    double bestScore = 0.0;
    List<String> bestHits = <String>[];

    for (final entry in _phrases.entries) {
      double score = 0.0;
      final hits = <String>[];
      for (final phrase in entry.value) {
        if (normalized.contains(phrase)) {
          score += phrase.length >= 12 ? 1.4 : 1.0;
          hits.add(phrase);
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestMode = entry.key;
        bestHits = hits;
      }
    }

    if (bestScore <= 0.0) {
      if (normalized.contains('?') ||
          normalized.startsWith('neden') ||
          normalized.startsWith('nasıl') ||
          normalized.startsWith('nasil')) {
        bestMode = NovaKnowledgeRequestMode.targetedRetrieval;
        bestScore = 0.42;
      }
    }

    final confidence = (bestScore / 4.0).clamp(0.0, 0.98).toDouble();
    final isDeep =
        bestMode == NovaKnowledgeRequestMode.deepResearch ||
        bestMode == NovaKnowledgeRequestMode.learnTopic;
    final isDiagnosis = bestMode == NovaKnowledgeRequestMode.domainDiagnosis;
    final isGuided =
        bestMode == NovaKnowledgeRequestMode.guidedProcedure ||
        bestMode == NovaKnowledgeRequestMode.problemSolve;

    return NovaKnowledgeRequestRoute(
      mode: bestMode,
      confidence: confidence,
      matchedPhrases: bestHits,
      shouldUseDeepCorpus:
          isDeep ||
          isDiagnosis ||
          isGuided ||
          bestMode == NovaKnowledgeRequestMode.targetedRetrieval,
      shouldDiagnoseDomainFirst: isDiagnosis,
      shouldUseGuidedSteps: isGuided,
      shouldOfferOverviewFirst: isGuided || isDeep,
    );
  }

  String buildPromptSection({required String prompt}) {
    final resolvedRoute = this.route(prompt);
    final procedure = _guidedProcedure.resolve(prompt);
    return <String>[
      '[İSTEK YÖNLENDİRME MOTORU]',
      '- mod: ${resolvedRoute.mode.name}',
      '- güven: ${resolvedRoute.confidence.toStringAsFixed(2)}',
      '- eşleşmeler: ${resolvedRoute.matchedPhrases.isEmpty ? 'yok' : resolvedRoute.matchedPhrases.join(' | ')}',
      '- derin korpus kullan: ${resolvedRoute.shouldUseDeepCorpus ? 'evet' : 'hayır'}',
      '- alanı önce teşhis et: ${resolvedRoute.shouldDiagnoseDomainFirst ? 'evet' : 'hayır'}',
      '- adım adım rehber moduna geç: ${resolvedRoute.shouldUseGuidedSteps ? 'evet' : 'hayır'}',
      '- gerekirse önce tüm akışı özetle: ${resolvedRoute.shouldOfferOverviewFirst ? 'evet' : 'hayır'}',
      '- prosedür yeniden başlatma kapsamı: ${procedure.restartScope.name}',
      '- mevcut adım tamamlandı sinyali: ${procedure.likelyCompletedCurrentStep ? 'evet' : 'hayır'}',
      '- öncesi/sonrası tasvir bekleniyor: ${procedure.shouldDescribeExpectedBeforeAfter ? 'evet' : 'hayır'}',
      '- prosedür sinyalleri: ${procedure.matchedSignals.isEmpty ? 'yok' : procedure.matchedSignals.join(' | ')}',
      '- Kullanıcı "en baştan" dediğinde bunun tüm akış mı yoksa sadece geçerli adım mı olduğunu metinden ayırt et.',
      '- Kullanıcı bir adımı bitirdiğini söylüyorsa sonraki adımda ne göreceğini ve neyin değişeceğini tasvir et.',
      '- Kullanıcı serbest doğal dil konuşabilir; sabit komut bekleme.',
    ].join('\n');
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
