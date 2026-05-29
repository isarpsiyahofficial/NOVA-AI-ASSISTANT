// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
class NovaConversationStateSnapshot {
  final String activeTopic;
  final String pendingTopic;
  final String unfinishedTopic;
  final String sensitiveTopic;
  final String awaitingUserTopic;
  final String actingTopic;
  final String returnTopic;

  const NovaConversationStateSnapshot({
    this.activeTopic = '',
    this.pendingTopic = '',
    this.unfinishedTopic = '',
    this.sensitiveTopic = '',
    this.awaitingUserTopic = '',
    this.actingTopic = '',
    this.returnTopic = '',
  });

  String buildPromptSection() {
    return [
      'KONU DURUM MAKİNESİ:',
      '- aktif konu: ${activeTopic.isEmpty ? 'yok' : activeTopic}',
      '- askıdaki konu: ${pendingTopic.isEmpty ? 'yok' : pendingTopic}',
      '- bitmemiş konu: ${unfinishedTopic.isEmpty ? 'yok' : unfinishedTopic}',
      '- hassas konu: ${sensitiveTopic.isEmpty ? 'yok' : sensitiveTopic}',
      '- kullanıcı cevabı beklenen konu: ${awaitingUserTopic.isEmpty ? 'yok' : awaitingUserTopic}',
      '- Nova aksiyonu süren konu: ${actingTopic.isEmpty ? 'yok' : actingTopic}',
      '- uygun yerde dönülecek konu: ${returnTopic.isEmpty ? 'yok' : returnTopic}',
    ].join('\n');
  }
}
