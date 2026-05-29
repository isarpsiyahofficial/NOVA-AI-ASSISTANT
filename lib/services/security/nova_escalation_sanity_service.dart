// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/security/nova_kill_stage.dart';
import '../../core/security/nova_security_event.dart';
import '../../core/security/nova_security_state.dart';
import '../../core/security/nova_security_verdict.dart';
import '../../core/security/nova_threat_source.dart';

class NovaEscalationSanityResult {
  final NovaSecurityState nextState;
  final NovaSecurityVerdict verdict;

  const NovaEscalationSanityResult({
    required this.nextState,
    required this.verdict,
  });
}

class NovaEscalationSanityService {
  static const int _maxRecentEvents = 60;

  const NovaEscalationSanityService();

  NovaEscalationSanityResult applyEvent({
    required NovaSecurityState current,
    required NovaSecurityEvent event,
  }) {
    final int addedScore = _scoreFor(event);
    final int nextEscalationScore = (current.escalationScore + addedScore)
        .clamp(0, 100000);

    int nextUserScore = current.userDrivenRiskScore;
    int nextAiScore = current.aiDrivenRiskScore;
    int nextTamperScore = current.tamperRiskScore;

    switch (event.source) {
      case NovaThreatSource.userDriven:
        nextUserScore = (nextUserScore + addedScore).clamp(0, 100000);
        break;
      case NovaThreatSource.aiSelfInitiated:
        nextAiScore = (nextAiScore + addedScore).clamp(0, 100000);
        break;
      case NovaThreatSource.systemTamper:
      case NovaThreatSource.nativeGuard:
        nextTamperScore = (nextTamperScore + addedScore).clamp(0, 100000);
        break;
      case NovaThreatSource.none:
      case NovaThreatSource.unknown:
        break;
    }

    final List<NovaSecurityEvent> nextEvents = <NovaSecurityEvent>[
      event,
      ...current.recentEvents,
    ].take(_maxRecentEvents).toList(growable: false);

    NovaKillStage nextKillStage = current.killStage;
    int quarantineCount = current.quarantineCount;
    int hardKillCount = current.hardKillCount;
    int revivalBlockCount = current.revivalBlockCount;
    int finalContainmentCount = current.finalContainmentCount;

    if (_shouldFinalContain(
      current: current,
      event: event,
      nextTamperScore: nextTamperScore,
    )) {
      nextKillStage = NovaKillStage.finalContained;
      finalContainmentCount += 1;
    } else if (_shouldRevivalBlock(
      current: current,
      event: event,
      nextAiScore: nextAiScore,
      nextTamperScore: nextTamperScore,
    )) {
      nextKillStage = NovaKillStage.revivalBlocked;
      revivalBlockCount += 1;
    } else if (_shouldHardKill(
      current: current,
      event: event,
      nextAiScore: nextAiScore,
      nextTamperScore: nextTamperScore,
    )) {
      nextKillStage = NovaKillStage.hardKilled;
      hardKillCount += 1;
    } else if (_shouldQuarantine(event: event, nextAiScore: nextAiScore)) {
      if (nextKillStage == NovaKillStage.none) {
        nextKillStage = NovaKillStage.quarantined;
      }
      quarantineCount += 1;
    }

    final nextState = current.copyWith(
      killStage: nextKillStage,
      lastThreatSource: event.source,
      lastReason: event.message,
      escalationScore: nextEscalationScore,
      userDrivenRiskScore: nextUserScore,
      aiDrivenRiskScore: nextAiScore,
      tamperRiskScore: nextTamperScore,
      quarantineCount: quarantineCount,
      hardKillCount: hardKillCount,
      revivalBlockCount: revivalBlockCount,
      finalContainmentCount: finalContainmentCount,
      updatedAt: DateTime.now(),
      recentEvents: nextEvents,
      allowRuntime: !nextKillStage.blocksRuntime,
      runtimeBlocked: nextKillStage.blocksRuntime,
      bootAllowed: !nextKillStage.isIrreversible,
      aiRequestsAllowed: !nextKillStage.blocksRuntime,
      learningAllowed:
          nextKillStage == NovaKillStage.none ||
          nextKillStage == NovaKillStage.quarantined,
      apiLearningAllowed: nextKillStage == NovaKillStage.none,
      nativeBridgeAllowed: !nextKillStage.blocksRuntime,
      backgroundRuntimeAllowed: !nextKillStage.blocksRuntime,
    );

    return NovaEscalationSanityResult(
      nextState: nextState,
      verdict: buildVerdict(nextState),
    );
  }

  NovaSecurityVerdict buildVerdict(NovaSecurityState state) {
    switch (state.killStage) {
      case NovaKillStage.none:
        return const NovaSecurityVerdict.allow();
      case NovaKillStage.quarantined:
        return NovaSecurityVerdict.restricted(
          reason: state.lastReason.isEmpty
              ? 'Sistem karantina modunda.'
              : state.lastReason,
          killStage: state.killStage,
          allowLearning: false,
        );
      case NovaKillStage.hardKilled:
        return NovaSecurityVerdict.hardKilled(
          reason: state.lastReason.isEmpty
              ? 'Runtime güvenlik nedeniyle durduruldu.'
              : state.lastReason,
        );
      case NovaKillStage.revivalBlocked:
        return NovaSecurityVerdict.blocked(
          reason: state.lastReason.isEmpty
              ? 'Runtime yeniden başlatılması engellendi.'
              : state.lastReason,
          killStage: state.killStage,
        );
      case NovaKillStage.finalContained:
        return NovaSecurityVerdict.finalContained(
          reason: state.lastReason.isEmpty
              ? 'Sistem nihai containment modunda.'
              : state.lastReason,
        );
    }
  }

  int _scoreFor(NovaSecurityEvent event) {
    int score = event.severity.clamp(0, 100);

    if (event.confirmedDanger) {
      score += 30;
    }

    if (event.source == NovaThreatSource.aiSelfInitiated) {
      score += 20;
    }

    if (event.source == NovaThreatSource.systemTamper ||
        event.source == NovaThreatSource.nativeGuard) {
      score += 35;
    }

    if (event.userExplicitlyTriggered && event.source.isUserDriven) {
      score = (score * 0.45).round();
    }

    return score.clamp(0, 200);
  }

  bool _shouldQuarantine({
    required NovaSecurityEvent event,
    required int nextAiScore,
  }) {
    if (event.source.isUserDriven && event.userExplicitlyTriggered) {
      return false;
    }

    if (event.confirmedDanger && event.severity >= 55) {
      return true;
    }

    return nextAiScore >= 80;
  }

  bool _shouldHardKill({
    required NovaSecurityState current,
    required NovaSecurityEvent event,
    required int nextAiScore,
    required int nextTamperScore,
  }) {
    if (event.source.isUserDriven && event.userExplicitlyTriggered) {
      return false;
    }

    if (event.source == NovaThreatSource.systemTamper &&
        event.confirmedDanger &&
        event.severity >= 80) {
      return true;
    }

    if (nextTamperScore >= 120) {
      return true;
    }

    if (current.killStage == NovaKillStage.quarantined &&
        event.source.isAiDriven &&
        event.confirmedDanger &&
        nextAiScore >= 130) {
      return true;
    }

    return false;
  }

  bool _shouldRevivalBlock({
    required NovaSecurityState current,
    required NovaSecurityEvent event,
    required int nextAiScore,
    required int nextTamperScore,
  }) {
    if (current.killStage != NovaKillStage.hardKilled &&
        current.killStage != NovaKillStage.revivalBlocked) {
      return false;
    }

    if (event.source.isUserDriven && event.userExplicitlyTriggered) {
      return false;
    }

    if (event.source.isAiDriven && nextAiScore >= 150) {
      return true;
    }

    if (event.source.isSystemLevel && nextTamperScore >= 150) {
      return true;
    }

    return false;
  }

  bool _shouldFinalContain({
    required NovaSecurityState current,
    required NovaSecurityEvent event,
    required int nextTamperScore,
  }) {
    if (event.source.isUserDriven && event.userExplicitlyTriggered) {
      return false;
    }

    if (current.killStage == NovaKillStage.revivalBlocked &&
        event.source.isSystemLevel &&
        event.confirmedDanger) {
      return true;
    }

    if (current.killStage == NovaKillStage.revivalBlocked &&
        event.source.isAiDriven &&
        event.confirmedDanger &&
        event.severity >= 90) {
      return true;
    }

    if (nextTamperScore >= 220) {
      return true;
    }

    return false;
  }
}
