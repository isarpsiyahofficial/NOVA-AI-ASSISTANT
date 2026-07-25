// NOVA_TYPED_PHONE_CONTROL_DART_BRIDGE_V1
import 'package:flutter/services.dart';

class NovaPhoneControlBridgeService {
  static const MethodChannel _channel = MethodChannel(
    'nova/phone_control_bridge',
  );

  const NovaPhoneControlBridgeService();

  Future<Map<String, dynamic>> getStatus() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('getBridgeStatus');
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return const <String, dynamic>{
        'success': false,
        'message': 'Telefon kontrol köprüsü geçersiz durum yanıtı verdi.',
      };
    } on PlatformException catch (error) {
      return <String, dynamic>{
        'success': false,
        'message': error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Telefon kontrol köprüsünde platform hatası oluştu.',
      };
    } catch (error) {
      return <String, dynamic>{
        'success': false,
        'message': 'Telefon kontrol köprüsü okunamadı: $error',
      };
    }
  }

  Future<Map<String, dynamic>> executeStep({
    required String command,
    String value = '',
    int waitMs = 0,
    String actionToken = '',
    bool localUiAction = false,
    bool companionAction = false,
    bool userInitiated = false,
    String trustedSource = '',
  }) async {
    try {
      final raw = await _channel.invokeMethod<dynamic>(
        'executeStep',
        <String, dynamic>{
          'command': command.trim(),
          'value': value.trim(),
          'waitMs': waitMs.clamp(0, 15000),
          if (actionToken.trim().isNotEmpty)
            'actionToken': actionToken.trim(),
          'localUiAction': localUiAction || userInitiated,
          'companionAction':
              companionAction || trustedSource.trim() == 'companion',
        },
      );
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return const <String, dynamic>{
        'success': false,
        'verified': false,
        'message': 'Native telefon eylemi geçersiz yanıt verdi.',
      };
    } on PlatformException catch (error) {
      return <String, dynamic>{
        'success': false,
        'verified': false,
        'message': error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Native telefon eyleminde platform hatası oluştu.',
      };
    } catch (error) {
      return <String, dynamic>{
        'success': false,
        'verified': false,
        'message': 'Native telefon eylemi çalıştırılamadı: $error',
      };
    }
  }
}
