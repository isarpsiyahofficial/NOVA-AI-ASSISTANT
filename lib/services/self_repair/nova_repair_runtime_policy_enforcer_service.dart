// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_const_constructors, prefer_const_literals_to_create_immutables
// GEMMA95952_SELF_REPAIR_SAFE_KERNEL_V5
import '../../core/self_repair/nova_repair_manifest.dart';
import '../../core/runtime/nova_runtime_signal.dart';
import 'nova_repair_policy_store_service.dart';
import 'nova_runtime_signal_service.dart';

class NovaRepairRuntimePolicyEnforcerService {
  final NovaRepairPolicyStoreService policyStoreService;
  final NovaRuntimeSignalService? _runtimeSignalService;

  static final NovaRepairRuntimePolicyEnforcerService instance =
      NovaRepairRuntimePolicyEnforcerService._internal();

  static bool _loaded = false;
  static bool _strictTtsAuthority = false;
  static bool _blockFallbackStaticSpeech = false;
  static bool _forceAsrTranscriptToSingleBrain = false;
  static bool _modelRecoveryPolicyActive = false;
  static bool _setupRuntimeBoundaryPolicyActive = false;

  NovaRepairRuntimePolicyEnforcerService._internal()
    : policyStoreService = const NovaRepairPolicyStoreService(),
      _runtimeSignalService = null;

  const NovaRepairRuntimePolicyEnforcerService({
    this.policyStoreService = const NovaRepairPolicyStoreService(),
    NovaRuntimeSignalService? runtimeSignalService,
  }) : _runtimeSignalService = runtimeSignalService;

  NovaRuntimeSignalService get runtimeSignalService =>
      _runtimeSignalService ?? NovaRuntimeSignalService.instance;

  bool get loaded => _loaded;
  bool get strictTtsAuthority => _strictTtsAuthority;
  bool get blockFallbackStaticSpeech => _blockFallbackStaticSpeech;
  bool get forceAsrTranscriptToSingleBrain => _forceAsrTranscriptToSingleBrain;
  bool get modelRecoveryPolicyActive => _modelRecoveryPolicyActive;
  bool get setupRuntimeBoundaryPolicyActive =>
      _setupRuntimeBoundaryPolicyActive;

  Future<void> refresh() async {
    final all = await policyStoreService.loadAll();
    _strictTtsAuthority = _contains(
      all[NovaRepairTargetPolicy.ttsSourcePolicy.key]?.activeValue,
      const <String>['brain_decision', 'authority_only', 'single_brain'],
    );
    _blockFallbackStaticSpeech = _contains(
      all[NovaRepairTargetPolicy.fallbackSpeechPolicy.key]?.activeValue,
      const <String>['no_static_speech', 'status_only', 'fallback_status'],
    );
    _forceAsrTranscriptToSingleBrain = _contains(
      all[NovaRepairTargetPolicy.asrSingleBrainRoutePolicy.key]?.activeValue,
      const <String>['single_brain', 'transcript_to_single_brain', 'required'],
    );
    _modelRecoveryPolicyActive = _contains(
      all[NovaRepairTargetPolicy.modelRetryPolicy.key]?.activeValue,
      const <String>['retry', 'recovery', 'bounded'],
    );
    _setupRuntimeBoundaryPolicyActive = _contains(
      all[NovaRepairTargetPolicy.setupRuntimeBoundaryPolicy.key]?.activeValue,
      const <String>['setup_phase', 'boundary', 'owner_auth'],
    );
    _loaded = true;
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await refresh();
  }

  Future<void> recordConsumerSignal({
    required NovaRepairTargetPolicy targetPolicy,
    required NovaRuntimeSignalKind kind,
    required String code,
    required String message,
    String technicalDetails = '',
  }) async {
    await runtimeSignalService.record(
      kind: kind,
      level: NovaRuntimeSignalLevel.info,
      code: code,
      message: message,
      technicalDetails: technicalDetails,
      diagnosticCandidate: false,
      metadata: <String, dynamic>{
        'source': 'repair_runtime_policy_consumer',
        'targetPolicy': targetPolicy.key,
      },
    );
  }

  bool _contains(String? raw, List<String> tokens) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value.isEmpty ||
        value == NovaRepairPolicyStoreService.rejectedSecurityValue) {
      return false;
    }
    return tokens.any(value.contains);
  }
}
