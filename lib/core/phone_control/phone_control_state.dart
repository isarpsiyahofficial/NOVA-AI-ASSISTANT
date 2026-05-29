// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class PhoneControlState {
  final bool enabled;
  final DateTime? enabledAt;
  final DateTime? lastReminderAt;
  final String preferredMediaPackage;

  const PhoneControlState({
    required this.enabled,
    this.enabledAt,
    this.lastReminderAt,
    this.preferredMediaPackage = 'com.spotify.music',
  });

  const PhoneControlState.disabled()
    : enabled = false,
      enabledAt = null,
      lastReminderAt = null,
      preferredMediaPackage = 'com.spotify.music';

  PhoneControlState copyWith({
    bool? enabled,
    DateTime? enabledAt,
    DateTime? lastReminderAt,
    String? preferredMediaPackage,
  }) {
    return PhoneControlState(
      enabled: enabled ?? this.enabled,
      enabledAt: enabledAt ?? this.enabledAt,
      lastReminderAt: lastReminderAt ?? this.lastReminderAt,
      preferredMediaPackage:
          preferredMediaPackage ?? this.preferredMediaPackage,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enabled': enabled,
      'enabledAt': enabledAt?.toIso8601String(),
      'lastReminderAt': lastReminderAt?.toIso8601String(),
      'preferredMediaPackage': preferredMediaPackage,
    };
  }

  factory PhoneControlState.fromMap(Map<String, dynamic> map) {
    return PhoneControlState(
      enabled: map['enabled'] as bool? ?? false,
      enabledAt: DateTime.tryParse(map['enabledAt'] as String? ?? ''),
      lastReminderAt: DateTime.tryParse(map['lastReminderAt'] as String? ?? ''),
      preferredMediaPackage:
          (map['preferredMediaPackage'] as String? ?? 'com.spotify.music')
              .trim(),
    );
  }
}
