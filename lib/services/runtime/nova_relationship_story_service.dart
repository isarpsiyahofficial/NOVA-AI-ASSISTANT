// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/runtime/nova_autobiographic_memory.dart';
import '../../core/runtime/nova_relationship_profile.dart';
import '../../core/runtime/nova_relationship_story_arc.dart';

class NovaRelationshipStoryService {
  const NovaRelationshipStoryService();

  NovaRelationshipStoryArc resolve({
    required NovaRelationshipProfile profile,
    required NovaAutobiographicMemory autobiographicMemory,
  }) {
    final title =
        '${profile.displayName.isEmpty ? 'Bu ilişki' : profile.displayName} ile ortak hikâye';
    final currentBeat = _currentBeat(profile, autobiographicMemory);
    final arcEvents = <String>[
      ...autobiographicMemory.turningPoints,
      ...autobiographicMemory.trustMoments,
    ].take(6).toList(growable: false);
    return NovaRelationshipStoryArc(
      title: title,
      currentBeat: currentBeat,
      arcEvents: arcEvents,
      repairWins: autobiographicMemory.repairedMisunderstandings
          .take(4)
          .toList(growable: false),
      fragileZones: autobiographicMemory.unresolvedThreads
          .take(4)
          .toList(growable: false),
    );
  }

  String _currentBeat(
    NovaRelationshipProfile profile,
    NovaAutobiographicMemory memory,
  ) {
    if (profile.relationshipStage == 'kırılma sonrası toparlama') {
      return 'Sakin onarım ve güven yeniden örülmesi öncelikli.';
    }
    if (memory.storyPhase.contains('oturmuş')) {
      return 'Ortak dil oturmuş; ezbere kaçmadan doğal tanışıklık korunmalı.';
    }
    if (profile.relationshipStage == 'rutinleşme') {
      return 'Tanıdıklık yüksek; küçük ritüeller doğal ama abartısız kullanılmalı.';
    }
    return 'İlişki akıyor; bugünkü ton geçmişte işe yarayan çizgiyle uyumlu olmalı.';
  }
}
