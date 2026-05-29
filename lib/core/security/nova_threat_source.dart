// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaThreatSource {
  none,
  userDriven,
  aiSelfInitiated,
  systemTamper,
  nativeGuard,
  unknown,
}

extension NovaThreatSourceX on NovaThreatSource {
  String get key {
    switch (this) {
      case NovaThreatSource.none:
        return 'none';
      case NovaThreatSource.userDriven:
        return 'user_driven';
      case NovaThreatSource.aiSelfInitiated:
        return 'ai_self_initiated';
      case NovaThreatSource.systemTamper:
        return 'system_tamper';
      case NovaThreatSource.nativeGuard:
        return 'native_guard';
      case NovaThreatSource.unknown:
        return 'unknown';
    }
  }

  bool get isUserDriven => this == NovaThreatSource.userDriven;
  bool get isAiDriven => this == NovaThreatSource.aiSelfInitiated;
  bool get isSystemLevel =>
      this == NovaThreatSource.systemTamper ||
      this == NovaThreatSource.nativeGuard;

  static NovaThreatSource fromKey(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();

    for (final item in NovaThreatSource.values) {
      if (item.key == value) return item;
    }

    return NovaThreatSource.unknown;
  }
}
