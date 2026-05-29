// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/services.dart';

class NovaBackgroundBridgeResult {
  final bool success;
  final String message;

  const NovaBackgroundBridgeResult({
    required this.success,
    required this.message,
  });
  bool get isOverlayPermissionMissing =>
      message.toLowerCase().contains('overlay izni kapalı');
  bool get hasUsableMessage => message.trim().isNotEmpty;
}

class NovaBackgroundBridgeService {
  static const MethodChannel _channel = MethodChannel('nova/background_bridge');
  const NovaBackgroundBridgeService();
  Future<NovaBackgroundBridgeResult> startBackground() async =>
      _call('startBackground');
  Future<NovaBackgroundBridgeResult> setBackgroundRunning() async =>
      _call('setBackgroundRunning');
  Future<NovaBackgroundBridgeResult> setBackgroundSleeping() async =>
      _call('setBackgroundSleeping');
  Future<NovaBackgroundBridgeResult> setBackgroundFullyOff() async =>
      _call('setBackgroundFullyOff');
  Future<NovaBackgroundBridgeResult> showOverlayIdle() async =>
      _call('showOverlayIdle');
  Future<NovaBackgroundBridgeResult> showOverlayListening() async =>
      _call('showOverlayListening');
  Future<NovaBackgroundBridgeResult> showOverlaySpeaking() async =>
      _call('showOverlaySpeaking');
  Future<NovaBackgroundBridgeResult> showOverlaySleeping() async =>
      _call('showOverlaySleeping');
  Future<NovaBackgroundBridgeResult> hideOverlay() async =>
      _call('hideOverlay');
  Future<NovaBackgroundBridgeResult> removeOverlay() async =>
      _call('removeOverlay');
  Future<NovaBackgroundBridgeResult> isIgnoringBatteryOptimizations() async =>
      _call('isIgnoringBatteryOptimizations');
  Future<NovaBackgroundBridgeResult> openBatteryOptimizationSettings() async =>
      _call('openBatteryOptimizationSettings');
  Future<NovaBackgroundBridgeResult> openAppBatterySettings() async =>
      _call('openAppBatterySettings');
  Future<NovaBackgroundBridgeResult> _call(String method) async {
    try {
      final raw = await _channel.invokeMethod<dynamic>(method);
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        return NovaBackgroundBridgeResult(
          success: map['success'] as bool? ?? false,
          message: (map['message'] as String? ?? '').trim(),
        );
      }
      return const NovaBackgroundBridgeResult(
        success: false,
        message: 'Background bridge geçersiz yanıt verdi.',
      );
    } on PlatformException catch (e) {
      return NovaBackgroundBridgeResult(
        success: false,
        message: e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Background bridge platform hatası oluştu.',
      );
    } catch (_) {
      return const NovaBackgroundBridgeResult(
        success: false,
        message: 'Background bridge beklenmeyen hata verdi.',
      );
    }
  }
}
