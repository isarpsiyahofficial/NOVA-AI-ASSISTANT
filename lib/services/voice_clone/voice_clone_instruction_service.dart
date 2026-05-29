// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class VoiceCloneInstructionResult {
  final bool shouldClone;
  final String targetStyleInstruction;
  final String suggestedName;

  const VoiceCloneInstructionResult({
    required this.shouldClone,
    required this.targetStyleInstruction,
    required this.suggestedName,
  });

  const VoiceCloneInstructionResult.empty()
    : shouldClone = false,
      targetStyleInstruction = '',
      suggestedName = '';
}

class VoiceCloneInstructionService {
  const VoiceCloneInstructionService();

  VoiceCloneInstructionResult interpret(String input) {
    final text = input.trim();
    final lower = text.toLowerCase();

    if (text.isEmpty) {
      return const VoiceCloneInstructionResult.empty();
    }

    final wantsClone =
        lower.contains('bu sesi klonla') ||
        lower.contains('sesi kendine klonla') ||
        lower.contains('kütüphanene eklesene') ||
        lower.contains('bu ses sana yakışır');

    if (!wantsClone) {
      return const VoiceCloneInstructionResult.empty();
    }

    return VoiceCloneInstructionResult(
      shouldClone: true,
      targetStyleInstruction: text,
      suggestedName: 'Klon Ses ${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
