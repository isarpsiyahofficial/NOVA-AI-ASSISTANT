// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/services.dart';

import '../../core/call/nova_call_control_result.dart';

class NovaCallControlBridgeService {
  static const MethodChannel _channel = MethodChannel('nova/call_control');

  const NovaCallControlBridgeService();

  Future<NovaCallControlResult> answerRingingCall({
    bool userInitiated = false,
    String trustedSource = '',
  }) async {
    return _call(
      'answerRingingCall',
      _meta(userInitiated: userInitiated, trustedSource: trustedSource),
    );
  }

  Future<NovaCallControlResult> rejectRingingCall({
    bool userInitiated = false,
    String trustedSource = '',
  }) async {
    return _call(
      'rejectRingingCall',
      _meta(userInitiated: userInitiated, trustedSource: trustedSource),
    );
  }

  Future<NovaCallControlResult> disconnectCurrentCall({
    bool userInitiated = false,
    String trustedSource = '',
  }) async {
    return _call(
      'disconnectCurrentCall',
      _meta(userInitiated: userInitiated, trustedSource: trustedSource),
    );
  }

  Future<NovaCallControlResult> setMuted(
    bool value, {
    bool userInitiated = false,
    String trustedSource = '',
  }) async {
    return _call('setMuted', <String, dynamic>{
      'muted': value,
      ..._meta(userInitiated: userInitiated, trustedSource: trustedSource),
    });
  }

  Future<NovaCallControlResult> routeToSpeaker(
    bool value, {
    bool userInitiated = false,
    String trustedSource = '',
  }) async {
    return _call('routeToSpeaker', <String, dynamic>{
      'speakerOn': value,
      ..._meta(userInitiated: userInitiated, trustedSource: trustedSource),
    });
  }

  Future<NovaCallControlResult> toggleMuted({
    bool userInitiated = false,
    String trustedSource = '',
  }) async {
    return _call(
      'toggleMuted',
      _meta(userInitiated: userInitiated, trustedSource: trustedSource),
    );
  }

  Future<NovaCallControlResult> toggleSpeaker({
    bool userInitiated = false,
    String trustedSource = '',
  }) async {
    return _call(
      'toggleSpeaker',
      _meta(userInitiated: userInitiated, trustedSource: trustedSource),
    );
  }

  Future<NovaCallControlResult> toggleHold({
    bool userInitiated = false,
    String trustedSource = '',
  }) async {
    return _call(
      'toggleHold',
      _meta(userInitiated: userInitiated, trustedSource: trustedSource),
    );
  }

  Future<NovaCallControlResult> showInCallScreen() async {
    return _call('showInCallScreen');
  }

  Future<NovaCallControlResult> handOverToNova({
    bool userInitiated = false,
    String trustedSource = '',
  }) async {
    return _call(
      'handOverToNova',
      _meta(userInitiated: userInitiated, trustedSource: trustedSource),
    );
  }

  Future<NovaCallControlResult> handOverToUser({
    bool userInitiated = false,
    String trustedSource = '',
  }) async {
    return _call(
      'handOverToUser',
      _meta(userInitiated: userInitiated, trustedSource: trustedSource),
    );
  }

  Future<NovaCallControlResult> registerOwnerApprovedOutbound(
    String number,
  ) async {
    return _call('registerOwnerApprovedOutbound', <String, dynamic>{
      'number': number.trim(),
      'userInitiated': true,
    });
  }

  Future<Map<String, dynamic>> getCapabilities() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('getCapabilities');
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
    } on PlatformException {
      // Sessiz fallback
    } catch (_) {
      // Sessiz fallback
    }
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

  Map<String, dynamic> _meta({
    bool userInitiated = false,
    String trustedSource = '',
  }) {
    final map = <String, dynamic>{};
    if (userInitiated) map['userInitiated'] = true;
    final source = trustedSource.trim();
    if (source.isNotEmpty) map['trustedSource'] = source;
    return map;
  }

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
    } on PlatformException catch (e) {
      return NovaCallControlResult.failure(
        e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Native çağrı kontrolünde platform hatası oluştu.',
      );
    } catch (_) {
      return NovaCallControlResult.failure(
        'Native çağrı kontrolünde beklenmeyen hata oluştu.',
      );
    }
  }
}
