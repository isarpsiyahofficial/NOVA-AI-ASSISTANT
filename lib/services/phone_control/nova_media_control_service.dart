// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'nova_media_dialogue_orchestrator_service.dart';
import 'phone_control_native_bridge_service.dart';

class NovaMediaIntent {
  final bool handled;
  final bool requiresForegroundChoice;
  final bool canRunInBackground;
  final bool isAffirmativeChoice;
  final bool isNegativeChoice;
  final String spokenPrompt;
  final String backgroundCommand;
  final String backgroundValue;
  final String suggestedQuery;
  final String suggestedAppPackage;

  const NovaMediaIntent({
    required this.handled,
    this.requiresForegroundChoice = false,
    this.canRunInBackground = false,
    this.isAffirmativeChoice = false,
    this.isNegativeChoice = false,
    this.spokenPrompt = '',
    this.backgroundCommand = '',
    this.backgroundValue = '',
    this.suggestedQuery = '',
    this.suggestedAppPackage = '',
  });

  const NovaMediaIntent.unhandled() : this(handled: false);
}

class NovaMediaControlResult {
  final bool handled;
  final bool success;
  final String spokenText;

  const NovaMediaControlResult({
    required this.handled,
    required this.success,
    required this.spokenText,
  });

  const NovaMediaControlResult.unhandled()
    : handled = false,
      success = false,
      spokenText = '';
}

class NovaMediaAppChoice {
  final String packageName;
  final String label;

  const NovaMediaAppChoice({required this.packageName, required this.label});
}

class NovaMediaControlService {
  static const String _prefKey = 'nova_preferred_media_package_v2';

  final NovaPhoneControlNativeBridgeService bridgeService;
  final NovaMediaDialogueOrchestratorService dialogueOrchestratorService =
      const NovaMediaDialogueOrchestratorService();

  const NovaMediaControlService({required this.bridgeService});

  static const List<NovaMediaAppChoice> supportedApps = <NovaMediaAppChoice>[
    NovaMediaAppChoice(packageName: 'com.spotify.music', label: 'Spotify'),
    NovaMediaAppChoice(
      packageName: 'com.google.android.apps.youtube.music',
      label: 'YouTube Music',
    ),
  ];

  Future<String> getPreferredPackage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey)?.trim() ?? '';
    if (raw.isNotEmpty) return raw;
    return 'com.spotify.music';
  }

  Future<void> setPreferredPackage(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = packageName.trim();
    final allowed = supportedApps.map((e) => e.packageName).toSet();
    if (!allowed.contains(normalized)) return;
    await prefs.setString(_prefKey, normalized);
  }

  Map<String, dynamic> buildDialogueHints(
    String raw, {
    String preferredPackage = '',
  }) {
    final plan = dialogueOrchestratorService.plan(
      raw: raw,
      preferredPackage: preferredPackage,
    );
    return <String, dynamic>{
      'handled': plan.handled,
      'needsAppChoice': plan.needsAppChoice,
      'shouldAskDashboardPreference': plan.shouldAskDashboardPreference,
      'spokenResponse': '',
      'normalizedQuery': plan.normalizedQuery,
      'preferredTarget': plan.preferredTarget,
      'voiceFirst': plan.shouldStayVoiceFirst,
    };
  }

  NovaMediaIntent interpret(String raw) {
    final n = _normalize(raw);
    if (n.isEmpty) return const NovaMediaIntent.unhandled();

    if (_containsAny(n, const <String>[
      'evet',
      'olur',
      'tamam',
      'acabilirsin',
      'açabilirsin',
    ])) {
      return const NovaMediaIntent(handled: true, isAffirmativeChoice: true);
    }
    if (_containsAny(n, const <String>[
      'hayir',
      'hayır',
      'gerek yok',
      'acma',
      'açma',
      'arka planda yap',
    ])) {
      return const NovaMediaIntent(handled: true, isNegativeChoice: true);
    }

    for (final app in supportedApps) {
      final label = _normalize(app.label);
      if ((n.contains('medya uygulamasını') ||
              n.contains('varsayilan medya') ||
              n.contains('varsayılan medya') ||
              n.contains('medya sec') ||
              n.contains('medya seç')) &&
          n.contains(label)) {
        return NovaMediaIntent(
          handled: true,
          canRunInBackground: false,
          backgroundCommand: 'set_preferred_media_app',
          backgroundValue: app.packageName,
          spokenPrompt: '',
          suggestedAppPackage: app.packageName,
        );
      }
      if (n.contains('$label ac') || n.contains('$label aç')) {
        return NovaMediaIntent(
          handled: true,
          canRunInBackground: true,
          backgroundCommand: 'open_package',
          backgroundValue: app.packageName,
          suggestedAppPackage: app.packageName,
        );
      }
    }

    if (_containsAny(n, const <String>[
      'muzigi degistir',
      'müziği değiştir',
      'sonraki sarki',
      'sonraki şarkı',
      'ileri sarki',
      'ileri şarkı',
      'sonrakine gec',
      'sonrakine geç',
      'diger sarkiya gec',
      'diğer şarkıya geç',
    ])) {
      return const NovaMediaIntent(
        handled: true,
        canRunInBackground: true,
        backgroundCommand: 'media_next',
      );
    }
    if (_containsAny(n, const <String>[
      'onceki sarki',
      'önceki şarkı',
      'geri sarki',
      'geri şarkı',
      'bir onceki',
      'bir önceki',
    ])) {
      return const NovaMediaIntent(
        handled: true,
        canRunInBackground: true,
        backgroundCommand: 'media_previous',
      );
    }
    if (_containsAny(n, const <String>[
      'muzigi durdur',
      'müziği durdur',
      'muzigi kapat',
      'müziği kapat',
      'duraklat',
      'muzigi pause',
      'sarki dursun',
      'şarkı dursun',
    ])) {
      return const NovaMediaIntent(
        handled: true,
        canRunInBackground: true,
        backgroundCommand: 'media_pause',
      );
    }
    if (_containsAny(n, const <String>[
      'muzigi devam ettir',
      'müziği devam ettir',
      'devam etsin',
      'muzigi oynat',
      'müziği oynat',
      'calmaya devam et',
      'çalmaya devam et',
    ])) {
      return const NovaMediaIntent(
        handled: true,
        canRunInBackground: true,
        backgroundCommand: 'media_resume',
      );
    }
    if (_containsAny(n, const <String>[
      'muzigi kapat tamamen',
      'müziği kapat tamamen',
      'medyayi kapat',
      'medyayı kapat',
    ])) {
      return const NovaMediaIntent(
        handled: true,
        canRunInBackground: true,
        backgroundCommand: 'media_pause',
      );
    }

    if (_containsAny(n, const <String>[
      'sesi ac',
      'sesi aç',
      'sesi biraz ac',
      'sesi biraz aç',
      'sesi yuksel',
      'sesi yüksel',
      'sesi artir',
      'sesi artır',
    ])) {
      return const NovaMediaIntent(
        handled: true,
        canRunInBackground: true,
        backgroundCommand: 'media_volume_up',
      );
    }
    if (_containsAny(n, const <String>[
      'sesi kis',
      'sesi kıs',
      'sesi azalt',
      'ses azalt',
    ])) {
      return const NovaMediaIntent(
        handled: true,
        canRunInBackground: true,
        backgroundCommand: 'media_volume_down',
      );
    }
    if (_containsAny(n, const <String>['sesi kapat', 'sessize al', 'mute'])) {
      return const NovaMediaIntent(
        handled: true,
        canRunInBackground: true,
        backgroundCommand: 'media_mute',
      );
    }

    if (_containsAny(n, const <String>[
      'hot list',
      'hot hits',
      'hit list',
      'trend sarkilar',
      'trend şarkılar',
      'yeni cikmis turkce sarki',
      'yeni çıkmış türkçe şarkı',
      'yeni türkçe şarkılar',
      'yeni turkce sarkilar',
    ])) {
      final query = n.contains('yeni') ? 'Yeni Türkçe' : 'Hot Hits Türkiye';
      return NovaMediaIntent(
        handled: true,
        requiresForegroundChoice: true,
        spokenPrompt: '',
        suggestedQuery: query,
        suggestedAppPackage: 'com.spotify.music',
      );
    }

    final playMatch = RegExp(r'(?:ac|aç|cal|çal|oynat)\s+(.+)$').firstMatch(n);
    if (playMatch != null) {
      final query = playMatch.group(1)?.trim() ?? '';
      if (query.isNotEmpty) {
        return NovaMediaIntent(
          handled: true,
          requiresForegroundChoice: true,
          spokenPrompt: '',
          suggestedQuery: query,
          suggestedAppPackage: '',
        );
      }
    }

    return const NovaMediaIntent.unhandled();
  }

  Future<NovaMediaControlResult> applySelection(NovaMediaIntent intent) async {
    if (intent.backgroundCommand != 'set_preferred_media_app' ||
        intent.backgroundValue.trim().isEmpty) {
      return const NovaMediaControlResult.unhandled();
    }
    await setPreferredPackage(intent.backgroundValue);
    return NovaMediaControlResult(
      handled: true,
      success: true,
      spokenText: '',
    );
  }

  Future<NovaMediaControlResult> executeBackground(
    NovaMediaIntent intent,
  ) async {
    if (!intent.canRunInBackground || intent.backgroundCommand.trim().isEmpty) {
      return const NovaMediaControlResult.unhandled();
    }
    final result = await bridgeService.executeStep(
      command: intent.backgroundCommand,
      value: intent.backgroundValue,
    );
    final fallback = switch (intent.backgroundCommand) {
      'media_next' => 'Sonraki medya öğesine geçmeyi deneyemedim efendim.',
      'media_previous' => 'Önceki medya öğesine geçmeyi deneyemedim efendim.',
      'media_pause' => 'Medyayı duraklatamadım efendim.',
      'media_resume' => 'Medyayı devam ettiremedim efendim.',
      'media_volume_up' => 'Sesi yükseltemedim efendim.',
      'media_volume_down' => 'Sesi kısamadım efendim.',
      'media_mute' => 'Sesi kapatamadım efendim.',
      'open_package' => 'İstenen medya uygulamasını açamadım efendim.',
      _ => 'Bu medya komutunu şimdi uygulayamadım efendim.',
    };
    return NovaMediaControlResult(
      handled: true,
      success: result.success,
      spokenText: '',
    );
  }

  Future<NovaMediaControlResult> openSearchInForeground({
    required String query,
    String? packageName,
  }) async {
    final q = query.trim();
    if (q.isEmpty) {
      return const NovaMediaControlResult(
        handled: true,
        success: false,
        spokenText: '',
      );
    }
    final resolvedPackage = (packageName?.trim().isNotEmpty == true)
        ? packageName!.trim()
        : await getPreferredPackage();
    final targetPackage = resolvedPackage.trim().isEmpty
        ? await getPreferredPackage()
        : resolvedPackage;
    final result = await bridgeService.executeStep(
      command: 'open_package',
      value: targetPackage,
    );
    return NovaMediaControlResult(
      handled: true,
      success: result.success,
      spokenText: '',
    );
  }

  bool _containsAny(String text, List<String> patterns) =>
      patterns.any((p) => text.contains(_normalize(p)));

  String _normalize(String raw) => raw
      .toLowerCase()
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('û', 'u')
      .replaceAll(RegExp(r'[^a-z0-9çğıöşü ]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  List<Map<String, String>> buildSupportedAppSummary() {
    return const <Map<String, String>>[
      <String, String>{
        'package': 'com.spotify.music',
        'label': 'Spotify',
        'mode': 'music',
      },
      <String, String>{
        'package': 'com.google.android.apps.youtube.music',
        'label': 'YouTube Music',
        'mode': 'music',
      },
    ];
  }

  Map<String, dynamic> buildForegroundRequirementHint(String query) {
    final cleaned = query.trim();
    return <String, dynamic>{
      'query': cleaned,
      'needsForeground': cleaned.isNotEmpty,
      'reason': cleaned.isEmpty ? 'boş_sorgu' : 'uygulama_ici_arama_gerekli',
      'voiceFirst': true,
    };
  }

  Map<String, dynamic> buildHeardIntentAudit(String rawText) {
    final intent = interpret(rawText);
    return <String, dynamic>{
      'handled': intent.handled,
      'requiresForegroundChoice': intent.requiresForegroundChoice,
      'backgroundCommand': intent.backgroundCommand,
      'backgroundValue': intent.backgroundValue,
      'suggestedQuery': intent.suggestedQuery,
      'suggestedAppPackage': intent.suggestedAppPackage,
    };
  }

  List<String> buildMediaFallbackPlan(String command) {
    return <String>[
      'Önce dashboard tercihi kontrol edilir.',
      'Ardından güvenli paket eşleşmesi yapılır.',
      'Arka planda yürütülemeyen sorgular için foreground izinli akış seçilir.',
      'Komut başarısızsa kısa ve net sesli geri bildirim verilir. İstenen komut: $command',
    ];
  }
}
