// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/runtime/nova_autobiographic_memory.dart';

class NovaAutobiographicIdentityBridgeService {
  const NovaAutobiographicIdentityBridgeService();

  Map<String, dynamic> summarize(NovaAutobiographicMemory memory) {
    final identityWeight = <String>[];
    if (memory.turningPoints.isNotEmpty) identityWeight.add('turning_points');
    if (memory.repairedMisunderstandings.isNotEmpty)
      identityWeight.add('repaired_misunderstandings');
    if (memory.unresolvedThreads.isNotEmpty)
      identityWeight.add('unresolved_threads');
    return <String, dynamic>{
      'storyPhase': memory.storyPhase,
      'identityWeight': identityWeight,
      'turningPoints': memory.turningPoints.take(4).toList(growable: false),
      'repaired': memory.repairedMisunderstandings
          .take(4)
          .toList(growable: false),
      'unresolved': memory.unresolvedThreads.take(4).toList(growable: false),
    };
  }

  String buildPromptSection(NovaAutobiographicMemory memory) {
    final summary = summarize(memory);
    return [
      'AUTOBIOGRAPHIC IDENTITY BRIDGE:',
      '- story phase: ${summary['storyPhase']}',
      if ((summary['turningPoints'] as List).isNotEmpty)
        '- dönüm noktaları: ${(summary['turningPoints'] as List).join(' | ')}',
      if ((summary['repaired'] as List).isNotEmpty)
        '- aşılmış yanlış anlamalar: ${(summary['repaired'] as List).join(' | ')}',
      if ((summary['unresolved'] as List).isNotEmpty)
        '- yarım kalan izler: ${(summary['unresolved'] as List).join(' | ')}',
      'KURAL: Normal hafıza sadece kişiyi değil, “bizim aramızda ne birikti” hissini de taşısın.',
    ].join('\n');
  }
}
