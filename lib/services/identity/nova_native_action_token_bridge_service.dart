// NOVA_NATIVE_ACTION_TOKEN_BRIDGE_V1
import 'package:flutter/services.dart';

class NovaNativeActionTokenBridgeService {
  static const MethodChannel _channel = MethodChannel(
    'nova/voice_identity_bridge',
  );

  const NovaNativeActionTokenBridgeService();

  Future<bool> bindTokenToTurn({
    required String token,
    required String turnLeaseId,
  }) async {
    final safeToken = token.trim();
    final safeLease = turnLeaseId.trim();
    if (safeToken.isEmpty || safeLease.isEmpty) return false;
    try {
      final raw = await _channel.invokeMethod<dynamic>(
        'bindOwnerActionTokenToTurn',
        <String, dynamic>{
          'token': safeToken,
          'turnLeaseId': safeLease,
        },
      );
      final map = raw is Map
          ? Map<String, dynamic>.from(raw)
          : const <String, dynamic>{};
      return map['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> activateTurn(String turnLeaseId) async {
    final safeLease = turnLeaseId.trim();
    if (safeLease.isEmpty) return false;
    try {
      final raw = await _channel.invokeMethod<dynamic>(
        'activateOwnerActionTurn',
        <String, dynamic>{'turnLeaseId': safeLease},
      );
      final map = raw is Map
          ? Map<String, dynamic>.from(raw)
          : const <String, dynamic>{};
      return map['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
