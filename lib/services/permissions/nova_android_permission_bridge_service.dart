// NOVA_VERIFIED_ANDROID_PERMISSION_RESULTS_V1
import 'dart:async';

import 'package:flutter/services.dart';

class NovaAndroidPermissionSnapshot {
  final bool canDrawOverlays;
  final bool accessibilityEnabled;
  final bool notificationsGranted;
  final bool recordAudioGranted;
  final bool defaultDialerGranted;
  final bool callScreeningRoleGranted;
  final bool readPhoneStateGranted;
  final bool readPhoneNumbersGranted;
  final bool readCallLogGranted;
  final bool answerPhoneCallsGranted;
  final bool callPhoneGranted;
  final bool hybridCallControlReady;
  final bool fullTelecomAutomationReady;
  final bool managedCallSupportReady;

  const NovaAndroidPermissionSnapshot({
    this.canDrawOverlays = false,
    this.accessibilityEnabled = false,
    this.notificationsGranted = false,
    this.recordAudioGranted = false,
    this.defaultDialerGranted = false,
    this.callScreeningRoleGranted = false,
    this.readPhoneStateGranted = false,
    this.readPhoneNumbersGranted = false,
    this.readCallLogGranted = false,
    this.answerPhoneCallsGranted = false,
    this.callPhoneGranted = false,
    this.hybridCallControlReady = false,
    this.fullTelecomAutomationReady = false,
    this.managedCallSupportReady = false,
  });

  bool get overlayGranted => canDrawOverlays;
  bool get essentialCallPermissionsGranted =>
      readPhoneStateGranted &&
      readPhoneNumbersGranted &&
      answerPhoneCallsGranted &&
      callPhoneGranted;
  bool get fullCallPermissionsGranted =>
      essentialCallPermissionsGranted && readCallLogGranted;
  bool get canAttemptAuthorizedCallHandling =>
      hybridCallControlReady || essentialCallPermissionsGranted;
  bool get shouldRecommendDefaultDialerOnlyForFullAutomation =>
      !defaultDialerGranted &&
      !callScreeningRoleGranted &&
      canAttemptAuthorizedCallHandling;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'canDrawOverlays': canDrawOverlays,
        'accessibilityEnabled': accessibilityEnabled,
        'notificationsGranted': notificationsGranted,
        'recordAudioGranted': recordAudioGranted,
        'defaultDialerGranted': defaultDialerGranted,
        'callScreeningRoleGranted': callScreeningRoleGranted,
        'readPhoneStateGranted': readPhoneStateGranted,
        'readPhoneNumbersGranted': readPhoneNumbersGranted,
        'readCallLogGranted': readCallLogGranted,
        'answerPhoneCallsGranted': answerPhoneCallsGranted,
        'callPhoneGranted': callPhoneGranted,
        'hybridCallControlReady': hybridCallControlReady,
        'fullTelecomAutomationReady': fullTelecomAutomationReady,
        'managedCallSupportReady': managedCallSupportReady,
      };

  factory NovaAndroidPermissionSnapshot.fromMap(Map<Object?, Object?> map) {
    bool b(String key) => map[key] == true;
    return NovaAndroidPermissionSnapshot(
      canDrawOverlays: b('canDrawOverlays'),
      accessibilityEnabled: b('accessibilityEnabled'),
      notificationsGranted: b('notificationsGranted'),
      recordAudioGranted: b('recordAudioGranted'),
      defaultDialerGranted: b('defaultDialerGranted'),
      callScreeningRoleGranted: b('callScreeningRoleGranted'),
      readPhoneStateGranted: b('readPhoneStateGranted'),
      readPhoneNumbersGranted: b('readPhoneNumbersGranted'),
      readCallLogGranted: b('readCallLogGranted'),
      answerPhoneCallsGranted: b('answerPhoneCallsGranted'),
      callPhoneGranted: b('callPhoneGranted'),
      hybridCallControlReady: b('hybridCallControlReady'),
      fullTelecomAutomationReady: b('fullTelecomAutomationReady'),
      managedCallSupportReady: b('managedCallSupportReady'),
    );
  }
}

class NovaAndroidPermissionBridgeService {
  static const MethodChannel _channel = MethodChannel(
    'nova/android_permission_bridge',
  );

  const NovaAndroidPermissionBridgeService();

  Future<bool> canDrawOverlays() => _invokeBool('canDrawOverlays');
  Future<bool> isAccessibilityEnabled() =>
      _invokeBool('isAccessibilityEnabled');
  Future<bool> canPostNotifications() => _invokeBool('canPostNotifications');
  Future<bool> hasRecordAudioPermission() =>
      _invokeBool('hasRecordAudioPermission');

  Future<bool> requestRecordAudioPermission() async {
    await _invokeBool('requestRecordAudioPermission');
    return _waitFor(hasRecordAudioPermission);
  }

  Future<bool> requestPostNotificationsPermission() async {
    await _invokeBool('requestPostNotificationsPermission');
    return _waitFor(canPostNotifications);
  }

  Future<bool> openOverlaySettings() async {
    await _invokeBool('openOverlaySettings');
    return _waitFor(canDrawOverlays);
  }

  Future<bool> openAccessibilitySettings() async {
    await _invokeBool('openAccessibilitySettings');
    return _waitFor(isAccessibilityEnabled);
  }

  Future<bool> openAppNotificationSettings() async {
    await _invokeBool('openAppNotificationSettings');
    return _waitFor(canPostNotifications);
  }

  Future<bool> openAppSettings() => _invokeBool('openAppSettings');
  Future<bool> isDefaultDialer() => _invokeBool('isDefaultDialer');

  Future<bool> requestDefaultDialerRole() async {
    await _invokeBool('requestDefaultDialerRole');
    return _waitFor(isDefaultDialer);
  }

  Future<bool> isCallScreeningRoleHeld() =>
      _invokeBool('isCallScreeningRoleHeld');

  Future<bool> requestCallScreeningRole() async {
    await _invokeBool('requestCallScreeningRole');
    return _waitFor(isCallScreeningRoleHeld);
  }

  Future<bool> hasReadPhoneStatePermission() =>
      _invokeBool('hasReadPhoneStatePermission');
  Future<bool> hasReadPhoneNumbersPermission() =>
      _invokeBool('hasReadPhoneNumbersPermission');
  Future<bool> hasReadCallLogPermission() =>
      _invokeBool('hasReadCallLogPermission');
  Future<bool> hasAnswerPhoneCallsPermission() =>
      _invokeBool('hasAnswerPhoneCallsPermission');
  Future<bool> hasCallPhonePermission() =>
      _invokeBool('hasCallPhonePermission');

  Future<bool> requestEssentialCallPermissions() async {
    await _invokeBool('requestEssentialCallPermissions');
    return _waitFor(() async =>
        (await getPermissionSnapshot()).essentialCallPermissionsGranted);
  }

  Future<NovaAndroidPermissionSnapshot> getPermissionSnapshot() async {
    try {
      final dynamic raw = await _channel.invokeMethod<dynamic>(
        'getPermissionSnapshot',
      );
      if (raw is Map) {
        return NovaAndroidPermissionSnapshot.fromMap(
          Map<Object?, Object?>.from(raw),
        );
      }
      return const NovaAndroidPermissionSnapshot();
    } catch (_) {
      return const NovaAndroidPermissionSnapshot();
    }
  }

  Future<bool> _waitFor(
    Future<bool> Function() probe, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final deadline = DateTime.now().add(timeout);
    do {
      if (await probe()) return true;
      await Future<void>.delayed(const Duration(milliseconds: 350));
    } while (DateTime.now().isBefore(deadline));
    return probe();
  }

  Future<bool> _invokeBool(String method) async {
    try {
      final dynamic raw = await _channel.invokeMethod<dynamic>(method);
      if (raw is bool) return raw;
      if (raw is num) return raw != 0;
      if (raw is String) {
        final normalized = raw.trim().toLowerCase();
        return normalized == 'true' || normalized == '1';
      }
      return false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
