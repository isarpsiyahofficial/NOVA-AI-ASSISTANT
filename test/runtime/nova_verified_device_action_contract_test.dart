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

      expect(executor, contains('NovaActionPolicy'));
      expect(executor, contains("request.metadata['localCompanionAuthorityProof']"));
      expect(executor, contains('policy.evaluate('));
      expect(executor, contains("failureCode: 'local_policy_blocked'"));
      expect(executor, isNot(contains("call.arguments['ownerVerified']")));
      expect(executor, isNot(contains("call.arguments['trustedSource']")));
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
      expect(executor, contains("failureCode: verification.verified ? '' : 'state_not_verified'"));
    });

    test('API route names used by the core controller remain authorized', () {
      final request = _read('lib/core/ai/ai_request.dart');
      final controller = _read('lib/core/turn/nova_core_turn_controller.dart');

      expect(request, contains("'dashboard_text'"));
      expect(request, contains("'call_companion_authorized_voice'"));
      expect(request, contains("'reminder_runtime_event'"));
      expect(request, contains('localCompanionAuthorityProof'));
      expect(controller, contains("return 'dashboard_text';"));
      expect(controller, contains("return 'call_companion_authorized_voice';"));
      expect(controller, contains('ownerConfidence: ownerConfidence'));
      expect(controller, contains("'ownerVerified': ownerConfidence >= 0.64"));
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
  });
}
