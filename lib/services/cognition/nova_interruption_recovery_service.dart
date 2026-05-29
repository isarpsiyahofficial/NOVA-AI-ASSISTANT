// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/cognition/nova_interruption_record.dart';

class NovaInterruptionRecoveryService {
  static final NovaInterruptionRecoveryService instance =
      NovaInterruptionRecoveryService._();
  NovaInterruptionRecoveryService._();

  NovaInterruptionRecord? _lastInterruption;

  void markInterrupted({required String topicId, required String reason}) {
    _lastInterruption = NovaInterruptionRecord(
      interruptedTopicId: topicId,
      interruptionReason: reason,
      createdAt: DateTime.now(),
    );
  }

  String buildPromptSection() {
    final record = _lastInterruption;
    if (record == null) return 'Kesilen ana konu kaydı yok.';
    return 'Kesilen konu: ${record.interruptedTopicId}. Sebep: ${record.interruptionReason}.';
  }
}
