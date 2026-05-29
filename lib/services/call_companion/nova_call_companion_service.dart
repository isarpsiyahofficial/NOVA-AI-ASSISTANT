// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/contacts/contact_role.dart';
import '../../core/contacts/nova_contact.dart';
import '../../core/ai/ai_mode.dart';
import '../../core/ai/ai_request.dart';
import '../../core/ai/ai_response.dart';
import '../../core/ai/nova_ai_service.dart';
import '../../core/call_companion/nova_call_companion_request.dart';
import '../../core/reminder/nova_reminder.dart';
import '../call/urgent_call_memory_service.dart';
import '../call_notes/call_note_service.dart';
import '../reminder/nova_reminder_service.dart';
import '../contacts/nova_contact_service.dart';
import '../adaptive/adaptive_call_behavior_service.dart';
import '../call_learning/learned_call_response_service.dart';
import '../call_learning/nova_call_style_learning_service.dart';
import '../runtime/nova_system_adaptation_contract_service.dart';
import '../runtime/nova_identity_runtime_service.dart';
import '../runtime/nova_single_brain_authority_service.dart';

class NovaCallCompanionReply {
  final String text;
  final AiResponse? authorityResponse;

  const NovaCallCompanionReply({required this.text, this.authorityResponse});

  const NovaCallCompanionReply.empty() : text = '', authorityResponse = null;

  String get trimmedText => text.trim();
  bool get hasText => trimmedText.isNotEmpty;
}

class NovaCallCompanionService {
  final NovaAiService aiService;
  final NovaContactService? contactService;
  final NovaReminderService? reminderService;
  final UrgentCallMemoryService? urgentCallMemoryService;
  final CallNoteService? callNoteService;
  final AdaptiveCallBehaviorService? adaptiveCallBehaviorService;
  final LearnedCallResponseService? learnedCallResponseService;
  final NovaCallStyleLearningService? callStyleLearningService;
  final NovaSystemAdaptationContractService? adaptationContractService;
  final NovaIdentityRuntimeService identityRuntimeService;

  const NovaCallCompanionService({
    required this.aiService,
    this.contactService,
    this.reminderService,
    this.urgentCallMemoryService,
    this.callNoteService,
    this.adaptiveCallBehaviorService,
    this.learnedCallResponseService,
    this.callStyleLearningService,
    this.adaptationContractService,
    this.identityRuntimeService = const NovaIdentityRuntimeService(),
  });

  Future<String> generateReply(NovaCallCompanionRequest request) async {
    // Plain string call-companion replies are disabled. Use
    // generateReplyWithAuthority so TTS receives an AiResponse proof.
    return '';
  }

  Future<NovaCallCompanionReply> generateReplyWithAuthority(
    NovaCallCompanionRequest request,
  ) async {
    if (!request.hasUsableConversation) {
      // No static companion shell may become a spoken call answer.
      // If the call audio/transcript is not usable, keep the companion silent
      // and let the runtime continue listening instead of emitting a fixed line
      // without SingleBrain/Gemma authority proof.
      return const NovaCallCompanionReply.empty();
    }

    final contact = await contactService?.findByPhoneNumber(
      request.phoneNumber,
    );
    final urgentMemory = await urgentCallMemoryService?.getActive(
      request.phoneNumber,
    );

    final authoritativeAiReply = await _tryGenerateAuthoritativeAiCallReply(
      request: request,
      contact: contact,
      urgentMemoryActive: urgentMemory != null,
    );
    if (authoritativeAiReply.hasText) {
      return authoritativeAiReply;
    }

    // SingleBrainAuthority dışından çağrı cevabı üretme. Acil/not/selamlaşma gibi
    // deterministic yan etkiler de kullanıcıya okunacak metin üretmeden önce AI marker
    // hattından geçmelidir. AI cevap yoksa companion susar ve runtime açıkça blocked
    // state/log üretir; static sekreter kabuğu konuşmaz.
    return const NovaCallCompanionReply.empty();
  }

  Future<NovaCallCompanionReply> _tryGenerateAuthoritativeAiCallReply({
    required NovaCallCompanionRequest request,
    required NovaContact? contact,
    required bool urgentMemoryActive,
  }) async {
    try {
      final bool allowApi =
          request.allowApi && request.isUserApproved && request.isUserInitiated;
      final styleSuffix =
          await callStyleLearningService?.buildPromptSuffix() ?? '';
      final contactPolicyBlock = contact?.buildCompanionPolicyBlock() ?? '';
      final relation = contact?.relationshipLabel.trim() ?? '';
      final prompt = <String>[
        'CALL COMPANION AI AUTHORITY:',
        'Bu çağrı içi cevap, güvenlik/native primitive dışındaki tek davranış kararı olarak Gemma/AI zincirinden geçmelidir.',
        'Kişiye özel alanları iç talimat olarak kullan; aynen okuma.',
        'Uygunsa yalnız iç marker ekle: [CALL_ACTION_URGENT] acil uyandırma/not, [CALL_ACTION_NOTE] not bırakma. Markerlar kullanıcıya okunmayacak.',
        'Arayan konuşması: ${request.liveConversation.trim()}',
        if (contact != null)
          'Kişi: ${contact.displayName}; ilişki: ${relation.isEmpty ? 'çağrı kişisi' : relation}; rol: ${contact.role.name}',
        if (contactPolicyBlock.trim().isNotEmpty) contactPolicyBlock.trim(),
        if (urgentMemoryActive)
          'Bu kişi için aktif acil çağrı hafızası var; tekrar aciliyet varsa kısa ve tutarlı davran.',
        if (styleSuffix.trim().isNotEmpty) styleSuffix.trim(),
      ].where((part) => part.trim().isNotEmpty).join('\n\n');

      final adaptiveMetadata =
          await (adaptationContractService ??
                  const NovaSystemAdaptationContractService())
              .buildMetadata(
                prompt: prompt,
                sourceSystem: 'call_companion_ai_authority',
                requestOrigin: request.requestOrigin,
                baseMetadata: <String, dynamic>{
                  'callStyle': 'human_like_call_companion',
                  'source': 'call_companion_ai_authority',
                  'phoneNumber': request.phoneNumber,
                  'allowTakeover': request.allowTakeover,
                  'allowHandoffBack': request.allowHandoffBack,
                  'companionMode': true,
                  'callMode': true,
                  'aiChainAuthorityGate': true,
                  if (contactPolicyBlock.trim().isNotEmpty)
                    'contactPolicyBlock': contactPolicyBlock,
                  if (contact != null)
                    'contactCustomizationSummary': contact.customizationSummary,
                },
                speakerName: contact?.displayName.trim() ?? '',
                relationshipLabel: relation.isEmpty ? 'çağrı kişisi' : relation,
                speakerVoiceId: request.phoneNumber.trim().isEmpty
                    ? ''
                    : 'call:${request.phoneNumber.trim()}',
                ownerConfidence: contact != null ? 0.72 : 0.44,
                callerName: contact?.displayName.trim() ?? '',
                callerNumber: request.phoneNumber.trim(),
                companionMode: true,
                callMode: true,
              );

      await identityRuntimeService.ensureLoaded();
      final aiRequest = AiRequest(
        prompt: prompt,
        mode: AiMode.apiOnly,
        internetAllowed: true,
        isResearchRequest: false,
        isSelfLearningRequest: false,
        isFastResponsePriority: false,
        isUserApprovedApiUsage: true,
        isBehaviorTeachingRequest: false,
        isScreenLocked: false,
        requestedByVoice: request.requestedByVoice,
        requestOrigin: 'background_authorized_voice',
        userInitiated: request.isUserInitiated,
        userConfirmedThisAction: request.isUserApproved,
        metadata: adaptiveMetadata,
      );
      final decision = await NovaSingleBrainAuthorityService.instance
          .handleInput(
            input: NovaBrainInput(
              text: request.liveConversation.trim(),
              source: 'call_companion_ai_authority',
              mode: 'liveCallCompanion',
              speakerName: contact?.displayName.trim() ?? '',
              speakerVoiceId: request.phoneNumber.trim().isEmpty
                  ? ''
                  : 'call:${request.phoneNumber.trim()}',
              relationshipLabel: relation.isEmpty ? 'çağrı kişisi' : relation,
              ownerConfidence: contact != null ? 0.72 : 0.44,
              primaryTurn: false,
              allowFallbackSpeech: false,
              requiresLocalModel: false,
              metadata: adaptiveMetadata,
            ),
            baseRequest: aiRequest,
            mode: aiRequest.mode,
            runAi: aiService.process,
          );
      final response = decision.response;

      if (response.isError || !decision.allowedToSpeak)
        return const NovaCallCompanionReply.empty();
      var text = decision.finalText.trim();
      if (text.isEmpty) return const NovaCallCompanionReply.empty();

      final lower = text.toLowerCase();
      final controlMarkers = (response.metadata['controlMarkers'] is List)
          ? (response.metadata['controlMarkers'] as List)
                .map((e) => e.toString().toLowerCase())
                .toList(growable: false)
          : const <String>[];
      final urgentMarker = lower.contains('[call_action_urgent]') ||
          controlMarkers.contains('[call_action_urgent]');
      final noteMarker = lower.contains('[call_action_note]') ||
          controlMarkers.contains('[call_action_note]');

      if (contact != null && urgentMarker) {
        final summary = request.liveConversation.trim();
        await urgentCallMemoryService?.markUrgent(
          callerNumber: request.phoneNumber,
          callerName: contact.displayName,
          summary: summary,
        );
        await reminderService?.add(
          text:
              '${contact.displayName.isEmpty ? 'Kayıtlı kişi' : contact.displayName} için acil çağrı bildirimi: $summary',
          dueAt: DateTime.now(),
          kind: NovaReminderKind.wakeAlarm,
          repeatUntilAcknowledged: true,
          maxActiveMinutes: 10,
        );
      }

      if (contact != null && noteMarker) {
        await callNoteService?.add(
          callerName: contact.displayName,
          callerNumber: request.phoneNumber,
          content: request.liveConversation.trim(),
        );
      }

      text = text
          .replaceAll(
            RegExp(r'\[CALL_ACTION_URGENT\]', caseSensitive: false),
            '',
          )
          .replaceAll(RegExp(r'\[CALL_ACTION_NOTE\]', caseSensitive: false), '')
          .replaceFirst(
            RegExp(
              '^${RegExp.escape(identityRuntimeService.defaultWakeReply())}\\s*',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (!response.hasAuthoritativeBrainProof)
        return const NovaCallCompanionReply.empty();
      final sanitizedResponse = response.withAuthoritativeBrainProofText(
        text,
        quickReplyOverride: response.quickReply,
        extraMetadata: const <String, dynamic>{
          'route': 'call_companion_sanitized_authoritative_proof',
        },
      );

      return NovaCallCompanionReply(
        text: text,
        authorityResponse: sanitizedResponse,
      );
    } catch (_) {
      return const NovaCallCompanionReply.empty();
    }
  }

  String _buildCompanionGreeting(
    NovaContact contact, {
    String ownerName = 'İbrahim',
  }) {
    return contact.buildCompanionGreeting(ownerName: ownerName);
  }

  Future<String> resolveAdaptiveGreeting(
    NovaContact contact, {
    String ownerName = 'İbrahim',
    String activeStatusLabel = '',
  }) async {
    final fallback = _buildCompanionGreeting(contact, ownerName: ownerName);
    final adaptive = adaptiveCallBehaviorService;
    if (adaptive == null) return fallback;
    return adaptive.resolveCallOpening(
      contact: contact,
      activeStatusLabel: activeStatusLabel,
      fallback: fallback,
    );
  }

  String _relationshipSpeech(NovaContact contact) {
    final custom = contact.customRoleLabel?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    switch (contact.role) {
      case ContactRole.mother:
      case ContactRole.father:
        return 'Oğlunuz';
      case ContactRole.brother:
      case ContactRole.sister:
        return 'Kardeşiniz';
      case ContactRole.spouse:
        return 'Eşiniz';
      case ContactRole.child:
        return 'Ebeveyniniz';
      case ContactRole.friend:
      case ContactRole.relative:
        return 'Yakınınız';
      case ContactRole.custom:
        return contact.relationshipLabel.trim().isNotEmpty
            ? contact.relationshipLabel.trim()
            : 'Yakınınız';
    }
  }
}
