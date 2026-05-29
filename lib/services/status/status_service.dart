// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
enum UserStatusType { sleeping, showering, driving, busy, custom }

class UserStatusConfig {
  final int nightlySleepStartHour;
  final int nightlySleepEndHour;
  final Duration periodicCheckInterval;

  const UserStatusConfig({
    this.nightlySleepStartHour = 0,
    this.nightlySleepEndHour = 6,
    this.periodicCheckInterval = const Duration(hours: 2),
  });

  UserStatusConfig copyWith({
    int? nightlySleepStartHour,
    int? nightlySleepEndHour,
    Duration? periodicCheckInterval,
  }) {
    return UserStatusConfig(
      nightlySleepStartHour:
          nightlySleepStartHour ?? this.nightlySleepStartHour,
      nightlySleepEndHour: nightlySleepEndHour ?? this.nightlySleepEndHour,
      periodicCheckInterval:
          periodicCheckInterval ?? this.periodicCheckInterval,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'nightlySleepStartHour': nightlySleepStartHour,
      'nightlySleepEndHour': nightlySleepEndHour,
      'periodicCheckIntervalSeconds': periodicCheckInterval.inSeconds,
    };
  }

  factory UserStatusConfig.fromMap(Map<String, dynamic> map) {
    return UserStatusConfig(
      nightlySleepStartHour: map['nightlySleepStartHour'] as int? ?? 0,
      nightlySleepEndHour: map['nightlySleepEndHour'] as int? ?? 6,
      periodicCheckInterval: Duration(
        seconds: map['periodicCheckIntervalSeconds'] as int? ?? 7200,
      ),
    );
  }
}

class ActiveUserStatus {
  final UserStatusType type;
  final String label;
  final DateTime startedAt;
  final DateTime expiresAt;
  final DateTime nextCheckAt;
  final bool setByVoice;
  final bool isManualOverride;

  const ActiveUserStatus({
    required this.type,
    required this.label,
    required this.startedAt,
    required this.expiresAt,
    required this.nextCheckAt,
    this.setByVoice = false,
    this.isManualOverride = true,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get needsCheckIn => DateTime.now().isAfter(nextCheckAt);

  ActiveUserStatus copyWith({
    UserStatusType? type,
    String? label,
    DateTime? startedAt,
    DateTime? expiresAt,
    DateTime? nextCheckAt,
    bool? setByVoice,
    bool? isManualOverride,
  }) {
    return ActiveUserStatus(
      type: type ?? this.type,
      label: label ?? this.label,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      nextCheckAt: nextCheckAt ?? this.nextCheckAt,
      setByVoice: setByVoice ?? this.setByVoice,
      isManualOverride: isManualOverride ?? this.isManualOverride,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type.name,
      'label': label,
      'startedAt': startedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'nextCheckAt': nextCheckAt.toIso8601String(),
      'setByVoice': setByVoice,
      'isManualOverride': isManualOverride,
    };
  }

  factory ActiveUserStatus.fromMap(Map<String, dynamic> map) {
    return ActiveUserStatus(
      type: UserStatusType.values.firstWhere(
        (UserStatusType e) => e.name == map['type'],
      ),
      label: map['label'] as String? ?? '',
      startedAt: DateTime.parse(map['startedAt'] as String),
      expiresAt: DateTime.parse(map['expiresAt'] as String),
      nextCheckAt: DateTime.parse(map['nextCheckAt'] as String),
      setByVoice: map['setByVoice'] as bool? ?? false,
      isManualOverride: map['isManualOverride'] as bool? ?? true,
    );
  }
}

class StatusService {
  UserStatusConfig _config = const UserStatusConfig();
  ActiveUserStatus? _activeStatus;

  UserStatusConfig get config => _config;
  ActiveUserStatus? get activeStatus =>
      isManualStatusActive ? _activeStatus : null;

  void updateConfig(UserStatusConfig config) {
    _config = config;
  }

  void setStatus({
    required UserStatusType type,
    required String label,
    required Duration duration,
    bool setByVoice = false,
  }) {
    final DateTime now = DateTime.now();

    _activeStatus = ActiveUserStatus(
      type: type,
      label: label,
      startedAt: now,
      expiresAt: now.add(duration),
      nextCheckAt: now.add(_config.periodicCheckInterval),
      setByVoice: setByVoice,
      isManualOverride: true,
    );
  }

  bool get isManualStatusActive {
    if (_activeStatus == null) return false;
    if (_activeStatus!.isExpired) {
      _activeStatus = null;
      return false;
    }
    return true;
  }

  bool get isNightRoutineActive {
    if (isManualStatusActive) return false;

    final DateTime now = DateTime.now();
    final int hour = now.hour;
    final int start = _config.nightlySleepStartHour;
    final int end = _config.nightlySleepEndHour;

    if (start == end) return false;

    if (start < end) {
      return hour >= start && hour < end;
    }

    return hour >= start || hour < end;
  }

  bool get isAnyStatusActive => isManualStatusActive || isNightRoutineActive;

  String? get currentStatusLabel {
    if (isManualStatusActive) {
      return _activeStatus?.label;
    }

    if (isNightRoutineActive) {
      return 'sleeping';
    }

    return null;
  }

  UserStatusType? get currentStatusType {
    if (isManualStatusActive) {
      return _activeStatus?.type;
    }

    if (isNightRoutineActive) {
      return UserStatusType.sleeping;
    }

    return null;
  }

  bool get shouldAskCheckIn {
    if (!isManualStatusActive) return false;
    return _activeStatus!.needsCheckIn;
  }

  void markCheckInAsked() {
    if (!isManualStatusActive) return;

    _activeStatus = _activeStatus!.copyWith(
      nextCheckAt: DateTime.now().add(_config.periodicCheckInterval),
    );
  }

  void cancelCurrentStatus() {
    _activeStatus = null;
  }

  void cancelByVoiceCommand() {
    _activeStatus = null;
  }

  bool get canOverrideByVoice => true;

  Map<String, dynamic> exportState() {
    return <String, dynamic>{
      'config': _config.toMap(),
      'activeStatus': _activeStatus?.toMap(),
    };
  }

  void restoreState(Map<String, dynamic> map) {
    final dynamic configMap = map['config'];
    final dynamic activeStatusMap = map['activeStatus'];

    if (configMap is Map<String, dynamic>) {
      _config = UserStatusConfig.fromMap(configMap);
    }

    if (activeStatusMap is Map<String, dynamic>) {
      _activeStatus = ActiveUserStatus.fromMap(activeStatusMap);
      if (_activeStatus!.isExpired) {
        _activeStatus = null;
      }
    }
  }
}
