import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active launch route owns continuous runtime and real overlay', () {
    final launch =
        File('lib/ui/launch/nova_launch_gate_page.dart').readAsStringSync();
    expect(launch, contains("import '../dashboard/dashboard_page.dart';"));
    expect(launch, contains('return DashboardPage('));
    expect(launch, contains('openOverlaySettings'));
    expect(launch, contains('openBatteryOptimizationSettings'));
  });

  test('wake and direct commands require a fresh captured voice sample', () {
    final runtime = File(
      'lib/services/system/nova_continuous_listening_runtime_service.dart',
    ).readAsStringSync();
    final auth = File(
      'lib/services/identity/voice_authorization_runtime_service.dart',
    ).readAsStringSync();
    expect(runtime, isNot(contains('wakeTrustedBySession')));
    expect(runtime, isNot(contains('wakeTrustedByRecent')));
    expect(runtime, contains('requiresFreshCommandAuthority'));
    expect(runtime, contains('inspection.captureSucceeded'));
    expect(runtime, contains('shutdownWakeInspection.captureSucceeded'));
    expect(runtime,
        contains('allowContinuityReuse: !requiresFreshCommandAuthority'));
    expect(auth, isNot(contains('bool allowContinuityReuse = true')));
  });

  test('API secrets and provider requests use hardened paths', () {
    final tokens =
        File('lib/core/api/nova_secure_token_store.dart').readAsStringSync();
    final api = File('lib/services/api/api_service.dart').readAsStringSync();
    expect(tokens, contains('FlutterSecureStorage'));
    expect(tokens, contains('AndroidOptions()'));
    expect(api, contains("'x-goog-api-key': execution.apiKey.trim()"));
    expect(api,
        isNot(contains("<String, String>{'key': execution.apiKey.trim()}")));
    expect(api, contains('current.statusCode == 429'));
  });
}
