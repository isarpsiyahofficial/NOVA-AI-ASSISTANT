import 'package:flutter_test/flutter_test.dart';
import 'package:nova/core/actions/nova_device_action.dart';
import 'package:nova/core/ai/ai_mode.dart';
import 'package:nova/core/ai/ai_request.dart';
import 'package:nova/core/turn/nova_turn_authority.dart';
import 'package:nova/core/turn/nova_turn_lease.dart';
import 'package:nova/services/actions/nova_action_intent_guard_service.dart';

AiRequest _request({
  required String text,
  required NovaTurnLease lease,
  NovaTurnAuthority? authority,
  bool confirmed = true,
}) {
  return AiRequest(
    prompt: text,
    originalUserText: text,
    mode: AiMode.apiOnly,
    requestOrigin: 'dashboard_text',
    userInitiated: true,
    userConfirmedThisAction: confirmed,
    authority: authority ??
        NovaTurnAuthority.localUser(evidenceId: 'dashboard_submit_button'),
    lease: lease,
  );
}

void main() {
  group('Nova immutable action intent guard', () {
    test('matching tool call requires current lease and typed authority', () {
      final lease = NovaTurnLeaseController.instance.begin(
        sessionId: 'guard_match',
      );
      final decision = NovaActionIntentGuardService.instance.authorize(
        call: const NovaDeviceActionCall(
          action: 'place_call',
          value: 'Ayşe',
          providerCallId: 'call_match_1',
        ),
        request: _request(text: 'Ayşe\'yi ara', lease: lease),
      );

      expect(decision.allowed, isTrue);
      expect(decision.bindingId, isNotEmpty);
    });

    test('tool call value must exist in immutable original transcript', () {
      final lease = NovaTurnLeaseController.instance.begin(
        sessionId: 'guard_mismatch',
      );
      final decision = NovaActionIntentGuardService.instance.authorize(
        call: const NovaDeviceActionCall(
          action: 'place_call',
          value: 'Mehmet',
          providerCallId: 'call_mismatch_1',
        ),
        request: _request(text: 'Ayşe\'yi ara', lease: lease),
      );

      expect(decision.allowed, isFalse);
      expect(decision.failureCode, 'tool_call_transcript_mismatch');
    });

    test('older turn lease becomes invalid when a new turn starts', () {
      final staleLease = NovaTurnLeaseController.instance.begin(
        sessionId: 'guard_stale_old',
      );
      NovaTurnLeaseController.instance.begin(sessionId: 'guard_stale_new');

      final decision = NovaActionIntentGuardService.instance.authorize(
        call: const NovaDeviceActionCall(
          action: 'home',
          providerCallId: 'call_stale_1',
        ),
        request: _request(text: 'Ana ekrana dön', lease: staleLease),
      );

      expect(decision.allowed, isFalse);
      expect(decision.failureCode, 'stale_or_missing_turn_lease');
    });

    test('same provider tool call cannot be replayed', () {
      final lease = NovaTurnLeaseController.instance.begin(
        sessionId: 'guard_replay',
      );
      final request = _request(text: 'Bildirimleri aç', lease: lease);
      const call = NovaDeviceActionCall(
        action: 'open_notifications',
        providerCallId: 'call_replay_1',
      );

      final first = NovaActionIntentGuardService.instance.authorize(
        call: call,
        request: request,
      );
      final second = NovaActionIntentGuardService.instance.authorize(
        call: call,
        request: request,
      );

      expect(first.allowed, isTrue);
      expect(second.allowed, isFalse);
      expect(second.failureCode, 'replayed_tool_call');
    });

    test('mutable metadata cannot replace typed authority', () {
      final lease = NovaTurnLeaseController.instance.begin(
        sessionId: 'guard_unverified',
      );
      final request = AiRequest(
        prompt: 'Ana ekrana dön',
        originalUserText: 'Ana ekrana dön',
        mode: AiMode.apiOnly,
        requestOrigin: 'dashboard_text',
        userInitiated: true,
        userConfirmedThisAction: true,
        authority: const NovaTurnAuthority.unverified(),
        lease: lease,
        metadata: const <String, dynamic>{
          'ownerVerified': true,
          'trustedSource': true,
        },
      );

      final decision = NovaActionIntentGuardService.instance.authorize(
        call: const NovaDeviceActionCall(
          action: 'home',
          providerCallId: 'call_unverified_1',
        ),
        request: request,
      );

      expect(decision.allowed, isFalse);
      expect(decision.failureCode, 'typed_authority_missing');
    });
  });
}
