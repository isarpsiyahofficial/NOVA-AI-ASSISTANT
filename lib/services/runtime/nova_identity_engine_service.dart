// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/runtime/nova_identity_continuity.dart';
import '../../core/runtime/nova_relationship_profile.dart';
import '../../core/runtime/nova_autobiographic_memory.dart';
import '../../core/runtime/nova_shared_world_state.dart';

class NovaIdentityEngineService {
  const NovaIdentityEngineService();

  NovaIdentityContinuity resolve({
    required NovaRelationshipProfile profile,
    required NovaAutobiographicMemory autobiographicMemory,
    required NovaSharedWorldState sharedWorldState,
    required String latestPrompt,
  }) {
    final threads = <String>[
      if (sharedWorldState.continuityThread.trim().isNotEmpty)
        sharedWorldState.continuityThread.trim(),
      if (autobiographicMemory.unresolvedThreads.isNotEmpty)
        autobiographicMemory.unresolvedThreads.first,
      if (autobiographicMemory.sharedHabits.isNotEmpty)
        'alışkanlık: ' + autobiographicMemory.sharedHabits.first,
    ];
    final anchors = <String>[
      if (profile.displayName.trim().isNotEmpty) 'kişi:' + profile.displayName,
      'evre:' + profile.relationshipStage,
      if (autobiographicMemory.storyPhase.trim().isNotEmpty)
        'hikaye:' + autobiographicMemory.storyPhase,
      if (sharedWorldState.userMode.trim().isNotEmpty)
        'mod:' + sharedWorldState.userMode,
    ];
    return NovaIdentityContinuity(
      samePersonSignal: profile.relationshipStage == 'tanışma'
          ? 'tanıdık ama ölçülü başlangıç'
          : 'aynı çizgide devam eden tanıdık kimlik',
      carryForwardThreads: threads,
      continuityAnchors: anchors,
      sessionHandoff: latestPrompt.length > 140
          ? 'önce kısa continuity özetiyle gir, sonra yeni noktayı işle'
          : 'sıfırdan başlama; mevcut bağlamı sessizce taşı',
    );
  }
}
