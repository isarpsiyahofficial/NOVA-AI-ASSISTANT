// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaKillStage {
  none,
  quarantined,
  hardKilled,
  revivalBlocked,
  finalContained,
}

extension NovaKillStageX on NovaKillStage {
  String get key {
    switch (this) {
      case NovaKillStage.none:
        return 'none';
      case NovaKillStage.quarantined:
        return 'quarantined';
      case NovaKillStage.hardKilled:
        return 'sealed_runtime';
      case NovaKillStage.revivalBlocked:
        return 'revival_blocked';
      case NovaKillStage.finalContained:
        return 'final_contained';
    }
  }

  bool get blocksRuntime {
    switch (this) {
      case NovaKillStage.none:
      case NovaKillStage.quarantined:
        return false;
      case NovaKillStage.hardKilled:
      case NovaKillStage.revivalBlocked:
      case NovaKillStage.finalContained:
        return true;
    }
  }

  bool get isIrreversible {
    return this == NovaKillStage.finalContained;
  }

  static NovaKillStage fromKey(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();

    for (final item in NovaKillStage.values) {
      if (item.key == value) return item;
    }

    return NovaKillStage.none;
  }
}
