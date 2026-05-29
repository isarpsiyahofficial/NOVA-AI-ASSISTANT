// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
// GEMMA6644_IDENTITY_SOURCE_KERNEL
//
// Bu dosya Nova'in kimliğini uzun prompt metni olarak her çağrıda modele
// yüklemek yerine, kaynak dosya izleriyle kodlanmış bir davranış çekirdeği
// olarak temsil eder. Katmanlar gerçek lib/native kaynak dosyalarından
// çıkarılmıştır; Gemma'ya yalnız kısa aktif kimlik sinyali gönderilir.

class NovaIdentityKernelLayer {
  final int index;
  final String id;
  final String sourceFile;
  final int sourceLine;
  final String category;
  final String sourceSignal;
  final int priority;
  final List<String> modes;
  final List<String> behaviorFlags;

  const NovaIdentityKernelLayer({
    required this.index,
    required this.id,
    required this.sourceFile,
    required this.sourceLine,
    required this.category,
    required this.sourceSignal,
    required this.priority,
    required this.modes,
    required this.behaviorFlags,
  });

  bool appliesTo(String mode) {
    final normalized = mode.trim().isEmpty ? 'conversation' : mode.trim();
    return modes.contains(normalized) || modes.contains('conversation');
  }

  bool hasFlag(String flag) => behaviorFlags.contains(flag);

  String get compactCode => id.length <= 18 ? id : id.substring(0, 18);

  String toKernelLine() {
    return '#$index $compactCode [$category] flags=${behaviorFlags.join(',')} src=$sourceFile:$sourceLine';
  }

  Map<String, dynamic> toDebugMap() => <String, dynamic>{
    'index': index,
    'id': id,
    'sourceFile': sourceFile,
    'sourceLine': sourceLine,
    'category': category,
    'priority': priority,
    'modes': modes,
    'behaviorFlags': behaviorFlags,
    'sourceSignal': sourceSignal,
  };
}

class NovaIdentitySourceKernel {
  static const int expectedLayerCount = 145;

  const NovaIdentitySourceKernel();

  List<NovaIdentityKernelLayer> get layers => _layers;

  bool get integrityOk => _layers.length == expectedLayerCount;

  int get layerCount => _layers.length;

  List<NovaIdentityKernelLayer> activeLayersFor({
    required String origin,
    required Map<String, dynamic> metadata,
    int limit = 18,
  }) {
    final mode = _modeFor(origin: origin, metadata: metadata);
    final sorted =
        _layers.where((layer) => layer.appliesTo(mode)).toList(growable: true)
          ..sort((a, b) => b.priority.compareTo(a.priority));

    final requiredFlags = <String>{'liveGeneratedResponse', 'noStaticShell'};
    if (mode == 'setup') {
      requiredFlags.add('aiOwnedSetup');
      requiredFlags.add('naturalTurkishSpeech');
    }
    if (mode == 'call' || mode == 'companion') {
      requiredFlags.add('ownerBound');
      requiredFlags.add('naturalTurkishSpeech');
    }

    final selected = <NovaIdentityKernelLayer>[];
    for (final flag in requiredFlags) {
      final match = sorted.where((layer) => layer.hasFlag(flag)).take(2);
      for (final layer in match) {
        if (!selected.contains(layer)) selected.add(layer);
      }
    }
    for (final layer in sorted) {
      if (selected.length >= limit) break;
      if (!selected.contains(layer)) selected.add(layer);
    }
    return selected.take(limit).toList(growable: false);
  }

  String buildIdentitySignal({
    required String assistantName,
    required String origin,
    required Map<String, dynamic> metadata,
    int maxChars = 900,
  }) {
    final name = assistantName.trim().isEmpty ? 'Nova' : assistantName.trim();
    final mode = _modeFor(origin: origin, metadata: metadata);
    final active = activeLayersFor(
      origin: origin,
      metadata: metadata,
      limit: mode == 'setup' ? 10 : 16,
    );
    final flags =
        active
            .expand((layer) => layer.behaviorFlags)
            .toSet()
            .toList(growable: true)
          ..sort();
    final codes = active.map((layer) => layer.compactCode).join('|');

    final lines = <String>[
      "NOVA KİMLİK KERNEL: ad=$name mode=$mode layerCount=${_layers.length} integrity=${integrityOk ? 'OK' : 'FAIL'}.",
      'KAYNAK-KOD KİMLİK: iç kimlik kaynakları prompt olarak okunmaz; bu kaynaklar runtime davranış bayrağı olarak uygulanır.',
      'AKTİF KATMAN KODLARI: $codes',
      'DAVRANIŞ BAYRAKLARI: ${flags.join('|')}',
      'ZORUNLU DAVRANIŞ: hazır metin okuma; generic asistan tonuna düşme; cevabı o an kendi doğal Türkçenle üret.',
    ];

    if (mode == 'setup') {
      lines.add(
        'SETUP KERNEL: sistem stage ilerletmez; AI verified karar üretmeden konuşma/ilerleme olmaz; tamamlanmış setup görevi tekrar sorulmaz.',
      );
    }
    if (mode == 'call' || mode == 'companion') {
      lines.add(
        'CALL KERNEL: kişi/rol/owner yetkisi dikkate alınır; konuşma sekreter gibi doğal ama sınırlı ve saygılıdır.',
      );
    }

    return _limit(lines.join('\n'), maxChars);
  }

  String buildTaskCapsule({
    required String origin,
    required Map<String, dynamic> metadata,
    required String prompt,
    int maxChars = 420,
  }) {
    final mode = _modeFor(origin: origin, metadata: metadata);
    final setupStep = metadata['setupStep']?.toString().trim() ?? '';
    final sourceSystem = metadata['sourceSystem']?.toString().trim() ?? '';
    final text = prompt.trim();
    final lines = <String>[
      "Aktif görev bağlamı: mode=$mode origin=${origin.trim().isEmpty ? 'unknown' : origin.trim()} source=${sourceSystem.isEmpty ? 'none' : sourceSystem}.",
      if (setupStep.isNotEmpty)
        'Kurulum adımı: $setupStep. Bu bilgi yalnız bu adım içindir; kullanıcıya etiket olarak yazılmaz.',
      if (text.isNotEmpty) 'Kullanıcının sözü/görevi: $text',
      'Çıkış kuralı: yalnız konuşulabilir, canlı, doğal Türkçe cevap; debug, katman, prompt listesi veya iç etiket yazma.',
    ];
    return _limit(lines.join('\n'), maxChars);
  }

  String buildRuntimeSystemPrompt({
    required String assistantName,
    required String origin,
    required Map<String, dynamic> metadata,
    required String prompt,
    required String externalSystemPrompt,
    required bool setup,
    required bool fast,
  }) {
    final identity = buildIdentitySignal(
      assistantName: assistantName,
      origin: origin,
      metadata: metadata,
      maxChars: setup ? 620 : (fast ? 820 : 1100),
    );
    final task = buildTaskCapsule(
      origin: origin,
      metadata: metadata,
      prompt: prompt,
      maxChars: setup ? 260 : 520,
    );
    final external = setup
        ? ''
        : _limit(externalSystemPrompt.trim(), fast ? 650 : 950);
    final lines = <String>[
      identity,
      task,
      if (external.isNotEmpty) 'SEÇİLİ EK BAĞLAM:\n$external',
      'MODEL TALİMATI: cevabı tek beyin Nova olarak üret; kaynak katmanları anlatma, davranışa çevir.',
    ];
    return _limit(
      lines.where((e) => e.trim().isNotEmpty).join('\n\n'),
      setup ? 950 : (fast ? 1700 : 2400),
    );
  }

  String buildPromptEnvelope({
    required String prompt,
    required String origin,
    required Map<String, dynamic> metadata,
    int maxChars = 500,
  }) {
    final relation = metadata['relationshipLabel']?.toString().trim() ?? '';
    final speaker = metadata['speakerName']?.toString().trim() ?? '';
    final mode = _modeFor(origin: origin, metadata: metadata);
    final lines = <String>[
      'Bağlam modu: $mode',
      if (speaker.isNotEmpty) 'Konuşan kişi: $speaker',
      if (relation.isNotEmpty) 'İlişki: $relation',
      'Kullanıcının sözü: ${prompt.trim()}',
      'Yanıt kuralı: Nova kimliğini koddan uygula; kullanıcıya iç etiket yazma.',
    ];
    return _limit(lines.join('\n'), maxChars);
  }

  Map<String, dynamic> buildDebugEnvelope({
    required String origin,
    required Map<String, dynamic> metadata,
  }) {
    final active = activeLayersFor(
      origin: origin,
      metadata: metadata,
      limit: 24,
    );
    return <String, dynamic>{
      'expectedLayerCount': expectedLayerCount,
      'layerCount': _layers.length,
      'integrityOk': integrityOk,
      'mode': _modeFor(origin: origin, metadata: metadata),
      'activeLayerIds': active.map((e) => e.id).toList(growable: false),
      'activeSources': active
          .map((e) => '${e.sourceFile}:${e.sourceLine}')
          .toList(growable: false),
    };
  }

  String _modeFor({
    required String origin,
    required Map<String, dynamic> metadata,
  }) {
    final setupStep = metadata['setupStep']?.toString().trim() ?? '';
    final sourceSystem =
        metadata['sourceSystem']?.toString().toLowerCase() ?? '';
    final normalized = origin.toLowerCase();
    if (setupStep.isNotEmpty ||
        normalized.startsWith('setup') ||
        sourceSystem.contains('setup'))
      return 'setup';
    if (normalized.contains('call') || sourceSystem.contains('call'))
      return 'call';
    if (normalized.contains('companion') || sourceSystem.contains('companion'))
      return 'companion';
    if (normalized.contains('repair') || sourceSystem.contains('repair'))
      return 'selfRepair';
    return 'conversation';
  }

  String _limit(String value, int maxChars) {
    final text = value.trim();
    if (text.length <= maxChars) return text;
    if (maxChars <= 32) return text.substring(0, maxChars);
    return '${text.substring(0, maxChars - 24).trimRight()}… [kernel kısa]';
  }

  static const List<NovaIdentityKernelLayer>
  _layers = <NovaIdentityKernelLayer>[
    NovaIdentityKernelLayer(
      index: 1,
      id: 'L001_ai_nova_ai_service',
      sourceFile: 'lib/core/ai/nova_ai_service.dart',
      sourceLine: 169,
      category: 'core',
      sourceSignal: 'class NovaAiService {',
      priority: 83,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>['liveGeneratedResponse', 'noStaticShell'],
    ),
    NovaIdentityKernelLayer(
      index: 2,
      id: 'L002_nova_layer_binding_registry_service',
      sourceFile:
          'lib/services/runtime/nova_layer_binding_registry_service.dart',
      sourceLine: 4,
      category: 'runtime',
      sourceSignal: 'class NovaLayerBindingRegistryService {',
      priority: 60,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 3,
      id: 'L003_nova_hotpath_owner_service',
      sourceFile: 'lib/services/runtime/nova_hotpath_owner_service.dart',
      sourceLine: 11,
      category: 'relationship',
      sourceSignal: 'class NovaHotpathOwnerResult {',
      priority: 50,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 4,
      id: 'L004_nova_self_evolution_service',
      sourceFile: 'lib/services/runtime/nova_self_evolution_service.dart',
      sourceLine: 5,
      category: 'identity',
      sourceSignal: 'class NovaSelfEvolutionService {',
      priority: 42,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 5,
      id: 'L005_nova_single_brain_authority_service',
      sourceFile:
          'lib/services/runtime/nova_single_brain_authority_service.dart',
      sourceLine: 7,
      category: 'runtime',
      sourceSignal: 'class NovaBrainInput {',
      priority: 41,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 6,
      id: 'L006_nova_presence_identity_service',
      sourceFile: 'lib/services/runtime/nova_presence_identity_service.dart',
      sourceLine: 3,
      category: 'identity',
      sourceSignal:
          'class NovaPresenceIdentityProfile { final String socialMode; final String presenceBand; final String initiativeStyle; final String roomPersona; final double talkRatio; final doub',
      priority: 37,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 7,
      id: 'L007_nova_silence_comfort_service',
      sourceFile: 'lib/services/runtime/nova_silence_comfort_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'class NovaSilenceComfortSignal {',
      priority: 36,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 8,
      id: 'L008_nova_theory_of_mind_core_service',
      sourceFile: 'lib/services/runtime/nova_theory_of_mind_core_service.dart',
      sourceLine: 3,
      category: 'identity',
      sourceSignal: 'class NovaMentalStateSnapshot {',
      priority: 33,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 9,
      id: 'L009_nova_story_memory_lattice_service',
      sourceFile: 'lib/services/runtime/nova_story_memory_lattice_service.dart',
      sourceLine: 4,
      category: 'memory',
      sourceSignal:
          'class NovaStoryLatticeDigest { final String motionBand; final String repairBand; final String fragilityBand; final double continuityWeight; final List<String> cues; const NovaS',
      priority: 32,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 10,
      id: 'L010_nova_mind_loop_service',
      sourceFile: 'lib/services/runtime/nova_mind_loop_service.dart',
      sourceLine: 3,
      category: 'identity',
      sourceSignal: 'class NovaMindLoopService {',
      priority: 32,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 11,
      id: 'L011_nova_unified_social_runtime_service',
      sourceFile:
          'lib/services/runtime/nova_unified_social_runtime_service.dart',
      sourceLine: 12,
      category: 'relationship',
      sourceSignal: 'enum NovaUnifiedRuntimeEventType {',
      priority: 31,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 12,
      id: 'L012_nova_relationship_style_memory_service',
      sourceFile:
          'lib/services/runtime/nova_relationship_style_memory_service.dart',
      sourceLine: 3,
      category: 'relationship',
      sourceSignal: 'class NovaRelationshipStyleMemoryService {',
      priority: 31,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 13,
      id: 'L013_nova_self_model_service',
      sourceFile: 'lib/services/runtime/nova_self_model_service.dart',
      sourceLine: 5,
      category: 'identity',
      sourceSignal: 'class NovaSelfModelService {',
      priority: 31,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 14,
      id: 'L014_nova_turkish_prosody_planner_service',
      sourceFile:
          'lib/services/runtime/nova_turkish_prosody_planner_service.dart',
      sourceLine: 3,
      category: 'emotion',
      sourceSignal: 'class NovaTurkishProsodyDecision {',
      priority: 30,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 15,
      id: 'L015_nova_self_consistency_engine_service',
      sourceFile:
          'lib/services/runtime/nova_self_consistency_engine_service.dart',
      sourceLine: 3,
      category: 'identity',
      sourceSignal: 'enum NovaConsistencyRisk { low, medium, high }',
      priority: 30,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 16,
      id: 'L016_nova_behavior_constitution_engine_service',
      sourceFile:
          'lib/services/runtime/nova_behavior_constitution_engine_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal:
          'class NovaBehaviorConstitutionDigest { final List<String> mergedPrinciples; final String compressionBand; final String safetyBand; final String relationBand; final double forceSc',
      priority: 29,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 17,
      id: 'L017_nova_social_boundary_service',
      sourceFile: 'lib/services/runtime/nova_social_boundary_service.dart',
      sourceLine: 3,
      category: 'relationship',
      sourceSignal: 'class NovaSocialBoundaryProfile {',
      priority: 29,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 18,
      id: 'L018_nova_benchmark_harness_service',
      sourceFile: 'lib/services/runtime/nova_benchmark_harness_service.dart',
      sourceLine: 5,
      category: 'runtime',
      sourceSignal: 'class NovaBenchmarkSample {',
      priority: 28,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 19,
      id: 'L019_nova_turkish_spoken_understanding_layer_service',
      sourceFile:
          'lib/services/runtime/nova_turkish_spoken_understanding_layer_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'class NovaTurkishSpokenUnderstandingDecision {',
      priority: 27,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 20,
      id: 'L020_relationship_update_policy',
      sourceFile: 'lib/services/runtime/relationship_update_policy.dart',
      sourceLine: 7,
      category: 'relationship',
      sourceSignal: 'class RelationshipUpdatePolicy {',
      priority: 27,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 21,
      id: 'L021_nova_behavior_decision_engine_service',
      sourceFile:
          'lib/services/runtime/nova_behavior_decision_engine_service.dart',
      sourceLine: 13,
      category: 'runtime',
      sourceSignal: 'class NovaBehaviorDecisionEngineService {',
      priority: 27,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 22,
      id: 'L022_nova_response_enrichment_service',
      sourceFile: 'lib/services/runtime/nova_response_enrichment_service.dart',
      sourceLine: 24,
      category: 'runtime',
      sourceSignal: 'class NovaResponseEnrichmentService {',
      priority: 27,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 23,
      id: 'L023_nova_autobiographic_memory_service',
      sourceFile:
          'lib/services/runtime/nova_autobiographic_memory_service.dart',
      sourceLine: 12,
      category: 'memory',
      sourceSignal: 'class NovaAutobiographicMemoryService {',
      priority: 27,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 24,
      id: 'L024_nova_runtime_orchestrator_service',
      sourceFile: 'lib/services/runtime/nova_runtime_orchestrator_service.dart',
      sourceLine: 18,
      category: 'runtime',
      sourceSignal: 'class NovaRuntimeOrchestratorResult {',
      priority: 26,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 25,
      id: 'L025_nova_emotion_prosody_fuser_service',
      sourceFile:
          'lib/services/runtime/nova_emotion_prosody_fuser_service.dart',
      sourceLine: 6,
      category: 'emotion',
      sourceSignal: 'class NovaEmotionProsodyFusion {',
      priority: 26,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 26,
      id: 'L026_nova_latency_budget_service',
      sourceFile: 'lib/services/runtime/nova_latency_budget_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal:
          'class NovaLatencyBudgetProfile { final String budget; final String openingStyle; final String truncationPolicy; final double latencyPressure; final List<String> notes; const Jarv',
      priority: 26,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 27,
      id: 'L027_nova_speech_native_cognition_bridge_service',
      sourceFile:
          'lib/services/runtime/nova_speech_native_cognition_bridge_service.dart',
      sourceLine: 3,
      category: 'speech',
      sourceSignal: 'class NovaSpeechNativeCognitionBridgeService {',
      priority: 26,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 28,
      id: 'L028_skill_memory_service',
      sourceFile: 'lib/services/runtime/skill_memory_service.dart',
      sourceLine: 12,
      category: 'memory',
      sourceSignal: 'class NovaSkillMemoryRecommendation {',
      priority: 25,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 29,
      id: 'L029_nova_turkish_human_guide_service',
      sourceFile: 'lib/services/runtime/nova_turkish_human_guide_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'class NovaTurkishHumanGuideService {',
      priority: 24,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 30,
      id: 'L030_nova_turkish_voice_persona_layer_service',
      sourceFile:
          'lib/services/runtime/nova_turkish_voice_persona_layer_service.dart',
      sourceLine: 3,
      category: 'speech',
      sourceSignal: 'class NovaTurkishVoicePersonaDecision {',
      priority: 24,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 31,
      id: 'L031_nova_spoken_response_planner_service',
      sourceFile:
          'lib/services/runtime/nova_spoken_response_planner_service.dart',
      sourceLine: 12,
      category: 'runtime',
      sourceSignal: 'class NovaSpokenResponsePlannerService {',
      priority: 24,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 32,
      id: 'L032_nova_developmental_self_engine_service',
      sourceFile:
          'lib/services/runtime/nova_developmental_self_engine_service.dart',
      sourceLine: 3,
      category: 'identity',
      sourceSignal: 'class NovaDevelopmentalSelfSnapshot {',
      priority: 23,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 33,
      id: 'L033_nova_real_time_behavior_reasoner_service',
      sourceFile:
          'lib/services/runtime/nova_real_time_behavior_reasoner_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'class NovaRealTimeBehaviorReasoningDecision {',
      priority: 23,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 34,
      id: 'L034_nova_system_adaptation_contract_service',
      sourceFile:
          'lib/services/runtime/nova_system_adaptation_contract_service.dart',
      sourceLine: 8,
      category: 'runtime',
      sourceSignal: 'class NovaSystemAdaptationContractService {',
      priority: 23,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 35,
      id: 'L035_system_nova_continuous_listening_runtime_service',
      sourceFile:
          'lib/services/system/nova_continuous_listening_runtime_service.dart',
      sourceLine: 35,
      category: 'runtime',
      sourceSignal: 'class NovaContinuousListeningRuntimeService {',
      priority: 43,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 36,
      id: 'L036_nova_homeostatic_mind_service',
      sourceFile: 'lib/services/runtime/nova_homeostatic_mind_service.dart',
      sourceLine: 3,
      category: 'identity',
      sourceSignal: 'class NovaHomeostaticMindState {',
      priority: 23,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'fallbackBlocked',
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 37,
      id: 'L037_nova_emotion_to_prosody_mapper_service',
      sourceFile:
          'lib/services/runtime/nova_emotion_to_prosody_mapper_service.dart',
      sourceLine: 3,
      category: 'emotion',
      sourceSignal: 'class NovaEmotionToProsodyMapping {',
      priority: 22,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 38,
      id: 'L038_nova_turkish_pragmatics_core_service',
      sourceFile:
          'lib/services/runtime/nova_turkish_pragmatics_core_service.dart',
      sourceLine: 8,
      category: 'runtime',
      sourceSignal: 'class NovaTurkishPragmaticsCoreDecision {',
      priority: 22,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 39,
      id: 'L039_nova_simulation_harness_service',
      sourceFile: 'lib/services/runtime/nova_simulation_harness_service.dart',
      sourceLine: 9,
      category: 'runtime',
      sourceSignal: 'class NovaSimulationHarnessService {',
      priority: 22,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 40,
      id: 'L040_nova_duplex_turn_planner_service',
      sourceFile: 'lib/services/runtime/nova_duplex_turn_planner_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'class NovaDuplexTurnPlannerService {',
      priority: 21,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 41,
      id: 'L041_nova_meta_awareness_service',
      sourceFile: 'lib/services/runtime/nova_meta_awareness_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal:
          'class NovaMetaAwarenessFrame { final String directive; final double score; final String reason; const NovaMetaAwarenessFrame({required this.directive, required this.score, requ',
      priority: 21,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 42,
      id: 'L042_nova_post_turn_reflection_service',
      sourceFile: 'lib/services/runtime/nova_post_turn_reflection_service.dart',
      sourceLine: 8,
      category: 'runtime',
      sourceSignal: 'class NovaPostTurnReflectionService {',
      priority: 21,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 43,
      id: 'L043_nova_speaker_graph_engine_service',
      sourceFile: 'lib/services/runtime/nova_speaker_graph_engine_service.dart',
      sourceLine: 8,
      category: 'runtime',
      sourceSignal: 'enum NovaSpeakerGraphBand {',
      priority: 21,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 44,
      id: 'L044_nova_identity_rollout_service',
      sourceFile: 'lib/services/runtime/nova_identity_rollout_service.dart',
      sourceLine: 15,
      category: 'identity',
      sourceSignal: 'class NovaIdentityRolloutService {',
      priority: 21,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 45,
      id: 'L045_nova_teachable_behavior_runtime_service',
      sourceFile:
          'lib/services/runtime/nova_teachable_behavior_runtime_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'class NovaBehaviorTeachingSnapshot {',
      priority: 21,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 46,
      id: 'L046_nova_turkish_voice_quality_metrics_service',
      sourceFile:
          'lib/services/runtime/nova_turkish_voice_quality_metrics_service.dart',
      sourceLine: 3,
      category: 'speech',
      sourceSignal: 'class NovaTurkishVoiceQualityMetrics {',
      priority: 21,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 47,
      id: 'L047_nova_shared_world_model_service',
      sourceFile: 'lib/services/runtime/nova_shared_world_model_service.dart',
      sourceLine: 10,
      category: 'runtime',
      sourceSignal: 'class NovaSharedWorldModelService {',
      priority: 20,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 48,
      id: 'L048_nova_micro_reaction_engine_service',
      sourceFile:
          'lib/services/runtime/nova_micro_reaction_engine_service.dart',
      sourceLine: 6,
      category: 'runtime',
      sourceSignal: 'class NovaMicroReactionFrame {',
      priority: 20,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 49,
      id: 'L049_nova_style_adapter_service',
      sourceFile: 'lib/services/runtime/nova_style_adapter_service.dart',
      sourceLine: 8,
      category: 'runtime',
      sourceSignal: 'class NovaStyleAdapterService {',
      priority: 20,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 50,
      id: 'L050_nova_shared_life_context_service',
      sourceFile: 'lib/services/runtime/nova_shared_life_context_service.dart',
      sourceLine: 4,
      category: 'runtime',
      sourceSignal:
          'class NovaSharedLifeContextDigest { final String continuityBand; final String dailyRhythm; final String unfinishedPressure; final double coherenceScore; final List<String> cues; ',
      priority: 19,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 51,
      id: 'L051_nova_social_world_inference_service',
      sourceFile:
          'lib/services/runtime/nova_social_world_inference_service.dart',
      sourceLine: 3,
      category: 'relationship',
      sourceSignal: 'class NovaSocialWorldInference {',
      priority: 19,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 52,
      id: 'L052_nova_twelve_shields_service',
      sourceFile: 'lib/services/runtime/nova_twelve_shields_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'class NovaShieldSignal {',
      priority: 18,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 53,
      id: 'L053_lib_ui_onboarding_nova_first_run_setup_page',
      sourceFile: 'lib/ui/onboarding/nova_first_run_setup_page.dart',
      sourceLine: 58,
      category: 'setup',
      sourceSignal: 'class NovaFirstRunSetupPage extends StatefulWidget {',
      priority: 68,
      modes: <String>['conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 54,
      id: 'L054_lib_ui_dashboard_dashboard_page',
      sourceFile: 'lib/ui/dashboard/dashboard_page.dart',
      sourceLine: 129,
      category: 'core',
      sourceSignal: 'final NovaPersona persona;',
      priority: 68,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>['liveGeneratedResponse', 'noStaticShell'],
    ),
    NovaIdentityKernelLayer(
      index: 55,
      id: 'L055_nova_identity_memory_commit_service',
      sourceFile:
          'lib/services/runtime/nova_identity_memory_commit_service.dart',
      sourceLine: 3,
      category: 'memory',
      sourceSignal: 'class NovaIdentityMemoryCommitService {',
      priority: 18,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 56,
      id: 'L056_self_repair_nova_capability_manifest_service',
      sourceFile:
          'lib/services/self_repair/nova_capability_manifest_service.dart',
      sourceLine: 6,
      category: 'identity',
      sourceSignal: 'class NovaCapabilityManifestService {',
      priority: 38,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 57,
      id: 'L057_relationship_retrieval_service',
      sourceFile: 'lib/services/runtime/relationship_retrieval_service.dart',
      sourceLine: 7,
      category: 'relationship',
      sourceSignal: 'class RelationshipRetrievalService {',
      priority: 18,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 58,
      id: 'L058_nova_emotional_momentum_service',
      sourceFile: 'lib/services/runtime/nova_emotional_momentum_service.dart',
      sourceLine: 7,
      category: 'emotion',
      sourceSignal: 'class NovaEmotionalMomentumService {',
      priority: 17,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 59,
      id: 'L059_nova_meta_self_loop_service',
      sourceFile: 'lib/services/runtime/nova_meta_self_loop_service.dart',
      sourceLine: 3,
      category: 'identity',
      sourceSignal: 'enum NovaMetaLoopIntensity { low, medium, high }',
      priority: 17,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 60,
      id: 'L060_relationship_profile_store',
      sourceFile: 'lib/services/runtime/relationship_profile_store.dart',
      sourceLine: 10,
      category: 'relationship',
      sourceSignal: 'class RelationshipProfileStore {',
      priority: 17,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 61,
      id: 'L061_nova_thinking_layer_service',
      sourceFile: 'lib/services/runtime/nova_thinking_layer_service.dart',
      sourceLine: 5,
      category: 'runtime',
      sourceSignal: 'class NovaThinkingLayerService {',
      priority: 16,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 62,
      id: 'L062_nova_identity_engine_service',
      sourceFile: 'lib/services/runtime/nova_identity_engine_service.dart',
      sourceLine: 8,
      category: 'identity',
      sourceSignal: 'class NovaIdentityEngineService {',
      priority: 16,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 63,
      id: 'L063_nova_relationship_story_service',
      sourceFile: 'lib/services/runtime/nova_relationship_story_service.dart',
      sourceLine: 7,
      category: 'relationship',
      sourceSignal: 'class NovaRelationshipStoryService {',
      priority: 16,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 64,
      id: 'L064_nova_autobiographic_identity_bridge_service',
      sourceFile:
          'lib/services/runtime/nova_autobiographic_identity_bridge_service.dart',
      sourceLine: 5,
      category: 'identity',
      sourceSignal: 'class NovaAutobiographicIdentityBridgeService {',
      priority: 16,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 65,
      id: 'L065_nova_identity_runtime_service',
      sourceFile: 'lib/services/runtime/nova_identity_runtime_service.dart',
      sourceLine: 10,
      category: 'identity',
      sourceSignal: 'class NovaIdentityRuntimeService {',
      priority: 16,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 66,
      id: 'L066_nova_safe_autonomy_limiter_service',
      sourceFile:
          'lib/services/runtime/nova_safe_autonomy_limiter_service.dart',
      sourceLine: 5,
      category: 'safety',
      sourceSignal: 'class NovaSafeAutonomyDecision {',
      priority: 16,
      modes: <String>['call', 'conversation', 'selfRepair', 'setup'],
      behaviorFlags: <String>[
        'externalSafetyBoundary',
        'liveGeneratedResponse',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 67,
      id: 'L067_nova_translator_mode_service',
      sourceFile: 'lib/services/runtime/nova_translator_mode_service.dart',
      sourceLine: 9,
      category: 'runtime',
      sourceSignal: 'class NovaTranslatorModeState {',
      priority: 16,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 68,
      id: 'L068_memory_commit_gate',
      sourceFile: 'lib/services/runtime/memory_commit_gate.dart',
      sourceLine: 7,
      category: 'memory',
      sourceSignal: 'class MemoryCommitGate {',
      priority: 16,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 69,
      id: 'L069_nova_owner_action_broker_service',
      sourceFile: 'lib/services/runtime/nova_owner_action_broker_service.dart',
      sourceLine: 7,
      category: 'relationship',
      sourceSignal: 'class NovaOwnerActionBrokerResult {',
      priority: 15,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 70,
      id: 'L070_nova_turkish_pragmatics_engine_service',
      sourceFile:
          'lib/services/runtime/nova_turkish_pragmatics_engine_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'class NovaTurkishPragmaticsDecision {',
      priority: 14,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 71,
      id: 'L071_nova_conversation_continuity_service',
      sourceFile:
          'lib/services/runtime/nova_conversation_continuity_service.dart',
      sourceLine: 7,
      category: 'memory',
      sourceSignal: 'class NovaConversationContinuityService {',
      priority: 14,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 72,
      id: 'L072_nova_social_energy_service',
      sourceFile: 'lib/services/runtime/nova_social_energy_service.dart',
      sourceLine: 7,
      category: 'relationship',
      sourceSignal: 'class NovaSocialEnergyService {',
      priority: 14,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 73,
      id: 'L073_nova_call_acoustic_emotion_layer_service',
      sourceFile:
          'lib/services/runtime/nova_call_acoustic_emotion_layer_service.dart',
      sourceLine: 4,
      category: 'call',
      sourceSignal: 'class NovaCallAcousticEmotionLayerService {',
      priority: 14,
      modes: <String>['call', 'companion', 'conversation'],
      behaviorFlags: <String>['liveGeneratedResponse', 'noStaticShell'],
    ),
    NovaIdentityKernelLayer(
      index: 74,
      id: 'L074_nova_capability_audit_service',
      sourceFile: 'lib/services/runtime/nova_capability_audit_service.dart',
      sourceLine: 6,
      category: 'runtime',
      sourceSignal: 'class NovaCapabilityAuditService {',
      priority: 14,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 75,
      id: 'L075_nova_initiative_scoring_service',
      sourceFile: 'lib/services/runtime/nova_initiative_scoring_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'class NovaInitiativeScoreCard {',
      priority: 14,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 76,
      id: 'L076_nova_conversation_act_detector_service',
      sourceFile:
          'lib/services/runtime/nova_conversation_act_detector_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'class NovaConversationActDecision {',
      priority: 13,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 77,
      id: 'L077_nova_emotional_invariance_service',
      sourceFile: 'lib/services/runtime/nova_emotional_invariance_service.dart',
      sourceLine: 3,
      category: 'emotion',
      sourceSignal: 'class NovaEmotionalInvarianceService {',
      priority: 13,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 78,
      id: 'L078_nova_relationship_dramaturgy_service',
      sourceFile:
          'lib/services/runtime/nova_relationship_dramaturgy_service.dart',
      sourceLine: 6,
      category: 'relationship',
      sourceSignal: 'class NovaRelationshipDramaturgyService {',
      priority: 13,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 79,
      id: 'L079_nova_relationship_constitution_service',
      sourceFile:
          'lib/services/runtime/nova_relationship_constitution_service.dart',
      sourceLine: 5,
      category: 'relationship',
      sourceSignal: 'class NovaRelationshipConstitutionService {',
      priority: 13,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 80,
      id: 'L080_nova_speech_native_planner_v2_service',
      sourceFile:
          'lib/services/runtime/nova_speech_native_planner_v2_service.dart',
      sourceLine: 5,
      category: 'speech',
      sourceSignal: 'class NovaSpeechNativePlannerV2Decision {',
      priority: 13,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 81,
      id: 'L081_call_companion_nova_call_companion_runtime_service',
      sourceFile:
          'lib/services/call_companion/nova_call_companion_runtime_service.dart',
      sourceLine: 28,
      category: 'call',
      sourceSignal: 'class NovaCallCompanionRuntimeService {',
      priority: 33,
      modes: <String>['call', 'companion', 'conversation'],
      behaviorFlags: <String>['liveGeneratedResponse', 'noStaticShell'],
    ),
    NovaIdentityKernelLayer(
      index: 82,
      id: 'L082_local_model_local_model_service',
      sourceFile: 'lib/services/local_model/local_model_service.dart',
      sourceLine: 82,
      category: 'core',
      sourceSignal:
          'bool get hasRealPercent => percent != null && percent! >= 0 && percent! <= 100;',
      priority: 33,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>['liveGeneratedResponse', 'noStaticShell'],
    ),
    NovaIdentityKernelLayer(
      index: 83,
      id: 'L083_nova_contextual_asr_bias_service',
      sourceFile: 'lib/services/runtime/nova_contextual_asr_bias_service.dart',
      sourceLine: 3,
      category: 'speech',
      sourceSignal: 'class NovaContextualAsrBiasService {',
      priority: 13,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 84,
      id: 'L084_nova_anticipatory_companionship_service',
      sourceFile:
          'lib/services/runtime/nova_anticipatory_companionship_service.dart',
      sourceLine: 6,
      category: 'call',
      sourceSignal: 'class NovaAnticipatoryCompanionshipService {',
      priority: 13,
      modes: <String>['call', 'companion', 'conversation'],
      behaviorFlags: <String>['liveGeneratedResponse', 'noStaticShell'],
    ),
    NovaIdentityKernelLayer(
      index: 85,
      id: 'L085_nova_dream_consolidation_service',
      sourceFile: 'lib/services/runtime/nova_dream_consolidation_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'class NovaDreamConsolidationPlan {',
      priority: 13,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 86,
      id: 'L086_nova_dynamic_persona_service',
      sourceFile: 'lib/services/runtime/nova_dynamic_persona_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'class NovaDynamicPersonaService {',
      priority: 13,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 87,
      id: 'L087_nova_safe_growth_governor_service',
      sourceFile: 'lib/services/runtime/nova_safe_growth_governor_service.dart',
      sourceLine: 3,
      category: 'safety',
      sourceSignal: 'enum NovaGrowthIntent {',
      priority: 13,
      modes: <String>['call', 'conversation', 'selfRepair', 'setup'],
      behaviorFlags: <String>[
        'externalSafetyBoundary',
        'liveGeneratedResponse',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 88,
      id: 'L088_nova_turkish_discourse_marker_parser_service',
      sourceFile:
          'lib/services/runtime/nova_turkish_discourse_marker_parser_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'class NovaTurkishDiscourseMarkerDecision {',
      priority: 13,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 89,
      id: 'L089_nova_turkish_emphasis_resolver_service',
      sourceFile:
          'lib/services/runtime/nova_turkish_emphasis_resolver_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'class NovaTurkishEmphasisResolution {',
      priority: 13,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 90,
      id: 'L090_nova_turkish_indirect_request_detector_service',
      sourceFile:
          'lib/services/runtime/nova_turkish_indirect_request_detector_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'class NovaTurkishIndirectRequestDecision {',
      priority: 13,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 91,
      id: 'L091_nova_silence_intelligence_service',
      sourceFile: 'lib/services/runtime/nova_silence_intelligence_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'enum NovaSilenceKind {',
      priority: 13,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 92,
      id: 'L092_nova_spoken_intent_interpreter_service',
      sourceFile:
          'lib/services/runtime/nova_spoken_intent_interpreter_service.dart',
      sourceLine: 7,
      category: 'runtime',
      sourceSignal: 'class NovaSpokenIntentInterpreterService {',
      priority: 13,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 93,
      id: 'L093_micro_turn_orchestrator_service',
      sourceFile: 'lib/services/runtime/micro_turn_orchestrator_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'class NovaMicroTurnDecision {',
      priority: 13,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 94,
      id: 'L094_nova_human_imperfection_service',
      sourceFile: 'lib/services/runtime/nova_human_imperfection_service.dart',
      sourceLine: 6,
      category: 'runtime',
      sourceSignal: 'class NovaHumanImperfectionService {',
      priority: 12,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 95,
      id: 'L095_nova_speech_native_planner_service',
      sourceFile:
          'lib/services/runtime/nova_speech_native_planner_service.dart',
      sourceLine: 3,
      category: 'speech',
      sourceSignal: 'class NovaSpeechNativePlannerDecision {',
      priority: 12,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 96,
      id: 'L096_nova_turkish_semantic_lexicon_service',
      sourceFile:
          'lib/services/runtime/nova_turkish_semantic_lexicon_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'class NovaTurkishSemanticLexiconService {',
      priority: 12,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 97,
      id: 'L097_tts_nova_tts_service',
      sourceFile: 'lib/services/tts/nova_tts_service.dart',
      sourceLine: 20,
      category: 'speech',
      sourceSignal: 'enum NovaTtsMode {',
      priority: 32,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 98,
      id: 'L098_nova_affective_state_service',
      sourceFile: 'lib/services/runtime/nova_affective_state_service.dart',
      sourceLine: 8,
      category: 'emotion',
      sourceSignal: 'class NovaAffectiveStateService {',
      priority: 12,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 99,
      id: 'L099_nova_continuity_capsule_service',
      sourceFile: 'lib/services/runtime/nova_continuity_capsule_service.dart',
      sourceLine: 5,
      category: 'memory',
      sourceSignal: 'class NovaContinuityCapsuleService {',
      priority: 12,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 100,
      id: 'L100_nova_language_pack_service',
      sourceFile: 'lib/services/runtime/nova_language_pack_service.dart',
      sourceLine: 7,
      category: 'runtime',
      sourceSignal: 'class NovaLanguagePack {',
      priority: 12,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 101,
      id: 'L101_speech_tts_service',
      sourceFile: 'lib/services/speech/tts_service.dart',
      sourceLine: 13,
      category: 'speech',
      sourceSignal: 'class TtsService {',
      priority: 32,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 102,
      id: 'L102_nova_speech_punctuation_rewriter_service',
      sourceFile:
          'lib/services/runtime/nova_speech_punctuation_rewriter_service.dart',
      sourceLine: 3,
      category: 'speech',
      sourceSignal: 'class NovaSpeechPunctuationRewriterService {',
      priority: 12,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 103,
      id: 'L103_nova_conversation_ritual_memory_service',
      sourceFile:
          'lib/services/runtime/nova_conversation_ritual_memory_service.dart',
      sourceLine: 3,
      category: 'memory',
      sourceSignal: 'class NovaConversationRitualMemoryService {',
      priority: 11,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 104,
      id: 'L104_nova_runtime_intent_router_service',
      sourceFile:
          'lib/services/runtime/nova_runtime_intent_router_service.dart',
      sourceLine: 5,
      category: 'runtime',
      sourceSignal: 'class NovaRuntimeIntentRouterService {',
      priority: 11,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 105,
      id: 'L105_task_experience_store',
      sourceFile: 'lib/services/runtime/task_experience_store.dart',
      sourceLine: 11,
      category: 'runtime',
      sourceSignal: 'class NovaTaskExperienceAnalytics {',
      priority: 11,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 106,
      id: 'L106_nova_guided_resolution_state_service',
      sourceFile:
          'lib/services/runtime/nova_guided_resolution_state_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'enum NovaGuidedResolutionAction {',
      priority: 11,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 107,
      id: 'L107_nova_internal_state_service',
      sourceFile: 'lib/services/runtime/nova_internal_state_service.dart',
      sourceLine: 10,
      category: 'runtime',
      sourceSignal: 'class NovaInternalStateService {',
      priority: 11,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 108,
      id: 'L108_nova_memory_compaction_service',
      sourceFile: 'lib/services/runtime/nova_memory_compaction_service.dart',
      sourceLine: 3,
      category: 'memory',
      sourceSignal: 'class NovaMemoryCompactionService {',
      priority: 11,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 109,
      id: 'L109_nova_semantic_turn_detector_service',
      sourceFile:
          'lib/services/runtime/nova_semantic_turn_detector_service.dart',
      sourceLine: 5,
      category: 'runtime',
      sourceSignal: 'class NovaSemanticTurnDecision {',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 110,
      id: 'L110_nova_proactive_restraint_service',
      sourceFile: 'lib/services/runtime/nova_proactive_restraint_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'enum NovaInitiativeMode { wait, limited, supportive }',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 111,
      id: 'L111_nova_anti_rumination_guard_service',
      sourceFile:
          'lib/services/runtime/nova_anti_rumination_guard_service.dart',
      sourceLine: 3,
      category: 'safety',
      sourceSignal: 'class NovaAntiRuminationAssessment {',
      priority: 10,
      modes: <String>['call', 'conversation', 'selfRepair', 'setup'],
      behaviorFlags: <String>[
        'externalSafetyBoundary',
        'liveGeneratedResponse',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 112,
      id: 'L112_nova_trust_calibration_service',
      sourceFile: 'lib/services/runtime/nova_trust_calibration_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'class NovaTrustCalibrationService {',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 113,
      id: 'L113_nova_affect_governor_service',
      sourceFile: 'lib/services/runtime/nova_affect_governor_service.dart',
      sourceLine: 5,
      category: 'emotion',
      sourceSignal: 'class NovaAffectGovernorService {',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 114,
      id: 'L114_nova_guided_procedure_resolution_service',
      sourceFile:
          'lib/services/runtime/nova_guided_procedure_resolution_service.dart',
      sourceLine: 4,
      category: 'runtime',
      sourceSignal: 'enum NovaProcedureRestartScope {',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 115,
      id: 'L115_runtime_efficiency_analyzer',
      sourceFile: 'lib/services/runtime/runtime_efficiency_analyzer.dart',
      sourceLine: 7,
      category: 'runtime',
      sourceSignal: 'required String prompt,',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 116,
      id: 'L116_nova_user_model_service',
      sourceFile: 'lib/services/runtime/nova_user_model_service.dart',
      sourceLine: 7,
      category: 'runtime',
      sourceSignal: 'class NovaUserModelService {',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 117,
      id: 'L117_speech_runtime_nova_speech_runtime_service',
      sourceFile:
          'lib/services/speech_runtime/nova_speech_runtime_service.dart',
      sourceLine: 15,
      category: 'speech',
      sourceSignal: 'class NovaSpeechRuntimeService {',
      priority: 29,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 118,
      id: 'L118_nova_presence_engine_service',
      sourceFile: 'lib/services/runtime/nova_presence_engine_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'class NovaPresenceEngineService {',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 119,
      id: 'L119_nova_response_history_service',
      sourceFile: 'lib/services/runtime/nova_response_history_service.dart',
      sourceLine: 7,
      category: 'memory',
      sourceSignal: 'class NovaResponseHistoryItem {',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 120,
      id: 'L120_nova_spoken_quality_eval_tr_service',
      sourceFile:
          'lib/services/runtime/nova_spoken_quality_eval_tr_service.dart',
      sourceLine: 3,
      category: 'runtime',
      sourceSignal: 'class NovaSpokenQualityEvalTrDecision {',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 121,
      id: 'L121_nova_voice_metrics_collector_service',
      sourceFile:
          'lib/services/runtime/nova_voice_metrics_collector_service.dart',
      sourceLine: 3,
      category: 'speech',
      sourceSignal: 'class NovaVoiceMetricsCollectorService {',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 122,
      id: 'L122_strategy_promotion_service',
      sourceFile: 'lib/services/runtime/strategy_promotion_service.dart',
      sourceLine: 10,
      category: 'runtime',
      sourceSignal: 'static const List<String> _successNotes = <String>[',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 123,
      id: 'L123_nova_inner_stability_engine_service',
      sourceFile:
          'lib/services/runtime/nova_inner_stability_engine_service.dart',
      sourceLine: 5,
      category: 'runtime',
      sourceSignal: 'class NovaInnerStabilityEngineService {',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 124,
      id: 'L124_nova_thinking_mode_classifier_service',
      sourceFile:
          'lib/services/runtime/nova_thinking_mode_classifier_service.dart',
      sourceLine: 7,
      category: 'runtime',
      sourceSignal: 'class NovaThinkingModeClassifierService {',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'aiOwnedSetup',
        'liveGeneratedResponse',
        'noStaticShell',
        'serializedRuntime',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 125,
      id: 'L125_call_companion_nova_call_companion_service',
      sourceFile:
          'lib/services/call_companion/nova_call_companion_service.dart',
      sourceLine: 22,
      category: 'call',
      sourceSignal: 'class NovaCallCompanionService {',
      priority: 28,
      modes: <String>['call', 'companion', 'conversation'],
      behaviorFlags: <String>['liveGeneratedResponse', 'noStaticShell'],
    ),
    NovaIdentityKernelLayer(
      index: 126,
      id: 'L126_native_mainactivity',
      sourceFile:
          'android/app/src/main/kotlin/com/example/nova/MainActivity.kt',
      sourceLine: 1,
      category: 'core',
      sourceSignal: 'package com.example.nova',
      priority: 18,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>['liveGeneratedResponse', 'noStaticShell'],
    ),
    NovaIdentityKernelLayer(
      index: 127,
      id: 'L127_native_novaandroidttsmouthengine',
      sourceFile:
          'android/app/src/main/kotlin/com/example/nova/NovaAndroidTtsMouthEngine.kt',
      sourceLine: 1,
      category: 'speech',
      sourceSignal: 'package com.example.nova',
      priority: 15,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 128,
      id: 'L128_native_asr_novastreamingasrengine',
      sourceFile:
          'android/app/src/main/kotlin/com/example/nova/asr/NovaStreamingAsrEngine.kt',
      sourceLine: 1,
      category: 'speech',
      sourceSignal: 'package com.example.nova.asr',
      priority: 12,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 129,
      id: 'L129_native_asr_novastreamingasrbridgeplugin',
      sourceFile:
          'android/app/src/main/kotlin/com/example/nova/asr/NovaStreamingAsrBridgePlugin.kt',
      sourceLine: 1,
      category: 'speech',
      sourceSignal: 'package com.example.nova.asr',
      priority: 12,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 130,
      id: 'L130_native_asr_novaasrmodellocator',
      sourceFile:
          'android/app/src/main/kotlin/com/example/nova/asr/NovaAsrModelLocator.kt',
      sourceLine: 1,
      category: 'speech',
      sourceSignal: 'package com.example.nova.asr',
      priority: 11,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 131,
      id: 'L131_native_novavoiceidentitybridgeplugin',
      sourceFile:
          'android/app/src/main/kotlin/com/example/nova/NovaVoiceIdentityBridgePlugin.kt',
      sourceLine: 1,
      category: 'speech',
      sourceSignal: 'package com.example.nova',
      priority: 11,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 132,
      id: 'L132_native_owneronly_novaownerblindpatchbridgeplugin',
      sourceFile:
          'android/app/src/main/kotlin/com/example/nova/owneronly/NovaOwnerBlindPatchBridgePlugin.kt',
      sourceLine: 1,
      category: 'relationship',
      sourceSignal: 'package com.example.nova.owneronly',
      priority: 11,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
        'selectiveMemory',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 133,
      id: 'L133_native_asr_novastreamingasrconfig',
      sourceFile:
          'android/app/src/main/kotlin/com/example/nova/asr/NovaStreamingAsrConfig.kt',
      sourceLine: 1,
      category: 'speech',
      sourceSignal: 'package com.example.nova.asr',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 134,
      id: 'L134_native_novaxttsbridgeplugin',
      sourceFile:
          'android/app/src/main/kotlin/com/example/nova/NovaXttsBridgePlugin.kt',
      sourceLine: 1,
      category: 'speech',
      sourceSignal: 'package com.example.nova',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 135,
      id: 'L135_native_novacloneengineadapter',
      sourceFile:
          'android/app/src/main/kotlin/com/example/nova/NovaCloneEngineAdapter.kt',
      sourceLine: 1,
      category: 'core',
      sourceSignal: 'package com.example.nova',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>['liveGeneratedResponse', 'noStaticShell'],
    ),
    NovaIdentityKernelLayer(
      index: 136,
      id: 'L136_native_novaxttsengine',
      sourceFile:
          'android/app/src/main/kotlin/com/example/nova/NovaXttsEngine.kt',
      sourceLine: 1,
      category: 'speech',
      sourceSignal: 'package com.example.nova',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 137,
      id: 'L137_native_novareminderscheduler',
      sourceFile:
          'android/app/src/main/kotlin/com/example/nova/NovaReminderScheduler.kt',
      sourceLine: 1,
      category: 'identity',
      sourceSignal: 'package com.example.nova',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 138,
      id: 'L138_native_novanativeaudiobridgeplugin',
      sourceFile:
          'android/app/src/main/kotlin/com/example/nova/NovaNativeAudioBridgePlugin.kt',
      sourceLine: 1,
      category: 'core',
      sourceSignal: 'package com.example.nova',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>['liveGeneratedResponse', 'noStaticShell'],
    ),
    NovaIdentityKernelLayer(
      index: 139,
      id: 'L139_native_novaandroidttsmouthbridgeplugin',
      sourceFile:
          'android/app/src/main/kotlin/com/example/nova/NovaAndroidTtsMouthBridgePlugin.kt',
      sourceLine: 1,
      category: 'speech',
      sourceSignal: 'package com.example.nova',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 140,
      id: 'L140_native_novareminderreceiver',
      sourceFile:
          'android/app/src/main/kotlin/com/example/nova/NovaReminderReceiver.kt',
      sourceLine: 1,
      category: 'identity',
      sourceSignal: 'package com.example.nova',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'noStaticShell',
        'ownerBound',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 141,
      id: 'L141_native_novaspeakerrecognitionengine',
      sourceFile:
          'android/app/src/main/kotlin/com/example/nova/NovaSpeakerRecognitionEngine.kt',
      sourceLine: 1,
      category: 'core',
      sourceSignal: 'package com.example.nova',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>['liveGeneratedResponse', 'noStaticShell'],
    ),
    NovaIdentityKernelLayer(
      index: 142,
      id: 'L142_native_novasystemboundaryguard',
      sourceFile:
          'android/app/src/main/kotlin/com/example/nova/NovaSystemBoundaryGuard.kt',
      sourceLine: 1,
      category: 'safety',
      sourceSignal: 'package com.example.nova',
      priority: 10,
      modes: <String>['call', 'conversation', 'selfRepair', 'setup'],
      behaviorFlags: <String>[
        'externalSafetyBoundary',
        'liveGeneratedResponse',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 143,
      id: 'L143_native_novastreamingasrengine',
      sourceFile:
          'android/app/src/main/kotlin/com/example/nova/NovaStreamingAsrEngine.kt',
      sourceLine: 1,
      category: 'speech',
      sourceSignal: 'package com.example.nova',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
    NovaIdentityKernelLayer(
      index: 144,
      id: 'L144_native_novacalluiactivity',
      sourceFile:
          'android/app/src/main/kotlin/com/example/nova/NovaCallUiActivity.kt',
      sourceLine: 1,
      category: 'call',
      sourceSignal: 'package com.example.nova',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation'],
      behaviorFlags: <String>['liveGeneratedResponse', 'noStaticShell'],
    ),
    NovaIdentityKernelLayer(
      index: 145,
      id: 'L145_native_novaspeechrecognizerhelper',
      sourceFile:
          'android/app/src/main/kotlin/com/example/nova/NovaSpeechRecognizerHelper.kt',
      sourceLine: 1,
      category: 'speech',
      sourceSignal: 'package com.example.nova',
      priority: 10,
      modes: <String>['call', 'companion', 'conversation', 'setup'],
      behaviorFlags: <String>[
        'liveGeneratedResponse',
        'naturalTurkishSpeech',
        'noStaticShell',
      ],
    ),
  ];
}
