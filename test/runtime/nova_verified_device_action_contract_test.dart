import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('Nova verified device action contracts', () {
    test('all API providers expose the same structured phone tool', () {
      final api = _read('lib/services/api/api_service.dart');
      final catalog = _read('lib/core/actions/nova_device_action.dart');

      expect(api, contains('NovaDeviceActionCatalog.geminiTool()'));
      expect(api, contains('NovaDeviceActionCatalog.openAiTool()'));
      expect(api, contains('NovaDeviceActionCatalog.qwenTool()'));
      expect(api, contains("'parallel_tool_calls': false"));
      expect(api, contains("'tool_choice': 'auto'"));
      expect(catalog, contains("functionName = 'execute_phone_action'"));
      expect(catalog, contains("'additionalProperties': false"));
      expect(catalog, contains("'required': <String>['action', 'value']"));
    });

    test('native side effect finishes before the final provider answer', () {
      final api = _read('lib/services/api/api_service.dart');

      final execute = api.indexOf('await actionExecutor.execute(');
      final actionPrompt = api.indexOf('_buildActionResultPrompt(result)', execute);
      final finalMarker = api.indexOf(
        "'nativeSideEffectCompletedBeforeFinalAnswer': true",
      );
      expect(execute, greaterThanOrEqualTo(0));
      expect(actionPrompt, greaterThan(execute));
      expect(finalMarker, greaterThanOrEqualTo(0));
      expect(api, contains('_safeActionSummary('));
      expect(api, contains('unsafe_action_summary_blocked'));
    });

    test('the model cannot mint device authority', () {
      final executor = _read(
        'lib/services/actions/nova_device_action_executor_service.dart',
      );
      final guard = _read(
        'lib/services/actions/nova_action_intent_guard_service.dart',
      );

      expect(executor, contains('NovaActionIntentGuardService.instance.authorize'));
      expect(executor, contains('request.authority'));
      expect(executor, contains('authority.toAuditMap()'));
      expect(executor, contains('policy.evaluate('));
      expect(executor, contains("failureCode: 'local_policy_blocked'"));
      expect(guard, contains('request.canonicalUserText'));
      expect(guard, contains('request.hasCurrentLease'));
      expect(guard, contains('request.authority.canRequestNativeAction'));
      expect(executor, isNot(contains("call.arguments['ownerVerified']")));
      expect(executor, isNot(contains("call.arguments['trustedSource']")));
    });

    test('same Silero segment feeds Whisper transcript and TitaNet identity', () {
      final engine = _read(
        'android/app/src/main/kotlin/com/example/nova/asr/NovaStreamingAsrEngine.kt',
      );
      final bridge = _read(
        'android/app/src/main/kotlin/com/example/nova/asr/NovaStreamingAsrBridgePlugin.kt',
      );
      final stt = _read('lib/services/stt/nova_speech_to_text_service.dart');
      final dashboard = _read('lib/ui/dashboard/dashboard_page.dart');

      expect(engine, contains('NovaAsrSegmentWavStore.write('));
      expect(engine, contains('samples = samples'));
      expect(engine, contains('identityAudioPath = identityAudioPath'));
      expect(bridge, contains('"identityAudioPath" to payload.identityAudioPath'));
      expect(stt, contains('identifyVoiceFromFile('));
      expect(stt, contains('identity.voiceId.trim() == owner.ownerVoiceId.trim()'));
      expect(stt, contains('ownerConfidence: matchedOwner ? identity.similarity : 0'));
      expect(stt, contains('nativeActionToken: matchedOwner'));
      expect(dashboard, contains('NovaTurnAuthority.ownerVoice('));
      expect(dashboard, contains("'nativeActionToken': sttResult.nativeActionToken"));
    });

    test('synthetic owner IDs and legacy dashboard setup cannot grant authority', () {
      final owner = _read(
        'lib/services/identity/device_owner_identity_service.dart',
      );
      final launch = _read('lib/ui/launch/nova_launch_gate_page.dart');
      final dashboard = _read('lib/ui/dashboard/dashboard_page.dart');

      expect(owner, contains("value.startsWith('owner_')"));
      expect(owner, contains("value.startsWith('nova_manual_owner_')"));
      expect(launch, contains('isVerifiedVoiceprintId(settings.activeVoiceProfileId)'));
      expect(dashboard, isNot(contains('nova_manual_owner_')));
      expect(dashboard, isNot(contains('_completeManualSetup')));
      expect(dashboard, contains('NovaTurnAuthority.ownerVoice('));
    });

    test('call actions are verified against fresh Telecom state', () {
      final executor = _read(
        'lib/services/actions/nova_device_action_executor_service.dart',
      );

      expect(executor, contains('await _pollCallState('));
      expect(executor, contains('after.isActiveCall && !after.isRinging'));
      expect(executor, contains('return !after.inCall;'));
      expect(executor, contains('after.inCall && after.isMuted'));
      expect(executor, contains('after.inCall && after.isSpeakerOn'));

      final verificationGate = executor.indexOf('if (!verification.verified)');
      final failureCode = executor.indexOf(
        "failureCode: 'state_not_verified'",
        verificationGate,
      );
      final verifiedSuccess = executor.indexOf(
        'success: true',
        failureCode,
      );
      expect(verificationGate, greaterThanOrEqualTo(0));
      expect(failureCode, greaterThan(verificationGate));
      expect(verifiedSuccess, greaterThan(failureCode));
    });

    test('API route names used by the core controller remain authorized', () {
      final request = _read('lib/core/ai/ai_request.dart');
      final controller = _read('lib/core/turn/nova_core_turn_controller.dart');

      expect(request, contains("'dashboard_text'"));
      expect(request, contains("'call_companion_authorized_voice'"));
      expect(request, contains("'reminder_runtime_event'"));
      expect(request, contains('final NovaTurnAuthority authority'));
      expect(request, contains('final NovaTurnLease? lease'));
      expect(controller, contains("return 'dashboard_text';"));
      expect(controller, contains("return 'call_companion_authorized_voice';"));
      expect(controller, contains('authority: authority'));
      expect(controller, contains('lease: lease'));
    });

    test('unverified native commands cannot be described as completed', () {
      final contract = _read('lib/core/actions/nova_device_action.dart');
      final api = _read('lib/services/api/api_service.dart');

      expect(
        contract,
        contains('ancak sonucunu cihaz durumundan doğrulayamadım'),
      );
      expect(api, contains("folded.contains('doğrulanamad')"));
      expect(api, contains("folded.contains('tamamlandı')"));
    });

    test('carrier call control is not misreported as AI conversation', () {
      final plugin = _read(
        'android/app/src/main/kotlin/com/example/nova/NovaCallControlBridgePlugin.kt',
      );

      expect(plugin, contains('carrier_ai_audio_transport_unavailable'));
      expect(plugin, contains('"carrierCallControlReady" to true'));
      expect(plugin, contains('"carrierAiConversationReady" to false'));
      expect(plugin, contains('"carrierDownlinkCaptureReady" to false'));
      expect(plugin, contains('"carrierUplinkInjectionReady" to false'));
      expect(
        plugin,
        isNot(contains('Kontrol Nova tarafına geçti. Seçili kişi için dijital insan çağrı düzeni aktif.')),
      );
    });


    test('runtime call controls use typed verified action routing', () {
      final router = _read(
        'lib/services/actions/nova_verified_call_action_service.dart',
      );
      final companion = _read(
        'lib/services/call_companion/nova_call_companion_runtime_service.dart',
      );
      final continuous = _read(
        'lib/services/system/nova_continuous_listening_runtime_service.dart',
      );
      final bridge = _read(
        'lib/services/call/nova_call_control_bridge_service.dart',
      );

      expect(router, contains('NovaDeviceActionExecutorService'));
      expect(router, contains('NovaTurnAuthority.companion('));
      expect(router, contains('NovaTurnLeaseController.instance.begin('));
      expect(companion, contains('verifiedCallActionService.executeCompanion('));
      expect(continuous, contains('fail_closed_before_answer'));
      expect(continuous, contains('companionRuntime!.startForCurrentCall('));
      expect(bridge, isNot(contains('localUiAction || userInitiated')));
    });

    test('native companion authorization is bound to managed active contacts', () {
      final native = _read(
        'android/app/src/main/kotlin/com/example/nova/NovaNativeActionAuthorization.kt',
      );

      expect(native, contains('NovaCallStateBridge.getState()'));
      expect(native, contains('NovaCallAuthorityGuard.canCompanionCallControl('));
      expect(native, isNot(contains('nova_companion_native_authority')));
    });
  });
}
