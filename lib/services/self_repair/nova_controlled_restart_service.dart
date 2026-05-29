// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/self_repair/nova_runtime_restart_target.dart';
import '../reminder/nova_reminder_runtime_service.dart';
import '../system/nova_background_bridge_service.dart';
import '../system/nova_continuous_listening_runtime_service.dart';
import '../tts/nova_tts_service.dart';

class NovaControlledRestartService {
  final NovaContinuousListeningRuntimeService?
  continuousListeningRuntimeService;
  final NovaBackgroundBridgeService? backgroundBridgeService;
  final NovaTtsService? ttsService;
  final NovaReminderRuntimeService? reminderRuntimeService;

  /// Host proje companion runtime'ını doğrudan bu callback ile bağlamalıdır.
  final Future<void> Function()? companionRestartAction;

  const NovaControlledRestartService({
    this.continuousListeningRuntimeService,
    this.backgroundBridgeService,
    this.ttsService,
    this.reminderRuntimeService,
    this.companionRestartAction,
  });

  Future<String> restart(Set<NovaRuntimeRestartTarget> targets) async {
    final logs = <String>[];

    if (targets.contains(NovaRuntimeRestartTarget.continuousListening) &&
        continuousListeningRuntimeService != null) {
      await continuousListeningRuntimeService!.stop();
      logs.add('Continuous listening güvenli şekilde durduruldu.');
    }

    if (targets.contains(NovaRuntimeRestartTarget.backgroundOverlay) &&
        backgroundBridgeService != null) {
      await backgroundBridgeService!.removeOverlay();
      await backgroundBridgeService!.setBackgroundSleeping();
      logs.add('Background/overlay zinciri yeniden bağlanmaya hazırlandı.');
    }

    if (targets.contains(NovaRuntimeRestartTarget.ttsStt) &&
        ttsService != null) {
      await ttsService!.stop();
      logs.add('TTS hattı temizlendi.');
    }

    if (targets.contains(NovaRuntimeRestartTarget.companion) &&
        companionRestartAction != null) {
      await companionRestartAction!.call();
      logs.add('Companion runtime yeniden bağlanmaya hazırlandı.');
    }

    if (targets.contains(NovaRuntimeRestartTarget.reminderRuntime) &&
        reminderRuntimeService != null) {
      await reminderRuntimeService!.runDueReminderCheck();
      logs.add('Reminder runtime kontrol koşusu yapıldı.');
    }

    if (logs.isEmpty) {
      return 'Seçilen restart hedefi uygulanmadı.';
    }

    return logs.join(' ');
  }
}
