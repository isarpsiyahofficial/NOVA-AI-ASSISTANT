// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaSessionHandoffService {
  const NovaSessionHandoffService();

  Map<String, dynamic> handshake({
    required String speakerName,
    required String topicKey,
    required String previousContinuityThread,
  }) {
    final topic = topicKey.isEmpty ? 'genel_akış' : topicKey;
    return <String, dynamic>{
      'speakerName': speakerName.isEmpty ? 'bilinmiyor' : speakerName,
      'topicKey': topic,
      'opening': previousContinuityThread.trim().isEmpty
          ? '$topic bağlamını koruyorum.'
          : '$topic bağlamına ${previousContinuityThread.trim()} üzerinden dönüyorum.',
    };
  }

  String buildPromptSection({
    required String speakerName,
    required String topicKey,
    String previousContinuityThread = '',
  }) {
    final handshakeMap = handshake(
      speakerName: speakerName,
      topicKey: topicKey,
      previousContinuityThread: previousContinuityThread,
    );
    return [
      'SESSION HANDOFF:',
      '- konuşan kişi: ${handshakeMap['speakerName']}',
      '- topic key: ${handshakeMap['topicKey']}',
      '- continuity opening: ${handshakeMap['opening']}',
      'KURAL: Yeni oturum veya yeni tur, kısa continuity el sıkışmasıyla başlar; sıfırdan başlıyormuş gibi davranma.',
    ].join('\n');
  }
}
