// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/call/call_conversation_turn.dart';

class CallIntentService {
  const CallIntentService();

  CallConversationIntent detectIntent(String input) {
    final text = input.toLowerCase().trim();

    if (text.isEmpty) {
      return CallConversationIntent.unknown;
    }

    if (_containsAny(text, const [
      'merhaba',
      'selam',
      'iyi akşamlar',
      'iyi günler',
      'alo',
    ])) {
      return CallConversationIntent.greeting;
    }

    if (_containsAny(text, const [
      'ibrahim',
      'müsait mi',
      'orada mı',
      'konuşabilir miyim',
      'ona verebilir misin',
      'telefonu verebilir misin',
    ])) {
      return CallConversationIntent.askingForOwner;
    }

    if (_containsAny(text, const [
      'not bırakayım',
      'mesaj bırakayım',
      'iletir misin',
      'şunu söyle',
      'not al',
    ])) {
      return CallConversationIntent.leavingNote;
    }

    if (_containsAny(text, const [
      'acil',
      'önemli',
      'hemen',
      'çok önemli',
      'beklemesin',
    ])) {
      return CallConversationIntent.urgencyCheck;
    }

    if (_containsAny(text, const [
      'sonra arasın',
      'geri dönüş yapsın',
      'bana dönsün',
      'arayabilir mi',
    ])) {
      return CallConversationIntent.callbackRequest;
    }

    if (_containsAny(text, const [
      'görüşürüz',
      'tamamdır',
      'teşekkür ederim',
      'sağ ol',
      'kapatabiliriz',
      'hoşça kal',
    ])) {
      return CallConversationIntent.ending;
    }

    if (_containsAny(text, const [
      'nasılsın',
      'gerçekten yapay zeka mısın',
      'sen kimsin',
      'ne yapıyorsun',
      'sohbet edelim',
    ])) {
      return CallConversationIntent.smallTalk;
    }

    return CallConversationIntent.unknown;
  }

  bool _containsAny(String text, List<String> phrases) {
    for (final phrase in phrases) {
      if (text.contains(phrase)) return true;
    }
    return false;
  }
}
