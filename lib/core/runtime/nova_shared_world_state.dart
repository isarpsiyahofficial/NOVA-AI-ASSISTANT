// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaSharedWorldState {
  final String dayPhase;
  final String userMode;
  final String ambientMode;
  final List<String> repeatedTopics;
  final List<String> unfinishedItems;
  final String continuityThread;
  final DateTime updatedAt;

  const NovaSharedWorldState({
    required this.dayPhase,
    required this.userMode,
    required this.ambientMode,
    required this.repeatedTopics,
    required this.unfinishedItems,
    required this.continuityThread,
    required this.updatedAt,
  });

  factory NovaSharedWorldState.initial() => NovaSharedWorldState(
    dayPhase: 'genel',
    userMode: 'denge',
    ambientMode: 'belirsiz',
    repeatedTopics: const <String>[],
    unfinishedItems: const <String>[],
    continuityThread:
        'Gün içi bağlam yeni kuruluyor; konuşmalar bağımsız hissedilmesin.',
    updatedAt: DateTime.now(),
  );

  NovaSharedWorldState copyWith({
    String? dayPhase,
    String? userMode,
    String? ambientMode,
    List<String>? repeatedTopics,
    List<String>? unfinishedItems,
    String? continuityThread,
    DateTime? updatedAt,
  }) {
    return NovaSharedWorldState(
      dayPhase: dayPhase ?? this.dayPhase,
      userMode: userMode ?? this.userMode,
      ambientMode: ambientMode ?? this.ambientMode,
      repeatedTopics: repeatedTopics ?? this.repeatedTopics,
      unfinishedItems: unfinishedItems ?? this.unfinishedItems,
      continuityThread: continuityThread ?? this.continuityThread,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'dayPhase': dayPhase,
    'userMode': userMode,
    'ambientMode': ambientMode,
    'repeatedTopics': repeatedTopics,
    'unfinishedItems': unfinishedItems,
    'continuityThread': continuityThread,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory NovaSharedWorldState.fromMap(Map<String, dynamic> map) {
    List<String> parse(String key) =>
        (map[key] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
    return NovaSharedWorldState(
      dayPhase: map['dayPhase']?.toString() ?? 'genel',
      userMode: map['userMode']?.toString() ?? 'denge',
      ambientMode: map['ambientMode']?.toString() ?? 'belirsiz',
      repeatedTopics: parse('repeatedTopics'),
      unfinishedItems: parse('unfinishedItems'),
      continuityThread: map['continuityThread']?.toString() ?? '',
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  String buildPromptSection() {
    return [
      'ORTAK DÜNYA MODELİ:',
      '- gün evresi: $dayPhase',
      '- kullanıcı modu: $userMode',
      '- ortam modu: $ambientMode',
      '- süreklilik ipliği: $continuityThread',
      if (repeatedTopics.isNotEmpty)
        '- tekrar eden konular: ${repeatedTopics.take(4).join(' | ')}',
      if (unfinishedItems.isNotEmpty)
        '- yarım kalan işler: ${unfinishedItems.take(4).join(' | ')}',
      'KURAL: Aynı günün, aynı dönemin ve aynı akışın içindeymiş gibi konuş; bağımsız mesaj cevabı üretme.',
    ].join('\n');
  }
}
