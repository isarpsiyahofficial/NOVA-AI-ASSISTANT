// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// GEMMA95952_SAFE_SELF_REPAIR_KERNEL
import '../../core/self_repair/nova_repair_manifest.dart';
import '../../core/runtime/nova_runtime_signal.dart';
import 'nova_boot_doctor_service.dart';

class NovaFaultClassification {
  final NovaRepairFaultType faultType;
  final NovaRepairTargetPolicy targetPolicy;
  final NovaRepairRiskLevel riskLevel;
  final int repeatCount;
  final String reason;
  final bool repairCandidate;

  const NovaFaultClassification({
    required this.faultType,
    required this.targetPolicy,
    required this.riskLevel,
    required this.repeatCount,
    required this.reason,
    required this.repairCandidate,
  });
}

class NovaFaultClassifierService {
  const NovaFaultClassifierService();

  NovaFaultClassification classify({
    required List<NovaRuntimeSignal> signals,
    required NovaBootDoctorReport bootReport,
  }) {
    final recent = signals.take(80).toList(growable: false);

    if (!bootReport.localModelReady) {
      return NovaFaultClassification(
        faultType: NovaRepairFaultType.modelNotReady,
        targetPolicy: NovaRepairTargetPolicy.modelRetryPolicy,
        riskLevel: NovaRepairRiskLevel.green,
        repeatCount: _atLeast(
          _countMatching(recent, const <String>[
            'model',
            'local_model',
            'timeout',
            'hazır değil',
            'not ready',
          ]),
          2,
        ),
        reason: bootReport.localModelMessage,
        repairCandidate: true,
      );
    }

    if (bootReport.hasNativeChannelSuspicion) {
      return NovaFaultClassification(
        faultType: NovaRepairFaultType.nativeChannelFail,
        targetPolicy: NovaRepairTargetPolicy.none,
        riskLevel: NovaRepairRiskLevel.red,
        repeatCount: _countMatching(recent, const <String>[
          'native',
          'methodchannel',
          'channel',
          'bridge',
        ]),
        reason:
            'Native/channel sinyali read-only kırmızı bölgeye işaret ediyor.',
        repairCandidate: false,
      );
    }

    final asrRouteCount = _countMatching(recent, const <String>[
      'transcript_not_routed',
      'not_routed',
      'singlebrain',
      'single_brain',
    ]);
    if (asrRouteCount >= 2 || bootReport.hasSingleBrainRouteSuspicion) {
      return NovaFaultClassification(
        faultType: NovaRepairFaultType.transcriptNotRouted,
        targetPolicy: NovaRepairTargetPolicy.asrSingleBrainRoutePolicy,
        riskLevel: NovaRepairRiskLevel.yellow,
        repeatCount: asrRouteCount,
        reason:
            'ASR/transcript SingleBrain hattına güvenilir şekilde ulaşmıyor.',
        repairCandidate: true,
      );
    }

    final ttsWrongSourceCount = _countMatching(recent, const <String>[
      'tts_wrong_source',
      'wrong_source',
      'static_source',
      'fallback_contamination',
      'source=static',
    ]);
    if (ttsWrongSourceCount >= 2) {
      return NovaFaultClassification(
        faultType: NovaRepairFaultType.ttsWrongSource,
        targetPolicy: NovaRepairTargetPolicy.ttsSourcePolicy,
        riskLevel: NovaRepairRiskLevel.green,
        repeatCount: ttsWrongSourceCount,
        reason: 'TTS yanlış/static kaynaktan konuşmaya çalışıyor.',
        repairCandidate: true,
      );
    }

    final ttsNotSpeakingCount = _countMatching(recent, const <String>[
      'tts_not_speaking',
      'speech_blocked',
      'brain_decision var',
      'tts yok',
    ]);
    if (ttsNotSpeakingCount >= 2 || bootReport.hasTtsSuspicion) {
      return NovaFaultClassification(
        faultType: NovaRepairFaultType.ttsNotSpeaking,
        targetPolicy: NovaRepairTargetPolicy.ttsSourcePolicy,
        riskLevel: NovaRepairRiskLevel.green,
        repeatCount: ttsNotSpeakingCount,
        reason: 'BrainDecision/TTS konuşma bağlantısı doğrulanamıyor.',
        repairCandidate: true,
      );
    }

    final queueCount = _countMatching(recent, const <String>[
      'stale',
      'old_turn',
      'queue',
      'turn_mismatch',
    ]);
    if (queueCount >= 2) {
      return NovaFaultClassification(
        faultType: NovaRepairFaultType.queueStaleTurn,
        targetPolicy: NovaRepairTargetPolicy.queueStalePolicy,
        riskLevel: NovaRepairRiskLevel.green,
        repeatCount: queueCount,
        reason: 'Eski turn/model cevabı yeni turn ile karışıyor.',
        repairCandidate: true,
      );
    }

    final securityFalsePositiveCount = _countMatching(recent, const <String>[
      'ownerVoice setup',
      'ownervoice setup',
      'security_false_positive',
      'setup auth',
    ]);
    if (securityFalsePositiveCount >= 2) {
      return NovaFaultClassification(
        faultType: NovaRepairFaultType.securityFalsePositive,
        targetPolicy: NovaRepairTargetPolicy.setupRuntimeBoundaryPolicy,
        riskLevel: NovaRepairRiskLevel.yellow,
        repeatCount: securityFalsePositiveCount,
        reason:
            'Setup başı ownerVoice/auth false-positive olabilir; security root değişmeden boundary policy gerekir.',
        repairCandidate: true,
      );
    }

    return NovaFaultClassification(
      faultType: NovaRepairFaultType.unknown,
      targetPolicy: NovaRepairTargetPolicy.none,
      riskLevel: NovaRepairRiskLevel.red,
      repeatCount: 0,
      reason: 'Tekrarlayan, güvenli repair adayı olan fault bulunmadı.',
      repairCandidate: false,
    );
  }

  int _atLeast(int value, int minimum) => value < minimum ? minimum : value;

  int _countMatching(List<NovaRuntimeSignal> signals, List<String> tokens) {
    int count = 0;
    for (final signal in signals) {
      final text = '${signal.code} ${signal.message} ${signal.technicalDetails}'
          .toLowerCase();
      if (tokens.any((token) => text.contains(token.toLowerCase()))) {
        count += 1;
      }
    }
    return count;
  }
}
