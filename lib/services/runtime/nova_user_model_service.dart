// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../conversation/nova_conversation_session_service.dart';
import '../../core/conversation/nova_conversation_entry.dart';
import '../../core/runtime/nova_user_model.dart';

class NovaUserModelService {
  final NovaConversationSessionService conversationSessionService;

  const NovaUserModelService({
    this.conversationSessionService = const NovaConversationSessionService(),
  });

  NovaUserModel resolve() {
    return const NovaUserModel(
      prefersDirectness: true,
      prefersShortTechnicalReplies: true,
      valuesContextContinuity: true,
      wantsValidationBeforeSolution: true,
      lowToleranceForRepetition: true,
      prefersNaturalConversation: true,
      prefersProactiveCheckins: true,
      prefersLowConfirmationForTrustedActions: true,
      valuesEmotionalAcknowledgement: true,
    );
  }

  Future<NovaUserModel> resolveAdaptive() async {
    final entries = await conversationSessionService.getAll();
    final recent = entries.length <= 60
        ? entries
        : entries.sublist(entries.length - 60);
    final userTexts = recent
        .where((e) => e.role == NovaConversationRole.user)
        .map((e) => e.text.toLowerCase())
        .toList(growable: false);
    if (userTexts.isEmpty) return resolve();

    final directness =
        _countAny(userTexts, const [
          'net',
          'direkt',
          'kısa',
          'kisa',
          'gereksiz',
          'uzatma',
          'lafı dolandırma',
          'süsleme',
        ]) >=
        2;
    final shortReplies =
        _countAny(userTexts, const [
          'kısa cevap',
          'kisa cevap',
          'uzatma',
          'kısa tut',
          'kisa tut',
          'özet geç',
          'ozet gec',
        ]) >=
        1;
    final continuity =
        _countAny(userTexts, const [
          'kaldığımız',
          'kaldigimiz',
          'geçen gün',
          'gecen gun',
          'unutma',
          'hatırla',
          'hatirla',
          'geri dön',
          'geri don',
          'az önce',
          'az once',
        ]) >=
        2;
    final validation =
        _countAny(userTexts, const [
          'beni anla',
          'önce anla',
          'once anla',
          'çözümden önce',
          'cozumden once',
          'dinle önce',
          'önce beni dinle',
        ]) >=
        1;
    final repetitionLow =
        _countAny(userTexts, const [
          'tekrar etme',
          'aynı şeyi',
          'ayni seyi',
          'aynı cümle',
          'robot gibi',
          'mekanik',
        ]) >=
        1;
    final naturalConversation =
        _countAny(userTexts, const [
          'sohbet et',
          'insan gibi',
          'doğal konuş',
          'dogal konus',
          'sorular sor',
          'düşün',
          'dusun',
        ]) >=
        1;
    final proactiveCheckins =
        _countAny(userTexts, const [
          'geri sor',
          'takip sorusu',
          'sor bakalım',
          'sorabilirsin',
          'ana meseleye dön',
          'ana meseleye don',
        ]) >=
        1;
    final lowConfirmationForTrustedActions =
        _countAny(userTexts, const [
          'her şeyi tekrar sorma',
          'teyit isteme',
          'az teyit',
          'hemen yap',
          'uzun teyit isteme',
        ]) >=
        1;
    final emotionalAcknowledgement =
        _countAny(userTexts, const [
          'duyguyu anla',
          'beni anladığını hissettir',
          'önce anla',
          'once anla',
          'rahatlat',
          'empati',
        ]) >=
        1;

    final defaults = resolve();
    return NovaUserModel(
      prefersDirectness: directness || defaults.prefersDirectness,
      prefersShortTechnicalReplies:
          shortReplies || defaults.prefersShortTechnicalReplies,
      valuesContextContinuity: continuity || defaults.valuesContextContinuity,
      wantsValidationBeforeSolution:
          validation || defaults.wantsValidationBeforeSolution,
      lowToleranceForRepetition:
          repetitionLow || defaults.lowToleranceForRepetition,
      prefersNaturalConversation:
          naturalConversation || defaults.prefersNaturalConversation,
      prefersProactiveCheckins:
          proactiveCheckins || defaults.prefersProactiveCheckins,
      prefersLowConfirmationForTrustedActions:
          lowConfirmationForTrustedActions ||
          defaults.prefersLowConfirmationForTrustedActions,
      valuesEmotionalAcknowledgement:
          emotionalAcknowledgement || defaults.valuesEmotionalAcknowledgement,
    );
  }

  int _countAny(List<String> texts, List<String> patterns) {
    var count = 0;
    for (final text in texts) {
      for (final pattern in patterns) {
        if (text.contains(pattern)) {
          count += 1;
          break;
        }
      }
    }
    return count;
  }
}
