#!/usr/bin/env python3
from pathlib import Path
import re, sys, json
root = Path(__file__).resolve().parents[1]
contract = root / 'lib/services/runtime/nova_decision_wrapper_contract_service.dart'
main = root / 'lib/main.dart'
runtime_graph = root / 'lib/services/runtime/nova_runtime_graph_service.dart'
errors = []
if not contract.exists():
    errors.append('missing_contract_service')
text = contract.read_text(encoding='utf-8', errors='ignore') if contract.exists() else ''
main_text = main.read_text(encoding='utf-8', errors='ignore') if main.exists() else ''
graph_text = runtime_graph.read_text(encoding='utf-8', errors='ignore') if runtime_graph.exists() else ''
required_names = re.findall(r"name:\s*'([^']+)'", text)
required_paths = re.findall(r"pathHint:\s*'([^']+)'", text)
if len(required_names) < 40:
    errors.append(f'wrapper_registry_too_small:{len(required_names)}')
if 'NovaDecisionWrapperContractService.registerAll();' not in main_text:
    errors.append('main_does_not_register_wrapper_contract')
if 'registerDecisionWrapper' not in graph_text or '_decisionWrappers' not in graph_text:
    errors.append('runtime_graph_missing_decision_wrapper_registry')
missing_paths = [p for p in required_paths if p and not (root / p).exists()]
if missing_paths:
    errors.append('missing_wrapper_path:' + ','.join(missing_paths[:20]))
# Known high-risk spoken/decision producers must be registered as wrappers or explicitly primitive.
high_risk_files = {
    'lib/services/call/call_decision_service.dart': 'call_decision_service',
    'lib/services/call_companion/nova_live_call_companion_brain_service.dart': 'live_call_companion_brain_service',
    'lib/services/call_companion/nova_call_companion_gate_service.dart': 'call_companion_gate_service',
    'lib/services/call_instruction/nova_call_instruction_command_service.dart': 'call_instruction_command_service',
    'lib/services/reminder/nova_reminder_command_service.dart': 'reminder_command_service',
    'lib/services/runtime/nova_runtime_intent_router_service.dart': 'runtime_intent_router',
    'lib/services/runtime/nova_runtime_orchestrator_service.dart': 'runtime_orchestrator',
    'lib/services/runtime/nova_owner_action_broker_service.dart': 'owner_action_broker',
    'lib/services/runtime/nova_hotpath_owner_service.dart': 'hotpath_owner_service',
    'lib/services/identity/voice_authorization_runtime_service.dart': 'voice_authorization_runtime',
    'lib/services/personality/nova_personality_command_service.dart': 'personality_command_service',
    'lib/services/phone_control/nova_media_control_service.dart': 'media_control_service',
    'lib/services/speech_runtime/nova_speech_runtime_service.dart': 'speech_runtime_service',
}
for path, name in high_risk_files.items():
    if name not in required_names:
        errors.append(f'high_risk_not_registered:{name}:{path}')
# No independent AI constructors / external success factories.
ctor_hits=[]
for p in (root/'lib').rglob('*.dart'):
    if str(p).endswith('lib/core/ai/nova_ai_service.dart') or str(p).endswith('lib/services/runtime/nova_runtime_graph_service.dart'):
        continue
    t=p.read_text(encoding='utf-8', errors='ignore')
    if 'NovaAiService(' in t:
        ctor_hits.append(str(p.relative_to(root)))
if ctor_hits:
    errors.append('independent_nova_ai_service_ctor:' + ','.join(ctor_hits))
success_hits=[]
for p in (root/'lib').rglob('*.dart'):
    if str(p).endswith('lib/core/ai/ai_response.dart'):
        continue
    t=p.read_text(encoding='utf-8', errors='ignore')
    if 'AiResponse.success' in t:
        success_hits.append(str(p.relative_to(root)))
if success_hits:
    errors.append('external_airesponse_success:' + ','.join(success_hits))
# Speech exits: direct TtsService.speak is only allowed behind NovaTtsService/NovaSpeechRuntimeService authority gates.
speech_bypass=[]
for p in (root/'lib').rglob('*.dart'):
    rel=str(p.relative_to(root))
    t=p.read_text(encoding='utf-8', errors='ignore')
    if '.speak(' in t and 'authorizeSpeech(' not in t and 'NovaTtsService' not in t and rel not in ('lib/main.dart','lib/services/speech/tts_service.dart'):
        if rel not in ('lib/ui/onboarding/nova_first_run_setup_page.dart','lib/ui/dashboard/dashboard_page.dart'):
            speech_bypass.append(rel)
# This gate is intentionally warning-only for UI pages that use injected NovaTtsService; hard fail only obvious raw TtsService users.
raw_tts_bypass=[]
for rel in speech_bypass:
    t=(root/rel).read_text(encoding='utf-8', errors='ignore')
    if 'TtsService' in t and 'NovaSpeechRuntimeService' not in t:
        raw_tts_bypass.append(rel)
if raw_tts_bypass:
    errors.append('raw_tts_speak_without_authority_gate:' + ','.join(raw_tts_bypass))
report = {
    'gate': 'NOVA_V36_WRAPPER_CONTRACT_GATE',
    'registeredWrapperCount': len(required_names),
    'requiredWrappers': required_names,
    'missingPaths': missing_paths,
    'errors': errors,
}
print(json.dumps(report, ensure_ascii=False, indent=2))
if errors:
    print('NOVA_V36_WRAPPER_CONTRACT_GATE FAIL')
    sys.exit(1)
print('NOVA_V36_WRAPPER_CONTRACT_GATE PASS')
