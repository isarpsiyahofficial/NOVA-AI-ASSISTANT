from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
local = ROOT / 'lib/services/local_model/local_model_service.dart'
text = local.read_text(encoding='utf-8')
errors = []

required = [
    'final orchestrator = NovaAutonomousSecurityOrchestratorService();',
    'final securityResult = await orchestrator.evaluateAndContain(request);',
    'final guarded = _shields.evaluate(',
    'final securityStaticRuleSection = securityShieldsPassive',
    'final securityPromptSection = securityShieldsPassive',
    'final securityOrchestratorPromptSection = securityShieldsPassive',
    'securityShieldsPassive: securityShieldsPassive',
    "'shieldStage': securityShieldsPassive  'diagnostic_passive_hidden' : guarded.containmentStage",
]
for needle in required:
    if needle not in text:
        errors.append(f'missing_required_local_model_scope_marker: {needle}')

# V38 broken pattern: guarded/orchestrator/securityResult declared inside an if block then used later.
broken_patterns = [
    "if (!securityShieldsPassive) {\n        final orchestrator",
    "if (!securityShieldsPassive) {\n        final guarded",
    "_fitActiveContextSection(guarded.buildPromptSection(), 900, 'gÃ¼venlik kalkanÄ±'),",
    "_fitActiveContextSection(orchestrator.buildPromptSection(request, securityResult), 900, 'runtime orkestrasyon'),",
    "return _sanitizeResponse(first, guarded);",
]
for pat in broken_patterns:
    if pat in text:
        errors.append(f'v38_scope_regression_pattern_present: {pat[:80]}')

# In passive mode, shield prompt sections must be hidden from Gemma context.
if "securityShieldsPassive\n           ''\n          : _fitActiveContextSection(guarded.buildPromptSection()" not in text:
    errors.append('security_prompt_section_not_hidden_in_passive_mode')
if "securityShieldsPassive\n           ''\n          : _fitActiveContextSection(orchestrator.buildPromptSection(request, securityResult)" not in text:
    errors.append('security_orchestrator_section_not_hidden_in_passive_mode')
if "securityShieldsPassive\n           ''\n          : 'GÃœVENLÄ°K KURAL:" not in text:
    errors.append('static_security_rule_not_hidden_in_passive_mode')

main_activity = ROOT / 'android/app/src/main/kotlin/com/example/nova/MainActivity.kt'
if 'FINALMOBILE_SECURITY_PASSIVE_SCOPE_FIX_CUTOVER_V39' not in main_activity.read_text(encoding='utf-8'):
    errors.append('missing_v39_build_marker')

if errors:
    print('NOVA_V39_LOCAL_MODEL_SCOPE_GATE FAIL')
    for e in errors:
        print('ERROR', e)
    raise SystemExit(1)
print('NOVA_V39_LOCAL_MODEL_SCOPE_GATE PASS')
print('local_model_scope=guarded/orchestrator/securityResult method_scope')
print('security_prompt_hidden_from_ai_when_passive=true')
print('build_marker=FINALMOBILE_SECURITY_PASSIVE_SCOPE_FIX_CUTOVER_V39')
