// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'nova_language_pack_service.dart';

class NovaTranslatorModeState {
  final bool enabled;
  final String sourceLanguageCode;
  final String targetLanguageCode;
  const NovaTranslatorModeState({
    required this.enabled,
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
  });
  const NovaTranslatorModeState.disabled()
    : enabled = false,
      sourceLanguageCode = 'tr',
      targetLanguageCode = 'en';
  NovaTranslatorModeState copyWith({
    bool? enabled,
    String? sourceLanguageCode,
    String? targetLanguageCode,
  }) => NovaTranslatorModeState(
    enabled: enabled ?? this.enabled,
    sourceLanguageCode: sourceLanguageCode ?? this.sourceLanguageCode,
    targetLanguageCode: targetLanguageCode ?? this.targetLanguageCode,
  );
  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'sourceLanguageCode': sourceLanguageCode,
    'targetLanguageCode': targetLanguageCode,
  };
  factory NovaTranslatorModeState.fromMap(
    Map<String, dynamic> map,
  ) => NovaTranslatorModeState(
    enabled: map['enabled'] as bool? ?? false,
    sourceLanguageCode: (map['sourceLanguageCode'] as String? ?? 'tr').trim(),
    targetLanguageCode: (map['targetLanguageCode'] as String? ?? 'en').trim(),
  );
}

class NovaTranslatorTurnPlan {
  final String mode;
  final String responseStyle;
  final bool shouldRepeatSource;
  final bool shouldExplainTone;
  final List<String> cues;
  const NovaTranslatorTurnPlan({
    required this.mode,
    required this.responseStyle,
    required this.shouldRepeatSource,
    required this.shouldExplainTone,
    required this.cues,
  });
  String buildPromptSection() => [
    'TERCÜMAN DÖNÜŞ PLANI:',
    '- mod: ' + mode,
    '- cevap stili: ' + responseStyle,
    '- kaynağı tekrar et: ' + shouldRepeatSource.toString(),
    '- tonu açıkla: ' + shouldExplainTone.toString(),
    if (cues.isNotEmpty) '- ipuçları: ' + cues.join(' | '),
    'KURAL: kim konuştuysa sırayı koru; tercümanda A ve B taraflarını karıştırma.',
  ].join('\n');
}

class NovaTranslatorModeService {
  static const String _storageKey = 'nova_translator_mode_state_v1';
  final NovaLanguagePackService languagePackService;
  const NovaTranslatorModeService({required this.languagePackService});

  static const List<String> _formalCues = <String>[
    'sayın',
    'rica ederim',
    'resmi',
    'kurumsal',
    'iş yazısı',
  ];
  static const List<String> _casualCues = <String>[
    'selam',
    'kanka',
    'abi',
    'günlük',
    'rahat',
  ];
  static const List<String> _interpreterCues = <String>[
    'o dedi ki',
    'şunu söyledi',
    'ona de ki',
    'çevir',
    'tercüme',
  ];
  static const List<String> _toneCues = <String>[
    'nazik',
    'sert',
    'samimi',
    'soğuk',
    'üzgün',
    'heyecanlı',
  ];

  Future<NovaTranslatorModeState> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty)
        return const NovaTranslatorModeState.disabled();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const NovaTranslatorModeState.disabled();
      return NovaTranslatorModeState.fromMap(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return const NovaTranslatorModeState.disabled();
    }
  }

  Future<void> save(NovaTranslatorModeState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toMap()));
  }

  Future<NovaTranslatorModeState> enable({
    required String source,
    required String target,
  }) async {
    await languagePackService.installByCode(source);
    await languagePackService.installByCode(target);
    final state = NovaTranslatorModeState(
      enabled: true,
      sourceLanguageCode: source,
      targetLanguageCode: target,
    );
    await save(state);
    return state;
  }

  Future<NovaTranslatorModeState> disable() async {
    const state = NovaTranslatorModeState.disabled();
    await save(state);
    return state;
  }

  Future<bool> hasRequiredPacks(NovaTranslatorModeState state) async {
    final installed = await languagePackService.loadInstalled();
    final set = installed.map((e) => e.code).toSet();
    return set.contains(state.sourceLanguageCode) &&
        set.contains(state.targetLanguageCode);
  }

  NovaTranslatorTurnPlan planTurn(
    String rawText, {
    String socialMode = 'voice',
  }) {
    final text = rawText.trim().toLowerCase();
    final cues = <String>[];
    final isFormal = _containsAny(text, _formalCues);
    final isCasual = _containsAny(text, _casualCues);
    final isInterpreter =
        _containsAny(text, _interpreterCues) ||
        socialMode.toLowerCase().contains('translator');
    final toneAware = _containsAny(text, _toneCues);
    if (isFormal) cues.add('resmi ton');
    if (isCasual) cues.add('günlük ton');
    if (isInterpreter) cues.add('konuşmacı sırası koru');
    if (toneAware) cues.add('tonu açıkla');
    return NovaTranslatorTurnPlan(
      mode: isInterpreter ? 'live_interpreter' : 'direct_translation',
      responseStyle: isFormal
          ? 'resmi ve berrak'
          : (isCasual ? 'günlük ve doğal' : 'nötr ve doğal'),
      shouldRepeatSource: isInterpreter,
      shouldExplainTone: toneAware,
      cues: cues,
    );
  }

  String buildPromptSection(String rawText, {String socialMode = 'voice'}) {
    return planTurn(rawText, socialMode: socialMode).buildPromptSection();
  }

  String normalizeForRelay(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    final collapsed = trimmed.replaceAll(RegExp(r'\s+'), ' ');
    return collapsed;
  }

  String describeLanguagePair(NovaTranslatorModeState state) {
    return '${state.sourceLanguageCode} -> ${state.targetLanguageCode}';
  }

  bool _containsAny(String text, List<String> cues) {
    for (final cue in cues) {
      if (cue.trim().isEmpty) continue;
      if (text.contains(cue.toLowerCase())) return true;
    }
    return false;
  }
}
