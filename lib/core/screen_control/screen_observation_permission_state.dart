// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class ScreenObservationPermissionState {
  final bool enabled;
  final DateTime? enabledAt;

  /// görev için geçici mi, kullanıcı kalıcı mı açtı
  final String mode;

  const ScreenObservationPermissionState({
    required this.enabled,
    this.enabledAt,
    this.mode = 'manual',
  });

  const ScreenObservationPermissionState.disabled()
    : enabled = false,
      enabledAt = null,
      mode = 'manual';

  ScreenObservationPermissionState copyWith({
    bool? enabled,
    DateTime? enabledAt,
    String? mode,
  }) {
    return ScreenObservationPermissionState(
      enabled: enabled ?? this.enabled,
      enabledAt: enabledAt ?? this.enabledAt,
      mode: mode ?? this.mode,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enabled': enabled,
      'enabledAt': enabledAt?.toIso8601String(),
      'mode': mode,
    };
  }

  factory ScreenObservationPermissionState.fromMap(Map<String, dynamic> map) {
    return ScreenObservationPermissionState(
      enabled: map['enabled'] as bool? ?? false,
      enabledAt: DateTime.tryParse(map['enabledAt'] as String? ?? ''),
      mode: (map['mode'] as String? ?? 'manual').trim(),
    );
  }
}
