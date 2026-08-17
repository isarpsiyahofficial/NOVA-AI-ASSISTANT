// NOVA_TYPED_POLICY_GATED_VERIFIED_DEVICE_ACTION_EXECUTOR_V3

import '../../core/actions/nova_device_action.dart';
import '../../core/ai/ai_request.dart';
import '../../core/call/nova_call_control_result.dart';
import '../../core/nova/nova_action_policy.dart';
import '../../core/turn/nova_turn_authority.dart';
import '../call/nova_call_control_bridge_service.dart';
import '../call/nova_call_state_service.dart';
import '../identity/nova_native_action_token_bridge_service.dart';
import 'nova_action_intent_guard_service.dart';
import 'nova_contact_call_target_resolver_service.dart';
import 'nova_phone_control_bridge_service.dart';

class NovaDeviceActionExecutorService {
  final NovaPhoneControlBridgeService phoneBridge;
  final NovaCallControlBridgeService callControl;
  final NovaCallStateService callState;
  final NovaContactCallTargetResolverService contactResolver;
  final NovaActionPolicy policy;
  final NovaNativeActionTokenBridgeService tokenBridge;

  const NovaDeviceActionExecutorService({
    this.phoneBridge = const NovaPhoneControlBridgeService(),
    this.callControl = const NovaCallControlBridgeService(),
    this.callState = const NovaCallStateService(),
    this.contactResolver = const NovaContactCallTargetResolverService(),
    this.policy = const NovaActionPolicy(),
    this.tokenBridge = const NovaNativeActionTokenBridgeService(),
  });

  Future<NovaDeviceActionResult> execute({
    required NovaDeviceActionCall call,
    required AiRequest request,
  }) async {
    final action = call.action.trim().toLowerCase();
    if (!NovaDeviceActionCatalog.isSupported(action)) {
      return NovaDeviceActionResult(
        action: action,
        success: false,
        verified: false,
        message: 'Desteklenmeyen telefon eylemi istendi: $action',
        failureCode: 'unsupported_action',
      );
    }
    if (NovaDeviceActionCatalog.requiresValue(action) &&
        call.value.trim().isEmpty) {
      return NovaDeviceActionResult(
        action: action,
        success: false,
        verified: false,
        message: 'Bu eylem için gerekli değer verilmedi.',
        failureCode: 'missing_action_value',
      );
    }

    final intentDecision = NovaActionIntentGuardService.instance.authorize(
      call: call,
      request: request,
    );
    if (!intentDecision.allowed) {
      return NovaDeviceActionResult(
        action: action,
        success: false,
        verified: false,
        message: intentDecision.message,
        failureCode: intentDecision.failureCode,
      );
    }

    final lease = request.lease!;
    final authority = request.authority;
    if (authority.kind == NovaTurnAuthorityKind.ownerVoice) {
      final bound = await tokenBridge.bindTokenToTurn(
        token: authority.nativeActionToken,
        turnLeaseId: lease.id,
      );
      if (!bound) {
        return NovaDeviceActionResult(
          action: action,
          success: false,
          verified: false,
          message: 'Native sahip eylem tokenı bu tura bağlanamadı.',
          failureCode: 'native_token_bind_failed',
        );
      }
      final activated = await tokenBridge.activateTurn(lease.id);
      if (!activated) {
        return NovaDeviceActionResult(
          action: action,
          success: false,
          verified: false,
          message: 'Native sahip eylem turu etkinleştirilemedi.',
          failureCode: 'native_turn_activation_failed',
        );
      }
    }

    final callTarget = action == 'place_call'
        ? await contactResolver.resolve(call.value)
        : null;
    if (callTarget != null && !callTarget.success) {
      return NovaDeviceActionResult(
        action: action,
        success: false,
        verified: false,
        message: callTarget.message,
        failureCode: 'contact_resolution_failed',
      );
    }

    final beforeCall = await callState.getSnapshot();
    final beforePhone = await phoneBridge.getStatus();
    final localUiAction = authority.kind == NovaTurnAuthorityKind.localUser;
    final ownerVoiceAction =
        authority.kind == NovaTurnAuthorityKind.ownerVoice &&
            authority.ownerVoiceVerified;
    final companionAction =
        authority.kind == NovaTurnAuthorityKind.companion &&
            authority.companionAuthorized;
    final typedInitiation = localUiAction || ownerVoiceAction || companionAction;

    final knownContact = localUiAction ||
        ownerVoiceAction ||
        callTarget?.fromContacts == true ||
        beforeCall.isAuthorizedManagedNumber;
    final explicitlyAllowedContact = localUiAction ||
        ownerVoiceAction ||
        beforeCall.isAuthorizedManagedNumber;
    final screenLocked = request.isScreenLocked ||
        beforePhone['screenLocked'] == true;

    final policyResult = policy.evaluate(
      action: _policyAction(action),
      ownerInitiated: typedInitiation,
      ownerVerified: typedInitiation,
      knownContact: knownContact,
      explicitlyAllowedContact: explicitlyAllowedContact,
      callActive: beforeCall.inCall,
      screenLocked: screenLocked,
      userConfirmedThisAction: request.userConfirmedThisAction,
    );

    if (!policyResult.mayExecute) {
      return NovaDeviceActionResult(
        action: action,
        success: false,
        verified: false,
        message: policyResult.reason,
        failureCode: 'local_policy_blocked',
        policy: <String, dynamic>{
          ...policyResult.toMap(),
          'typedAuthority': authority.toAuditMap(),
          'intentBindingId': intentDecision.bindingId,
        },
        beforeState: _combinedState(beforeCall, beforePhone),
      );
    }

    try {
      final native = await _executeNative(
        call: call,
        request: request,
        callTarget: callTarget,
      );
      final nativeSuccess = native['success'] == true;
      final nativeMessage = native['message']?.toString().trim() ?? '';
      if (!nativeSuccess) {
        return NovaDeviceActionResult(
          action: action,
          success: false,
          verified: false,
          message: nativeMessage.isEmpty
              ? 'Android telefon katmanı eylemi kabul etmedi.'
              : nativeMessage,
          nativeMessage: nativeMessage,
          failureCode: 'native_action_failed',
          policy: policyResult.toMap(),
          beforeState: _combinedState(beforeCall, beforePhone),
        );
      }

      final verification = await _verify(
        call: call,
        beforeCall: beforeCall,
        beforePhone: beforePhone,
        native: native,
      );
      if (!verification.verified) {
        return NovaDeviceActionResult(
          action: action,
          success: false,
          verified: false,
          message:
              'Android katmanı komutu kabul etti fakat gerçek cihaz son durumu doğrulanamadı.',
          nativeMessage: nativeMessage,
          failureCode: 'state_not_verified',
          policy: policyResult.toMap(),
          beforeState: _combinedState(beforeCall, beforePhone),
          afterState: verification.afterState,
        );
      }

      return NovaDeviceActionResult(
        action: action,
        success: true,
        verified: true,
        message: verification.message,
        nativeMessage: nativeMessage,
        policy: <String, dynamic>{
          ...policyResult.toMap(),
          'typedAuthority': authority.toAuditMap(),
          'intentBindingId': intentDecision.bindingId,
        },
        beforeState: _combinedState(beforeCall, beforePhone),
        afterState: verification.afterState,
      );
    } catch (error) {
      return NovaDeviceActionResult(
        action: action,
        success: false,
        verified: false,
        message: 'Telefon eylemi çalıştırılırken hata oluştu: $error',
        failureCode: 'action_executor_exception',
        policy: policyResult.toMap(),
        beforeState: _combinedState(beforeCall, beforePhone),
      );
    }
  }

  Future<Map<String, dynamic>> _executeNative({
    required NovaDeviceActionCall call,
    required AiRequest request,
    NovaContactCallTargetResolution? callTarget,
  }) async {
    final action = call.action;
    final authority = request.authority;
    final actionToken = authority.nativeActionToken;
    final localUiAction = authority.kind == NovaTurnAuthorityKind.localUser;
    final companionAction = authority.kind == NovaTurnAuthorityKind.companion;

    switch (action) {
      case 'answer_call':
        return _callResultMap(await callControl.answerRingingCall(
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction: companionAction,
        ));
      case 'reject_call':
        return _callResultMap(await callControl.rejectRingingCall(
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction: companionAction,
        ));
      case 'hang_up':
        return _callResultMap(await callControl.disconnectCurrentCall(
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction: companionAction,
        ));
      case 'mute_call':
        return _callResultMap(await callControl.setMuted(
          true,
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction: companionAction,
        ));
      case 'unmute_call':
        return _callResultMap(await callControl.setMuted(
          false,
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction: companionAction,
        ));
      case 'speaker_on':
        return _callResultMap(await callControl.routeToSpeaker(
          true,
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction: companionAction,
        ));
      case 'speaker_off':
        return _callResultMap(await callControl.routeToSpeaker(
          false,
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction: companionAction,
        ));
      case 'toggle_hold':
        return _callResultMap(await callControl.toggleHold(
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction: companionAction,
        ));
      case 'place_call':
        final target = callTarget;
        if (target == null || !target.success || target.number.isEmpty) {
          return const <String, dynamic>{
            'success': false,
            'verified': false,
            'message': 'Arama hedefi yerel olarak çözülemedi.',
          };
        }
        final approval = await callControl.registerOwnerApprovedOutbound(
          target.number,
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction: companionAction,
        );
        if (!approval.success) return _callResultMap(approval);
        final native = await phoneBridge.executeStep(
          command: 'place_call',
          value: target.number,
          localUiAction: localUiAction,
          companionAction: companionAction,
        );
        return <String, dynamic>{
          ...native,
          'resolvedDialNumber': target.number,
          'resolvedContactName': target.displayName,
          'resolvedFromContacts': target.fromContacts,
        };
      case 'media_next':
        return phoneBridge.executeStep(
          command: 'media_next',
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction: companionAction,
        );
      case 'media_previous':
        return phoneBridge.executeStep(
          command: 'media_previous',
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction: companionAction,
        );
      case 'media_pause':
        return phoneBridge.executeStep(
          command: 'media_pause',
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction: companionAction,
        );
      case 'media_resume':
        return phoneBridge.executeStep(
          command: 'media_resume',
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction: companionAction,
        );
      case 'media_play_pause':
        return phoneBridge.executeStep(
          command: 'media_play_pause',
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction: companionAction,
        );
      case 'volume_up':
        return phoneBridge.executeStep(
          command: 'media_volume_up',
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction: companionAction,
        );
      case 'volume_down':
        return phoneBridge.executeStep(
          command: 'media_volume_down',
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction: companionAction,
        );
      case 'mute_media':
        return phoneBridge.executeStep(
          command: 'media_mute',
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction: companionAction,
        );
      case 'open_spotify':
        return phoneBridge.executeStep(
          command: 'open_package',
          value: 'com.spotify.music',
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction: companionAction,
        );
      case 'open_youtube_music':
        return phoneBridge.executeStep(
          command: 'open_package',
          value: 'com.google.android.apps.youtube.music',
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction: companionAction,
        );
      case 'back':
      case 'home':
      case 'open_notifications':
      case 'open_quick_settings':
        return phoneBridge.executeStep(
          command: action,
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction: companionAction,
        );
      case 'tap_text':
      case 'set_focused_text':
        return phoneBridge.executeStep(
          command: action,
          value: call.value,
          actionToken: actionToken,
          localUiAction: localUiAction,
          companionAction: companionAction,
        );
    }
    return <String, dynamic>{
      'success': false,
      'verified': false,
      'message': 'Eylem native komuta eşlenemedi: $action',
    };
  }

  Future<_NovaActionVerification> _verify({
    required NovaDeviceActionCall call,
    required NovaCallStateSnapshot beforeCall,
    required Map<String, dynamic> beforePhone,
    required Map<String, dynamic> native,
  }) async {
    final action = call.action;
    if (_isCallStateAction(action)) {
      final expectedValue =
          native['resolvedDialNumber']?.toString() ?? call.value;
      final afterCall = await _pollCallState(
        (snapshot) =>
            _callPostcondition(action, beforeCall, snapshot, expectedValue),
      );
      final verified = _callPostcondition(
        action,
        beforeCall,
        afterCall,
        expectedValue,
      );
      return _NovaActionVerification(
        verified: verified,
        message: verified
            ? _verifiedMessage(
                action,
                resolvedContactName:
                    native['resolvedContactName']?.toString() ?? '',
              )
            : 'Çağrı komutu kabul edildi ancak çağrı durumu beklenen hâle gelmedi.',
        afterState: _callStateMap(afterCall),
      );
    }

    if (action == 'open_spotify' || action == 'open_youtube_music') {
      final expectedPackage = action == 'open_spotify'
          ? 'com.spotify.music'
          : 'com.google.android.apps.youtube.music';
      var afterPhone = await phoneBridge.getStatus();
      for (var i = 0;
          i < 5 &&
              afterPhone['currentPackageName']?.toString() != expectedPackage;
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        afterPhone = await phoneBridge.getStatus();
      }
      final verified =
          afterPhone['currentPackageName']?.toString() == expectedPackage;
      return _NovaActionVerification(
        verified: verified,
        message: verified
            ? (action == 'open_spotify'
                ? 'Spotify telefonda açıldı ve doğrulandı.'
                : 'YouTube Music telefonda açıldı ve doğrulandı.')
            : 'Uygulama açma komutu kabul edildi ancak ön plandaki paket doğrulanamadı.',
        afterState: afterPhone,
      );
    }

    if (_nativeAcknowledgementIsVerification(action)) {
      final afterPhone = await phoneBridge.getStatus();
      return _NovaActionVerification(
        verified: native['success'] == true,
        message: _verifiedMessage(action),
        afterState: afterPhone,
      );
    }

    final afterPhone = await phoneBridge.getStatus();
    return _NovaActionVerification(
      verified: native['verified'] == true,
      message: native['verified'] == true
          ? _verifiedMessage(action)
          : 'Komut Android katmanına gönderildi; hedef uygulamanın son durumu okunamadı.',
      afterState: afterPhone,
    );
  }

  Future<NovaCallStateSnapshot> _pollCallState(
    bool Function(NovaCallStateSnapshot snapshot) postcondition,
  ) async {
    var snapshot = await callState.getSnapshot();
    for (var i = 0; i < 7 && !postcondition(snapshot); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      snapshot = await callState.getSnapshot();
    }
    return snapshot;
  }

  bool _callPostcondition(
    String action,
    NovaCallStateSnapshot before,
    NovaCallStateSnapshot after,
    String value,
  ) {
    switch (action) {
      case 'answer_call':
        return after.inCall && after.isActiveCall && !after.isRinging;
      case 'reject_call':
        return !after.isRinging && !after.inCall;
      case 'hang_up':
        return !after.inCall;
      case 'mute_call':
        return after.inCall && after.isMuted;
      case 'unmute_call':
        return after.inCall && !after.isMuted;
      case 'speaker_on':
        return after.inCall && after.isSpeakerOn;
      case 'speaker_off':
        return after.inCall && !after.isSpeakerOn;
      case 'toggle_hold':
        return after.inCall && after.state != before.state;
      case 'place_call':
        final expected =
            NovaContactCallTargetResolverService.normalizeDialNumber(value);
        final actual = NovaContactCallTargetResolverService.normalizeDialNumber(
          after.normalizedActiveNumber,
        );
        final numberMatches = expected.isNotEmpty &&
            (actual == expected ||
                (actual.length >= 7 && expected.endsWith(actual)) ||
                (expected.length >= 7 && actual.endsWith(expected)));
        return after.inCall && numberMatches;
    }
    return false;
  }

  bool _isCallStateAction(String action) => <String>{
        'answer_call',
        'reject_call',
        'hang_up',
        'mute_call',
        'unmute_call',
        'speaker_on',
        'speaker_off',
        'toggle_hold',
        'place_call',
      }.contains(action);

  bool _nativeAcknowledgementIsVerification(String action) => <String>{
        'back',
        'home',
        'open_notifications',
        'open_quick_settings',
        'tap_text',
        'set_focused_text',
      }.contains(action);

  String _verifiedMessage(
    String action, {
    String resolvedContactName = '',
  }) {
    switch (action) {
      case 'answer_call':
        return 'Gelen çağrı telefonda cevaplandı ve aktif çağrı durumu doğrulandı.';
      case 'reject_call':
        return 'Gelen çağrı telefonda reddedildi ve çağrının kapandığı doğrulandı.';
      case 'hang_up':
        return 'Çağrı telefonda sonlandırıldı ve bağlantının kapandığı doğrulandı.';
      case 'mute_call':
        return 'Çağrı mikrofonu kapatıldı ve durum doğrulandı.';
      case 'unmute_call':
        return 'Çağrı mikrofonu açıldı ve durum doğrulandı.';
      case 'speaker_on':
        return 'Çağrı hoparlöre alındı ve ses yolu doğrulandı.';
      case 'speaker_off':
        return 'Çağrı hoparlörden çıkarıldı ve ses yolu doğrulandı.';
      case 'toggle_hold':
        return 'Çağrının bekletme durumu değiştirildi ve doğrulandı.';
      case 'place_call':
        return resolvedContactName.trim().isEmpty
            ? 'Dış arama telefonda başlatıldı ve çağrı durumu doğrulandı.'
            : '$resolvedContactName aranıyor; çağrı durumu telefonda doğrulandı.';
      case 'back':
        return 'Telefonda geri işlemi uygulandı.';
      case 'home':
        return 'Telefonun ana ekranı açıldı.';
      case 'open_notifications':
        return 'Telefonun bildirim paneli açıldı.';
      case 'open_quick_settings':
        return 'Telefonun hızlı ayarlar paneli açıldı.';
      case 'tap_text':
        return 'İstenen ekran öğesine dokunma işlemi Android tarafından uygulandı.';
      case 'set_focused_text':
        return 'Metin odaktaki alana Android tarafından yazıldı.';
      default:
        return 'Telefon eylemi tamamlandı ve doğrulandı.';
    }
  }

  String _policyAction(String action) {
    switch (action) {
      case 'answer_call':
        return 'answer_call';
      case 'reject_call':
        return 'reject_call';
      case 'hang_up':
        return 'disconnect_call';
      case 'place_call':
        return 'start_call';
      case 'mute_call':
      case 'unmute_call':
      case 'speaker_on':
      case 'speaker_off':
      case 'toggle_hold':
        return 'media_call_control_$action';
      case 'media_next':
      case 'media_previous':
      case 'media_pause':
      case 'media_resume':
      case 'media_play_pause':
      case 'volume_up':
      case 'volume_down':
      case 'mute_media':
      case 'open_spotify':
      case 'open_youtube_music':
      case 'tap_text':
      case 'set_focused_text':
        return 'media_phone_action_$action';
      default:
        return action;
    }
  }

  Map<String, dynamic> _callResultMap(NovaCallControlResult result) =>
      <String, dynamic>{
        'success': result.success,
        'message': result.message,
        'isSpeakerOn': result.isSpeakerOn,
        'isMuted': result.isMuted,
      };

  Map<String, dynamic> _combinedState(
    NovaCallStateSnapshot call,
    Map<String, dynamic> phone,
  ) => <String, dynamic>{
        'call': _callStateMap(call),
        'phone': phone,
      };

  Map<String, dynamic> _callStateMap(NovaCallStateSnapshot state) =>
      <String, dynamic>{
        'inCall': state.inCall,
        'activeNumber': state.normalizedActiveNumber,
        'state': state.state,
        'isRinging': state.isRinging,
        'isActiveCall': state.isActiveCall,
        'canAnswer': state.canAnswer,
        'canDisconnect': state.canDisconnect,
        'canMute': state.canMute,
        'isMuted': state.isMuted,
        'isSpeakerOn': state.isSpeakerOn,
        'callerDisplayName': state.callerDisplayName,
        'isDefaultDialer': state.isDefaultDialer,
        'telephonyObserverReady': state.telephonyObserverReady,
        'callScreeningReady': state.callScreeningReady,
        'isAuthorizedManagedNumber': state.isAuthorizedManagedNumber,
      };
}

class _NovaActionVerification {
  final bool verified;
  final String message;
  final Map<String, dynamic> afterState;

  const _NovaActionVerification({
    required this.verified,
    required this.message,
    required this.afterState,
  });
}
