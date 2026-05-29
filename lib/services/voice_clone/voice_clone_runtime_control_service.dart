// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/voice_clone/voice_clone_runtime_state.dart';
import '../audio_runtime/nova_native_audio_bridge_service.dart';
import '../system/nova_overlay_bridge_service.dart';

class VoiceCloneRuntimeControlService extends ChangeNotifier {
  final NovaNativeAudioBridgeService nativeAudioBridgeService;
  final NovaOverlayBridgeService overlayBridgeService;

  VoiceCloneRuntimeControlService({
    required this.nativeAudioBridgeService,
    required this.overlayBridgeService,
  });

  VoiceCloneRuntimeState _state = const VoiceCloneRuntimeState.idle();
  Timer? _idleResetTimer;

  VoiceCloneRuntimeState get state => _state;

  bool get isRunning =>
      _state.status == VoiceCloneRuntimeStatus.preparing ||
      _state.status == VoiceCloneRuntimeStatus.listeningExternal ||
      _state.status == VoiceCloneRuntimeStatus.listeningInternal ||
      _state.status == VoiceCloneRuntimeStatus.cleaningAudio ||
      _state.status == VoiceCloneRuntimeStatus.creatingClone;

  void _pushOverlay() {
    final progress = _state.progress.clamp(0.0, 1.0);

    if (_state.status == VoiceCloneRuntimeStatus.idle) {
      overlayBridgeService.hideCloneOverlayProgress();
      return;
    }

    final shouldIndeterminate =
        _state.status == VoiceCloneRuntimeStatus.preparing ||
        _state.status == VoiceCloneRuntimeStatus.listeningExternal ||
        _state.status == VoiceCloneRuntimeStatus.listeningInternal;

    overlayBridgeService.showCloneOverlayProgress(
      title: 'Asistan Klonu',
      status: _state.message,
      progress: shouldIndeterminate ? -1.0 : progress,
    );
  }

  void setState(VoiceCloneRuntimeState value) {
    _idleResetTimer?.cancel();
    _state = value;
    notifyListeners();
    _pushOverlay();
    if (value.status == VoiceCloneRuntimeStatus.completed ||
        value.status == VoiceCloneRuntimeStatus.failed ||
        value.status == VoiceCloneRuntimeStatus.cancelled) {
      _idleResetTimer = Timer(const Duration(seconds: 3), resetToIdle);
    }
  }

  Future<void> forceStopCloneRuntime() async {
    _idleResetTimer?.cancel();
    try {
      await nativeAudioBridgeService.clearInternalAudioCapturePermission();
    } catch (_) {}

    _state = const VoiceCloneRuntimeState(
      status: VoiceCloneRuntimeStatus.cancelled,
      message: 'Klon işlemi durduruldu efendim.',
      progress: 0.0,
      activeJobId: '',
    );
    notifyListeners();
    _pushOverlay();
  }

  void resetToIdle() {
    _idleResetTimer?.cancel();
    _state = const VoiceCloneRuntimeState.idle();
    notifyListeners();
    _pushOverlay();
  }

  void markPreparing(String jobId) {
    _state = VoiceCloneRuntimeState(
      status: VoiceCloneRuntimeStatus.preparing,
      message: 'Klon işlemi hazırlanıyor efendim.',
      progress: 0.10,
      activeJobId: jobId,
    );
    notifyListeners();
    _pushOverlay();
  }

  void markListeningExternal(String jobId) {
    _state = VoiceCloneRuntimeState(
      status: VoiceCloneRuntimeStatus.listeningExternal,
      message: 'Dış sesten örnek dinleniyor efendim.',
      progress: 0.30,
      activeJobId: jobId,
    );
    notifyListeners();
    _pushOverlay();
  }

  void markListeningInternal(String jobId) {
    _state = VoiceCloneRuntimeState(
      status: VoiceCloneRuntimeStatus.listeningInternal,
      message: 'Telefon içi sesten örnek dinleniyor efendim.',
      progress: 0.30,
      activeJobId: jobId,
    );
    notifyListeners();
    _pushOverlay();
  }

  void markCleaningAudio(String jobId) {
    _state = VoiceCloneRuntimeState(
      status: VoiceCloneRuntimeStatus.cleaningAudio,
      message: 'Ses temizleniyor ve hedef ton ayrıştırılıyor efendim.',
      progress: 0.60,
      activeJobId: jobId,
    );
    notifyListeners();
    _pushOverlay();
  }

  void markCreatingClone(String jobId) {
    _state = VoiceCloneRuntimeState(
      status: VoiceCloneRuntimeStatus.creatingClone,
      message: 'Klon ses oluşturuluyor efendim.',
      progress: 0.85,
      activeJobId: jobId,
    );
    notifyListeners();
    _pushOverlay();
  }

  void markCompleted(String jobId) {
    _state = VoiceCloneRuntimeState(
      status: VoiceCloneRuntimeStatus.completed,
      message: 'Klon işlemi tamamlandı efendim.',
      progress: 1.0,
      activeJobId: jobId,
    );
    notifyListeners();
    _pushOverlay();
  }

  void markFailed(String jobId, String message) {
    _state = VoiceCloneRuntimeState(
      status: VoiceCloneRuntimeStatus.failed,
      message: message,
      progress: 0.0,
      activeJobId: jobId,
    );
    notifyListeners();
    _pushOverlay();
  }
}
