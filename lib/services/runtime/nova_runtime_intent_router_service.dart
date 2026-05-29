// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/runtime/nova_runtime_intent.dart';

class NovaRuntimeIntentRouterService {
  const NovaRuntimeIntentRouterService();

  NovaRuntimeIntentMatch resolve(String rawInput) {
    final normalized = _normalize(rawInput);
    if (normalized.isEmpty) {
      return const NovaRuntimeIntentMatch(
        intent: NovaRuntimeIntent.generalConversation,
        confidence: 0,
        normalizedCommand: '',
        reason: 'empty_input',
        riskLevel: NovaIntentRiskLevel.low,
        allowedContexts: <NovaAllowedContext>[NovaAllowedContext.general],
      );
    }

    final matches = <NovaRuntimeIntentMatch>[
      _matchStatus(normalized),
      _matchStartListening(normalized),
      _matchStopListening(normalized),
      _matchSleep(normalized),
      _matchWake(normalized),
      _matchShutdown(normalized),
      _matchBatterySaver(normalized),
      _matchLimbo(normalized),
      _matchAnswerCall(normalized),
      _matchRejectCall(normalized),
      _matchHandoverToNova(normalized),
      _matchHandoverToUser(normalized),
      _matchSelfRepair(normalized),
      _matchDebug(normalized),
      _matchReminder(normalized),
    ]..removeWhere((e) => e.confidence <= 0);

    if (matches.isEmpty) {
      return NovaRuntimeIntentMatch(
        intent: NovaRuntimeIntent.generalConversation,
        confidence: 0.20,
        normalizedCommand: normalized,
        reason: 'fallback_general_conversation',
        riskLevel: NovaIntentRiskLevel.low,
        allowedContexts: const <NovaAllowedContext>[NovaAllowedContext.general],
      );
    }

    matches.sort((a, b) => b.confidence.compareTo(a.confidence));
    return matches.first;
  }

  NovaRuntimeIntentMatch _matchStatus(String n) => NovaRuntimeIntentMatch(
    intent: NovaRuntimeIntent.statusReport,
    confidence: _scoreAny(n, const [
      'durum',
      'sistem durumu',
      'hangi sistemler acik',
      'neler calisiyor',
      'kontrol et',
      'kendini tani',
      'rapor ver',
      'genel durum',
      'saglik raporu',
      'calisiyor musun',
      'modulleri kontrol et',
      'butun zinciri kontrol et',
      'kendini tani ve anlat',
    ]),
    normalizedCommand: n,
    reason: 'status',
  );
  NovaRuntimeIntentMatch _matchStartListening(String n) =>
      NovaRuntimeIntentMatch(
        intent: NovaRuntimeIntent.startListening,
        confidence: _scoreAny(n, const [
          'beni dinle',
          'dinlemeye basla',
          'surekli dinle',
          'uyan ve dinle',
          'aktif dinleme',
          'dinleme moduna gec',
          'komut bekle',
          'her an dinle',
          'hazir bekle',
          'benden komut bekle',
        ]),
        normalizedCommand: n,
        reason: 'start_listening',
      );
  NovaRuntimeIntentMatch _matchStopListening(String n) =>
      NovaRuntimeIntentMatch(
        intent: NovaRuntimeIntent.stopListening,
        confidence: _scoreAny(n, const [
          'dinlemeyi kapat',
          'beni dinleme',
          'sus ve bekle',
          'pasif dinleme',
          'mikrofonu dinleme modundan cikar',
          'dinlemeyi durdur',
          'simdilik sus',
          'yalnizca bekle',
        ]),
        normalizedCommand: n,
        reason: 'stop_listening',
      );
  NovaRuntimeIntentMatch _matchSleep(String n) => NovaRuntimeIntentMatch(
    intent: NovaRuntimeIntent.sleepMode,
    confidence: _scoreAny(n, const [
      'uyku moduna gec',
      'uyu nova',
      'pasif moda gec',
      'beni rahatsiz etme',
      'uykuya gec',
      'uyuyacagim',
      'isim var',
      'mesgulum',
      'uykuya don',
      'uyku modu',
      'gece moduna gec',
      'benim yerime sen bak',
      'bu gece cagirilara sen bak',
      'gece moduna al',
      'ben uyuyacagim sen bak',
      'bugun sen ilgilen',
      'telefonlara bakamiyorum sen bak',
      'telefonlara bakamicam sen bak',
      'telefonlara bakamayacagim sen bak',
      'ben telefona bakamayacagim',
      'ben telefona bakamiyorum',
      'telefonlara sen bak',
      'cagrilara sen bak',
      'bugun telefonlara sen bak',
    ]),
    normalizedCommand: n,
    reason: 'sleep',
  );
  NovaRuntimeIntentMatch _matchWake(String n) => NovaRuntimeIntentMatch(
    intent: NovaRuntimeIntent.wakeMode,
    confidence: _scoreAny(n, const [
      'uyan nova',
      'aktif ol',
      'tam guce gec',
      'uyan ve hazir ol',
      'kendine gel',
      'gel nova',
      'uyan',
      'geri gel',
      'tam guc modu',
      'hazir ol',
      'tam performansa gec',
      'nova burada misin',
      'nova burda misin',
      'burada misin nova',
      'burda misin nova',
    ]),
    normalizedCommand: n,
    reason: 'wake',
  );
  NovaRuntimeIntentMatch _matchShutdown(String n) => NovaRuntimeIntentMatch(
    intent: NovaRuntimeIntent.shutdownMode,
    confidence: _scoreAny(n, const [
      'tamamen kapan',
      'kendini kapat',
      'full kapat',
      'tam kapat',
      'cikis yap ve bekle',
      'tam kapali mod',
      'full shutdown',
      'tamamen uykuya dal',
    ]),
    normalizedCommand: n,
    reason: 'shutdown',
  );
  NovaRuntimeIntentMatch _matchBatterySaver(String n) => NovaRuntimeIntentMatch(
    intent: NovaRuntimeIntent.batterySaverMode,
    confidence: _scoreAny(n, const [
      'pil tasarrufu',
      'tasarruf moduna gec',
      'guc tasarrufu',
      'ekonomi modu',
      'tasarruf modu',
      'pil moduna gec',
      'tasarrufa gec',
      'dusuk guc',
      'enerji tasarrufu',
    ]),
    normalizedCommand: n,
    reason: 'battery_saver',
  );
  NovaRuntimeIntentMatch _matchLimbo(String n) => NovaRuntimeIntentMatch(
    intent: NovaRuntimeIntent.limboMode,
    confidence: _scoreAny(n, const [
      'araf modu',
      'arafa gec',
      'arafa al',
      'sessiz bekle',
      'sadece cagri ve hatirlatma',
      'yalnizca cagri ve hatirlatma',
      'arada kal',
      'orta mod',
    ]),
    normalizedCommand: n,
    reason: 'limbo',
  );
  NovaRuntimeIntentMatch _matchAnswerCall(String n) => NovaRuntimeIntentMatch(
    intent: NovaRuntimeIntent.answerCall,
    confidence: _scoreAny(n, const [
      'cevapla',
      'cagriyi cevapla',
      'cagriyi ac',
      'telefonu ac',
      'sen ac',
      'hoparlorle cevapla',
      'hoparlörle cevapla',
      'ac sen konus',
      'aç sen konuş',
    ]),
    normalizedCommand: n,
    reason: 'answer_call',
    target: 'call',
    riskLevel: NovaIntentRiskLevel.high,
    needsConfirmation: true,
    allowedContexts: const <NovaAllowedContext>[
      NovaAllowedContext.activeCall,
      NovaAllowedContext.ownerConfirmed,
    ],
  );
  NovaRuntimeIntentMatch _matchRejectCall(String n) => NovaRuntimeIntentMatch(
    intent: NovaRuntimeIntent.rejectCall,
    confidence: _scoreAny(n, const [
      'reddet',
      'mesgul at',
      'kapat cagrıyı',
      'aramayi sonlandir',
      'cagriyi reddet',
    ]),
    normalizedCommand: n,
    reason: 'reject_call',
    target: 'call',
    riskLevel: NovaIntentRiskLevel.high,
    needsConfirmation: true,
    allowedContexts: const <NovaAllowedContext>[
      NovaAllowedContext.activeCall,
      NovaAllowedContext.ownerConfirmed,
    ],
  );
  NovaRuntimeIntentMatch _matchHandoverToNova(String n) =>
      NovaRuntimeIntentMatch(
        intent: NovaRuntimeIntent.handOverCallToNova,
        confidence: _scoreAny(n, const [
          'sen devral',
          'cagriyi sen yonet',
          'nova devral',
          'telefona sen bak',
          'sen konus',
          'sen cevapla',
          'cevapla sen konus',
          'ac sen konus',
          'aç sen konuş',
          'telefonu benim icin ac hoparlore ver',
          'telefonu benim için aç hoparlöre ver',
        ]),
        normalizedCommand: n,
        reason: 'handover_to_nova',
        target: 'call',
        riskLevel: NovaIntentRiskLevel.high,
        needsConfirmation: true,
        allowedContexts: const <NovaAllowedContext>[
          NovaAllowedContext.activeCall,
          NovaAllowedContext.ownerConfirmed,
        ],
      );
  NovaRuntimeIntentMatch _matchHandoverToUser(String n) =>
      NovaRuntimeIntentMatch(
        intent: NovaRuntimeIntent.handOverCallToUser,
        confidence: _scoreAny(n, const [
          'cagriyi bana birak',
          'ben devralayim',
          'sus ben konusayim',
          'kullaniciya devret',
          'bana aktar',
          'mikrofonu bana ver',
          'hoparlorle ver ben konusayim',
          'hoparlörle ver ben konuşayım',
          'telefonu bana ver',
          'ben acarim',
          'ben açarım',
        ]),
        normalizedCommand: n,
        reason: 'handover_to_user',
        target: 'call',
        riskLevel: NovaIntentRiskLevel.medium,
        needsConfirmation: false,
        allowedContexts: const <NovaAllowedContext>[
          NovaAllowedContext.activeCall,
        ],
      );
  NovaRuntimeIntentMatch _matchSelfRepair(String n) {
    final s = _scoreAny(n, const [
      'kendini onar',
      'onarim baslat',
      'sorunu onar',
      'hata ayikla',
      'repair modunu ac',
      'onarim paneli',
    ]);
    return NovaRuntimeIntentMatch(
      intent: s >= 0.74
          ? NovaRuntimeIntent.startSelfRepair
          : NovaRuntimeIntent.openSelfRepair,
      confidence: s,
      normalizedCommand: n,
      reason: 'self_repair',
      target: 'self_repair',
      riskLevel: NovaIntentRiskLevel.high,
      needsConfirmation: true,
      allowedContexts: const <NovaAllowedContext>[
        NovaAllowedContext.selfRepairWindow,
        NovaAllowedContext.ownerConfirmed,
      ],
    );
  }

  NovaRuntimeIntentMatch _matchDebug(String n) => NovaRuntimeIntentMatch(
    intent: NovaRuntimeIntent.debugSystems,
    confidence: _scoreAny(n, const [
      'debug',
      'tani koy',
      'hata logu',
      'sistemleri tara',
      'butun sistemleri kontrol et',
      'runtime kontrolu',
    ]),
    normalizedCommand: n,
    reason: 'debug',
  );
  NovaRuntimeIntentMatch _matchReminder(String n) => NovaRuntimeIntentMatch(
    intent: NovaRuntimeIntent.reminderAction,
    confidence: _scoreAny(n, const [
      'hatirlat',
      'not al',
      'beni uyar',
      'alarm kur',
      'sonra soyle',
    ]),
    normalizedCommand: n,
    reason: 'reminder',
  );

  double _scoreAny(String text, List<String> phrases) {
    final foldedText = _foldTurkish(text);
    double best = 0;
    for (final phrase in phrases) {
      final foldedPhrase = _foldTurkish(phrase);
      if (foldedPhrase.isEmpty) continue;
      if (foldedText.contains(foldedPhrase)) {
        final density =
            foldedPhrase.length / foldedText.length.clamp(1, 1000000);
        final exactBonus = foldedText == foldedPhrase ? 0.10 : 0.0;
        final score = (0.72 + density + exactBonus).clamp(0.0, 0.99);
        if (score > best) best = score;
      }
    }
    return best;
  }

  String _normalize(String input) {
    return _foldTurkish(input)
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _foldTurkish(String input) {
    return input
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u');
  }
}
