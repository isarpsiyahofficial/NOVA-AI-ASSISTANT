// NOVA_TYPED_NATIVE_CALL_CONTROL_BRIDGE_V1
import 'package:flutter/services.dart';

import '../../core/call/nova_call_control_result.dart';

class NovaCallControlBridgeService {
  static const MethodChannel _channel = MethodChannel('nova/call_control');

  const NovaCallControlBridgeService();

  Future<NovaCallControlResult> answerRingingCall({
    String actionToken = '',
    bool localUiAction = false,
    bool companionAction = false,
    bool userInitiated = false,
    String trustedSource = '',
  }) => _call(
        'answerRingingCall',
        _authority(
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction:
              companionAction || trustedSource.trim() == 'companion',
        ),
      );

  Future<NovaCallControlResult> rejectRingingCall({
    String actionToken = '',
    bool localUiAction = false,
    bool companionAction = false,
    bool userInitiated = false,
    String trustedSource = '',
  }) => _call(
        'rejectRingingCall',
        _authority(
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction:
              companionAction || trustedSource.trim() == 'companion',
        ),
      );

  Future<NovaCallControlResult> disconnectCurrentCall({
    String actionToken = '',
    bool localUiAction = false,
    bool companionAction = false,
    bool userInitiated = false,
    String trustedSource = '',
  }) => _call(
        'disconnectCurrentCall',
        _authority(
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction:
              companionAction || trustedSource.trim() == 'companion',
        ),
      );

  Future<NovaCallControlResult> setMuted(
    bool value, {
    String actionToken = '',
    bool localUiAction = false,
    bool companionAction = false,
    bool userInitiated = false,
    String trustedSource = '',
  }) =>
      _call('setMuted', <String, dynamic>{
        'muted': value,
        ..._authority(
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction:
              companionAction || trustedSource.trim() == 'companion',
        ),
      });

  Future<NovaCallControlResult> routeToSpeaker(
    bool value, {
    String actionToken = '',
    bool localUiAction = false,
    bool companionAction = false,
    bool userInitiated = false,
    String trustedSource = '',
  }) =>
      _call('routeToSpeaker', <String, dynamic>{
        'speakerOn': value,
        ..._authority(
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction:
              companionAction || trustedSource.trim() == 'companion',
        ),
      });

  Future<NovaCallControlResult> toggleMuted({
    String actionToken = '',
    bool localUiAction = false,
    bool companionAction = false,
    bool userInitiated = false,
    String trustedSource = '',
  }) => _call(
        'toggleMuted',
        _authority(
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction:
              companionAction || trustedSource.trim() == 'companion',
        ),
      );

  Future<NovaCallControlResult> toggleSpeaker({
    String actionToken = '',
    bool localUiAction = false,
    bool companionAction = false,
    bool userInitiated = false,
    String trustedSource = '',
  }) => _call(
        'toggleSpeaker',
        _authority(
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction:
              companionAction || trustedSource.trim() == 'companion',
        ),
      );

  Future<NovaCallControlResult> toggleHold({
    String actionToken = '',
    bool localUiAction = false,
    bool companionAction = false,
    bool userInitiated = false,
    String trustedSource = '',
  }) => _call(
        'toggleHold',
        _authority(
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction:
              companionAction || trustedSource.trim() == 'companion',
        ),
      );

  Future<NovaCallControlResult> showInCallScreen() =>
      _call('showInCallScreen');

  Future<NovaCallControlResult> handOverToNova({
    String actionToken = '',
    bool localUiAction = false,
    bool companionAction = false,
    bool userInitiated = false,
    String trustedSource = '',
  }) => _call(
        'handOverToNova',
        _authority(
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction:
              companionAction || trustedSource.trim() == 'companion',
        ),
      );

  Future<NovaCallControlResult> handOverToUser({
    String actionToken = '',
    bool localUiAction = false,
    bool companionAction = false,
    bool userInitiated = false,
    String trustedSource = '',
  }) => _call(
        'handOverToUser',
        _authority(
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction:
              companionAction || trustedSource.trim() == 'companion',
        ),
      );

  Future<NovaCallControlResult> registerOwnerApprovedOutbound(
    String number, {
    String actionToken = '',
    bool localUiAction = false,
    bool companionAction = false,
  }) =>
      _call('registerOwnerApprovedOutbound', <String, dynamic>{
        'number': number.trim(),
        ..._authority(
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction: companionAction,
        ),
      });

  Future<Map<String, dynamic>> getCapabilities() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('getCapabilities');
      if (raw is Map) return Map<String, dynamic>.from(raw);
    } catch (_) {}
    return const <String, dynamic>{
      'dialerRoleHeld': false,
      'inCallServiceReady': false,
      'hasRingingCall': false,
      'hasOngoingCall': false,
      'notificationSyncReady': false,
      'speakerAvailable': false,
      'muteAvailable': false,
      'holdAvailable': false,
      'showCallUiAvailable': false,
      'message': 'Çağrı yetenekleri alınamadı.',
    };
  }

  Map<String, dynamic> _authority({
    required String actionToken,
    required bool localUiAction,
    required bool companionAction,
  }) =>
      <String, dynamic>{
        if (actionToken.trim().isNotEmpty) 'actionToken': actionToken.trim(),
        'localUiAction': localUiAction,
        'companionAction': companionAction,
      };

  Future<NovaCallControlResult> _call(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    try {
      final raw = await _channel.invokeMethod<dynamic>(method, arguments);
      if (raw is Map) {
        return NovaCallControlResult.fromMap(Map<String, dynamic>.from(raw));
      }
      return NovaCallControlResult.failure(
        'Native çağrı kontrolü geçersiz yanıt verdi.',
      );
    } on PlatformException catch (error) {
      return NovaCallControlResult.failure(
        error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Native çağrı kontrolünde platform hatası oluştu.',
      );
    } catch (_) {
      return NovaCallControlResult.failure(
        'Native çağrı kontrolünde beklenmeyen hata oluştu.',
      );
    }
  }
}
