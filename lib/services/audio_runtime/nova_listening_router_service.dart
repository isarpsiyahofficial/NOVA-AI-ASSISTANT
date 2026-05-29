// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/audio_runtime/nova_listening_mode.dart';
import '../../core/voice_clone/voice_clone_source_type.dart';
import '../call/nova_call_state_service.dart';
import '../call_companion/nova_call_companion_runtime_service.dart';
import '../system/nova_lifecycle_service.dart';
import '../system/nova_power_service.dart';

enum NovaListeningRoute {
  blockedByShutdown,
  passiveSleep,
  normalListening,
  ringingCall,
  activeCall,
  companionOwnsCall,
}

class NovaListeningRouteDecision {
  final NovaListeningRoute route;
  final String message;
  const NovaListeningRouteDecision({
    required this.route,
    required this.message,
  });
  bool get shouldIgnoreNormalPrompt =>
      route == NovaListeningRoute.blockedByShutdown ||
      route == NovaListeningRoute.companionOwnsCall;
}

class NovaListeningRouterService {
  final NovaPowerService powerService;
  final NovaLifecycleService lifecycleService;
  final NovaCallStateService? callStateService;
  final NovaCallCompanionRuntimeService? companionRuntime;

  const NovaListeningRouterService({
    required this.powerService,
    required this.lifecycleService,
    this.callStateService,
    this.companionRuntime,
  });

  Future<NovaListeningRouteDecision> resolve() async {
    if (powerService.isFullyShutdown)
      return const NovaListeningRouteDecision(
        route: NovaListeningRoute.blockedByShutdown,
        message: 'Nova tamamen kapalı durumda.',
      );
    if (companionRuntime?.isActive == true)
      return const NovaListeningRouteDecision(
        route: NovaListeningRoute.companionOwnsCall,
        message: 'Aktif çağrı companion tarafından yönetiliyor.',
      );
    if (callStateService != null) {
      final snapshot = await callStateService!.getSnapshot();
      if (snapshot.isRinging)
        return const NovaListeningRouteDecision(
          route: NovaListeningRoute.ringingCall,
          message: 'Gelen çağrı algılandı.',
        );
      if (snapshot.isActiveCall)
        return const NovaListeningRouteDecision(
          route: NovaListeningRoute.activeCall,
          message: 'Aktif çağrı devam ediyor.',
        );
    }
    if (powerService.isPassiveSleep ||
        powerService.isLimbo ||
        lifecycleService.isSleeping)
      return const NovaListeningRouteDecision(
        route: NovaListeningRoute.passiveSleep,
        message: 'Nova pasif beklemede.',
      );
    return const NovaListeningRouteDecision(
      route: NovaListeningRoute.normalListening,
      message: 'Normal dinleme aktif.',
    );
  }

  Future<NovaListeningMode> resolveNormalListeningMode() async {
    final decision = await resolve();
    switch (decision.route) {
      case NovaListeningRoute.blockedByShutdown:
        return NovaListeningMode.fullyShutdown;
      case NovaListeningRoute.passiveSleep:
        return NovaListeningMode.wakeOnlyListening;
      case NovaListeningRoute.normalListening:
        return NovaListeningMode.normalCommandListening;
      case NovaListeningRoute.ringingCall:
      case NovaListeningRoute.activeCall:
      case NovaListeningRoute.companionOwnsCall:
        return NovaListeningMode.callCompanionListening;
    }
  }

  Future<NovaListeningMode> resolveCloneListeningMode(
    VoiceCloneSourceType sourceType,
  ) async {
    final decision = await resolve();
    if (decision.route == NovaListeningRoute.blockedByShutdown) {
      return NovaListeningMode.fullyShutdown;
    }
    return sourceType == VoiceCloneSourceType.internalPhoneAudio
        ? NovaListeningMode.internalAudioCloneListening
        : NovaListeningMode.externalCloneListening;
  }

  bool isCloneSpecificListening(NovaListeningMode mode) {
    return mode == NovaListeningMode.externalCloneListening ||
        mode == NovaListeningMode.internalAudioCloneListening ||
        mode == NovaListeningMode.cloneListeningExternal ||
        mode == NovaListeningMode.cloneListeningInternal;
  }

  String denyReasonForCloneBlocked(VoiceCloneSourceType sourceType) {
    if (powerService.isFullyShutdown)
      return 'Nova tamamen kapalı olduğu için klon dinleme engellendi.';
    if (companionRuntime?.isActive == true)
      return 'Çağrı companion aktifken klon dinleme başlatılamaz.';
    return sourceType == VoiceCloneSourceType.internalPhoneAudio
        ? 'Telefon içi klon dinleme şu anda uygun değil.'
        : 'Harici klon dinleme şu anda uygun değil.';
  }
}
