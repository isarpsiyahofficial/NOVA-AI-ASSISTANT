// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/contacts/nova_contact.dart';
import '../call/call_response_policy_service.dart';
import 'learned_call_response_service.dart';

class CallResponseResolverService {
  final LearnedCallResponseService learnedService;
  final CallResponsePolicyService fallbackPolicyService;

  const CallResponseResolverService({
    required this.learnedService,
    required this.fallbackPolicyService,
  });

  Future<String> resolveOpening({
    required NovaContact? contact,
    required String? activeStatusLabel,
    String? rawTrigger,
  }) async {
    final learned = await learnedService.resolve(
      callerName: contact?.displayName,
      statusLabel: activeStatusLabel,
      rawTrigger: rawTrigger,
    );

    // Learned/fallback call responses are not final speech. They must be routed
    // as structured context through NovaCoreTurnController before TTS.
    if (learned != null && learned.responseText.trim().isNotEmpty) {
      return '';
    }

    return '';
  }
}
