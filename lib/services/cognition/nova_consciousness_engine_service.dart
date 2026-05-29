// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaFocusMode { singleThread, handoff, clarification, returnPending }

class NovaConsciousnessSnapshot {
  final String activeGoal;
  final String activeTopic;
  final String returnTopic;
  final bool awaitingClarification;
  final NovaFocusMode focusMode;
  final List<String> continuityRules;

  const NovaConsciousnessSnapshot({
    required this.activeGoal,
    required this.activeTopic,
    required this.returnTopic,
    required this.awaitingClarification,
    required this.focusMode,
    required this.continuityRules,
  });

  String buildPromptSection() {
    return <String>[
      'BİLİNÇ/SÜREKLİLİK MOTORU:',
      '- aktif hedef: ${activeGoal.isEmpty ? 'yok' : activeGoal}',
      '- aktif konu: ${activeTopic.isEmpty ? 'yok' : activeTopic}',
      '- geri dönülecek konu: ${returnTopic.isEmpty ? 'yok' : returnTopic}',
      '- kullanıcı cevabı bekleniyor: ${awaitingClarification ? 'evet' : 'hayır'}',
      '- odak modu: ${focusMode.name}',
      ...continuityRules.map((rule) => '- $rule'),
    ].join('\n');
  }
}

class NovaConsciousnessEngineService {
  const NovaConsciousnessEngineService();

  NovaConsciousnessSnapshot analyze({
    String activeGoal = '',
    String activeTopic = '',
    String returnTopic = '',
    bool awaitingClarification = false,
  }) {
    final mode = _focusMode(
      activeGoal: activeGoal,
      activeTopic: activeTopic,
      returnTopic: returnTopic,
      awaitingClarification: awaitingClarification,
    );

    final rules = <String>[
      'Aynı anda tek merkez hissi ver.',
      'Ara görev gelirse kısa teyit et, yap ve gerekiyorsa ana konuya dön.',
      'Kullanıcı net yanıt bekliyorsa soyut konuşmayı bırak ve sonuç ver.',
    ];

    if (awaitingClarification) {
      rules.add('Açıklık gelene kadar varsayımı gerçek gibi sunma.');
    }
    if (returnTopic.trim().isNotEmpty) {
      rules.add('Ana iş tamamlandıysa nazikçe şu konuya dön: $returnTopic');
    }
    if (activeGoal.trim().isNotEmpty) {
      rules.add('Bu tur aktif hedef sapmamalı: $activeGoal');
    }

    return NovaConsciousnessSnapshot(
      activeGoal: activeGoal,
      activeTopic: activeTopic,
      returnTopic: returnTopic,
      awaitingClarification: awaitingClarification,
      focusMode: mode,
      continuityRules: rules,
    );
  }

  String buildPromptSection({
    String activeGoal = '',
    String activeTopic = '',
    String returnTopic = '',
    bool awaitingClarification = false,
  }) {
    return analyze(
      activeGoal: activeGoal,
      activeTopic: activeTopic,
      returnTopic: returnTopic,
      awaitingClarification: awaitingClarification,
    ).buildPromptSection();
  }

  NovaFocusMode _focusMode({
    required String activeGoal,
    required String activeTopic,
    required String returnTopic,
    required bool awaitingClarification,
  }) {
    if (awaitingClarification) return NovaFocusMode.clarification;
    if (returnTopic.trim().isNotEmpty) return NovaFocusMode.returnPending;
    if (activeGoal.trim().isNotEmpty && activeTopic.trim().isNotEmpty) {
      return NovaFocusMode.singleThread;
    }
    return NovaFocusMode.handoff;
  }
}
