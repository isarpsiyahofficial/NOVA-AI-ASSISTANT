// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/runtime/nova_post_task_reflection.dart';
import '../../core/runtime/nova_post_turn_reflection.dart';

class PostTaskReflectionService {
  const PostTaskReflectionService();

  NovaPostTaskReflection evaluate({
    required String taskKey,
    required String prompt,
    required String reply,
    required NovaPostTurnReflection turnReflection,
    required double durationSeconds,
    required int turnCount,
    required int correctionCount,
  }) {
    final keep = <String>[];
    final avoid = <String>[];

    if (turnReflection.memoryValue >= 0.55)
      keep.add('önce ilgili hafızayı yüklemek faydalı');
    if (turnReflection.styleConsistency >= 0.66)
      keep.add('aynı ilişki tonunu korumak işe yaradı');
    if (reply.length <= 240) keep.add('ilk cevabı kısa tutmak iyi çalıştı');
    if (durationSeconds <= 18) keep.add('cevap zinciri yeterince hızlı');

    if (turnReflection.repairNeed >= 0.60)
      avoid.add('ilk yorumda acele karar verme');
    if (turnReflection.shouldReduceQuestionsNextTurn)
      avoid.add('aynı turda iki veya daha fazla takip sorusu');
    if (durationSeconds > 30) avoid.add('uzun işleme zinciri');
    if (reply.length > 280) avoid.add('nefessiz uzun cevap');
    if (correctionCount > 0) avoid.add('düzeltmeye açık belirsiz ifade');

    final improvementPotential =
        ((durationSeconds / 40.0).clamp(0.0, 1.0) * 0.50) +
        ((correctionCount / 3.0).clamp(0.0, 1.0) * 0.25) +
        ((turnCount / 5.0).clamp(0.0, 1.0) * 0.25);
    final confidence =
        ((turnReflection.voiceNaturalness * 0.30) +
                (turnReflection.styleConsistency * 0.25) +
                ((1.0 - turnReflection.repairNeed) * 0.20) +
                ((1.0 - (correctionCount / 3.0).clamp(0.0, 1.0)) * 0.25))
            .clamp(0.0, 0.98);

    final summary = _buildSummary(
      taskKey: taskKey,
      keep: keep,
      avoid: avoid,
      durationSeconds: durationSeconds,
      improvementPotential: improvementPotential,
    );

    return NovaPostTaskReflection(
      taskKey: taskKey,
      summary: summary,
      shouldKeep: keep,
      shouldAvoid: avoid,
      shouldPromoteSkill:
          confidence >= 0.62 && (keep.isNotEmpty || durationSeconds <= 22),
      improvementPotential: improvementPotential.clamp(0.0, 1.0),
      confidence: confidence,
    );
  }

  String _buildSummary({
    required String taskKey,
    required List<String> keep,
    required List<String> avoid,
    required double durationSeconds,
    required double improvementPotential,
  }) {
    final pieces = <String>['$taskKey için'];
    if (keep.isNotEmpty) {
      pieces.add('korunacak: ${keep.take(2).join(', ')}');
    }
    if (avoid.isNotEmpty) {
      pieces.add('azaltılacak: ${avoid.take(2).join(', ')}');
    }
    pieces.add('süre: ${durationSeconds.toStringAsFixed(1)} sn');
    if (improvementPotential >= 0.55) {
      pieces.add('bir sonraki turda daha kısa rota denenmeli');
    }
    return pieces.join(' | ');
  }
}
