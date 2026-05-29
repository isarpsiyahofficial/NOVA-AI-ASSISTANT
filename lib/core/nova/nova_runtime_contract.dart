// NOVA_APK_STANDALONE_RUNTIME_CONTRACT_V4
// Phone-only Nova contract: APK runtime must not depend on PC, OpenClaw, localhost, LAN gateway, VPS, or Cloudflare.

class NovaRuntimeContract {
  const NovaRuntimeContract._();

  static const String productName = 'NOVA';
  static const String assistantName = 'Nova';
  static const String runtimeMode = 'apk_only_phone_local_first';
  static const String buildLine = 'NOVA_APK_STANDALONE_V4';

  static const bool pcGatewayAllowed = false;
  static const bool openClawRuntimeRequired = false;
  static const bool localServerAllowed = false;
  static const bool lanBridgeAllowed = false;
  static const bool vpsOrCloudWorkerRequired = false;
  static const bool apiBrainOptionalButSupported = true;

  static const List<String> forbiddenRuntimeDependencies = <String>[
    'openclaw_gateway',
    'pc_localhost_server',
    'lan_required_bridge',
    'cloudflare_worker_runtime',
    'vps_backend',
    'desktop_daemon',
  ];

  static const List<String> allowedRuntimeSurfaces = <String>[
    'android_apk',
    'flutter_ui',
    'android_foreground_service',
    'android_overlay',
    'android_asr_bridge',
    'android_tts_mouth',
    'android_call_observer',
    'selected_ai_provider_api',
  ];

  static bool isForbiddenEndpoint(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return normalized.contains('localhost') ||
        normalized.contains('127.0.0.1') ||
        normalized.contains('0.0.0.0') ||
        normalized.contains('openclaw') ||
        normalized.contains('cloudflare') ||
        normalized.contains('worker.dev') ||
        normalized.contains('pages.dev') ||
        normalized.contains('ws://') ||
        normalized.contains('wss://') ||
        normalized.contains(':18789') ||
        normalized.contains(':11434') ||
        normalized.contains(':18901');
  }

  static Map<String, dynamic> toMap() => const <String, dynamic>{
    'productName': productName,
    'assistantName': assistantName,
    'runtimeMode': runtimeMode,
    'buildLine': buildLine,
    'pcGatewayAllowed': pcGatewayAllowed,
    'openClawRuntimeRequired': openClawRuntimeRequired,
    'localServerAllowed': localServerAllowed,
    'lanBridgeAllowed': lanBridgeAllowed,
    'vpsOrCloudWorkerRequired': vpsOrCloudWorkerRequired,
    'apiBrainOptionalButSupported': apiBrainOptionalButSupported,
    'forbiddenRuntimeDependencies': forbiddenRuntimeDependencies,
    'allowedRuntimeSurfaces': allowedRuntimeSurfaces,
  };
}
