// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import '../../core/system/nova_activation_decision.dart';
import 'nova_lifecycle_service.dart';

class NovaActivationService {
  final NovaLifecycleService lifecycleService;

  const NovaActivationService({required this.lifecycleService});

  NovaActivationDecision evaluateVoiceInput(String input) {
    final text = input.trim().toLowerCase();
    if (text.isEmpty) return const NovaActivationDecision.ignore();
    if (_isSleepCommand(text)) {
      lifecycleService.sleep();
      return const NovaActivationDecision.processOnly();
    }
    if (!lifecycleService.isSleeping)
      return const NovaActivationDecision.processOnly();
    if (_isWakeWord(text)) {
      lifecycleService.wake();
      return const NovaActivationDecision.wakeAndProcess(
        reason: NovaWakeReason.wakeWord,
      );
    }
    if (_isTeachingInput(text)) {
      lifecycleService.wake();
      return const NovaActivationDecision.wakeAndProcess(
        reason: NovaWakeReason.teachingRequest,
      );
    }
    return const NovaActivationDecision.ignore();
  }

  NovaActivationDecision evaluatePriorityCall({
    required bool isAuthorizedCaller,
    required bool callHandlingEnabled,
  }) {
    if (!isAuthorizedCaller || !callHandlingEnabled)
      return const NovaActivationDecision.ignore();
    if (lifecycleService.isSleeping) {
      lifecycleService.wake();
      return const NovaActivationDecision.wakeAndProcess(
        reason: NovaWakeReason.priorityCall,
      );
    }
    return const NovaActivationDecision.processOnly();
  }

  bool _isSleepCommand(String text) =>
      text.contains('nova uykuya dön') ||
      text.contains('uykuya dön nova') ||
      text == 'uykuya dön' ||
      text.contains('nova uyu') ||
      text.contains('uyku moduna geç') ||
      text.contains('işim var') ||
      text.contains('uyuyacağım');
  bool _isWakeWord(String text) =>
      text == 'nova' ||
      text.startsWith('nova ') ||
      text.contains('nova burda mısın') ||
      text.contains('nova burada mısın') ||
      text.contains('uyan nova') ||
      text.contains('nova uyan') ||
      text.contains('gel nova') ||
      text.contains('nova gel');
  bool _isTeachingInput(String text) =>
      text.contains('şunu böyle yap') ||
      text.contains('bunu öğren') ||
      text.contains('bak bunu şöyle yapacaksın') ||
      text.contains('çağrı öğret') ||
      text.contains('şunu öğret');
}
