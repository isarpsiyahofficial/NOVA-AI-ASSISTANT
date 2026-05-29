from pathlib import Path
import re, sys
ROOT = Path(__file__).resolve().parents[1]
fail=[]

def read(rel):
    p=ROOT/rel
    if not p.exists():
        fail.append(f'missing:{rel}')
        return ''
    return p.read_text(encoding='utf-8', errors='ignore')

service = read('lib/services/security/nova_security_diagnostic_mode_service.dart')
if 'NOVA_V38_SECURITY_DIAGNOSTIC_PASSIVE_MODE' not in service:
    fail.append('missing_security_diagnostic_service_marker')
if 'const NovaSecurityDiagnosticModeState.defaultPassive()' not in service:
    fail.append('default_passive_state_missing')
if "passiveShields = true" not in service:
    fail.append('default_passive_true_missing')
if "hiddenFromAiRuntime = true" not in service:
    fail.append('hidden_from_ai_default_missing')
if "_allowedUiWriters" not in service or "setup_ui" not in service or "dashboard_ui" not in service:
    fail.append('ui_only_writer_guard_missing')

main = read('lib/main.dart')
for needle in [
    'SystemChrome.setPreferredOrientations',
    'DeviceOrientation.portraitUp',
    'forceDefaultPassiveIfMissing',
    'NOVA_SECURITY_DIAGNOSTIC_PASSIVE_BOOT_OVERRIDE',
    '!securityDiagnosticMode.passiveShields',
]:
    if needle not in main:
        fail.append(f'main_missing:{needle}')

manifest = read('android/app/src/main/AndroidManifest.xml')
for activity in ['.MainActivity','.NovaPhoneLauncherActivity','.NovaContactsLauncherActivity','.NovaDialerActivity','.NovaCallUiActivity','.NovaIncomingCallBannerActivity']:
    m = re.search(r'<activity[^>]*android:name="'+re.escape(activity)+r'"[^>]*>', manifest, flags=re.S)
    if not m or 'android:screenOrientation="portrait"' not in m.group(0):
        fail.append(f'portrait_lock_missing:{activity}')

required_gates = {
    'lib/core/ai/nova_ai_service.dart': ['securityShieldsPassive', 'NOVA_SECURITY_DIAGNOSTIC_PASSIVE_AI_SERVICE', '!securityShieldsPassive && securityDecision.isBlocked'],
    'lib/services/local_model/local_model_service.dart': ['securityShieldsPassive', 'NOVA_SECURITY_DIAGNOSTIC_PASSIVE_LOCAL_MODEL_GATE', 'if (!securityShieldsPassive)'],
    'lib/services/security/nova_autonomous_security_orchestrator_service.dart': ['NOVA_SECURITY_DIAGNOSTIC_PASSIVE_ORCHESTRATOR', 'diagnostic_passive_observe_only'],
    'lib/services/security/nova_security_quarantine_service.dart': ['NOVA_SECURITY_DIAGNOSTIC_PASSIVE_QUARANTINE_STRIKE_IGNORED', 'isPassive()'],
    'lib/services/security/nova_restricted_capability_guard_service.dart': ['NOVA_SECURITY_DIAGNOSTIC_PASSIVE_RESTRICTED_CAPABILITY_ALLOW'],
    'lib/ui/dashboard/dashboard_page.dart': ['_saveSecurityDiagnosticPassive', 'dashboard_ui', 'GÃ¼venlik kalkanlarÄ± pasif gÃ¶zlem modu'],
    'lib/ui/onboarding/nova_first_run_setup_page.dart': ['_setSetupSecurityDiagnosticPassive', 'setup_ui', 'GÃ¼venlik kalkanlarÄ± pasif gÃ¶zlem modu'],
}
for rel, needles in required_gates.items():
    text=read(rel)
    for needle in needles:
        if needle not in text:
            fail.append(f'{rel}_missing:{needle}')

# Ensure the private diagnostic switch is not injected into model prompt/request metadata as a capability Nova can reason about.
# UI labels are allowed; AiRequest metadata and system prompt envelope should not contain the private storage key.
for rel in ['lib/core/ai/ai_request.dart','lib/core/ai/nova_ai_service.dart','lib/services/local_model/local_model_service.dart','lib/services/runtime/nova_single_brain_authority_service.dart']:
    text=read(rel)
    if 'nova_security_diagnostic_mode_v38_private_ui_only' in text:
        fail.append(f'private_storage_key_exposed_to_ai_path:{rel}')

# Cumulative V31-V37 markers/files must remain.
for rel in [
    'lib/services/runtime/nova_runtime_graph_service.dart',
    'lib/services/runtime/nova_decision_wrapper_contract_service.dart',
    'tool/nova_v37_final_authority_and_call_compat_gate.py',
    'tool/nova_v36_wrapper_contract_gate.py',
    'tool/nova_v34_static_runtime_gate.py',
]:
    if not (ROOT/rel).exists():
        fail.append(f'cumulative_file_missing:{rel}')

if fail:
    print('NOVA_V38_SECURITY_PASSIVE_ORIENTATION_GATE FAIL')
    for f in fail:
        print(' -', f)
    sys.exit(1)
print('NOVA_V38_SECURITY_PASSIVE_ORIENTATION_GATE PASS')
print('security_default=passive_observe_only')
print('hidden_from_ai=true')
print('portrait_lock=main_flutter_and_native_activities')
print('cumulative_v31_to_v38=present')
