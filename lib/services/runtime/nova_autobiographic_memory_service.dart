// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/runtime/nova_autobiographic_memory.dart';
import '../../core/runtime/nova_post_turn_reflection.dart';
import '../../core/runtime/nova_relationship_profile.dart';
import 'nova_memory_compaction_service.dart';

class NovaAutobiographicMemoryService {
  static const NovaMemoryCompactionService _compaction =
      NovaMemoryCompactionService();
  static const String _storageKey = 'nova_autobiographic_memory_v2';

  const NovaAutobiographicMemoryService();

  Future<NovaAutobiographicMemory> get(String speakerKey) async {
    final all = await _getAll();
    return _compact(
      all[speakerKey.trim()] ??
          NovaAutobiographicMemory.empty(speakerKey.trim()),
    );
  }

  Future<void> update({
    required String speakerKey,
    required NovaRelationshipProfile profile,
    required String prompt,
    required String reply,
    required NovaPostTurnReflection reflection,
  }) async {
    if (speakerKey.trim().isEmpty) return;
    final current = await get(speakerKey);
    final normalizedPrompt = _normalize(prompt);
    final normalizedReply = _normalize(reply);
    final updated = current.copyWith(
      relationshipStage: profile.relationshipStage,
      turningPoints: _merge(
        current.turningPoints,
        _turningPoints(normalizedPrompt, normalizedReply, reflection, profile),
      ),
      repairedMisunderstandings: _merge(
        current.repairedMisunderstandings,
        reflection.repairNeed >= 0.52
            ? _repairMoments(normalizedPrompt, normalizedReply, reflection)
            : const <String>[],
      ),
      unresolvedThreads: _merge(
        current.unresolvedThreads,
        _openLoops(normalizedPrompt, normalizedReply, reflection),
      ),
      sharedHabits: _merge(
        current.sharedHabits,
        _habitMoments(profile, normalizedPrompt, normalizedReply),
      ),
      trustMoments: _merge(
        current.trustMoments,
        _trustMoments(reflection, profile, normalizedPrompt, normalizedReply),
      ),
      storyPhase: _storyPhase(
        profile,
        reflection,
        normalizedPrompt,
        normalizedReply,
      ),
      continuitySummary: _summary(
        profile,
        current,
        normalizedPrompt,
        normalizedReply,
        reflection,
      ),
      updatedAt: DateTime.now(),
    );
    final all = await _getAll();
    all[speakerKey.trim()] = _compact(updated);
    await _saveAll(all);
  }

  List<String> _turningPoints(
    String prompt,
    String reply,
    NovaPostTurnReflection reflection,
    NovaRelationshipProfile profile,
  ) {
    final results = <String>[];
    if (profile.totalInteractions <= 2) {
      results.add('Erken evre konuşmaları nazik ve dikkatli çizgide ilerledi.');
    }
    if (reflection.memoryValue >= 0.72) {
      results.add('Önceki bağlam kullanılarak süreklilik hissi güçlendi.');
    }
    if (reply.contains('kısa özet') || reply.contains('özetle')) {
      results.add('Cevap biçimi kısa özet eğilimi gösterdi.');
    }
    if (_containsAny(prompt, const <String>[
      'yanlış',
      'öyle değil',
      'demek istediğim',
    ])) {
      results.add('Onarım gerektiren anlar sakin çizgide yönetildi.');
    }
    if (_containsAny(prompt, const <String>[
      'teşekkür',
      'sağ ol',
      'iyi oldu',
    ])) {
      results.add('Olumlu geri bildirim ilişki sıcaklığını artırdı.');
    }
    if (_containsAny(prompt, const <String>['nova', 'nova']) &&
        profile.totalInteractions >= 4) {
      results.add('Kimlik ve hitap çizgisi daha yerleşik hale geldi.');
    }
    return results;
  }

  List<String> _repairMoments(
    String prompt,
    String reply,
    NovaPostTurnReflection reflection,
  ) {
    final out = <String>[];
    out.add(_short('Yanlış anlama sakin biçimde toparlandı: $prompt'));
    if (reflection.shouldReduceQuestionsNextTurn) {
      out.add('Onarım sonrası takip sorusu azaltma ihtiyacı kaydedildi.');
    }
    if (_containsAny(reply, const <String>[
      'yanlış anladıysam',
      'daha net anlatayım',
      'şunu mu demek istedin',
    ])) {
      out.add('Meta farkındalıklı onarım kalıbı işe yaradı.');
    }
    return out;
  }

  List<String> _openLoops(
    String prompt,
    String reply,
    NovaPostTurnReflection reflection,
  ) {
    final out = <String>[];
    if (reply.contains('?')) {
      out.add(_short('Açık takip sorusu kaldı: $reply'));
    }
    if (_containsAny(prompt, const <String>[
      'sonra',
      'daha sonra',
      'yarın',
      'haftaya',
    ])) {
      out.add(_short('Sonraya bırakılan başlık: $prompt'));
    }
    if (reflection.continuityValue >= 0.58 &&
        !_containsAny(reply, const <String>['tamamlandı', 'kapandı'])) {
      out.add('Süreklilik taşıyan ama tam kapanmayan akış var.');
    }
    return out;
  }

  List<String> _habitMoments(
    NovaRelationshipProfile profile,
    String prompt,
    String reply,
  ) {
    final out = <String>[...profile.ritualSeeds];
    if (_containsAny(prompt, const <String>['kısaca', 'özet', 'önce kısa'])) {
      out.add('önce kısa çerçeve sonra detay');
    }
    if (_containsAny(prompt, const <String>['sakin', 'nazik'])) {
      out.add('yumuşak açılış ve ölçülü hız');
    }
    if (_containsAny(reply, const <String>[
      'istersen açarım',
      'buradan devam',
    ])) {
      out.add('cevap sonunda kontrollü devam kapısı');
    }
    return out;
  }

  List<String> _trustMoments(
    NovaPostTurnReflection reflection,
    NovaRelationshipProfile profile,
    String prompt,
    String reply,
  ) {
    final out = <String>[];
    if (reflection.styleConsistency >= 0.70 && profile.trustLevel >= 0.62) {
      out.add('Ton tutarlılığı güveni biraz daha oturttu.');
    }
    if (_containsAny(prompt, const <String>[
      'güven',
      'rahat',
      'iyi hissettim',
    ])) {
      out.add(_short('Güven vurgusu konuşmada açıkça geçti: $prompt'));
    }
    if (_containsAny(reply, const <String>[
      'buradayım',
      'sakin bakalım',
      'adım adım',
    ])) {
      out.add('Destekleyici sabit kalıplar güven anı oluşturdu.');
    }
    return out;
  }

  String _storyPhase(
    NovaRelationshipProfile profile,
    NovaPostTurnReflection reflection,
    String prompt,
    String reply,
  ) {
    if (profile.relationshipStage == 'kırılma sonrası toparlama')
      return 'onarım ve güven sakinliği';
    if (profile.relationshipStage == 'rutinleşme') return 'oturmuş ortak dil';
    if (reflection.memoryValue >= 0.72) return 'süreklilik güçleniyor';
    if (_containsAny(prompt, const <String>['yeni', 'tanış', 'ilk']))
      return 'başlangıç yakınlığı';
    if (_containsAny(reply, const <String>['beraber', 'birlikte']))
      return 'eşlik derinleşiyor';
    return 'akış kuruluyor';
  }

  String _summary(
    NovaRelationshipProfile profile,
    NovaAutobiographicMemory current,
    String prompt,
    String reply,
    NovaPostTurnReflection reflection,
  ) {
    final parts = <String>[
      'Bu ilişki ${profile.relationshipStage} evresinde ilerliyor.',
      if (current.sharedHabits.isNotEmpty || profile.ritualSeeds.isNotEmpty)
        'Küçük ortak ritüeller ve tanıdık açılışlar süreklilik hissini destekliyor.',
      if (reflection.repairNeed >= 0.60)
        'Yanlış anlama anlarında savunma yerine sakin onarım tercih edilmeli.',
      if (_containsAny(prompt, const <String>['acele', 'hızlı']))
        'Acele anlarında kısa-net akış önemli.',
      if (_containsAny(reply, const <String>['istersen', 'gerekirse']))
        'Kontrollü devam kapıları sosyal baskı oluşturmadan kullanılabiliyor.',
    ];
    return parts.join(' ');
  }

  List<String> _merge(List<String> base, List<String> incoming) {
    final merged = <String>[
      ...incoming,
      ...base,
    ].map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
    return _unique(merged, limit: 10);
  }

  String _short(String text) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.length <= 140 ? cleaned : '${cleaned.substring(0, 137)}...';
  }

  Future<Map<String, NovaAutobiographicMemory>> _getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty)
        return <String, NovaAutobiographicMemory>{};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, NovaAutobiographicMemory>{};
      final out = <String, NovaAutobiographicMemory>{};
      decoded.forEach((key, value) {
        if (value is Map) {
          out[key.toString()] = NovaAutobiographicMemory.fromMap(
            Map<String, dynamic>.from(value),
          );
        }
      });
      return out;
    } catch (_) {
      return <String, NovaAutobiographicMemory>{};
    }
  }

  Future<void> _saveAll(Map<String, NovaAutobiographicMemory> all) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(all.map((key, value) => MapEntry(key, value.toMap()))),
    );
  }

  NovaAutobiographicMemory _compact(NovaAutobiographicMemory value) {
    return value.copyWith(
      turningPoints: _compaction.compactStrings(
        value.turningPoints,
        limit: 10,
        maxItemLength: 100,
      ),
      repairedMisunderstandings: _compaction.compactStrings(
        value.repairedMisunderstandings,
        limit: 8,
        maxItemLength: 100,
      ),
      unresolvedThreads: _compaction.compactStrings(
        value.unresolvedThreads,
        limit: 8,
        maxItemLength: 100,
      ),
      sharedHabits: _compaction.compactStrings(
        value.sharedHabits,
        limit: 8,
        maxItemLength: 84,
      ),
      trustMoments: _compaction.compactStrings(
        value.trustMoments,
        limit: 8,
        maxItemLength: 100,
      ),
      storyPhase: _compaction.compactSummary(value.storyPhase, maxLength: 100),
      continuitySummary: _compaction.compactSummary(
        value.continuitySummary,
        maxLength: 240,
      ),
    );
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _containsAny(String text, List<String> cues) {
    for (final cue in cues) {
      if (text.contains(cue)) return true;
    }
    return false;
  }

  List<String> _unique(List<String> values, {required int limit}) {
    final out = <String>[];
    final seen = <String>{};
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      final key = trimmed.toLowerCase();
      if (seen.add(key)) out.add(trimmed);
      if (out.length >= limit) break;
    }
    return out;
  }

  Map<String, dynamic> buildContinuityAudit(NovaAutobiographicMemory value) {
    return <String, dynamic>{
      'storyPhase': value.storyPhase,
      'turningPointCount': value.turningPoints.length,
      'repairedMisunderstandingCount': value.repairedMisunderstandings.length,
      'unresolvedThreadCount': value.unresolvedThreads.length,
      'sharedHabitCount': value.sharedHabits.length,
      'trustMomentCount': value.trustMoments.length,
      'continuitySummaryLength': value.continuitySummary.length,
    };
  }

  List<String> buildNarrativeAnchors(NovaAutobiographicMemory value) {
    final out = <String>[];
    if (value.turningPoints.isNotEmpty)
      out.add('dönüm_noktaları:' + value.turningPoints.first);
    if (value.sharedHabits.isNotEmpty)
      out.add('ortak_alışkanlık:' + value.sharedHabits.first);
    if (value.trustMoments.isNotEmpty)
      out.add('güven_anı:' + value.trustMoments.first);
    if (value.unresolvedThreads.isNotEmpty)
      out.add('açık_iz:' + value.unresolvedThreads.first);
    if (out.isEmpty) out.add('henüz_güçlü_otobiyografik_ankraj_yok');
    return out;
  }

  String classifyStoryTemperature(NovaAutobiographicMemory value) {
    final signal =
        value.trustMoments.length +
        value.sharedHabits.length -
        value.unresolvedThreads.length;
    if (signal >= 8) return 'warm_stable';
    if (signal >= 3) return 'balanced';
    if (signal >= 0) return 'careful';
    return 'repair_needed';
  }
}
