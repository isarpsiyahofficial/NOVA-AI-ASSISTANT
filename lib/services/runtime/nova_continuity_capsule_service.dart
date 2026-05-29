// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/runtime/nova_continuity_capsule.dart';

class NovaContinuityCapsuleService {
  const NovaContinuityCapsuleService();

  NovaContinuityCapsule build({
    required String speakerName,
    required String relationshipLabel,
    required String contextMode,
    required String topicKey,
    required String prompt,
    required String reply,
  }) {
    final summary = [
      if (speakerName.trim().isNotEmpty) speakerName.trim() + ' ile continuity',
      'bağlam ' + contextMode,
      'kullanıcı: ' + prompt.trim(),
      'Nova: ' + reply.trim(),
      'aynı kişi ve aynı ilişki çizgisi korunmalı',
    ].join(' | ');
    return NovaContinuityCapsule(
      topicKey: topicKey.isEmpty
          ? 'continuity:general'
          : 'continuity:' + topicKey,
      summary: summary,
      tags: <String>[
        'continuity_capsule',
        if (speakerName.trim().isNotEmpty)
          'speaker:' + speakerName.trim().toLowerCase(),
        if (relationshipLabel.trim().isNotEmpty)
          'relation:' + relationshipLabel.trim().toLowerCase(),
        'context:' + contextMode,
      ],
      importance: 0.86,
    );
  }
}
