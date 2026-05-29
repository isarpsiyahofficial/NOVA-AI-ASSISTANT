#!/usr/bin/env python3
from pathlib import Path
import re, sys, json, hashlib
root = Path(__file__).resolve().parents[1]
errors=[]
warnings=[]
contract = root/'lib/services/runtime/nova_decision_wrapper_contract_service.dart'
ct = contract.read_text(encoding='utf-8', errors='ignore') if contract.exists() else ''
paths=set(re.findall(r"pathHint:\s*'([^']+)'", ct))
names=re.findall(r"name:\s*'([^']+)'", ct)
if 'NOVA_V37_DECISION_WRAPPER_CONTRACT_FULL_AUTHORITY_SURFACE' not in ct:
    errors.append('wrapper_contract_not_v37')
if len(names) < 140:
    errors.append(f'wrapper_coverage_too_small:{len(names)}')
# Recompute high-risk services. All detected services must be represented in contract pathHint,
# except the contract/runtime graph files themselves.
keywords=['decision','authority','policy','router','orchestrator','brain','runtime','command','guard','gate','intent','companion','call','speech','tts','asr','voice','owner','permission','security','fallback','response']
def risk_for(rel,text):
    name=Path(rel).name.lower(); score=0
    for k in keywords:
        if k in name or re.search(r'\b'+re.escape(k), text, re.I): score+=1
    high=[]
    for pat,label in [(r'Future<\s*String\s*>','future_string'),(r'\bString\s+\w+\s*\(','string_method'),(r'\.speak\s*\(','speak'),(r'AiResponse','airesponse'),(r'Future<\s*[^>]*(Decision|Command|Plan|Result)','future_decision'),(r'(Decision|Command|Plan|Policy|Authority|Intent|Router|Brain|Orchestrator|Gate|Guard)','class_keyword')]:
        if re.search(pat,text): high.append(label)
    return score, high
unwrapped=[]
for p in sorted((root/'lib/services').rglob('*.dart')):
    rel=str(p.relative_to(root))
    if rel in ('lib/services/runtime/nova_decision_wrapper_contract_service.dart','lib/services/runtime/nova_runtime_graph_service.dart'):
        continue
    txt=p.read_text(encoding='utf-8', errors='ignore')
    score, high = risk_for(rel, txt)
    if score>=2 and high and rel not in paths:
        unwrapped.append(rel)
if unwrapped:
    errors.append('unwrapped_high_risk_services:' + ','.join(unwrapped[:80]))
# AI factories and response factories must not escape the graph/factory file.
ctor_hits=[]
for p in (root/'lib').rglob('*.dart'):
    rel=str(p.relative_to(root))
    if rel in ('lib/core/ai/nova_ai_service.dart','lib/services/runtime/nova_runtime_graph_service.dart'):
        continue
    txt=p.read_text(encoding='utf-8', errors='ignore')
    if 'NovaAiService(' in txt:
        ctor_hits.append(rel)
if ctor_hits:
    errors.append('independent_nova_ai_service_ctor:' + ','.join(ctor_hits))
success_hits=[]
for p in (root/'lib').rglob('*.dart'):
    rel=str(p.relative_to(root))
    if rel == 'lib/core/ai/ai_response.dart':
        continue
    txt=p.read_text(encoding='utf-8', errors='ignore')
    if 'AiResponse.success' in txt:
        success_hits.append(rel)
if success_hits:
    errors.append('external_airesponse_success:' + ','.join(success_hits))
# TTS direct speech must be through NovaTtsService authority gate or raw TtsService primitive.
raw=[]
for p in (root/'lib').rglob('*.dart'):
    rel=str(p.relative_to(root))
    txt=p.read_text(encoding='utf-8', errors='ignore')
    if '.speak(' in txt and 'TtsService' in txt and 'NovaTtsService' not in txt and rel not in ('lib/services/speech/tts_service.dart','lib/services/speech_runtime/nova_speech_runtime_service.dart'):
        raw.append(rel)
if raw:
    errors.append('raw_tts_speak_without_nova_gate:' + ','.join(raw))
# Call feature compatibility manifest: call/native files must remain present; unchanged except allowed file.
manifest_path=root/'tool/nova_v37_call_feature_manifest.json'
if not manifest_path.exists():
    errors.append('missing_call_feature_manifest')
else:
    manifest=json.loads(manifest_path.read_text(encoding='utf-8'))
    allowed=set(manifest.get('allowedChangedCallFiles',[]))
    for rel in manifest.get('requiredFiles',[]):
        if not (root/rel).exists(): errors.append('missing_required_call_file:'+rel)
    missing=[]; changed=[]
    for rel,h in manifest.get('callFileHashes',{}).items():
        path=root/rel
        if not path.exists():
            missing.append(rel); continue
        current=hashlib.sha256(path.read_bytes()).hexdigest()
        if current != h and rel not in allowed:
            changed.append(rel)
    if missing:
        errors.append('removed_call_feature_files:' + ','.join(missing[:40]))
    if changed:
        errors.append('unexpected_changed_call_feature_files:' + ','.join(changed[:40]))
    for rel, markers in manifest.get('requiredTextMarkers',{}).items():
        path=root/rel
        if not path.exists(): continue
        txt=path.read_text(encoding='utf-8', errors='ignore')
        for marker in markers:
            if marker not in txt:
                errors.append(f'missing_call_marker:{rel}:{marker}')
# Specific V37 known fixes.
main_activity=root/'android/app/src/main/kotlin/com/example/nova/MainActivity.kt'
ma=main_activity.read_text(encoding='utf-8', errors='ignore') if main_activity.exists() else ''
if 'FINALMOBILE_SINGLE_BRAIN_RUNTIME_GRAPH_CUTOVER_V37' not in ma and 'FINALMOBILE_SECURITY_PASSIVE_ORIENTATION_CUTOVER_V38' not in ma and 'FINALMOBILE_SECURITY_PASSIVE_SCOPE_FIX_CUTOVER_V39' not in ma:
    errors.append('missing_v37_or_newer_build_marker')
ci=root/'lib/services/call_instruction/nova_call_instruction_runtime_service.dart'
ci_text=ci.read_text(encoding='utf-8', errors='ignore') if ci.exists() else ''
if 'await ttsService!.speak(\n          rewritten,' not in ci_text:
    errors.append('call_instruction_tts_not_using_rewritten_authority_text')
report={
    'gate':'NOVA_V37_FINAL_AUTHORITY_AND_CALL_COMPAT_GATE',
    'wrapperCount':len(names),
    'unwrappedHighRiskCount':len(unwrapped),
    'errors':errors,
    'warnings':warnings,
}
print(json.dumps(report, ensure_ascii=False, indent=2))
if errors:
    print('NOVA_V37_FINAL_AUTHORITY_AND_CALL_COMPAT_GATE FAIL')
    sys.exit(1)
print('NOVA_V37_FINAL_AUTHORITY_AND_CALL_COMPAT_GATE PASS')
