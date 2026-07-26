from pathlib import Path


def read(path: str) -> str:
    return Path(path).read_text(encoding="utf-8")


def write(path: str, text: str) -> None:
    Path(path).write_text(text, encoding="utf-8")


def replace_once(path: str, old: str, new: str) -> None:
    text = read(path)
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected exactly one match, found {count}: {old[:120]!r}")
    write(path, text.replace(old, new, 1))


# 1) Secure provider/runtime secrets with Android Keystore-backed storage.
replace_once(
    "pubspec.yaml",
    "  shared_preferences: ^2.5.3\n",
    "  shared_preferences: ^2.5.3\n  flutter_secure_storage: ^10.3.1\n",
)

write(
    "lib/core/api/nova_secure_token_store.dart",
    r'''// NOVA_KEYSTORE_BACKED_RUNTIME_SECRETS_V1
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nova_ai_provider_type.dart';

class NovaSecureTokenStore {
  static const String _legacyApiKeyPrefsKey = 'nova_legacy_api_key_mirror';
  static const String carrierBridgeTokenName = 'carrier_bridge_control_token';
  static final FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  const NovaSecureTokenStore();

  String _keyFor(NovaAiProviderType provider) => 'nova_api_key_${provider.key}';
  String _namedKey(String name) =>
      'nova_runtime_secret_${name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '_')}';

  Future<String> read(NovaAiProviderType provider) async {
    final key = _keyFor(provider);
    final secure = (await _storage.read(key: key))?.trim() ?? '';
    if (secure.isNotEmpty) return secure;

    final prefs = await SharedPreferences.getInstance();
    var legacy = prefs.getString(key)?.trim() ?? '';
    if (legacy.isEmpty && provider == NovaAiProviderType.gemini) {
      legacy = prefs.getString(_legacyApiKeyPrefsKey)?.trim() ?? '';
    }
    if (legacy.isNotEmpty) {
      await _storage.write(key: key, value: legacy);
      await prefs.remove(key);
      if (provider == NovaAiProviderType.gemini) {
        await prefs.remove(_legacyApiKeyPrefsKey);
      }
    }
    return legacy;
  }

  Future<void> write(NovaAiProviderType provider, String token) async {
    final key = _keyFor(provider);
    final normalized = token.trim();
    final prefs = await SharedPreferences.getInstance();
    if (normalized.isEmpty) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: normalized);
    }
    await prefs.remove(key);
    if (provider == NovaAiProviderType.gemini) {
      await prefs.remove(_legacyApiKeyPrefsKey);
    }
  }

  Future<String> readNamed(String name) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) return '';
    final key = _namedKey(normalizedName);
    final secure = (await _storage.read(key: key))?.trim() ?? '';
    if (secure.isNotEmpty) return secure;

    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(key)?.trim() ?? '';
    if (legacy.isNotEmpty) {
      await _storage.write(key: key, value: legacy);
      await prefs.remove(key);
    }
    return legacy;
  }

  Future<void> writeNamed(String name, String secret) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Secret name cannot be empty');
    }
    final key = _namedKey(normalizedName);
    final normalizedSecret = secret.trim();
    if (normalizedSecret.isEmpty) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: normalizedSecret);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
''',
)

# 2) Await actual Android permission/role state instead of accepting dialog launch.
write(
    "lib/services/permissions/nova_android_permission_bridge_service.dart",
    r'''// NOVA_VERIFIED_ANDROID_PERMISSION_RESULTS_V1
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
''',
)

# 3) Activate the complete dashboard that owns continuous listening + native orb.
replace_once(
    "lib/ui/launch/nova_launch_gate_page.dart",
    "import '../../services/settings/nova_settings_service.dart';\n",
    "import '../../services/settings/nova_settings_service.dart';\nimport '../../services/system/nova_background_bridge_service.dart';\n",
)
replace_once(
    "lib/ui/launch/nova_launch_gate_page.dart",
    "import '../nova/nova_dashboard_page.dart';\n",
    "import '../dashboard/dashboard_page.dart';\n",
)
replace_once(
    "lib/ui/launch/nova_launch_gate_page.dart",
    "  final NovaAndroidPermissionBridgeService _permissionBridgeService =\n      const NovaAndroidPermissionBridgeService();\n",
    "  final NovaAndroidPermissionBridgeService _permissionBridgeService =\n      const NovaAndroidPermissionBridgeService();\n  final NovaBackgroundBridgeService _backgroundBridgeService =\n      const NovaBackgroundBridgeService();\n",
)
replace_once(
    "lib/ui/launch/nova_launch_gate_page.dart",
    "      if (includeCallPermissions) {\n        // Call permissions remain explicit and are not forced during setup.\n      }\n",
    "      if (includeCallPermissions) {\n        if (!await _permissionBridgeService.canDrawOverlays()) {\n          await _permissionBridgeService.openOverlaySettings();\n        }\n        final battery =\n            await _backgroundBridgeService.isIgnoringBatteryOptimizations();\n        if (!battery.success) {\n          await _backgroundBridgeService.openBatteryOptimizationSettings();\n        }\n        // Call and accessibility permissions remain explicit in the dashboard.\n      }\n",
)
replace_once(
    "lib/ui/launch/nova_launch_gate_page.dart",
    "    return NovaDashboardPage(\n",
    "    return DashboardPage(\n",
)
replace_once(
    "lib/ui/launch/nova_launch_gate_page.dart",
    "      deferHeavyBootstrap: _justCompletedSetup,\n      setupRequired: false,\n",
    "      deferHeavyBootstrap: _justCompletedSetup,\n",
)

# 4) Fresh voice proof is mandatory for wake/control operations.
replace_once(
    "lib/services/identity/voice_authorization_runtime_service.dart",
    "    bool allowContinuityReuse = true,\n",
    "    bool allowContinuityReuse = false,\n",
)
replace_once(
    "lib/services/identity/voice_authorization_runtime_service.dart",
    "    bool allowContinuityReuse = true,\n",
    "    bool allowContinuityReuse = false,\n",
)
replace_once(
    "lib/services/identity/voice_authorization_runtime_service.dart",
    "    final decision = await decideFromFreshExternalSample(\n      maxDurationSeconds: maxDurationSeconds,\n      outputName: outputName,\n      minSimilarity: minSimilarity,\n    );\n\n    return decision.level == VoiceAccessLevel.owner ||\n        decision.level == VoiceAccessLevel.authorizedGuest;\n",
    "    final inspection = await inspectFreshExternalSample(\n      maxDurationSeconds: maxDurationSeconds,\n      outputName: outputName,\n      minSimilarity: minSimilarity,\n    );\n\n    return inspection.captureSucceeded &&\n        (inspection.decision.level == VoiceAccessLevel.owner ||\n            inspection.decision.level == VoiceAccessLevel.authorizedGuest);\n",
)
replace_once(
    "lib/services/identity/voice_authorization_runtime_service.dart",
    "    final decision = await decideFromFreshExternalSample(\n      maxDurationSeconds: maxDurationSeconds,\n      outputName: outputName,\n      minSimilarity: minSimilarity,\n    );\n\n    return decision.level == VoiceAccessLevel.owner ||\n        decision.level == VoiceAccessLevel.authorizedGuest;\n",
    "    final inspection = await inspectFreshExternalSample(\n      maxDurationSeconds: maxDurationSeconds,\n      outputName: outputName,\n      minSimilarity: minSimilarity,\n    );\n\n    return inspection.captureSucceeded &&\n        (inspection.decision.level == VoiceAccessLevel.owner ||\n            inspection.decision.level == VoiceAccessLevel.authorizedGuest);\n",
)

continuous = "lib/services/system/nova_continuous_listening_runtime_service.dart"
replace_once(
    continuous,
    "          lifecycleService.wake();\n          await powerService.setFullyOn(userInitiated: true);\n",
    "          final shutdownWakeInspection = await authorizationRuntimeService\n              .inspectFreshExternalSample(\n                maxDurationSeconds: 3,\n                outputName: 'nova_shutdown_wake_auth',\n                minSimilarity: 0.58,\n              );\n          final shutdownWakeAuthorized =\n              shutdownWakeInspection.captureSucceeded &&\n              (shutdownWakeInspection.decision.level ==\n                      VoiceAccessLevel.owner ||\n                  shutdownWakeInspection.decision.level ==\n                      VoiceAccessLevel.authorizedGuest);\n          if (!shutdownWakeAuthorized) {\n            if (onUnauthorizedOrStatus != null &&\n                !shutdownWakeInspection.decision.suppressStatusBroadcast) {\n              await _emitStatusIfChanged(\n                shutdownWakeInspection.decision.message.trim().isEmpty\n                    ? 'Yetkiniz bulunmamaktadır.'\n                    : shutdownWakeInspection.decision.message.trim(),\n                onUnauthorizedOrStatus,\n              );\n            }\n            await Future<void>.delayed(\n              const Duration(milliseconds: 1200),\n            );\n            continue;\n          }\n\n          lifecycleService.wake();\n          await powerService.setFullyOn(userInitiated: true);\n",
)
replace_once(
    continuous,
    "          VoiceAccessDecision? wakeDecision;\n          final bool wakeTrustedBySession =\n              trustedDailySession != null && trustedDailySession.isTrusted;\n          final bool wakeTrustedByRecent =\n              recentTrustedSpeaker != null &&\n              recentTrustedSpeaker.observedAt.isAfter(\n                DateTime.now().subtract(const Duration(hours: 20)),\n              ) &&\n              (recentTrustedSpeaker.level == VoiceAccessLevel.owner ||\n                  recentTrustedSpeaker.level ==\n                      VoiceAccessLevel.authorizedGuest);\n\n          bool wakeAuthorized = wakeTrustedBySession || wakeTrustedByRecent;\n          if (!wakeAuthorized) {\n            wakeDecision = await authorizationRuntimeService\n                .decideFromFreshExternalSample(\n                  maxDurationSeconds: 3,\n                  outputName: 'nova_wake_auth',\n                  minSimilarity: 0.58,\n                );\n            wakeAuthorized =\n                wakeDecision.level == VoiceAccessLevel.owner ||\n                wakeDecision.level == VoiceAccessLevel.authorizedGuest;\n          }\n",
    "          final wakeInspection = await authorizationRuntimeService\n              .inspectFreshExternalSample(\n                maxDurationSeconds: 3,\n                outputName: 'nova_wake_auth',\n                minSimilarity: 0.58,\n              );\n          final wakeDecision = wakeInspection.decision;\n          final wakeAuthorized =\n              wakeInspection.captureSucceeded &&\n              (wakeDecision.level == VoiceAccessLevel.owner ||\n                  wakeDecision.level == VoiceAccessLevel.authorizedGuest);\n",
)
replace_once(
    continuous,
    "                !(wakeDecision?.suppressStatusBroadcast ?? false)) {\n",
    "                !wakeDecision.suppressStatusBroadcast) {\n",
)
replace_once(
    continuous,
    "                wakeDecision?.message.trim().isEmpty != false\n                    ? 'Yetkiniz bulunmamaktadır.'\n                    : wakeDecision!.message.trim(),\n",
    "                wakeDecision.message.trim().isEmpty\n                    ? 'Yetkiniz bulunmamaktadır.'\n                    : wakeDecision.message.trim(),\n",
)
replace_once(
    continuous,
    "          _lastAuthorizedLevel =\n              wakeDecision?.level ??\n              trustedDailySession?.level ??\n              recentTrustedSpeaker?.level ??\n              VoiceAccessLevel.owner;\n",
    "          _lastAuthorizedLevel = wakeDecision.level;\n",
)
replace_once(
    continuous,
    "        final bool canReuseSpeakerIdentity =\n            hasFreshConversationAuthorization ||\n            hasDailyTrustedAuthorization ||\n            hasRecentTrustedAuthorization ||\n            (ownerPriorityActive && likelyForNova) ||\n            (hasSoftIdentityWindow && likelyForNova) ||\n            (hasRecentConversationSpeaker && likelyForNova);\n",
    "        final requiresFreshCommandAuthority =\n            _spokenIntentInterpreter.isDirectCommand(prompt);\n        final bool canReuseSpeakerIdentity =\n            !requiresFreshCommandAuthority &&\n            (hasFreshConversationAuthorization ||\n                hasDailyTrustedAuthorization ||\n                hasRecentTrustedAuthorization ||\n                (ownerPriorityActive && likelyForNova) ||\n                (hasSoftIdentityWindow && likelyForNova) ||\n                (hasRecentConversationSpeaker && likelyForNova));\n",
)
replace_once(
    continuous,
    "            !allowFamiliarConversation &&\n            !hasDailyTrustedAuthorization) {\n",
    "            !allowFamiliarConversation &&\n            (!hasDailyTrustedAuthorization ||\n                requiresFreshCommandAuthority)) {\n",
)
replace_once(
    continuous,
    "                allowContinuityReuse: true,\n",
    "                allowContinuityReuse: !requiresFreshCommandAuthority,\n",
)
replace_once(
    continuous,
    "          authorized =\n              decision.level == VoiceAccessLevel.owner ||\n              decision.level == VoiceAccessLevel.authorizedGuest;\n",
    "          authorized =\n              (!requiresFreshCommandAuthority || inspection.captureSucceeded) &&\n              (decision.level == VoiceAccessLevel.owner ||\n                  decision.level == VoiceAccessLevel.authorizedGuest);\n",
)
replace_once(
    continuous,
    "          final bool canTolerateTransientIdentityMiss =\n              hasRecentVoiceFlow &&\n",
    "          final bool canTolerateTransientIdentityMiss =\n              !requiresFreshCommandAuthority &&\n              hasRecentVoiceFlow &&\n",
)
replace_once(
    continuous,
    "        if (!authorized && hasDailyTrustedAuthorization && likelyForNova) {\n",
    "        if (!authorized &&\n            !requiresFreshCommandAuthority &&\n            hasDailyTrustedAuthorization &&\n            likelyForNova) {\n",
)

# 5) Provider request compatibility and bounded transient retry.
replace_once(
    "lib/services/api/api_service.dart",
    "    final uri = Uri.https(\n      'generativelanguage.googleapis.com',\n      '/v1beta/models/$activeModel:generateContent',\n      <String, String>{'key': execution.apiKey.trim()},\n    );\n",
    "    final uri = Uri.https(\n      'generativelanguage.googleapis.com',\n      '/v1beta/models/$activeModel:generateContent',\n    );\n",
)
replace_once(
    "lib/services/api/api_service.dart",
    "      'generationConfig': <String, dynamic>{\n        'temperature': expectedActionSummary.isNotEmpty\n            ? 0.0\n            : request.isFastResponsePriority\n                ? 0.25\n                : 0.45,\n        'maxOutputTokens': expectedActionSummary.isNotEmpty\n",
    "      'generationConfig': <String, dynamic>{\n        'maxOutputTokens': expectedActionSummary.isNotEmpty\n",
)
replace_once(
    "lib/services/api/api_service.dart",
    "      if (expectedActionSummary.isNotEmpty) 'temperature': 0,\n",
    "",
)
replace_once(
    "lib/services/api/api_service.dart",
    "  Future<_ApiHttpResponse> _postJson(\n    Uri uri, {\n    required Duration timeout,\n    required Map<String, String> headers,\n    required Map<String, dynamic> body,\n  }) async {\n    final httpClient = HttpClient()..connectionTimeout = timeout;\n    try {\n      final request = await httpClient.postUrl(uri).timeout(timeout);\n      headers.forEach(request.headers.set);\n      request.write(jsonEncode(body));\n      final response = await request.close().timeout(timeout);\n      final responseBody = await utf8.decodeStream(response).timeout(timeout);\n      return _ApiHttpResponse(\n        statusCode: response.statusCode,\n        body: responseBody,\n      );\n    } finally {\n      httpClient.close(force: true);\n    }\n  }\n",
    "  Future<_ApiHttpResponse> _postJson(\n    Uri uri, {\n    required Duration timeout,\n    required Map<String, String> headers,\n    required Map<String, dynamic> body,\n  }) async {\n    _ApiHttpResponse? lastResponse;\n    Object? lastError;\n    for (var attempt = 0; attempt < 3; attempt++) {\n      final httpClient = HttpClient()..connectionTimeout = timeout;\n      try {\n        final request = await httpClient.postUrl(uri).timeout(timeout);\n        headers.forEach(request.headers.set);\n        request.write(jsonEncode(body));\n        final response = await request.close().timeout(timeout);\n        final responseBody = await utf8.decodeStream(response).timeout(timeout);\n        final current = _ApiHttpResponse(\n          statusCode: response.statusCode,\n          body: responseBody,\n        );\n        lastResponse = current;\n        final transient = current.statusCode == 429 ||\n            current.statusCode == 408 ||\n            current.statusCode >= 500;\n        if (!transient || attempt == 2) return current;\n      } catch (error) {\n        lastError = error;\n        if (attempt == 2) rethrow;\n      } finally {\n        httpClient.close(force: true);\n      }\n      await Future<void>.delayed(\n        Duration(milliseconds: attempt == 0 ? 350 : 900),\n      );\n    }\n    if (lastResponse != null) return lastResponse;\n    throw StateError('API isteği tamamlanamadı: $lastError');\n  }\n",
)

# 6) Static regression contract proving the dormant runtime is now active and fail-closed.
write(
    "test/runtime/nova_background_authority_contract_test.dart",
    r'''import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active launch route owns continuous runtime and real overlay', () {
    final launch = File('lib/ui/launch/nova_launch_gate_page.dart').readAsStringSync();
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
    expect(runtime, contains('allowContinuityReuse: !requiresFreshCommandAuthority'));
    expect(auth, isNot(contains('bool allowContinuityReuse = true')));
  });

  test('API secrets and provider requests use hardened paths', () {
    final tokens = File('lib/core/api/nova_secure_token_store.dart').readAsStringSync();
    final api = File('lib/services/api/api_service.dart').readAsStringSync();
    expect(tokens, contains('FlutterSecureStorage'));
    expect(tokens, contains('AndroidOptions()'));
    expect(api, contains("'x-goog-api-key': execution.apiKey.trim()"));
    expect(api, isNot(contains("<String, String>{'key': execution.apiKey.trim()}")));
    expect(api, contains('current.statusCode == 429'));
  });
}
''',
)

print('NOVA runtime integration transformations applied successfully.')
