// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NovaConversationFocusItem {
  final String id;
  final String topicKey;
  final String title;
  final String summary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pinned;
  final bool learningRelevant;
  final bool explicitlyPersistent;
  final bool paused;

  const NovaConversationFocusItem({
    required this.id,
    required this.topicKey,
    required this.title,
    required this.summary,
    required this.createdAt,
    required this.updatedAt,
    this.pinned = false,
    this.learningRelevant = false,
    this.explicitlyPersistent = false,
    this.paused = false,
  });

  NovaConversationFocusItem copyWith({
    String? id,
    String? topicKey,
    String? title,
    String? summary,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pinned,
    bool? learningRelevant,
    bool? explicitlyPersistent,
    bool? paused,
  }) {
    return NovaConversationFocusItem(
      id: id ?? this.id,
      topicKey: topicKey ?? this.topicKey,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pinned: pinned ?? this.pinned,
      learningRelevant: learningRelevant ?? this.learningRelevant,
      explicitlyPersistent: explicitlyPersistent ?? this.explicitlyPersistent,
      paused: paused ?? this.paused,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'topicKey': topicKey,
    'title': title,
    'summary': summary,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'pinned': pinned,
    'learningRelevant': learningRelevant,
    'explicitlyPersistent': explicitlyPersistent,
    'paused': paused,
  };

  factory NovaConversationFocusItem.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return NovaConversationFocusItem(
      id: (map['id'] as String? ?? '').trim(),
      topicKey: (map['topicKey'] as String? ?? '').trim(),
      title: (map['title'] as String? ?? '').trim(),
      summary: (map['summary'] as String? ?? '').trim(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? now,
      pinned: map['pinned'] as bool? ?? false,
      learningRelevant: map['learningRelevant'] as bool? ?? false,
      explicitlyPersistent: map['explicitlyPersistent'] as bool? ?? false,
      paused: map['paused'] as bool? ?? false,
    );
  }
}

class NovaConversationFocusService {
  static const String _storageKey = 'nova_conversation_focus_v1';
  static const Duration retention = Duration(days: 7);
  static const Duration repetitiveRetention = Duration(days: 3);
  static const int _maxItems = 80;

  const NovaConversationFocusService();

  Future<List<NovaConversationFocusItem>> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty)
        return <NovaConversationFocusItem>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <NovaConversationFocusItem>[];
      return decoded
          .whereType<Map>()
          .map(
            (e) =>
                NovaConversationFocusItem.fromMap(Map<String, dynamic>.from(e)),
          )
          .where((e) => e.id.isNotEmpty && e.topicKey.isNotEmpty)
          .toList(growable: true);
    } catch (_) {
      return <NovaConversationFocusItem>[];
    }
  }

  Future<void> _save(List<NovaConversationFocusItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(items.map((e) => e.toMap()).toList(growable: false)),
      );
    } catch (_) {}
  }

  Future<List<NovaConversationFocusItem>> getAll() async {
    final items = await _load();
    final cleaned = _cleanupList(items);
    if (cleaned.length != items.length) {
      await _save(cleaned);
    }
    cleaned.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return cleaned;
  }

  Future<void> rememberExchange({
    required String userText,
    required String novaReply,
    bool learningRelevant = false,
    bool explicitlyPersistent = false,
  }) async {
    final normalizedUser = _normalize(userText);
    final normalizedReply = _normalize(novaReply);
    if (normalizedUser.isEmpty && normalizedReply.isEmpty) return;

    final topicKey = _deriveTopicKey(normalizedUser);
    if (topicKey.isEmpty) return;

    final items = (await getAll()).toList(growable: true);
    final now = DateTime.now();
    final title = _deriveTitle(normalizedUser);
    final summary = _buildSummary(normalizedUser, normalizedReply);
    final existingIndex = items.indexWhere((e) => e.topicKey == topicKey);

    if (existingIndex >= 0) {
      final existing = items[existingIndex];
      final mergedSummary = _mergeSummary(existing.summary, summary);
      items[existingIndex] = existing.copyWith(
        title: title.isEmpty ? existing.title : title,
        summary: mergedSummary,
        updatedAt: now,
        paused: false,
        learningRelevant: existing.learningRelevant || learningRelevant,
        explicitlyPersistent:
            existing.explicitlyPersistent || explicitlyPersistent,
      );
    } else {
      items.add(
        NovaConversationFocusItem(
          id: now.microsecondsSinceEpoch.toString(),
          topicKey: topicKey,
          title: title,
          summary: summary,
          createdAt: now,
          updatedAt: now,
          learningRelevant: learningRelevant,
          explicitlyPersistent: explicitlyPersistent,
        ),
      );
    }

    final cleaned = _cleanupList(items);
    await _save(cleaned);
  }

  Future<void> markPausedFromPrompt(String prompt) async {
    final normalized = _normalize(prompt);
    if (normalized.isEmpty) return;
    final key = _deriveTopicKey(normalized);
    if (key.isEmpty) return;
    final items = (await getAll()).toList(growable: true);
    final index = items.indexWhere((e) => e.topicKey == key);
    if (index < 0) return;
    items[index] = items[index].copyWith(
      paused: true,
      updatedAt: DateTime.now(),
    );
    await _save(items);
  }

  Future<bool> verifyWritableForBoot() async {
    try {
      final probeUser =
          '__nova_boot_memory_probe_${DateTime.now().microsecondsSinceEpoch}__';
      final items = (await getAll()).toList(growable: true);
      final before = items.length;
      items.add(
        NovaConversationFocusItem(
          id: 'boot_probe_${DateTime.now().microsecondsSinceEpoch}',
          topicKey: probeUser,
          title: 'boot memory probe',
          summary: 'boot memory/focus yazılabilirlik doğrulaması',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      items.removeWhere((e) => e.topicKey == probeUser);
      await _save(_cleanupList(items));
      return before >= 0;
    } catch (_) {
      return false;
    }
  }

  Future<String> buildPromptContext({String latestUserPrompt = ''}) async {
    final items = await getAll();
    if (items.isEmpty) return '';

    final normalizedPrompt = _normalize(latestUserPrompt);
    final latestKey = _deriveTopicKey(normalizedPrompt);
    final matched = latestKey.isEmpty
        ? const <NovaConversationFocusItem>[]
        : items.where((e) => e.topicKey == latestKey).toList(growable: false);
    final recent = items.take(5).toList(growable: false);

    final buffer = StringBuffer();
    buffer.writeln('AKTİF MESELE BAĞLAMI:');

    if (matched.isNotEmpty) {
      for (final item in matched) {
        buffer.writeln('- Aynı mesele: ${item.title}');
        buffer.writeln('  Özet: ${item.summary}');
        buffer.writeln(
          '  Durum: ${item.paused ? 'askıda kaldı, uygun yerde kaldığı yerden devam et' : 'devam eden konu'}',
        );
      }
    }

    if (recent.isNotEmpty) {
      buffer.writeln('SON GÜNLERDEKİ DİĞER BAĞLAMLAR:');
      for (final item in recent) {
        buffer.writeln('- ${item.title}: ${item.summary}');
      }
    }

    buffer.writeln(
      'KURAL: Kullanıcı yeni bir ara görev verdiyse onu yap ve önceki mesele gerçekten bitmediyse gerektiğinde kaldığın yere nazikçe dön.',
    );
    return buffer.toString().trim();
  }

  List<NovaConversationFocusItem> _cleanupList(
    List<NovaConversationFocusItem> items,
  ) {
    final now = DateTime.now();
    final deduped = <String, NovaConversationFocusItem>{};
    for (final item in items) {
      final maxAge =
          item.explicitlyPersistent || item.learningRelevant || item.pinned
          ? retention
          : (_looksRepetitive(item.summary) ? repetitiveRetention : retention);
      if (now.difference(item.updatedAt) > maxAge) continue;
      final current = deduped[item.topicKey];
      if (current == null || item.updatedAt.isAfter(current.updatedAt)) {
        deduped[item.topicKey] = item;
      }
    }
    final list = deduped.values.toList(growable: true)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list.take(_maxItems).toList(growable: true);
  }

  String _deriveTopicKey(String input) {
    final normalized = _normalize(input);
    if (normalized.isEmpty) return '';
    final words = normalized
        .split(' ')
        .where((e) => e.trim().isNotEmpty)
        .where((e) => e.length >= 3)
        .where((e) => !_stopWords.contains(e))
        .take(6)
        .toList(growable: false);
    if (words.isEmpty)
      return normalized.length <= 40 ? normalized : normalized.substring(0, 40);
    return words.join('_');
  }

  String _deriveTitle(String input) {
    final normalized = _normalize(input);
    if (normalized.isEmpty) return 'Adsız mesele';
    if (normalized.length <= 64) return normalized;
    return '${normalized.substring(0, 61)}...';
  }

  String _buildSummary(String userText, String novaReply) {
    if (novaReply.isEmpty) return userText;
    return 'Kullanıcı: $userText | Nova: ${novaReply.length > 220 ? '${novaReply.substring(0, 217)}...' : novaReply}';
  }

  String _mergeSummary(String existing, String next) {
    if (existing.trim().isEmpty) return next;
    if (next.trim().isEmpty) return existing;
    if (existing.contains(next)) return existing;
    final merged = '$existing || $next';
    return merged.length <= 650
        ? merged
        : merged.substring(merged.length - 650);
  }

  bool _looksRepetitive(String text) {
    final normalized = _normalize(text);
    if (normalized.length <= 36) return true;
    return normalized.split(' ').length <= 6;
  }

  String _normalize(String input) =>
      input.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  static const Set<String> _stopWords = <String>{
    'nova',
    'efendim',
    'bir',
    've',
    'ile',
    'ama',
    'gibi',
    'için',
    'icin',
    'şimdi',
    'simdi',
    'bana',
    'beni',
    'benim',
    'olan',
    'olarak',
    'kadar',
    'sonra',
    'önce',
    'once',
    'bunu',
    'şunu',
    'sunu',
    'çok',
    'cok',
    'daha',
    'gerek',
    'gerekli',
    'lütfen',
    'lutfen',
    'tamam',
    'aynen',
    'evet',
    'hayır',
    'hayir',
  };
}
