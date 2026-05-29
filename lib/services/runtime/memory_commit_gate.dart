// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/runtime/nova_memory_commit_decision.dart';
import '../../core/runtime/nova_post_task_reflection.dart';
import '../../core/runtime/nova_post_turn_reflection.dart';

class MemoryCommitGate {
  const MemoryCommitGate();

  NovaMemoryCommitDecision decide({
    required String prompt,
    required NovaPostTurnReflection turnReflection,
    required NovaPostTaskReflection taskReflection,
    required Map<String, dynamic> learningAnalysis,
    required String relationshipLabel,
  }) {
    final persistentTeaching = learningAnalysis['persistent'] as bool? ?? false;
    final shouldStoreLearning =
        learningAnalysis['shouldStore'] as bool? ?? false;
    final relationshipCritical =
        relationshipLabel.trim().isNotEmpty ||
        _containsAny(prompt.toLowerCase(), const [
          'unutma',
          'bundan sonra',
          'beni',
          'ona',
          'hitap',
        ]);

    final persistRelationship =
        relationshipCritical ||
        turnReflection.styleConsistency >= 0.62 ||
        turnReflection.memoryValue >= 0.66;
    final persistExperience =
        shouldStoreLearning ||
        taskReflection.improvementPotential >= 0.28 ||
        taskReflection.shouldAvoid.isNotEmpty;
    final persistSemantic =
        persistentTeaching || turnReflection.memoryValue >= 0.60;
    final promoteSkill =
        taskReflection.shouldPromoteSkill && taskReflection.confidence >= 0.62;

    return NovaMemoryCommitDecision(
      shouldPersistRelationship: persistRelationship,
      shouldPersistExperience: persistExperience,
      shouldPersistSemanticSummary: persistSemantic,
      shouldPromoteSkill: promoteSkill,
      reason: _reason(
        persistRelationship,
        persistExperience,
        persistSemantic,
        promoteSkill,
      ),
    );
  }

  String _reason(bool rel, bool exp, bool sem, bool skill) {
    final reasons = <String>[];
    if (rel) reasons.add('ilişki profili davranışı etkiliyor');
    if (exp) reasons.add('görev verisi sonraki turu hızlandırabilir');
    if (sem) reasons.add('seçici kalıcı hafıza değeri var');
    if (skill) reasons.add('tekrarlanabilir kısayol doğrulanıyor');
    return reasons.isEmpty
        ? 'kalıcı commit için yeterli sinyal yok'
        : reasons.join('; ');
  }

  bool _containsAny(String text, List<String> parts) {
    for (final part in parts) {
      if (text.contains(part)) return true;
    }
    return false;
  }
}
