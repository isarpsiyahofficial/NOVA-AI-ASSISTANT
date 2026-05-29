// NOVA_APK_STANDALONE_RUNTIME_SERVICE_V4
// Small state composer for the Nova dashboard. It does not open ports, start servers, or require OpenClaw/PC.

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/nova/nova_action_policy.dart';
import '../../core/nova/nova_runtime_contract.dart';
import '../../core/settings/nova_settings.dart';
import '../../services/call/nova_call_state_service.dart';
import '../../services/permissions/nova_android_permission_bridge_service.dart';

class NovaRuntimeSnapshot {
  final String mode;
  final bool localServerDisabled;
  final bool pcBridgeDisabled;
  final bool apiConfigured;
  final bool manualSetupCompleted;
  final bool essentialVoiceReady;
  final bool overlayReady;
  final bool callObserveReady;
  final bool backgroundRecommendedReady;
  final bool safeToAutoExecuteCallActions;
  final int readinessScore;
  final List<String> readyItems;
  final List<String> missingItems;
  final String summary;

  const NovaRuntimeSnapshot({
    required this.mode,
    required this.localServerDisabled,
    required this.pcBridgeDisabled,
    required this.apiConfigured,
    required this.manualSetupCompleted,
    required this.essentialVoiceReady,
    required this.overlayReady,
    required this.callObserveReady,
    required this.backgroundRecommendedReady,
    required this.safeToAutoExecuteCallActions,
    required this.readinessScore,
    required this.readyItems,
    required this.missingItems,
    required this.summary,
  });

  factory NovaRuntimeSnapshot.initial() {
    return const NovaRuntimeSnapshot(
      mode: NovaRuntimeContract.runtimeMode,
      localServerDisabled: true,
      pcBridgeDisabled: true,
      apiConfigured: false,
      manualSetupCompleted: false,
      essentialVoiceReady: false,
      overlayReady: false,
      callObserveReady: false,
      backgroundRecommendedReady: false,
      safeToAutoExecuteCallActions: false,
      readinessScore: 18,
      readyItems: <String>[
        'APK modu',
        'Local server kapalı',
        'PC bridge kapalı',
      ],
      missingItems: <String>['Durum henüz okunmadı'],
      summary: 'Nova APK-only runtime hazırlanıyor.',
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'mode': mode,
    'localServerDisabled': localServerDisabled,
    'pcBridgeDisabled': pcBridgeDisabled,
    'apiConfigured': apiConfigured,
    'manualSetupCompleted': manualSetupCompleted,
    'essentialVoiceReady': essentialVoiceReady,
    'overlayReady': overlayReady,
    'callObserveReady': callObserveReady,
    'backgroundRecommendedReady': backgroundRecommendedReady,
    'safeToAutoExecuteCallActions': safeToAutoExecuteCallActions,
    'readinessScore': readinessScore,
    'readyItems': readyItems,
    'missingItems': missingItems,
    'summary': summary,
  };
}

class NovaApkRuntimeService {
  static const String _manualSetupKey = 'nova_manual_setup_completed_v2';
  static const NovaActionPolicy _policy = NovaActionPolicy();

  const NovaApkRuntimeService();

  Future<bool> loadManualSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_manualSetupKey) ?? false;
  }

  Future<void> markManualSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_manualSetupKey, true);
  }

  NovaRuntimeSnapshot buildSnapshot({
    required NovaSettings settings,
    required NovaAndroidPermissionSnapshot permissions,
    required NovaCallStateSnapshot callSnapshot,
    required bool manualSetupCompleted,
    bool backgroundRunning = false,
  }) {
    final ready = <String>[
      'APK-only mod',
      'Local server yok',
      'PC/OpenClaw bağımlılığı yok',
    ];
    final missing = <String>[];

    final apiReady =
        settings.apiBrainEnabled && settings.apiKey.trim().isNotEmpty;
    if (apiReady) {
      ready.add('API beyin ayarı kayıtlı');
    } else {
      missing.add('Zeki cevap için API anahtarı');
    }

    if (manualSetupCompleted ||
        settings.activeVoiceProfileId.trim().isNotEmpty) {
      ready.add('Sahip profili hazırlanmış');
    } else {
      missing.add('Nova manuel APK kurulumu');
    }

    if (permissions.recordAudioGranted) {
      ready.add('Mikrofon izni');
    } else {
      missing.add('Mikrofon izni');
    }

    if (permissions.notificationsGranted) {
      ready.add('Bildirim izni');
    } else {
      missing.add('Bildirim izni');
    }

    if (permissions.canDrawOverlays) {
      ready.add('Overlay izni');
    } else {
      missing.add('Overlay izni');
    }

    final callObserveReady =
        settings.callHandlingEnabled &&
        (permissions.callScreeningRoleGranted ||
            permissions.readPhoneStateGranted ||
            callSnapshot.telephonyObserverReady ||
            callSnapshot.callScreeningReady);
    if (callObserveReady) {
      ready.add('Çağrı gözlem/companion hazır');
    } else if (settings.callHandlingEnabled) {
      missing.add('Çağrı gözlem rolü/izinleri');
    }

    final essentialVoiceReady = apiReady && permissions.recordAudioGranted;
    final overlayReady = permissions.canDrawOverlays;
    final backgroundReady =
        backgroundRunning || permissions.notificationsGranted;

    var score = 20;
    if (apiReady) score += 20;
    if (manualSetupCompleted || settings.activeVoiceProfileId.trim().isNotEmpty)
      score += 14;
    if (permissions.recordAudioGranted) score += 14;
    if (permissions.notificationsGranted) score += 8;
    if (permissions.canDrawOverlays) score += 10;
    if (callObserveReady) score += 8;
    if (!NovaRuntimeContract.localServerAllowed &&
        !NovaRuntimeContract.pcGatewayAllowed)
      score += 6;
    score = score.clamp(0, 100);

    final callAutoPolicy = _policy.evaluate(
      action: 'answer_call',
      ownerInitiated: false,
      ownerVerified: false,
      knownContact: callSnapshot.hasActiveNumber,
      explicitlyAllowedContact: callSnapshot.isAuthorizedManagedNumber,
      callActive: callSnapshot.inCall,
      screenLocked: true,
      userConfirmedThisAction: false,
    );

    final summary = missing.isEmpty
        ? 'Nova APK modu temel olarak hazır; yine de otomatik çağrı aksiyonları kapalı kalır.'
        : 'Nova APK modu ayakta; eksik kalan parçalar: ${missing.join(', ')}.';

    return NovaRuntimeSnapshot(
      mode: NovaRuntimeContract.runtimeMode,
      localServerDisabled: !NovaRuntimeContract.localServerAllowed,
      pcBridgeDisabled: !NovaRuntimeContract.pcGatewayAllowed,
      apiConfigured: apiReady,
      manualSetupCompleted:
          manualSetupCompleted ||
          settings.activeVoiceProfileId.trim().isNotEmpty,
      essentialVoiceReady: essentialVoiceReady,
      overlayReady: overlayReady,
      callObserveReady: callObserveReady,
      backgroundRecommendedReady: backgroundReady,
      safeToAutoExecuteCallActions: callAutoPolicy.mayExecute,
      readinessScore: score,
      readyItems: List<String>.unmodifiable(ready),
      missingItems: List<String>.unmodifiable(missing),
      summary: summary,
    );
  }

  NovaActionPolicyResult evaluateAction({
    required String action,
    bool ownerInitiated = false,
    bool ownerVerified = false,
    bool knownContact = false,
    bool explicitlyAllowedContact = false,
    bool callActive = false,
    bool screenLocked = false,
    bool userConfirmedThisAction = false,
  }) {
    return _policy.evaluate(
      action: action,
      ownerInitiated: ownerInitiated,
      ownerVerified: ownerVerified,
      knownContact: knownContact,
      explicitlyAllowedContact: explicitlyAllowedContact,
      callActive: callActive,
      screenLocked: screenLocked,
      userConfirmedThisAction: userConfirmedThisAction,
    );
  }
}
