// ignore_for_file: avoid_print
// NOVA_RUNTIME_GRAPH_SINGLE_BRAIN_CUTOVER_V37_FULL_AUTHORITY_SURFACE
import '../../core/ai/nova_ai_service.dart';
import '../../core/behavior/nova_persona.dart';
import '../../core/behavior/response_style.dart';
import '../api/api_service.dart';
import '../local_model/local_model_service.dart';
import 'nova_single_brain_authority_service.dart';

class NovaRuntimeGraphAudit {
  final bool sharedAiReady;
  final String sharedAiOwner;
  final List<String> delegates;
  final List<String> duplicateDecisionFactories;
  final Map<String, dynamic> metadata;

  const NovaRuntimeGraphAudit({
    required this.sharedAiReady,
    required this.sharedAiOwner,
    required this.delegates,
    required this.duplicateDecisionFactories,
    this.metadata = const <String, dynamic>{},
  });

  bool get healthy => sharedAiReady && duplicateDecisionFactories.isEmpty;
}

/// Single runtime graph root for Nova decision authority.
///
/// This does not remove features. It prevents setup/dashboard/background/TTS
/// paths from becoming separate decision roots. Same-purpose mechanisms are
/// registered as wrappers/delegates and must pass spoken output through
/// NovaSingleBrainAuthorityService.
class NovaRuntimeGraphService {
  static final NovaRuntimeGraphService instance = NovaRuntimeGraphService._();

  NovaAiService? _sharedAiService;
  String _sharedAiOwner = '';
  final Map<String, String> _delegates = <String, String>{};
  final List<String> _duplicateDecisionFactories = <String>[];
  final Map<String, Map<String, dynamic>> _decisionWrappers =
      <String, Map<String, dynamic>>{};

  NovaRuntimeGraphService._();

  NovaAiService registerSharedAi({
    required NovaAiService service,
    required String owner,
  }) {
    final cleanOwner = owner.trim().isEmpty ? 'unknown_owner' : owner.trim();
    if (_sharedAiService == null) {
      _sharedAiService = service;
      _sharedAiOwner = cleanOwner;
      print(
        'NOVA_RUNTIME_GRAPH_SHARED_AI owner=$_sharedAiOwner hash=${identityHashCode(service)}',
      );
    } else if (!identical(_sharedAiService, service)) {
      final duplicate = '$cleanOwner#${identityHashCode(service)}';
      if (!_duplicateDecisionFactories.contains(duplicate)) {
        _duplicateDecisionFactories.add(duplicate);
      }
      print(
        'NOVA_RUNTIME_GRAPH_DUPLICATE_AI_WRAPPED owner=$cleanOwner existing=$_sharedAiOwner duplicateHash=${identityHashCode(service)}',
      );
    }
    _registerCoreSources();
    return _sharedAiService!;
  }

  NovaAiService resolveSharedAi({
    required String requester,
    required NovaAiService Function() factory,
  }) {
    final current = _sharedAiService;
    if (current != null) {
      registerDelegate(requester, 'shared_ai_delegate');
      print(
        'NOVA_RUNTIME_GRAPH_RESOLVE_SHARED requester=$requester owner=$_sharedAiOwner hash=${identityHashCode(current)}',
      );
      return current;
    }
    final created = factory();
    return registerSharedAi(service: created, owner: requester);
  }

  void registerDelegate(String name, String role) {
    final safeName = name.trim();
    if (safeName.isEmpty) return;
    _delegates[safeName] = role.trim().isEmpty ? 'delegate' : role.trim();
    NovaSingleBrainAuthorityService.instance.registerSource(safeName);
    _registerCoreSources();
    print(
      'NOVA_RUNTIME_GRAPH_REGISTER delegate=$safeName role=${_delegates[safeName]}',
    );
  }

  void registerDecisionWrapper(
    String name, {
    String role = 'decision_wrapper',
    String pathHint = '',
    bool canProduceSpokenText = false,
    bool requiresSingleBrainBeforeSpeech = true,
    bool securityPrimitive = false,
  }) {
    final safeName = name.trim();
    if (safeName.isEmpty) return;
    final safeRole = role.trim().isEmpty ? 'decision_wrapper' : role.trim();
    _delegates[safeName] = safeRole;
    _decisionWrappers[safeName] = <String, dynamic>{
      'role': safeRole,
      'pathHint': pathHint,
      'canProduceSpokenText': canProduceSpokenText,
      'requiresSingleBrainBeforeSpeech': requiresSingleBrainBeforeSpeech,
      'securityPrimitive': securityPrimitive,
    };
    NovaSingleBrainAuthorityService.instance.registerSource(safeName);
    _registerCoreSources();
    print(
      'NOVA_RUNTIME_GRAPH_DECISION_WRAPPER '
      'name=$safeName role=$safeRole spoken=$canProduceSpokenText '
      'requiresSingleBrainBeforeSpeech=$requiresSingleBrainBeforeSpeech '
      'securityPrimitive=$securityPrimitive',
    );
  }

  bool isDecisionWrapperRegistered(String name) {
    return _decisionWrappers.containsKey(name.trim());
  }

  void markWrappedDecisionFactory(String name, {String reason = ''}) {
    final safe = name.trim().isEmpty ? 'unknown_decision_factory' : name.trim();
    final item = reason.trim().isEmpty ? safe : '$safe:$reason';
    if (!_duplicateDecisionFactories.contains(item)) {
      _duplicateDecisionFactories.add(item);
    }
    print(
      'NOVA_RUNTIME_GRAPH_WRAPPED_DECISION_FACTORY name=$safe reason=$reason',
    );
  }

  NovaRuntimeGraphAudit audit() {
    final delegates = _delegates.keys.toList(growable: false)..sort();
    final duplicates = _duplicateDecisionFactories.toList(growable: false)
      ..sort();
    return NovaRuntimeGraphAudit(
      sharedAiReady: _sharedAiService != null,
      sharedAiOwner: _sharedAiOwner,
      delegates: delegates,
      duplicateDecisionFactories: duplicates,
      metadata: <String, dynamic>{
        'sharedAiHash': _sharedAiService == null
            ? 0
            : identityHashCode(_sharedAiService!),
        'delegateRoles': Map<String, String>.unmodifiable(_delegates),
        'decisionWrappers': Map<String, Map<String, dynamic>>.unmodifiable(
          _decisionWrappers,
        ),
        'decisionWrapperCount': _decisionWrappers.length,
        'policy':
            'V37: all detected decision/authority/speech/call/runtime surfaces are registered as wrappers/delegates or security primitives; normal speech must pass SingleBrainAuthority and TTS authority proof; call/native feature primitives stay intact and do not become model authority',
      },
    );
  }

  void _registerCoreSources() {
    final authority = NovaSingleBrainAuthorityService.instance;
    for (final source in const <String>[
      'dashboard_voice',
      'setup_voice',
      'hotpath_owner',
      'runtime_orchestrator',
      'local_model',
      'tts_gate',
      'asr_final_transcript',
      'native_main_activity',
      'native_model_bridge',
      'call_companion',
      'reminder_runtime',
      'speech_runtime',
      'runtime_intent_router',
      'owner_action_broker',
      'call_decision_service',
      'call_companion_gate_service',
      'live_call_companion_brain_service',
      'voice_authorization_runtime',
      'personality_command_service',
      'media_control_service',
    ]) {
      authority.registerSource(source);
    }
  }

  static NovaAiService buildAiService({
    required LocalModelService localModelService,
    required ApiService apiService,
    required NovaPersona persona,
    required ResponseStyle responseStyle,
  }) {
    return NovaAiService(
      localModelService: localModelService,
      apiService: apiService,
      persona: persona,
      responseStyle: responseStyle,
    );
  }
}
