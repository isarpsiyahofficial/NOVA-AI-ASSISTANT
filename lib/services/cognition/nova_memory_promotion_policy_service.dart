// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/memory/nova_memory_retention_policy.dart';
import '../../core/memory/nova_memory_scope.dart';

class NovaMemoryPromotionPolicyService {
  const NovaMemoryPromotionPolicyService();

  NovaMemoryRetentionPolicy decide(String text) {
    final normalized = text.toLowerCase().trim();
    if (normalized.contains('bundan sonra') ||
        normalized.contains('unutma') ||
        normalized.contains('hatırla')) {
      return const NovaMemoryRetentionPolicy(
        scope: NovaMemoryScope.longTerm,
        ttlDays: 365,
        reason: 'Kalıcı davranış/tercih sinyali',
      );
    }
    if (_containsSmallTalk(normalized)) {
      return const NovaMemoryRetentionPolicy(
        scope: NovaMemoryScope.shortTerm,
        ttlDays: 0,
        reason: 'Geçici small-talk; kalıcı hafızaya yazma',
      );
    }
    if (normalized.contains('bu hafta') || normalized.contains('7 gün')) {
      return const NovaMemoryRetentionPolicy(
        scope: NovaMemoryScope.sevenDay,
        ttlDays: 7,
        reason: 'Yedi günlük bağlam sinyali',
      );
    }
    return const NovaMemoryRetentionPolicy(
      scope: NovaMemoryScope.shortTerm,
      ttlDays: 1,
      reason: 'Geçici bağlam',
    );
  }

  String buildPromptSection(String text) {
    final decision = decide(text);
    return 'Hafıza tutma kararı: ${decision.scope.name}, ${decision.ttlDays} gün, ${decision.reason}. '
        'KURAL: Gereksiz ayrıntı şişmesi yok; yalnız davranışı değiştiren sinyali sakla.';
  }

  bool _containsSmallTalk(String normalized) {
    return normalized.length < 24 ||
        normalized == 'tamam' ||
        normalized == 'hmm' ||
        normalized == 'evet' ||
        normalized.contains('günaydın') ||
        normalized.contains('iyi geceler') ||
        normalized.contains('sağ ol') ||
        normalized.contains('teşekkür');
  }
}
