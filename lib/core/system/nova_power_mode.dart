// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum NovaPowerMode { batterySaver, fullyOn, passiveSleep, limbo, fullyShutdown }

extension NovaPowerModeX on NovaPowerMode {
  bool get isOperational => this != NovaPowerMode.fullyShutdown;

  bool get allowsWakeWord =>
      this == NovaPowerMode.fullyOn ||
      this == NovaPowerMode.batterySaver ||
      this == NovaPowerMode.passiveSleep ||
      this == NovaPowerMode.limbo ||
      this == NovaPowerMode.fullyShutdown;

  bool get allowsPriorityCalls => true;

  bool get allowsOnlyWakeAndPriorityCalls =>
      this == NovaPowerMode.passiveSleep || this == NovaPowerMode.limbo;

  bool get keepsContinuousListeningAvailable =>
      this == NovaPowerMode.fullyOn || this == NovaPowerMode.batterySaver;

  bool get shouldKeepCompanionReady =>
      this == NovaPowerMode.fullyOn ||
      this == NovaPowerMode.batterySaver ||
      this == NovaPowerMode.fullyShutdown;

  bool get allowsSelfRepairDiagnostics => this == NovaPowerMode.fullyOn;

  String get label {
    switch (this) {
      case NovaPowerMode.batterySaver:
        return 'Tasarruf';
      case NovaPowerMode.fullyOn:
        return 'Tam güç';
      case NovaPowerMode.passiveSleep:
        return 'Gece modu';
      case NovaPowerMode.limbo:
        return 'Araf modu';
      case NovaPowerMode.fullyShutdown:
        return 'Tam kapalı';
    }
  }

  String get spokenLabel {
    switch (this) {
      case NovaPowerMode.batterySaver:
        return 'tasarruf modu';
      case NovaPowerMode.fullyOn:
        return 'tam güç modu';
      case NovaPowerMode.passiveSleep:
        return 'gece modu';
      case NovaPowerMode.limbo:
        return 'araf modu';
      case NovaPowerMode.fullyShutdown:
        return 'tam kapalı mod';
    }
  }
}
