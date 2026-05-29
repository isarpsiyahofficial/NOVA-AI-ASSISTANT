// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/runtime/nova_shared_world_state.dart';
import 'nova_memory_compaction_service.dart';

class NovaSharedWorldModelService {
  static const NovaMemoryCompactionService _compaction =
      NovaMemoryCompactionService();
  static const String _storageKey = 'nova_shared_world_model_v2';

  const NovaSharedWorldModelService();

  Future<NovaSharedWorldState> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty)
        return NovaSharedWorldState.initial();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>)
        return NovaSharedWorldState.initial();
      return _compact(NovaSharedWorldState.fromMap(decoded));
    } catch (_) {
      return NovaSharedWorldState.initial();
    }
  }

  Future<NovaSharedWorldState> evolve({
    required String prompt,
    required String reply,
    required String contextMode,
    required String socialMode,
  }) async {
    final current = await load();
    final now = DateTime.now();
    final normalizedPrompt = _normalize(prompt);
    final normalizedReply = _normalize(reply);
    final promptTokens = _tokens(prompt);

    final phase = _dayPhase(now);
    final userMode = _userMode(normalizedPrompt, contextMode, socialMode);
    final ambientMode = _ambientMode(contextMode, normalizedPrompt, socialMode);
    final repeatedTopics = _merge(
      current.repeatedTopics,
      _topicHints(normalizedPrompt, promptTokens, normalizedReply),
    );
    final unfinishedItems = _merge(
      current.unfinishedItems,
      _unfinished(normalizedPrompt, normalizedReply),
    );
    final continuityThread = _continuityThread(
      prompt: normalizedPrompt,
      reply: normalizedReply,
      current: current,
      contextMode: contextMode,
      socialMode: socialMode,
      topics: repeatedTopics,
      unfinishedItems: unfinishedItems,
    );

    final next = current.copyWith(
      dayPhase: phase,
      userMode: userMode,
      ambientMode: ambientMode,
      repeatedTopics: repeatedTopics,
      unfinishedItems: unfinishedItems,
      continuityThread: continuityThread,
      updatedAt: now,
    );

    final compacted = _compact(next);
    await _save(compacted);
    return compacted;
  }

  Map<String, dynamic> buildWorldAudit(NovaSharedWorldState state) {
    return <String, dynamic>{
      'dayPhase': state.dayPhase,
      'userMode': state.userMode,
      'ambientMode': state.ambientMode,
      'repeatedTopicCount': state.repeatedTopics.length,
      'unfinishedCount': state.unfinishedItems.length,
      'continuityLength': state.continuityThread.length,
    };
  }

  String describeContinuityRisk(NovaSharedWorldState state) {
    if (state.unfinishedItems.length >= 4) return 'yüksek';
    if (state.repeatedTopics.length >= 4) return 'orta';
    return 'düşük';
  }

  List<String> buildCarryForwardHints(NovaSharedWorldState state) {
    final hints = <String>[];
    if (state.repeatedTopics.isNotEmpty) {
      hints.add('aynı gün içinde dönen temaları sıfırlama');
    }
    if (state.unfinishedItems.isNotEmpty) {
      hints.add('yarım kalan akışlardan en az birini hafifçe hatırla');
    }
    if (state.ambientMode == 'telefon_kanalı') {
      hints.add(
        'çağrı ile oda konuşması ayrı modlar olsa da aynı gün bağını koru',
      );
    }
    if (hints.isEmpty) hints.add('yeni bağlamı kopuk cevap gibi başlatma');
    return hints;
  }

  String _dayPhase(DateTime now) {
    final hour = now.hour;
    if (hour < 5) return 'gece_derin';
    if (hour < 8) return 'erken_sabah';
    if (hour < 12) return 'sabah';
    if (hour < 15) return 'öğlen';
    if (hour < 19) return 'gündüz';
    if (hour < 22) return 'akşam';
    return 'gece';
  }

  String _userMode(String prompt, String contextMode, String socialMode) {
    if (_containsAny(contextMode, const <String>['call', 'çağrı']))
      return 'çağrı';
    if (_containsAny(prompt, const <String>['acele', 'hızlı', 'kısa', 'çabuk']))
      return 'acele';
    if (_containsAny(prompt, const <String>[
      'üzgün',
      'gergin',
      'bunaldım',
      'kırgın',
      'yorgun',
    ]))
      return 'duygusal';
    if (_containsAny(contextMode, const <String>['iş']) || socialMode == 'task')
      return 'iş';
    if (_containsAny(prompt, const <String>['sohbet', 'konuşalım', 'sence']))
      return 'sohbet';
    if (_containsAny(prompt, const <String>['uyku', 'uyuyacağım', 'gece']))
      return 'dinlenme';
    return socialMode == 'conversation' ? 'denge_sohbet' : 'denge';
  }

  String _ambientMode(String contextMode, String prompt, String socialMode) {
    if (_containsAny(contextMode, const <String>['call', 'çağrı']))
      return 'telefon_kanalı';
    if (_containsAny(contextMode, const <String>['iş'])) return 'iş_ortamı';
    if (_containsAny(prompt, const <String>['odada', 'yanımda', 'burada biri']))
      return 'paylaşılan_oda';
    if (_containsAny(prompt, const <String>['yolda', 'sürüşte', 'arabadayım']))
      return 'hareket_halinde';
    if (_containsAny(prompt, const <String>['uyuyorum', 'yatıyorum']))
      return 'dinlenme_ortamı';
    if (socialMode == 'chat' || socialMode == 'conversation')
      return 'rahat_sohbet';
    return contextMode.trim().isEmpty ? 'belirsiz' : contextMode.trim();
  }

  List<String> _topicHints(
    String normalizedPrompt,
    List<String> promptTokens,
    String normalizedReply,
  ) {
    final candidates = <String>[];
    for (final phrase in const <String>[
      'çağrı',
      'companion',
      'mikrofon',
      'hoparlör',
      'izin',
      'hafıza',
      'öğrenme',
      'duygu',
      'nova',
      'nova',
      'otomasyon',
      'uyku',
      'sürüş',
      'arkadaş',
      'aile',
      'iş',
      'zamanlama',
      'hatırlatma',
      'konuşma',
      'ses',
      'kimlik',
      'güven',
      'sosyal',
      'ritüel',
      'ilişki',
      'bellek',
      'prosodi',
      'latency',
      'turn',
      'duplex',
    ]) {
      if (normalizedPrompt.contains(phrase) ||
          normalizedReply.contains(phrase)) {
        candidates.add(phrase);
      }
    }
    for (final token in promptTokens) {
      final lower = token.toLowerCase();
      if (lower.length >= 5 && !_isStopWord(lower) && !_looksGeneric(lower)) {
        candidates.add(lower);
      }
    }
    return _compaction.compactStrings(
      _unique(candidates, limit: 12),
      limit: 8,
      maxItemLength: 40,
    );
  }

  List<String> _unfinished(String prompt, String reply) {
    final items = <String>[];
    if (reply.contains('?')) items.add('takip gerektiren soru izi');
    if (_containsAny(prompt, const <String>[
      'sonra',
      'daha sonra',
      'yarın',
      'haftaya',
    ])) {
      items.add('zamana bırakılmış takip başlığı');
    }
    if (_containsAny(prompt, const <String>[
      'bitmedi',
      'devam edeceğiz',
      'yarım',
    ])) {
      items.add('tamamlanmamış akış');
    }
    if (_containsAny(reply, const <String>[
      'istersen devam',
      'açabilirim',
      'buradan sürdürebiliriz',
    ])) {
      items.add('nova tarafından açık bırakılmış devam kapısı');
    }
    return _compaction.compactStrings(
      _unique(items, limit: 8),
      limit: 6,
      maxItemLength: 80,
    );
  }

  String _continuityThread({
    required String prompt,
    required String reply,
    required NovaSharedWorldState current,
    required String contextMode,
    required String socialMode,
    required List<String> topics,
    required List<String> unfinishedItems,
  }) {
    final parts = <String>[];
    if (topics.isNotEmpty) {
      parts.add(
        'Bugün dönen ana temalar ${topics.take(4).join(', ')} etrafında toplanıyor.',
      );
    }
    if (unfinishedItems.isNotEmpty) {
      parts.add(
        'Bazı başlıklar kapatılmadı; sonraki cevaplar bunu hatırlayan bir akış taşımalı.',
      );
    }
    if (_containsAny(prompt, const <String>[
      'az önce',
      'demin',
      'geçen sefer',
    ])) {
      parts.add(
        'Kullanıcı açık süreklilik referansı verdi; sıfırdan başlama hissi kırılmamalı.',
      );
    }
    if (_containsAny(contextMode, const <String>['call', 'çağrı'])) {
      parts.add(
        'Çağrı ve normal oda konuşması ayrı modlar olsa da ortak gün bağlamının parçaları.',
      );
    }
    if (socialMode == 'conversation' || socialMode == 'chat') {
      parts.add(
        'Sohbet çizgisi korunmalı; aşırı mekanik soru-cevap hissi azaltılmalı.',
      );
    }
    if (current.repeatedTopics.isNotEmpty && topics.isEmpty) {
      parts.add(
        'Önceki tekrar eden temalar hafif zemin olarak canlı tutulmalı.',
      );
    }
    if (_containsAny(reply, const <String>[
      'buradan devam',
      'istersen açarım',
    ])) {
      parts.add(
        'Nova yanıtı yeni bir alt akış kapısı açtı; bunu sonraki turda hatırlayabilir.',
      );
    }
    if (parts.isEmpty) {
      parts.add('Gün içi akış yeni kuruluyor; kopuk cevaplardan kaçınılmalı.');
    }
    return _compaction.compactSummary(parts.join(' '), maxLength: 260);
  }

  List<String> _merge(List<String> base, List<String> incoming) {
    final merged = <String>[
      ...incoming,
      ...base,
    ].map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
    return _compaction.compactStrings(
      _unique(merged, limit: 14),
      limit: 8,
      maxItemLength: 72,
    );
  }

  Future<void> _save(NovaSharedWorldState value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(value.toMap()));
  }

  NovaSharedWorldState _compact(NovaSharedWorldState value) {
    return value.copyWith(
      repeatedTopics: _compaction.compactStrings(
        value.repeatedTopics,
        limit: 8,
        maxItemLength: 40,
      ),
      unfinishedItems: _compaction.compactStrings(
        value.unfinishedItems,
        limit: 6,
        maxItemLength: 80,
      ),
      continuityThread: _compaction.compactSummary(
        value.continuityThread,
        maxLength: 260,
      ),
    );
  }

  List<String> _tokens(String raw) {
    return raw
        .split(RegExp(r'\s+'))
        .map(
          (e) => e
              .replaceAll(
                RegExp(r'^[^\wçğıöşüÇĞİÖŞÜ]+|[^\wçğıöşüÇĞİÖŞÜ]+$'),
                '',
              )
              .trim(),
        )
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  bool _containsAny(String text, List<String> cues) {
    final normalized = _normalize(text);
    for (final cue in cues) {
      if (normalized.contains(cue)) return true;
    }
    return false;
  }

  bool _looksGeneric(String token) {
    return const <String>{
      'şöyle',
      'böyle',
      'zaten',
      'ancak',
      'fakat',
      'orada',
      'burada',
      'hemen',
      'sonra',
    }.contains(token);
  }

  bool _isStopWord(String token) {
    return const <String>{
      'şimdi',
      'bence',
      'çünkü',
      'falan',
      'işte',
      'yani',
      'gibi',
      'veya',
      'ama',
    }.contains(token);
  }

  List<String> _unique(List<String> values, {required int limit}) {
    final seen = <String>{};
    final out = <String>[];
    for (final value in values) {
      final normalized = _normalize(value);
      if (normalized.isEmpty || !seen.add(normalized)) continue;
      out.add(value.trim());
      if (out.length >= limit) break;
    }
    return out;
  }

  String _normalize(String value) => value.trim().toLowerCase();
}
