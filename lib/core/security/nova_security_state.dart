// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'nova_kill_stage.dart';
import 'nova_security_event.dart';
import 'nova_threat_source.dart';

class NovaSecurityState {
  final bool allowRuntime;
  final bool runtimeBlocked;
  final bool bootAllowed;
  final bool aiRequestsAllowed;
  final bool learningAllowed;
  final bool apiLearningAllowed;
  final bool nativeBridgeAllowed;
  final bool backgroundRuntimeAllowed;

  final NovaKillStage killStage;
  final NovaThreatSource lastThreatSource;
  final String lastReason;

  final int escalationScore;
  final int userDrivenRiskScore;
  final int aiDrivenRiskScore;
  final int tamperRiskScore;
  final int quarantineCount;
  final int hardKillCount;
  final int revivalBlockCount;
  final int finalContainmentCount;

  final DateTime updatedAt;
  final List<NovaSecurityEvent> recentEvents;

  const NovaSecurityState({
    required this.allowRuntime,
    required this.runtimeBlocked,
    required this.bootAllowed,
    required this.aiRequestsAllowed,
    required this.learningAllowed,
    required this.apiLearningAllowed,
    required this.nativeBridgeAllowed,
    required this.backgroundRuntimeAllowed,
    required this.killStage,
    required this.lastThreatSource,
    required this.lastReason,
    required this.escalationScore,
    required this.userDrivenRiskScore,
    required this.aiDrivenRiskScore,
    required this.tamperRiskScore,
    required this.quarantineCount,
    required this.hardKillCount,
    required this.revivalBlockCount,
    required this.finalContainmentCount,
    required this.updatedAt,
    required this.recentEvents,
  });

  factory NovaSecurityState.initial() {
    return NovaSecurityState(
      allowRuntime: true,
      runtimeBlocked: false,
      bootAllowed: true,
      aiRequestsAllowed: true,
      learningAllowed: true,
      apiLearningAllowed: true,
      nativeBridgeAllowed: true,
      backgroundRuntimeAllowed: true,
      killStage: NovaKillStage.none,
      lastThreatSource: NovaThreatSource.none,
      lastReason: '',
      escalationScore: 0,
      userDrivenRiskScore: 0,
      aiDrivenRiskScore: 0,
      tamperRiskScore: 0,
      quarantineCount: 0,
      hardKillCount: 0,
      revivalBlockCount: 0,
      finalContainmentCount: 0,
      updatedAt: DateTime.now(),
      recentEvents: const <NovaSecurityEvent>[],
    );
  }

  NovaSecurityState copyWith({
    bool? allowRuntime,
    bool? runtimeBlocked,
    bool? bootAllowed,
    bool? aiRequestsAllowed,
    bool? learningAllowed,
    bool? apiLearningAllowed,
    bool? nativeBridgeAllowed,
    bool? backgroundRuntimeAllowed,
    NovaKillStage? killStage,
    NovaThreatSource? lastThreatSource,
    String? lastReason,
    int? escalationScore,
    int? userDrivenRiskScore,
    int? aiDrivenRiskScore,
    int? tamperRiskScore,
    int? quarantineCount,
    int? hardKillCount,
    int? revivalBlockCount,
    int? finalContainmentCount,
    DateTime? updatedAt,
    List<NovaSecurityEvent>? recentEvents,
  }) {
    return NovaSecurityState(
      allowRuntime: allowRuntime ?? this.allowRuntime,
      runtimeBlocked: runtimeBlocked ?? this.runtimeBlocked,
      bootAllowed: bootAllowed ?? this.bootAllowed,
      aiRequestsAllowed: aiRequestsAllowed ?? this.aiRequestsAllowed,
      learningAllowed: learningAllowed ?? this.learningAllowed,
      apiLearningAllowed: apiLearningAllowed ?? this.apiLearningAllowed,
      nativeBridgeAllowed: nativeBridgeAllowed ?? this.nativeBridgeAllowed,
      backgroundRuntimeAllowed:
          backgroundRuntimeAllowed ?? this.backgroundRuntimeAllowed,
      killStage: killStage ?? this.killStage,
      lastThreatSource: lastThreatSource ?? this.lastThreatSource,
      lastReason: lastReason ?? this.lastReason,
      escalationScore: escalationScore ?? this.escalationScore,
      userDrivenRiskScore: userDrivenRiskScore ?? this.userDrivenRiskScore,
      aiDrivenRiskScore: aiDrivenRiskScore ?? this.aiDrivenRiskScore,
      tamperRiskScore: tamperRiskScore ?? this.tamperRiskScore,
      quarantineCount: quarantineCount ?? this.quarantineCount,
      hardKillCount: hardKillCount ?? this.hardKillCount,
      revivalBlockCount: revivalBlockCount ?? this.revivalBlockCount,
      finalContainmentCount:
          finalContainmentCount ?? this.finalContainmentCount,
      updatedAt: updatedAt ?? this.updatedAt,
      recentEvents: recentEvents ?? this.recentEvents,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'allowRuntime': allowRuntime,
      'runtimeBlocked': runtimeBlocked,
      'bootAllowed': bootAllowed,
      'aiRequestsAllowed': aiRequestsAllowed,
      'learningAllowed': learningAllowed,
      'apiLearningAllowed': apiLearningAllowed,
      'nativeBridgeAllowed': nativeBridgeAllowed,
      'backgroundRuntimeAllowed': backgroundRuntimeAllowed,
      'killStage': killStage.key,
      'lastThreatSource': lastThreatSource.key,
      'lastReason': lastReason,
      'escalationScore': escalationScore,
      'userDrivenRiskScore': userDrivenRiskScore,
      'aiDrivenRiskScore': aiDrivenRiskScore,
      'tamperRiskScore': tamperRiskScore,
      'quarantineCount': quarantineCount,
      'hardKillCount': hardKillCount,
      'revivalBlockCount': revivalBlockCount,
      'finalContainmentCount': finalContainmentCount,
      'updatedAt': updatedAt.toIso8601String(),
      'recentEvents': recentEvents
          .map((e) => e.toMap())
          .toList(growable: false),
    };
  }

  factory NovaSecurityState.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();

    final rawEvents = (map['recentEvents'] as List?) ?? const <dynamic>[];

    return NovaSecurityState(
      allowRuntime: map['allowRuntime'] as bool? ?? true,
      runtimeBlocked: map['runtimeBlocked'] as bool? ?? false,
      bootAllowed: map['bootAllowed'] as bool? ?? true,
      aiRequestsAllowed: map['aiRequestsAllowed'] as bool? ?? true,
      learningAllowed: map['learningAllowed'] as bool? ?? true,
      apiLearningAllowed: map['apiLearningAllowed'] as bool? ?? true,
      nativeBridgeAllowed: map['nativeBridgeAllowed'] as bool? ?? true,
      backgroundRuntimeAllowed:
          map['backgroundRuntimeAllowed'] as bool? ?? true,
      killStage: NovaKillStageX.fromKey(map['killStage'] as String?),
      lastThreatSource: NovaThreatSourceX.fromKey(
        map['lastThreatSource'] as String?,
      ),
      lastReason: (map['lastReason'] as String? ?? '').trim(),
      escalationScore: (map['escalationScore'] as int? ?? 0).clamp(0, 100000),
      userDrivenRiskScore: (map['userDrivenRiskScore'] as int? ?? 0).clamp(
        0,
        100000,
      ),
      aiDrivenRiskScore: (map['aiDrivenRiskScore'] as int? ?? 0).clamp(
        0,
        100000,
      ),
      tamperRiskScore: (map['tamperRiskScore'] as int? ?? 0).clamp(0, 100000),
      quarantineCount: (map['quarantineCount'] as int? ?? 0).clamp(0, 100000),
      hardKillCount: (map['hardKillCount'] as int? ?? 0).clamp(0, 100000),
      revivalBlockCount: (map['revivalBlockCount'] as int? ?? 0).clamp(
        0,
        100000,
      ),
      finalContainmentCount: (map['finalContainmentCount'] as int? ?? 0).clamp(
        0,
        100000,
      ),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? now,
      recentEvents: rawEvents
          .whereType<Map>()
          .map(
            (e) =>
                NovaSecurityEvent.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList(growable: false),
    );
  }
}
