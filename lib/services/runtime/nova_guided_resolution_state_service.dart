// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaGuidedResolutionAction {
  none,
  explainOverview,
  startGuidedFlow,
  replayCurrentStep,
  restartAllSteps,
  confirmCurrentStep,
  blockedStep,
  describeNextState,
}

class NovaGuidedResolutionDecision {
  final NovaGuidedResolutionAction action;
  final double confidence;
  final String reason;

  const NovaGuidedResolutionDecision({
    required this.action,
    required this.confidence,
    required this.reason,
  });
}

class NovaGuidedResolutionStateService {
  const NovaGuidedResolutionStateService();

  NovaGuidedResolutionDecision interpret({
    required String prompt,
    required bool hasActivePlan,
  }) {
    final normalized = _normalize(prompt);
    if (normalized.isEmpty) {
      return const NovaGuidedResolutionDecision(
        action: NovaGuidedResolutionAction.none,
        confidence: 0,
        reason: 'empty',
      );
    }
    if (_containsAny(normalized, const <String>[
      'önce tüm adımları anlat',
      'once tum adimlari anlat',
      'önce tüm süreci anlat',
      'once tum sureci anlat',
    ])) {
      return const NovaGuidedResolutionDecision(
        action: NovaGuidedResolutionAction.explainOverview,
        confidence: 0.96,
        reason: 'overview_request',
      );
    }
    if (_containsAny(normalized, const <String>[
      'benimle ilerle',
      'birlikte yapalım',
      'birlikte yapalim',
      'adım adım gidelim',
      'adim adim gidelim',
    ])) {
      return const NovaGuidedResolutionDecision(
        action: NovaGuidedResolutionAction.startGuidedFlow,
        confidence: 0.95,
        reason: 'guided_start',
      );
    }
    if (_containsAny(normalized, const <String>[
      'tüm süreci baştan al',
      'tum sureci bastan al',
      'tüm adımları baştan al',
      'tum adimlari bastan al',
      'her şeyi baştan yapalım',
      'her seyi bastan yapalim',
    ])) {
      return const NovaGuidedResolutionDecision(
        action: NovaGuidedResolutionAction.restartAllSteps,
        confidence: 0.98,
        reason: 'restart_all',
      );
    }
    if (hasActivePlan &&
        _containsAny(normalized, const <String>[
          'bu adımı baştan al',
          'bu adimi bastan al',
          'bu kısmı tekrar anlat',
          'bu kismi tekrar anlat',
          'en baştan benimle ilerle',
          'en bastan benimle ilerle',
        ])) {
      return const NovaGuidedResolutionDecision(
        action: NovaGuidedResolutionAction.replayCurrentStep,
        confidence: 0.90,
        reason: 'replay_current_step',
      );
    }
    if (_containsAny(normalized, const <String>[
      'tamam oldu',
      'oldu',
      'bitti',
      'bu da tamam',
      'tamamdır',
      'tamamdir',
    ])) {
      return const NovaGuidedResolutionDecision(
        action: NovaGuidedResolutionAction.confirmCurrentStep,
        confidence: 0.86,
        reason: 'step_confirmed',
      );
    }
    if (_containsAny(normalized, const <String>[
      'takıldım',
      'takildim',
      'olmadı',
      'olmadi',
      'burada kaldım',
      'burada kaldim',
      'beklediğim gibi değil',
      'bekledigim gibi degil',
    ])) {
      return const NovaGuidedResolutionDecision(
        action: NovaGuidedResolutionAction.blockedStep,
        confidence: 0.88,
        reason: 'blocked',
      );
    }
    if (_containsAny(normalized, const <String>[
      'sonra ne olacak',
      'sonra ne gorucem',
      'sonra ne göreceğim',
      'ne görmem lazım',
      'ne gormem lazim',
    ])) {
      return const NovaGuidedResolutionDecision(
        action: NovaGuidedResolutionAction.describeNextState,
        confidence: 0.84,
        reason: 'next_state',
      );
    }
    return const NovaGuidedResolutionDecision(
      action: NovaGuidedResolutionAction.none,
      confidence: 0.18,
      reason: 'no_guided_signal',
    );
  }

  String buildPromptSection({
    required String prompt,
    required bool hasActivePlan,
  }) {
    final decision = interpret(prompt: prompt, hasActivePlan: hasActivePlan);
    return <String>[
      '[ADIM DURUM MAKİNESİ]',
      '- aksiyon: ${decision.action.name}',
      '- güven: ${decision.confidence.toStringAsFixed(2)}',
      '- neden: ${decision.reason}',
      '- Kural: belirsiz “en baştan” ifadesi ve aktif plan varsa önce mevcut adımı tekrar anlatma ihtimalini düşün.',
      '- Kural: “tüm süreç / tüm adımlar / her şey” geçiyorsa global restart kabul et.',
      '- Kural: kullanıcı “oldu / tamam / bitti” diyorsa sıradaki adıma veya sonraki görünür sonuca hazırlan.',
      '- Kural: her adım sonrasında kullanıcıya ne görmesi gerektiğini ve ne değişeceğini tasvir et.',
    ].join('\n');
  }

  bool _containsAny(String text, List<String> phrases) =>
      phrases.any(text.contains);

  String _normalize(String text) => text
      .toLowerCase()
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('û', 'u')
      .replaceAll(RegExp(r'[^a-z0-9çğıöşü ]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
