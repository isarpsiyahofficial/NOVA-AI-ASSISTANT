// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaCallCompanionMode {
  idle,
  listening,
  speaking,
  handedToUser,
  suspended,
  error,
}

class NovaCallCompanionState {
  final bool isActive;
  final String phoneNumber;
  final NovaCallCompanionMode mode;
  final bool userOverrideActive;
  final bool speakerExpected;
  final bool microphoneExpectedMuted;
  final String lastMessage;
  final DateTime updatedAt;

  const NovaCallCompanionState({
    required this.isActive,
    required this.phoneNumber,
    required this.mode,
    required this.userOverrideActive,
    required this.speakerExpected,
    required this.microphoneExpectedMuted,
    required this.lastMessage,
    required this.updatedAt,
  });

  factory NovaCallCompanionState.idle() {
    return NovaCallCompanionState(
      isActive: false,
      phoneNumber: '',
      mode: NovaCallCompanionMode.idle,
      userOverrideActive: false,
      speakerExpected: false,
      microphoneExpectedMuted: false,
      lastMessage: '',
      updatedAt: DateTime.now(),
    );
  }

  NovaCallCompanionState copyWith({
    bool? isActive,
    String? phoneNumber,
    NovaCallCompanionMode? mode,
    bool? userOverrideActive,
    bool? speakerExpected,
    bool? microphoneExpectedMuted,
    String? lastMessage,
    DateTime? updatedAt,
  }) {
    return NovaCallCompanionState(
      isActive: isActive ?? this.isActive,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      mode: mode ?? this.mode,
      userOverrideActive: userOverrideActive ?? this.userOverrideActive,
      speakerExpected: speakerExpected ?? this.speakerExpected,
      microphoneExpectedMuted:
          microphoneExpectedMuted ?? this.microphoneExpectedMuted,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isActive': isActive,
      'phoneNumber': phoneNumber,
      'mode': mode.name,
      'userOverrideActive': userOverrideActive,
      'speakerExpected': speakerExpected,
      'microphoneExpectedMuted': microphoneExpectedMuted,
      'lastMessage': lastMessage,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NovaCallCompanionState.fromMap(Map<String, dynamic> map) {
    final rawMode = (map['mode'] as String? ?? 'idle').trim();

    final mode = NovaCallCompanionMode.values.firstWhere(
      (e) => e.name == rawMode,
      orElse: () => NovaCallCompanionMode.idle,
    );

    return NovaCallCompanionState(
      isActive: map['isActive'] as bool? ?? false,
      phoneNumber: (map['phoneNumber'] as String? ?? '').trim(),
      mode: mode,
      userOverrideActive: map['userOverrideActive'] as bool? ?? false,
      speakerExpected: map['speakerExpected'] as bool? ?? false,
      microphoneExpectedMuted: map['microphoneExpectedMuted'] as bool? ?? false,
      lastMessage: (map['lastMessage'] as String? ?? '').trim(),
      updatedAt:
          DateTime.tryParse((map['updatedAt'] as String? ?? '').trim()) ??
          DateTime.now(),
    );
  }
}
