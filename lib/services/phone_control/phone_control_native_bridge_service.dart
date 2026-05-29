// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/services.dart';

class PhoneControlNativeStepResult {
  final bool success;
  final String message;

  const PhoneControlNativeStepResult({
    required this.success,
    required this.message,
  });
}

class NovaPhoneControlBridgeStatus {
  final bool success;
  final bool accessibilityReady;
  final String message;
  final bool screenLocked;
  final String currentPackageName;

  const NovaPhoneControlBridgeStatus({
    required this.success,
    required this.accessibilityReady,
    required this.message,
    this.screenLocked = false,
    this.currentPackageName = '',
  });
}

class NovaPhoneControlNativeBridgeService {
  static const MethodChannel _channel = MethodChannel(
    'nova/phone_control_bridge',
  );

  const NovaPhoneControlNativeBridgeService();

  Future<NovaPhoneControlBridgeStatus> getStatus() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('getBridgeStatus');

      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        return NovaPhoneControlBridgeStatus(
          success: map['success'] as bool? ?? false,
          accessibilityReady: map['accessibilityReady'] as bool? ?? false,
          message: (map['message'] as String? ?? '').trim(),
          screenLocked: map['screenLocked'] as bool? ?? false,
          currentPackageName: (map['currentPackageName'] as String? ?? '')
              .trim(),
        );
      }

      return const NovaPhoneControlBridgeStatus(
        success: false,
        accessibilityReady: false,
        message: 'Phone control native bridge geçersiz yanıt verdi.',
        screenLocked: false,
        currentPackageName: '',
      );
    } on PlatformException catch (e) {
      return NovaPhoneControlBridgeStatus(
        success: false,
        accessibilityReady: false,
        message: e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Phone control bridge platform hatası oluştu.',
      );
    } catch (_) {
      return const NovaPhoneControlBridgeStatus(
        success: false,
        accessibilityReady: false,
        screenLocked: false,
        currentPackageName: '',
        message: 'Phone control bridge beklenmeyen hata verdi.',
      );
    }
  }

  Future<PhoneControlNativeStepResult> executeStep({
    required String command,
    String value = '',
    int waitMs = 0,
    bool userInitiated = false,
    String trustedSource = '',
  }) async {
    try {
      final raw = await _channel
          .invokeMethod<dynamic>('executeStep', <String, dynamic>{
            'command': command.trim(),
            'value': value.trim(),
            'waitMs': waitMs,
            if (userInitiated) 'userInitiated': true,
            if (trustedSource.trim().isNotEmpty)
              'trustedSource': trustedSource.trim(),
          });

      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        return PhoneControlNativeStepResult(
          success: map['success'] as bool? ?? false,
          message: (map['message'] as String? ?? '').trim(),
        );
      }

      return const PhoneControlNativeStepResult(
        success: false,
        message: 'Phone control native step geçersiz yanıt verdi.',
      );
    } on PlatformException catch (e) {
      return PhoneControlNativeStepResult(
        success: false,
        message: e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Phone control native step platform hatası oluştu.',
      );
    } catch (_) {
      return const PhoneControlNativeStepResult(
        success: false,
        message: 'Phone control native step beklenmeyen hata verdi.',
      );
    }
  }
}
