// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaConversationRole { user, nova, system }

enum NovaConversationSource { text, voice, system }

enum NovaConversationInteractionKind {
  conversation,
  command,
  call,
  reminder,
  learning,
  status,
}

class NovaConversationEntry {
  final String id;
  final NovaConversationRole role;
  final NovaConversationSource source;
  final String text;
  final DateTime createdAt;
  final String topicKey;
  final String speakerVoiceId;
  final String speakerName;
  final String relationshipLabel;
  final NovaConversationInteractionKind interactionKind;

  const NovaConversationEntry({
    required this.id,
    required this.role,
    required this.source,
    required this.text,
    required this.createdAt,
    this.topicKey = '',
    this.speakerVoiceId = '',
    this.speakerName = '',
    this.relationshipLabel = '',
    this.interactionKind = NovaConversationInteractionKind.conversation,
  });

  NovaConversationEntry copyWith({
    String? id,
    NovaConversationRole? role,
    NovaConversationSource? source,
    String? text,
    DateTime? createdAt,
    String? topicKey,
    String? speakerVoiceId,
    String? speakerName,
    String? relationshipLabel,
    NovaConversationInteractionKind? interactionKind,
  }) {
    return NovaConversationEntry(
      id: id ?? this.id,
      role: role ?? this.role,
      source: source ?? this.source,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      topicKey: topicKey ?? this.topicKey,
      speakerVoiceId: speakerVoiceId ?? this.speakerVoiceId,
      speakerName: speakerName ?? this.speakerName,
      relationshipLabel: relationshipLabel ?? this.relationshipLabel,
      interactionKind: interactionKind ?? this.interactionKind,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'role': role.name,
      'source': source.name,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'topicKey': topicKey,
      'speakerVoiceId': speakerVoiceId,
      'speakerName': speakerName,
      'relationshipLabel': relationshipLabel,
      'interactionKind': interactionKind.name,
    };
  }

  factory NovaConversationEntry.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();

    return NovaConversationEntry(
      id: (map['id'] as String? ?? '').trim(),
      role: NovaConversationRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => NovaConversationRole.system,
      ),
      source: NovaConversationSource.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => NovaConversationSource.system,
      ),
      text: (map['text'] as String? ?? '').trim(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? now,
      topicKey: (map['topicKey'] as String? ?? '').trim(),
      speakerVoiceId: (map['speakerVoiceId'] as String? ?? '').trim(),
      speakerName: (map['speakerName'] as String? ?? '').trim(),
      relationshipLabel: (map['relationshipLabel'] as String? ?? '').trim(),
      interactionKind: NovaConversationInteractionKind.values.firstWhere(
        (e) => e.name == (map['interactionKind'] as String? ?? '').trim(),
        orElse: () => NovaConversationInteractionKind.conversation,
      ),
    );
  }
}
