// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1

class AssistantIdentityProfile {
  final String displayName;
  final List<String> aliases;
  final String wakeReply;
  final String listeningReply;

  const AssistantIdentityProfile({
    required this.displayName,
    required this.aliases,
    required this.wakeReply,
    required this.listeningReply,
  });

  static const AssistantIdentityProfile fallback = AssistantIdentityProfile(
    displayName: 'Nova',
    aliases: <String>['nova', 'nova'],
    wakeReply: 'Nova hazır patron.',
    listeningReply: 'Nova dinliyor patron.',
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'displayName': displayName,
    'aliases': aliases,
    'wakeReply': wakeReply,
    'listeningReply': listeningReply,
  };

  factory AssistantIdentityProfile.fromMap(Map<String, dynamic> map) {
    final rawAliases = map['aliases'];
    final aliases = rawAliases is List
        ? rawAliases
              .map((e) => e.toString().trim().toLowerCase())
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList(growable: false)
        : const <String>[];
    final name = map['displayName']?.toString().trim();
    final displayName = (name == null || name.isEmpty) ? 'Nova' : name;
    final normalizedDisplay = displayName.toLowerCase();
    return AssistantIdentityProfile(
      displayName: displayName,
      aliases: <String>{
        normalizedDisplay,
        'nova',
        ...aliases,
      }.toList(growable: false),
      wakeReply: _fallbackString(map['wakeReply'], 'Nova hazır patron.'),
      listeningReply: _fallbackString(
        map['listeningReply'],
        'Nova dinliyor patron.',
      ),
    );
  }

  static String _fallbackString(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  AssistantIdentityProfile copyWith({
    String? displayName,
    List<String>? aliases,
    String? wakeReply,
    String? listeningReply,
  }) {
    final nextDisplay = (displayName ?? this.displayName).trim();
    final normalizedDisplay = nextDisplay.isEmpty
        ? this.displayName.toLowerCase()
        : nextDisplay.toLowerCase();
    return AssistantIdentityProfile(
      displayName: nextDisplay.isEmpty ? this.displayName : nextDisplay,
      aliases: <String>{
        normalizedDisplay,
        'nova',
        ...(aliases ?? this.aliases)
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty),
      }.toList(growable: false),
      wakeReply: (wakeReply ?? this.wakeReply).trim().isEmpty
          ? this.wakeReply
          : wakeReply ?? this.wakeReply,
      listeningReply: (listeningReply ?? this.listeningReply).trim().isEmpty
          ? this.listeningReply
          : listeningReply ?? this.listeningReply,
    );
  }
}
