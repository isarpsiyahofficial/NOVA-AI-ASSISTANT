// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/call/call_handling_decision.dart';
import '../../core/call/incoming_call_context.dart';

class CallDecisionService {
  const CallDecisionService();

  CallHandlingDecision decide(IncomingCallContext context) {
    if (!context.callHandlingEnabled) {
      return const CallHandlingDecision.ignore();
    }

    if (!context.hasKnownContact) {
      return const CallHandlingDecision.askUserFirst(
        openingLine: 'Efendim bilinmeyen bir numara arıyor.',
      );
    }

    if (!context.canNovaHandleThisCaller) {
      return CallHandlingDecision.askUserFirst(
        openingLine: context.incomingCallerAnnouncement,
      );
    }

    if (context.hasActiveStatus) {
      return CallHandlingDecision.autoHandleByNova(
        openingLine: _buildStatusAwareOpening(context),
        wokeNovaForThisCall: context.novaSleeping,
        shouldOfferNote: true,
        shouldAskUrgency: true,
      );
    }

    if (context.novaSleeping && context.canNovaHandleThisCaller) {
      return CallHandlingDecision.autoHandleByNova(
        openingLine: _buildSleepingOpening(context),
        wokeNovaForThisCall: true,
        shouldOfferNote: true,
        shouldAskUrgency: true,
      );
    }

    return CallHandlingDecision.askUserFirst(
      openingLine: context.incomingCallerAnnouncement,
      wokeNovaForThisCall: false,
    );
  }

  String _buildStatusAwareOpening(IncomingCallContext context) {
    final String normalizedStatus = (context.activeStatusLabel ?? '')
        .trim()
        .toLowerCase();

    switch (normalizedStatus) {
      case 'sleeping':
        return 'Ben Nova. İbrahim şu an uyuyor. İsterseniz not bırakabilirsiniz.';
      case 'driving':
        return 'Ben Nova. İbrahim şu an araç kullanıyor. Acilse bana söyleyebilirsiniz.';
      case 'showering':
        return 'Ben Nova. İbrahim şu an telefona bakamıyor. Not bırakmak ister misiniz?';
      case 'busy':
        return 'Ben Nova. İbrahim şu an meşgul görünüyor. İsterseniz kısa bir not bırakabilirsiniz.';
      default:
        return 'Ben Nova. Şu an uygun görünmüyor. İsterseniz not bırakabilirsiniz.';
    }
  }

  String _buildSleepingOpening(IncomingCallContext context) {
    return 'Ben Nova. İbrahim şu an uyuyor. Durum önemliyse bana söyleyebilirsiniz.';
  }
}
