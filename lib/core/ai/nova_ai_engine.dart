// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../learning/learning_engine.dart';
import '../learning/learned_rule.dart';

class NovaAiEngine {
  final LearningEngine learningEngine;

  const NovaAiEngine({required this.learningEngine});

  Future<NovaResponse> processInput(String input) async {
    final String normalizedInput = input.trim();

    // Legacy engine is now only a compatibility reader for learned rules.
    // It must not synthesize independent/static Nova speech because active
    // voice decisions must go through NovaAiService -> SingleBrainAuthority.
    const String quickReply = '';

    // Öğrenilmiş kuralları kontrol et; learned rule varsa bile doğal konuşma
    // otoritesi sayılmaz, üst hotpath bunu ayrıca SingleBrain'e taşımalıdır.
    final learnedResponse = await learningEngine.process(normalizedInput);

    if (learnedResponse != null && learnedResponse.trim().isNotEmpty) {
      return NovaResponse(
        quickReply: quickReply,
        fullResponse: _normalizeFullResponse(
          learnedResponse,
          quickReply: quickReply,
        ),
      );
    }

    return const NovaResponse(quickReply: '', fullResponse: '');
  }

  String _buildQuickReply(String input) {
    final String lowered = input.toLowerCase();

    if (lowered.isEmpty) {
      return 'Buyurun efendim.';
    }

    if (_containsAny(lowered, const [
      'acil',
      'hemen',
      'dikkat',
      'uyan',
      'yardım',
    ])) {
      return 'Dinliyorum efendim.';
    }

    if (_containsAny(lowered, const [
      'araştır',
      'incele',
      'bak',
      'kontrol et',
    ])) {
      return 'Hemen bakıyorum efendim.';
    }

    return 'Buyurun efendim.';
  }

  String _defaultResponse(String input) {
    final String lowered = input.toLowerCase().trim();

    if (lowered.isEmpty) {
      return 'Ne yapmamı istediğinizi söylerseniz hemen ilgilenirim efendim.';
    }

    if (_containsAny(lowered, const [
      'merhaba',
      'selam',
      'günaydın',
      'iyi akşamlar',
    ])) {
      return 'Merhaba efendim. Hazırım, ne yapmamı istersiniz?';
    }

    if (_containsAny(lowered, const ['nasılsın', 'iyi misin'])) {
      return 'Hazırım efendim. Sistemler çalışıyor. Size nasıl yardımcı olayım?';
    }

    if (_containsAny(lowered, const ['kim', 'nesin', 'sen kimsin'])) {
      return 'Ben Nova efendim. Size yardımcı olmak, görevlerinizi yönetmek ve gerektiğinde öğrenmek için buradayım.';
    }

    if (_containsAny(lowered, const [
      'araştır',
      'incele',
      'kontrol et',
      'öğren',
      'chatgpt',
    ])) {
      return 'Bu isteği araştırma akışıyla ele alabilirim efendim. Uygun izinleri verdiğinizde dış kaynağa danışırım.';
    }

    if (_containsAny(lowered, const ['hatırlat', 'not al', 'unutma'])) {
      return 'Bunu hatırlatma veya not akışıyla ele alabilirim efendim. İsterseniz zamanı ya da ayrıntıyı netleştirelim.';
    }

    if (_containsAny(lowered, const ['kapat', 'uyu', 'pasif', 'sessiz'])) {
      return 'Güç ve çalışma durumunu isteğinize göre ayarlayabilirim efendim.';
    }

    return 'İsteğinizi aldım efendim. Gerekli zinciri çalıştırıp en doğru şekilde yardımcı olmaya hazırım.';
  }

  String _normalizeFullResponse(String response, {required String quickReply}) {
    final String trimmed = response.trim();

    if (trimmed.isEmpty) {
      return '$quickReply Uygun bir yanıt oluşturamadım efendim.';
    }

    if (trimmed.startsWith(quickReply)) {
      return trimmed;
    }

    if (trimmed.startsWith('Buyurun efendim.') ||
        trimmed.startsWith('Dinliyorum efendim.') ||
        trimmed.startsWith('Hemen bakıyorum efendim.')) {
      return trimmed;
    }

    return '$quickReply $trimmed';
  }

  bool _containsAny(String text, List<String> phrases) {
    for (final String phrase in phrases) {
      if (text.contains(phrase)) {
        return true;
      }
    }
    return false;
  }

  Future<void> teachUserRule({
    required String trigger,
    required String action,
  }) async {
    await learningEngine.teach(
      trigger: trigger,
      action: action,
      priority: RulePriority.user,
    );
  }

  Future<void> teachFromChatGPT({
    required String trigger,
    required String action,
  }) async {
    await learningEngine.teach(
      trigger: trigger,
      action: action,
      priority: RulePriority.chatgpt,
    );
  }
}

class NovaResponse {
  final String quickReply;
  final String fullResponse;

  const NovaResponse({required this.quickReply, required this.fullResponse});
}
