// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/conversation/nova_conversation_entry.dart';

class NovaConversationSessionService {
  static const String _storageKey = 'nova_conversation_session_v2';
  static const Duration retention = Duration(days: 7);
  static const Duration repetitiveRetention = Duration(days: 3);
  static const int _maxEntryCount = 2400;
  static const int _defaultPromptContextLimit = 72;

  const NovaConversationSessionService();

  Future<List<NovaConversationEntry>> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw == null || raw.trim().isEmpty) {
        return <NovaConversationEntry>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <NovaConversationEntry>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (e) => NovaConversationEntry.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .where((e) => e.text.trim().isNotEmpty)
          .toList(growable: true);
    } catch (_) {
      return <NovaConversationEntry>[];
    }
  }

  Future<void> _save(List<NovaConversationEntry> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmed = _trim(items);
      final encoded = jsonEncode(
        trimmed.map((e) => e.toMap()).toList(growable: false),
      );
      await prefs.setString(_storageKey, encoded);
    } catch (_) {
      // Sessiz fallback
    }
  }

  List<NovaConversationEntry> _trim(List<NovaConversationEntry> items) {
    final sorted = List<NovaConversationEntry>.from(items)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final cutoff = DateTime.now().subtract(retention);
    final filtered = sorted
        .where((item) => item.createdAt.isAfter(cutoff))
        .toList(growable: true);

    filtered.removeWhere((item) {
      if (!_looksRepetitive(item.text)) return false;
      final repetitiveCutoff = DateTime.now().subtract(repetitiveRetention);
      return item.createdAt.isBefore(repetitiveCutoff);
    });

    if (filtered.length <= _maxEntryCount) {
      return filtered;
    }

    return filtered.sublist(filtered.length - _maxEntryCount);
  }

  Future<int> cleanupExpired() async {
    final before = await _load();
    final trimmed = _trim(before);
    await _save(trimmed);
    return before.length - trimmed.length;
  }

  Future<int> cleanupManual() async {
    return cleanupExpired();
  }

  Future<List<NovaConversationEntry>> getAll() async {
    final items = List<NovaConversationEntry>.from(await _load())
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  Future<void> addUserText(
    String text, {
    String speakerName = '',
    String speakerVoiceId = '',
    String relationshipLabel = '',
  }) async {
    await _add(
      role: NovaConversationRole.user,
      source: NovaConversationSource.text,
      text: text,
      speakerName: speakerName,
      speakerVoiceId: speakerVoiceId,
      relationshipLabel: relationshipLabel,
    );
  }

  Future<void> addUserVoice(
    String text, {
    String speakerName = '',
    String speakerVoiceId = '',
    String relationshipLabel = '',
  }) async {
    await _add(
      role: NovaConversationRole.user,
      source: NovaConversationSource.voice,
      text: text,
      speakerName: speakerName,
      speakerVoiceId: speakerVoiceId,
      relationshipLabel: relationshipLabel,
    );
  }

  Future<void> addNovaText(
    String text, {
    required bool fromVoiceFlow,
    String topicKey = '',
  }) async {
    await _add(
      role: NovaConversationRole.nova,
      source: fromVoiceFlow
          ? NovaConversationSource.voice
          : NovaConversationSource.text,
      text: text,
      topicKey: topicKey,
    );
  }

  Future<void> addSystemNote(String text) async {
    await _add(
      role: NovaConversationRole.system,
      source: NovaConversationSource.system,
      text: text,
    );
  }

  Future<void> _add({
    required NovaConversationRole role,
    required NovaConversationSource source,
    required String text,
    String topicKey = '',
    String speakerVoiceId = '',
    String speakerName = '',
    String relationshipLabel = '',
  }) async {
    final cleaned = _normalizeText(text);
    if (cleaned.isEmpty) return;
    if (!_shouldPersist(role: role, source: source, text: cleaned)) {
      return;
    }

    final resolvedTopicKey = topicKey.trim().isNotEmpty
        ? topicKey.trim()
        : deriveTopicKey(cleaned);
    final interactionKind = _inferKind(cleaned, source);
    final items = List<NovaConversationEntry>.from(await _load());
    final now = DateTime.now();

    final duplicateWindow = _duplicateWindowFor(cleaned);
    final duplicate = items.lastWhere(
      (item) {
        if (item.role != role || item.source != source) return false;
        if (item.text.trim().toLowerCase() != cleaned.toLowerCase())
          return false;
        return now.difference(item.createdAt) <= duplicateWindow;
      },
      orElse: () => NovaConversationEntry(
        id: '',
        role: NovaConversationRole.system,
        source: NovaConversationSource.system,
        text: '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );

    if (duplicate.id.isNotEmpty) {
      return;
    }

    items.add(
      NovaConversationEntry(
        id: now.microsecondsSinceEpoch.toString(),
        role: role,
        source: source,
        text: cleaned,
        createdAt: now,
        topicKey: resolvedTopicKey,
        speakerVoiceId: speakerVoiceId.trim(),
        speakerName: speakerName.trim(),
        relationshipLabel: relationshipLabel.trim(),
        interactionKind: interactionKind,
      ),
    );

    await _save(items);
  }

  Duration _duplicateWindowFor(String text) {
    if (_looksRepetitive(text)) {
      return repetitiveRetention;
    }
    if (text.split(' ').length <= 6) {
      return const Duration(hours: 4);
    }
    return const Duration(minutes: 10);
  }

  static const Set<String> _familyAndAuthorityMarkers = <String>{
    'anne',
    'baba',
    'eş',
    'es',
    'abi',
    'abla',
    'kardeş',
    'kardes',
    'patron',
    'sahibim',
    'owner',
    'efendim',
  };

  bool _shouldPersist({
    required NovaConversationRole role,
    required NovaConversationSource source,
    required String text,
  }) {
    final normalized = text.toLowerCase().trim();
    if (normalized.isEmpty) return false;
    if (_looksLikeNoise(normalized)) return false;
    if (normalized.length < 2) return false;

    if (source == NovaConversationSource.system) {
      return normalized.contains('hatırlat') ||
          normalized.contains('çağrı') ||
          normalized.contains('cagri') ||
          normalized.contains('onar') ||
          normalized.contains('izin') ||
          normalized.contains('dinleme') ||
          normalized.contains('mikrofon');
    }

    if (role == NovaConversationRole.nova) {
      return !_looksLikeDisposableReply(normalized);
    }

    final addressedToNova = _isLikelyAddressedToNova(normalized);
    final importantInteraction =
        _inferKind(normalized, source) !=
        NovaConversationInteractionKind.conversation;
    final memorableConversation = _looksMemorableConversation(normalized);
    return addressedToNova || importantInteraction || memorableConversation;
  }

  bool _isLikelyAddressedToNova(String text) {
    const markers = <String>{
      'nova',
      'beni',
      'bana',
      'benim için',
      'benim icin',
      'hatırlat',
      'hatirlat',
      'ara',
      'aç',
      'ac',
      'kapat',
      'değiştir',
      'degistir',
      'uyandır',
      'uyandir',
      'sence',
      'sohbet edelim',
      'konuşalım',
      'konusalim',
      'yardım et',
      'yardim et',
      'anlat',
      'dinle',
    };
    for (final marker in markers) {
      if (text == marker ||
          text.startsWith('$marker ') ||
          text.contains(' $marker ')) {
        return true;
      }
    }
    for (final marker in _familyAndAuthorityMarkers) {
      if (text.contains(' $marker ') ||
          text.startsWith('$marker ') ||
          text.endsWith(' $marker')) {
        return true;
      }
    }
    return false;
  }

  bool _looksLikeNoise(String text) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) return true;
    if (RegExp(r'^[\W_]+$').hasMatch(compact)) return true;
    if (compact.length <= 3 &&
        RegExp(
          r'^(hmm|eee|ııı|iii|aaa|cızırtı|cizirti|parazit)$',
        ).hasMatch(compact)) {
      return true;
    }
    if (compact.split(' ').where((e) => e.isNotEmpty).length == 1 &&
        compact.length <= 2) {
      return true;
    }
    return false;
  }

  bool _looksRepetitive(String text) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    if (compact.isEmpty) return false;
    if (compact.length <= 24) return true;
    final words = compact.split(' ');
    if (words.length <= 4) return true;
    return false;
  }

  bool _looksMemorableConversation(String text) {
    return text.contains('geçen gün') ||
        text.contains('gecen gun') ||
        text.contains('unutma') ||
        text.contains('öğren') ||
        text.contains('ogren') ||
        text.contains('bundan sonra') ||
        text.contains('bunu bil') ||
        text.contains('hatırla') ||
        text.contains('hatirla') ||
        text.contains('beni dinle') ||
        text.contains('benim sesim') ||
        text.contains('çağrıda') ||
        text.contains('cagri') ||
        text.contains('mikrofon') ||
        text.contains('hatırlatıcı') ||
        text.contains('hatirlatici');
  }

  bool _looksLikeDisposableReply(String text) {
    return text == 'tamam' ||
        text == 'olur' ||
        text == 'peki' ||
        text == 'anlaşıldı' ||
        text == 'anlasildi';
  }

  String _normalizeText(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  NovaConversationInteractionKind _inferKind(
    String text,
    NovaConversationSource source,
  ) {
    final normalized = text.toLowerCase();
    if (_containsAny(normalized, const [
      'hatırlat',
      'hatirlat',
      'alarm',
      'uyandır',
      'uyandir',
      'yarın',
      'yarin',
      'saat',
    ])) {
      return NovaConversationInteractionKind.reminder;
    }
    if (_containsAny(normalized, const [
      'ara',
      'çağrı',
      'cagri',
      'telefon',
      'hoparlör',
      'hoparlor',
      'mikrofon',
      'devral',
      'devret',
      'companion',
    ])) {
      return NovaConversationInteractionKind.call;
    }
    if (_containsAny(normalized, const [
      'hafıza',
      'hafiza',
      'hatırla',
      'hatirla',
      'öğren',
      'ogren',
      'unutma',
    ])) {
      return NovaConversationInteractionKind.learning;
    }
    if (_containsAny(normalized, const [
      'tam güç',
      'tam guc',
      'tasarruf',
      'araf',
      'gece modu',
      'uykuya dön',
      'uykuya don',
      'kapan',
    ])) {
      return NovaConversationInteractionKind.status;
    }
    return NovaConversationInteractionKind.conversation;
  }

  bool _containsAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) return true;
    }
    return false;
  }

  String deriveTopicKey(String text) {
    final normalized = text.toLowerCase();
    if (_containsAny(normalized, const ['çağrı', 'cagri', 'ara', 'telefon'])) {
      return 'call_flow';
    }
    if (_containsAny(normalized, const ['hatırlat', 'hatirlat', 'alarm'])) {
      return 'reminder_flow';
    }
    if (_containsAny(normalized, const [
      'hafıza',
      'hafiza',
      'hatırla',
      'hatirla',
    ])) {
      return 'memory_flow';
    }
    if (_containsAny(normalized, const [
      'gece modu',
      'araf',
      'tasarruf',
      'tam güç',
      'tam guc',
    ])) {
      return 'power_modes';
    }
    final words = normalized
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü ]', unicode: true), ' ')
        .split(' ')
        .map((e) => e.trim())
        .where((e) => e.length >= 3)
        .take(4)
        .toList(growable: false);
    return words.isEmpty ? 'general' : words.join('_');
  }

  Future<String> buildParticipantSummary({int limit = 48}) async {
    final items = await getAll();
    if (items.isEmpty) return '';

    final recent = items.length <= limit
        ? items
        : items.sublist(items.length - limit);
    final seen = <String, int>{};
    final labels = <String, String>{};
    for (final item in recent) {
      final speaker = item.speakerName.trim();
      if (speaker.isEmpty) continue;
      seen[speaker] = (seen[speaker] ?? 0) + 1;
      final relationship = item.relationshipLabel.trim();
      if (relationship.isNotEmpty && !labels.containsKey(speaker)) {
        labels[speaker] = relationship;
      }
    }

    if (seen.isEmpty) return '';
    final names = seen.keys.toList(growable: false);
    final parts = <String>[];
    for (final name in names.take(6)) {
      final relationship = labels[name];
      final count = seen[name] ?? 0;
      parts.add(
        relationship == null || relationship.isEmpty
            ? '$name($count)'
            : '$name/$relationship($count)',
      );
    }
    return 'KATILIMCI ÖZETİ: ' + parts.join(', ');
  }

  Future<String> buildPromptContext({
    int limit = _defaultPromptContextLimit,
  }) async {
    final items = await getAll();
    if (items.isEmpty) return '';

    final recent = items.length <= limit
        ? items
        : items.sublist(items.length - limit);
    final buffer = StringBuffer('SON KONUŞMA AKIŞI:\n');
    for (final item in recent) {
      final role = switch (item.role) {
        NovaConversationRole.user => 'Kullanıcı',
        NovaConversationRole.nova => 'Nova',
        NovaConversationRole.system => 'Sistem',
      };
      final source = switch (item.source) {
        NovaConversationSource.voice => 'ses',
        NovaConversationSource.text => 'yazı',
        NovaConversationSource.system => 'sistem',
      };
      final speaker = item.speakerName.trim().isEmpty
          ? ''
          : ' (${item.speakerName.trim()})';
      buffer.writeln('- $role/$source$speaker: ${item.text}');
    }
    return buffer.toString().trimRight();
  }
}

class NovaConversationTopicSummary {
  final String topicKey;
  final int count;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final List<String> speakerNames;
  final List<String> sampleLines;

  const NovaConversationTopicSummary({
    required this.topicKey,
    required this.count,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.speakerNames,
    required this.sampleLines,
  });

  String render() {
    return <String>[
      '[KONU] $topicKey',
      '- tekrar: $count',
      '- ilk/güncel: ${firstSeenAt.toIso8601String()} -> ${lastSeenAt.toIso8601String()}',
      if (speakerNames.isNotEmpty) '- konuşanlar: ${speakerNames.join(', ')}',
      if (sampleLines.isNotEmpty) '- örnek: ${sampleLines.join(' | ')}',
    ].join('\n');
  }
}

class NovaConversationRepairCue {
  final String text;
  final String reason;
  final DateTime createdAt;

  const NovaConversationRepairCue({
    required this.text,
    required this.reason,
    required this.createdAt,
  });
}

extension NovaConversationSessionServiceLivingContextExtension
    on NovaConversationSessionService {
  Future<List<NovaConversationTopicSummary>> buildTopicSummaries({
    int maxTopics = 6,
  }) async {
    final items = await getAll();
    final grouped = <String, List<NovaConversationEntry>>{};
    for (final item in items) {
      final key = item.topicKey.trim().isEmpty
          ? deriveTopicKey(item.text)
          : item.topicKey.trim();
      grouped.putIfAbsent(key, () => <NovaConversationEntry>[]).add(item);
    }
    final summaries =
        grouped.entries
            .map((entry) {
              final records = entry.value
                ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
              final speakers = records
                  .map((e) => e.speakerName.trim())
                  .where((e) => e.isNotEmpty)
                  .toSet()
                  .toList(growable: false);
              final samples = records
                  .map((e) => e.text.trim())
                  .where((e) => e.isNotEmpty)
                  .take(3)
                  .toList(growable: false);
              return NovaConversationTopicSummary(
                topicKey: entry.key,
                count: records.length,
                firstSeenAt: records.first.createdAt,
                lastSeenAt: records.last.createdAt,
                speakerNames: speakers,
                sampleLines: samples,
              );
            })
            .toList(growable: false)
          ..sort((a, b) => b.lastSeenAt.compareTo(a.lastSeenAt));
    return summaries.take(maxTopics).toList(growable: false);
  }

  Future<List<NovaConversationRepairCue>> extractRepairCues({
    int maxItems = 8,
  }) async {
    final items = await getAll();
    final cues = <NovaConversationRepairCue>[];
    for (final item in items.reversed) {
      final normalized = item.text.toLowerCase();
      String? reason;
      if (_containsAny(normalized, const [
        'yanlış',
        'yanlis',
        'öyle değil',
        'oyle degil',
      ])) {
        reason = 'yanlış anlama';
      } else if (_containsAny(normalized, const [
        'tekrar',
        'baştan',
        'bastan',
      ])) {
        reason = 'yeniden ifade talebi';
      } else if (_containsAny(normalized, const [
        'dur bir dakika',
        'bekle',
        'hayır',
      ])) {
        reason = 'akış kesme / düzeltme';
      }
      if (reason == null) continue;
      cues.add(
        NovaConversationRepairCue(
          text: item.text,
          reason: reason,
          createdAt: item.createdAt,
        ),
      );
      if (cues.length >= maxItems) break;
    }
    return cues;
  }

  Future<String> buildLivingMindContext() async {
    final participantSummary = await buildParticipantSummary(limit: 64);
    final topicSummaries = await buildTopicSummaries(maxTopics: 5);
    final repairs = await extractRepairCues(maxItems: 5);
    final parts = <String>['YAŞAYAN ZİHİN BAĞLAMI'];
    if (participantSummary.isNotEmpty) parts.add(participantSummary);
    if (topicSummaries.isNotEmpty) {
      parts.add('AKTİF KONU YÖRÜNGELERİ:');
      parts.addAll(topicSummaries.map((e) => e.render()));
    }
    if (repairs.isNotEmpty) {
      parts.add('SON ONARIM İZLERİ:');
      parts.addAll(repairs.map((e) => '- ${e.reason}: ${e.text}'));
    }
    return parts.join('\n\n');
  }
}
