// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/behavior_control/behavior_keys.dart';
import '../../core/call/call_conversation_context.dart';
import '../../core/call/call_conversation_turn.dart';
import '../behavior_control/behavior_resolver_service.dart';
import '../call_learning/call_response_resolver_service.dart';
import 'call_intent_service.dart';

class CallConversationService {
  final CallIntentService intentService;
  final CallResponseResolverService responseResolverService;
  final BehaviorResolverService behaviorResolverService;

  const CallConversationService({
    required this.intentService,
    required this.responseResolverService,
    required this.behaviorResolverService,
  });

  Future<CallConversationTurn> respond({
    required String callerText,
    required CallConversationContext context,
  }) async {
    final safeCallerText = callerText.trim();
    final intent = intentService.detectIntent(safeCallerText);

    switch (intent) {
      case CallConversationIntent.greeting:
        return _buildGreetingTurn(callerText: safeCallerText, context: context);

      case CallConversationIntent.askingForOwner:
        return _buildOwnerAvailabilityTurn(
          callerText: safeCallerText,
          context: context,
        );

      case CallConversationIntent.leavingNote:
        return _buildLeaveNoteTurn(
          callerText: safeCallerText,
          context: context,
        );

      case CallConversationIntent.urgencyCheck:
        return _buildUrgencyTurn(callerText: safeCallerText, context: context);

      case CallConversationIntent.callbackRequest:
        return _buildCallbackTurn(callerText: safeCallerText, context: context);

      case CallConversationIntent.smallTalk:
        return _buildSmallTalkTurn(
          callerText: safeCallerText,
          context: context,
        );

      case CallConversationIntent.ending:
        return const CallConversationTurn(
          callerText: '',
          intent: CallConversationIntent.ending,
          responseText:
              'Anlaşıldı efendim. İletmemi istediğiniz bir not varsa ekleyebilirim. İyi günler dilerim.',
          shouldStoreNote: false,
          shouldAskFollowUp: false,
          conversationShouldEnd: true,
        );

      case CallConversationIntent.unknown:
        return _buildUnknownTurn(callerText: safeCallerText, context: context);
    }
  }

  Future<CallConversationTurn> _buildGreetingTurn({
    required String callerText,
    required CallConversationContext context,
  }) async {
    final fallback = await responseResolverService.resolveOpening(
      contact: context.contact,
      activeStatusLabel: context.activeStatusLabel,
      rawTrigger: callerText,
    );

    return CallConversationTurn(
      callerText: callerText,
      intent: CallConversationIntent.greeting,
      responseText: fallback,
      shouldStoreNote: false,
      shouldAskFollowUp: true,
      conversationShouldEnd: false,
    );
  }

  Future<CallConversationTurn> _buildOwnerAvailabilityTurn({
    required String callerText,
    required CallConversationContext context,
  }) async {
    final fallback = await responseResolverService.resolveOpening(
      contact: context.contact,
      activeStatusLabel: context.activeStatusLabel,
      rawTrigger: callerText,
    );

    return CallConversationTurn(
      callerText: callerText,
      intent: CallConversationIntent.askingForOwner,
      responseText: fallback,
      shouldStoreNote: false,
      shouldAskFollowUp: true,
      conversationShouldEnd: false,
    );
  }

  Future<CallConversationTurn> _buildLeaveNoteTurn({
    required String callerText,
    required CallConversationContext context,
  }) async {
    final noteStyle = await behaviorResolverService.resolveNoteAskingStyle(
      fallback:
          'Tabii efendim, notunuzu söyleyebilirsiniz. Uygun olduğunda ileteceğim.',
    );

    return CallConversationTurn(
      callerText: callerText,
      intent: CallConversationIntent.leavingNote,
      responseText: noteStyle,
      shouldStoreNote: true,
      shouldAskFollowUp: false,
      conversationShouldEnd: false,
    );
  }

  Future<CallConversationTurn> _buildUrgencyTurn({
    required String callerText,
    required CallConversationContext context,
  }) async {
    final urgentStyle = await behaviorResolverService.resolveUrgentWakeStyle(
      fallback:
          'Anladım efendim, konuyu acil olarak işaretleyebilirim. Kısa şekilde söyleyebilirsiniz.',
    );

    return CallConversationTurn(
      callerText: callerText,
      intent: CallConversationIntent.urgencyCheck,
      responseText: urgentStyle,
      shouldStoreNote: true,
      shouldAskFollowUp: false,
      conversationShouldEnd: false,
    );
  }

  Future<CallConversationTurn> _buildCallbackTurn({
    required String callerText,
    required CallConversationContext context,
  }) async {
    return const CallConversationTurn(
      callerText: '',
      intent: CallConversationIntent.callbackRequest,
      responseText:
          'Elbette efendim, uygun olduğunda size dönüş yapmasını not alabilirim. İsterseniz kısa bir mesaj bırakabilirsiniz.',
      shouldStoreNote: true,
      shouldAskFollowUp: false,
      conversationShouldEnd: false,
    );
  }

  Future<CallConversationTurn> _buildSmallTalkTurn({
    required String callerText,
    required CallConversationContext context,
  }) async {
    if (!context.allowSmallTalk) {
      return const CallConversationTurn(
        callerText: '',
        intent: CallConversationIntent.smallTalk,
        responseText:
            'Şu an daha çok çağrıyı yönetmek ve not almak için yardımcı oluyorum efendim. İsterseniz kısa bir mesaj iletebilirim.',
        shouldStoreNote: false,
        shouldAskFollowUp: true,
        conversationShouldEnd: false,
      );
    }

    final speakingTone = await behaviorResolverService.resolveOrDefault(
      key: BehaviorKeys.speechTone,
      defaultInstruction:
          'Ben Nova, İbrahim’in kişisel asistanıyım. Gerekirse çağrıları karşılıyor ve not alıyorum.',
    );

    return CallConversationTurn(
      callerText: callerText,
      intent: CallConversationIntent.smallTalk,
      responseText: speakingTone,
      shouldStoreNote: false,
      shouldAskFollowUp: true,
      conversationShouldEnd: false,
    );
  }

  Future<CallConversationTurn> _buildUnknownTurn({
    required String callerText,
    required CallConversationContext context,
  }) async {
    final fallback = await responseResolverService.resolveOpening(
      contact: context.contact,
      activeStatusLabel: context.activeStatusLabel,
      rawTrigger: callerText,
    );

    return CallConversationTurn(
      callerText: callerText,
      intent: CallConversationIntent.unknown,
      responseText: fallback,
      shouldStoreNote: false,
      shouldAskFollowUp: true,
      conversationShouldEnd: false,
    );
  }
}
