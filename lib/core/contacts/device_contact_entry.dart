// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class DeviceContactEntry {
  final String id;
  final String displayName;
  final String phoneNumber;

  const DeviceContactEntry({
    required this.id,
    required this.displayName,
    required this.phoneNumber,
  });

  bool get hasUsablePhoneNumber => phoneNumber.trim().isNotEmpty;
  bool get hasUsableDisplayName => displayName.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
    };
  }

  factory DeviceContactEntry.fromMap(Map<String, dynamic> map) {
    return DeviceContactEntry(
      id: (map['id'] as String? ?? '').trim(),
      displayName: (map['displayName'] as String? ?? '').trim(),
      phoneNumber: (map['phoneNumber'] as String? ?? '').trim(),
    );
  }
}
