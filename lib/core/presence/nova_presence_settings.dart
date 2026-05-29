// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaPresenceSettings {
  final bool indicatorEnabled;
  final double indicatorSize;

  const NovaPresenceSettings({
    this.indicatorEnabled = true,
    this.indicatorSize = 18,
  });

  NovaPresenceSettings copyWith({
    bool? indicatorEnabled,
    double? indicatorSize,
  }) => NovaPresenceSettings(
    indicatorEnabled: indicatorEnabled ?? this.indicatorEnabled,
    indicatorSize: indicatorSize ?? this.indicatorSize,
  );

  Map<String, dynamic> toMap() => {
    'indicatorEnabled': indicatorEnabled,
    'indicatorSize': indicatorSize,
  };
  factory NovaPresenceSettings.fromMap(Map<String, dynamic> map) =>
      NovaPresenceSettings(
        indicatorEnabled: map['indicatorEnabled'] as bool? ?? true,
        indicatorSize: (map['indicatorSize'] as num?)?.toDouble() ?? 18,
      );
}
