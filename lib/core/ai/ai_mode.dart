// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum AiMode { localOnly, hybrid, apiOnly }

extension AiModeX on AiMode {
  String get key {
    switch (this) {
      case AiMode.localOnly:
        return 'local_only';
      case AiMode.hybrid:
        return 'hybrid';
      case AiMode.apiOnly:
        return 'api_only';
    }
  }

  String get label {
    switch (this) {
      case AiMode.localOnly:
        return 'Yerel Mod';
      case AiMode.hybrid:
        return 'Hibrit Mod';
      case AiMode.apiOnly:
        return 'API Modu';
    }
  }

  bool get usesLocalModel {
    switch (this) {
      case AiMode.localOnly:
      case AiMode.apiOnly:
        return false;
      case AiMode.hybrid:
        return true;
    }
  }

  bool get canUseApi {
    switch (this) {
      case AiMode.localOnly:
      case AiMode.hybrid:
      case AiMode.apiOnly:
        return true;
    }
  }
}
