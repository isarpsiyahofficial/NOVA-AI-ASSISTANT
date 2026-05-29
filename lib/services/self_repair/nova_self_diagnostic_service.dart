// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/self_repair/nova_capability_descriptor.dart';
import '../../core/runtime/nova_runtime_signal.dart';
import '../../core/self_repair/nova_system_issue.dart';
import 'nova_runtime_signal_service.dart';
import 'nova_self_recognition_service.dart';

class NovaSelfDiagnosticService {
  final NovaRuntimeSignalService signalService;
  final NovaSelfRecognitionService recognitionService;

  const NovaSelfDiagnosticService({
    required this.signalService,
    required this.recognitionService,
  });

  Future<void> resolveIssueSignals(NovaSystemIssue issue) async {
    final ids = issue.relatedSignalIds
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toSet();

    if (ids.isNotEmpty) {
      await signalService.clearByIds(ids);
    }
  }

  Future<List<NovaSystemIssue>> diagnose() async {
    final signals = (await signalService.getAll())
        .where((signal) => !_isNonIssueSignal(signal))
        .where(
          (signal) =>
              signal.level == NovaRuntimeSignalLevel.warning ||
              signal.level == NovaRuntimeSignalLevel.error ||
              signal.level == NovaRuntimeSignalLevel.critical,
        )
        .toList(growable: false);
    final descriptors = await recognitionService.discoverCapabilities();
    final List<NovaSystemIssue> issues = <NovaSystemIssue>[];

    for (final descriptor in descriptors) {
      final relatedSignals = signals
          .where(
            (e) =>
                descriptor.signalCodes.contains(e.code) ||
                _belongsToDescriptor(e, descriptor),
          )
          .toList(growable: false);
      if (relatedSignals.isEmpty) continue;
      relatedSignals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final latest = relatedSignals.first;
      issues.add(
        NovaSystemIssue(
          issueId: '${descriptor.capabilityId}_${latest.code}',
          capabilityId: descriptor.capabilityId,
          title: descriptor.title,
          humanMessage: latest.message,
          technicalMessage: latest.technicalDetails.isEmpty
              ? latest.code
              : latest.technicalDetails,
          suggestedAction: _suggestedActionFor(descriptor, latest),
          canSelfHeal:
              descriptor.selfRepairAllowed && latest.diagnosticCandidate,
          canRequestOwnerPatch: descriptor.ownerPatchAllowed,
          status: NovaSystemIssueStatus.open,
          createdAt: latest.createdAt,
          updatedAt: latest.createdAt,
          relatedSignalIds: relatedSignals
              .map((e) => e.id)
              .toList(growable: false),
        ),
      );
    }

    issues.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return issues;
  }

  bool _belongsToDescriptor(
    NovaRuntimeSignal signal,
    NovaCapabilityDescriptor descriptor,
  ) {
    switch (descriptor.capabilityId) {
      case 'voice_identity':
        return signal.kind == NovaRuntimeSignalKind.voiceIdentity ||
            signal.kind == NovaRuntimeSignalKind.authorization;
      case 'listening_runtime':
        return signal.kind == NovaRuntimeSignalKind.stt ||
            signal.kind == NovaRuntimeSignalKind.tts ||
            signal.kind == NovaRuntimeSignalKind.background;
      case 'call_companion':
        return signal.kind == NovaRuntimeSignalKind.call ||
            signal.kind == NovaRuntimeSignalKind.callCompanion;
      case 'ai_response':
        if (signal.code.startsWith('setup_') ||
            signal.code.startsWith('brain_kernel_')) {
          return false;
        }
        return signal.kind == NovaRuntimeSignalKind.ai ||
            signal.kind == NovaRuntimeSignalKind.localModel ||
            signal.kind == NovaRuntimeSignalKind.api;
      case 'dialogue_runtime':
        return signal.kind == NovaRuntimeSignalKind.ai ||
            signal.kind == NovaRuntimeSignalKind.stt;
      case 'speaker_priority_runtime':
        return signal.kind == NovaRuntimeSignalKind.voiceIdentity ||
            signal.kind == NovaRuntimeSignalKind.authorization ||
            signal.kind == NovaRuntimeSignalKind.stt;
      case 'family_contacts_runtime':
        return signal.kind == NovaRuntimeSignalKind.contacts ||
            signal.kind == NovaRuntimeSignalKind.callCompanion ||
            signal.kind == NovaRuntimeSignalKind.call;
      default:
        return false;
    }
  }

  bool _isNonIssueSignal(NovaRuntimeSignal signal) {
    final code = signal.code.toLowerCase().trim();
    final message = signal.message.toLowerCase().trim();
    final joined = '$code $message';
    if (code == 'authorization_blocked_during_synthetic_playback') {
      return true;
    }
    const healthyTokens = <String>[
      'healthy',
      'ready',
      'verified',
      'ok',
      'running',
      'available',
      'success',
      'resolved',
      'çalışıyor',
      'calisiyor',
      'hazır',
      'hazir',
      'doğrulandı',
      'dogrulandi',
      'aktif',
      'uygun',
    ];
    final looksHealthy = healthyTokens.any(joined.contains);
    final looksBroken =
        joined.contains('fail') ||
        joined.contains('failed') ||
        joined.contains('degraded') ||
        joined.contains('blocked') ||
        joined.contains('timeout') ||
        joined.contains('error') ||
        joined.contains('hata') ||
        joined.contains('başarısız') ||
        joined.contains('basarisiz') ||
        joined.contains('engellendi') ||
        joined.contains('zaman aşımı') ||
        joined.contains('zaman asimi');
    if (signal.level == NovaRuntimeSignalLevel.info) return true;
    if (looksHealthy && !looksBroken) return true;
    return false;
  }

  String _suggestedActionFor(
    NovaCapabilityDescriptor descriptor,
    NovaRuntimeSignal signal,
  ) {
    if (descriptor.selfRepairAllowed && signal.diagnosticCandidate) {
      return 'Otomatik onarım denenebilir.';
    }
    return 'Sorun sahibine doğal dilde açıklanmalı ve gerekirse owner patch alanına yönlendirilmeli.';
  }
}
