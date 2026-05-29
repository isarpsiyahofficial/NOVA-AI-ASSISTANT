// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaDashboardGuardDecision {
  final bool allow;
  final int minIntervalMs;
  final String reason;
  const NovaDashboardGuardDecision({
    required this.allow,
    required this.minIntervalMs,
    required this.reason,
  });
}

class NovaDashboardPerformanceGuardService {
  final Map<String, DateTime> _lastByBucket = <String, DateTime>{};
  final Map<String, String> _lastSignatureByBucket = <String, String>{};
  final Map<String, int> _burstByBucket = <String, int>{};
  DateTime _lastGlobal = DateTime.fromMillisecondsSinceEpoch(0);
  bool _heavyPhase = false;
  NovaDashboardPerformanceGuardService();
  NovaDashboardGuardDecision shouldAllow({
    required String bucket,
    String signature = '',
    bool force = false,
    int baseIntervalMs = 80,
  }) {
    final now = DateTime.now();
    if (force) {
      _commit(bucket, signature, now);
      return const NovaDashboardGuardDecision(
        allow: true,
        minIntervalMs: 0,
        reason: 'forced',
      );
    }
    final last =
        _lastByBucket[bucket] ?? DateTime.fromMillisecondsSinceEpoch(0);
    final lastSignature = _lastSignatureByBucket[bucket] ?? '';
    final burst = _burstByBucket[bucket] ?? 0;
    final interval = _dynamicInterval(
      bucket: bucket,
      base: baseIntervalMs,
      burst: burst,
      signature: signature,
    );
    if (signature.isNotEmpty &&
        signature == lastSignature &&
        now.difference(last).inMilliseconds < interval * 2) {
      return NovaDashboardGuardDecision(
        allow: false,
        minIntervalMs: interval,
        reason: 'duplicate_signature',
      );
    }
    if (now.difference(last).inMilliseconds < interval) {
      return NovaDashboardGuardDecision(
        allow: false,
        minIntervalMs: interval,
        reason: 'bucket_debounce',
      );
    }
    if (now.difference(_lastGlobal).inMilliseconds < (interval ~/ 2)) {
      return NovaDashboardGuardDecision(
        allow: false,
        minIntervalMs: interval,
        reason: 'global_debounce',
      );
    }
    _commit(bucket, signature, now);
    return NovaDashboardGuardDecision(
      allow: true,
      minIntervalMs: interval,
      reason: 'allowed',
    );
  }

  void beginHeavyPhase() {
    _heavyPhase = true;
  }

  void endHeavyPhase() {
    _heavyPhase = false;
  }

  Map<String, dynamic> snapshot() => <String, dynamic>{
    'heavyPhase': _heavyPhase,
    'buckets': _lastByBucket.keys.toList(growable: false),
    'burst': Map<String, int>.from(_burstByBucket),
  };
  void _commit(String bucket, String signature, DateTime now) {
    _lastByBucket[bucket] = now;
    _lastSignatureByBucket[bucket] = signature;
    _lastGlobal = now;
    _burstByBucket[bucket] = ((_burstByBucket[bucket] ?? 0) + 1).clamp(0, 9999);
  }

  int _dynamicInterval({
    required String bucket,
    required int base,
    required int burst,
    required String signature,
  }) {
    var value = base;
    if (_heavyPhase) value += 40;
    for (final profile in _bucketProfiles) {
      if (bucket.contains(profile.bucketContains)) value += profile.extraMs;
    }
    if (signature.isEmpty) value += 10;
    value += (burst ~/ 5) * 10;
    return value.clamp(40, 400);
  }

  static const List<_BucketProfile> _bucketProfiles = <_BucketProfile>[
    _BucketProfile(bucketContains: 'overlay', extraMs: 35),
    _BucketProfile(bucketContains: 'response', extraMs: 20),
    _BucketProfile(bucketContains: 'status', extraMs: 25),
    _BucketProfile(bucketContains: 'identity', extraMs: 15),
    _BucketProfile(bucketContains: 'voice', extraMs: 20),
    _BucketProfile(bucketContains: 'call', extraMs: 30),
    _BucketProfile(bucketContains: 'companion', extraMs: 28),
    _BucketProfile(bucketContains: 'presence', extraMs: 18),
    _BucketProfile(bucketContains: 'power', extraMs: 18),
    _BucketProfile(bucketContains: 'dashboard', extraMs: 12),
  ];
  Map<String, dynamic> buildDecisionDebug({
    required String bucket,
    String signature = '',
    int baseIntervalMs = 80,
  }) {
    final decision = shouldAllow(
      bucket: bucket,
      signature: signature,
      baseIntervalMs: baseIntervalMs,
    );
    return <String, dynamic>{
      'allow': decision.allow,
      'reason': decision.reason,
      'minIntervalMs': decision.minIntervalMs,
      'heavyPhase': _heavyPhase,
      'snapshot': snapshot(),
    };
  }

  int suggestIntervalFor(String bucket, {bool hasHeavyBootstrap = false}) {
    final burst = _burstByBucket[bucket] ?? 0;
    final previousHeavy = _heavyPhase;
    _heavyPhase = hasHeavyBootstrap || previousHeavy;
    final value = _dynamicInterval(
      bucket: bucket,
      base: 80,
      burst: burst,
      signature: 'suggest',
    );
    _heavyPhase = previousHeavy;
    return value;
  }

  void registerExternalLoad({required bool heavyPhase}) {
    _heavyPhase = heavyPhase;
  }

  static const List<String> performanceRules = <String>[
    'Aynı imza arka arkaya basılmaz.',
    'Bootstrap ağırsa debounce yükselir.',
    'Overlay, status ve response pingi aynı öncelikte akmaz.',
    'Kullanıcının gördüğü son yanıt önceliklidir.',
    'UI sadece anlamlı değişimde yenilenir.',
    'Global debouncing bucket debouncing ile birlikte çalışır.',
    'Patlayan burst durumlarında aralık kademeli artar.',
    'Görünmeyen arka plan pingi görünür etkileşimi baskılamaz.',
  ];
}

class _BucketProfile {
  final String bucketContains;
  final int extraMs;
  const _BucketProfile({required this.bucketContains, required this.extraMs});
}
