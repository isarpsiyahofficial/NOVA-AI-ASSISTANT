// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// GEMMA95952_SAFE_SELF_REPAIR_KERNEL
import '../../core/runtime/nova_runtime_signal.dart';
import '../local_model/local_model_service.dart';
import 'nova_runtime_signal_service.dart';

class NovaBootDoctorReport {
  final bool localModelReady;
  final bool localModelPathPresent;
  final String localModelMessage;
  final int criticalSignalCount;
  final int warningSignalCount;
  final bool hasNativeChannelSuspicion;
  final bool hasAsrSuspicion;
  final bool hasTtsSuspicion;
  final bool hasSingleBrainRouteSuspicion;
  final DateTime checkedAt;

  const NovaBootDoctorReport({
    required this.localModelReady,
    required this.localModelPathPresent,
    required this.localModelMessage,
    required this.criticalSignalCount,
    required this.warningSignalCount,
    required this.hasNativeChannelSuspicion,
    required this.hasAsrSuspicion,
    required this.hasTtsSuspicion,
    required this.hasSingleBrainRouteSuspicion,
    required this.checkedAt,
  });

  bool get bootLooksHealthy {
    return localModelReady &&
        localModelPathPresent &&
        !hasNativeChannelSuspicion &&
        !hasSingleBrainRouteSuspicion;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'localModelReady': localModelReady,
    'localModelPathPresent': localModelPathPresent,
    'localModelMessage': localModelMessage,
    'criticalSignalCount': criticalSignalCount,
    'warningSignalCount': warningSignalCount,
    'hasNativeChannelSuspicion': hasNativeChannelSuspicion,
    'hasAsrSuspicion': hasAsrSuspicion,
    'hasTtsSuspicion': hasTtsSuspicion,
    'hasSingleBrainRouteSuspicion': hasSingleBrainRouteSuspicion,
    'checkedAt': checkedAt.toIso8601String(),
  };
}

class NovaBootDoctorService {
  final LocalModelService localModelService;
  final NovaRuntimeSignalService? _signalService;

  const NovaBootDoctorService({
    this.localModelService = const LocalModelService(),
    NovaRuntimeSignalService? signalService,
  }) : _signalService = signalService;

  NovaRuntimeSignalService get signalService =>
      _signalService ?? NovaRuntimeSignalService.instance;

  Future<NovaBootDoctorReport> inspectReadOnly() async {
    final state = await localModelService.getState();
    final signals = await signalService.getAll();
    int critical = 0;
    int warning = 0;
    bool nativeSuspect = false;
    bool asrSuspect = false;
    bool ttsSuspect = false;
    bool brainRouteSuspect = false;

    for (final signal in signals.take(80)) {
      final text = '${signal.code} ${signal.message} ${signal.technicalDetails}'
          .toLowerCase();
      if (signal.level == NovaRuntimeSignalLevel.critical) critical += 1;
      if (signal.level == NovaRuntimeSignalLevel.warning ||
          signal.level == NovaRuntimeSignalLevel.error)
        warning += 1;
      if (text.contains('native') ||
          text.contains('methodchannel') ||
          text.contains('channel') ||
          text.contains('bridge')) {
        nativeSuspect = true;
      }
      if (signal.kind == NovaRuntimeSignalKind.stt ||
          text.contains('asr') ||
          text.contains('transcript')) {
        if (signal.level != NovaRuntimeSignalLevel.info) asrSuspect = true;
      }
      if (signal.kind == NovaRuntimeSignalKind.tts ||
          text.contains('tts') ||
          text.contains('speech')) {
        if (signal.level != NovaRuntimeSignalLevel.info) ttsSuspect = true;
      }
      if (text.contains('singlebrain') ||
          text.contains('single_brain') ||
          text.contains('brain_route') ||
          text.contains('not_routed')) {
        brainRouteSuspect = true;
      }
    }

    return NovaBootDoctorReport(
      localModelReady: state.ready,
      localModelPathPresent: state.hasUsablePath,
      localModelMessage: state.normalizedMessage,
      criticalSignalCount: critical,
      warningSignalCount: warning,
      hasNativeChannelSuspicion: nativeSuspect,
      hasAsrSuspicion: asrSuspect,
      hasTtsSuspicion: ttsSuspect,
      hasSingleBrainRouteSuspicion: brainRouteSuspect,
      checkedAt: DateTime.now(),
    );
  }
}
