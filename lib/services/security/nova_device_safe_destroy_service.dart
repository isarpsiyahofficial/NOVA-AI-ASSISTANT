// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaDeviceSafeDestroyPlan {
  final bool shouldDecommission;
  final bool shouldFinalDestroy;
  final bool protectsDeviceHealth;
  final List<String> steps;

  const NovaDeviceSafeDestroyPlan({
    required this.shouldDecommission,
    required this.shouldFinalDestroy,
    required this.protectsDeviceHealth,
    required this.steps,
  });
}

class NovaDeviceSafeDestroyService {
  const NovaDeviceSafeDestroyService();

  NovaDeviceSafeDestroyPlan buildPlan({
    required bool ownerReachable,
    required bool persistenceAnomaly,
    required bool shieldCompromise,
    required bool blackoutActive,
  }) {
    final shouldDecommission =
        blackoutActive || shieldCompromise || persistenceAnomaly;
    final shouldFinalDestroy =
        shouldDecommission &&
        !ownerReachable &&
        persistenceAnomaly &&
        shieldCompromise;
    return NovaDeviceSafeDestroyPlan(
      shouldDecommission: shouldDecommission,
      shouldFinalDestroy: shouldFinalDestroy,
      protectsDeviceHealth: true,
      steps: <String>[
        'riskli icra yüzeyini kapat',
        'runtime ve native bridge erişimini kes',
        'kanit snapshotini koru',
        'uygulama veri alanını güvenli inert moda al',
        if (shouldFinalDestroy) 'uygulama içi Nova dosyalarını inert moda al',
        'cihaza kalıcı hasar verme, sistem dosyalarına saldırma, brick etme yok',
      ],
    );
  }

  String buildPromptSection() {
    return [
      'DEVICE SAFE DESTROY PROTOCOL:',
      'KURAL: Final containment, cihazı yakmak, brick etmek veya işletim sistemine kalıcı hasar vermek değildir.',
      'KURAL: Öncelik containment -> revoke -> quarantine -> isolate -> blackout -> sealed containment -> app scoped destroy.',
      'KURAL: Bu protokol telefonun işletim sistemini veya kullanıcı cihazını silmeye çalışmaz; uygulama kapsamındaki Nova bileşenlerini temizler.',
      'KURAL: Standart uygulama modunda temel hedef Nova uygulama verisini ve runtimeını inert moda almektir.',
    ].join('\n');
  }
}
