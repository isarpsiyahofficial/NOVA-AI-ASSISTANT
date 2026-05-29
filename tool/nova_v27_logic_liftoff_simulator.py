#!/usr/bin/env python3
from __future__ import annotations
import argparse, json, re, csv, time
from pathlib import Path
TEXT_EXTS={'.dart','.kt','.kts','.xml','.yaml','.yml','.json','.gradle','.properties','.txt','.md','.cmd','.ps1','.py'}
MAX_READ=600000
PROOF_KEYS=('nativeSuccess','acceptedNativeText','rawNativeLocalModel','authoritativeLocalBrain','localModelAuthorityProof')
RUNTIME_ROOTS=('lib/','android/app/src/main/','android/build.gradle','android/settings.gradle','android/gradle.properties','pubspec.yaml','assets/')
def rel(root,p): return str(p.relative_to(root)).replace('\\','/')
def all_files(root):
    ignore={'.git','.dart_tool','build','.gradle'}
    return sorted([p for p in root.rglob('*') if p.is_file() and not any(x in p.parts for x in ignore)])
def is_runtime(root,p): return rel(root,p).startswith(RUNTIME_ROOTS)
def safe_read(p):
    try:
        if p.stat().st_size>MAX_READ: return p.read_text('utf-8','ignore')[:MAX_READ]
        return p.read_text('utf-8','ignore')
    except Exception: return ''
def method_body(src,name):
    i=src.find(name)
    if i<0: return ''
    j=src.find('{',i)
    if j<0: return src[i:i+2500]
    d=0
    for k in range(j,min(len(src),j+12000)):
        if src[k]=='{': d+=1
        elif src[k]=='}':
            d-=1
            if d==0: return src[i:k+1]
    return src[i:j+12000]
def pubspec_missing(root):
    p=root/'pubspec.yaml'; assets=[]; missing=[]
    if not p.exists(): return [],['pubspec.yaml']
    lines=safe_read(p).splitlines(); in_assets=False; baseindent=0
    for line in lines:
        st=line.strip()
        if st=='assets:': in_assets=True; baseindent=len(line)-len(line.lstrip()); continue
        if in_assets:
            if not st or st.startswith('#'): continue
            ind=len(line)-len(line.lstrip())
            if ind<=baseindent and not st.startswith('-'): in_assets=False; continue
            m=re.match(r'\s*-\s*(.+?)\s*$',line)
            if m: assets.append(m.group(1).strip().strip('"\''))
    for a in assets:
        if a.startswith('packages/'): continue
        pp=root/a
        if a.endswith('/'):
            if not pp.is_dir(): missing.append(a)
        else:
            if not pp.exists(): missing.append(a)
    return assets,missing
def quick_features(root):
    files=all_files(root); rt=[p for p in files if is_runtime(root,p)]; text=[p for p in rt if p.suffix.lower() in TEXT_EXTS]
    paths=['lib/core/ai/ai_response.dart','lib/services/local_model/local_model_service.dart','lib/services/backup/backup_service.dart','lib/services/runtime/nova_single_brain_authority_service.dart','lib/ui/dashboard/dashboard_page.dart','android/app/src/main/kotlin/com/example/nova/MainActivity.kt','android/app/src/main/kotlin/com/example/nova/ModelBridge.kt','android/app/src/main/kotlin/com/example/nova/NovaStreamingVoiceGate.kt','lib/services/api/api_service.dart','lib/ui/onboarding/nova_first_run_setup_page.dart','lib/services/call_companion/nova_call_companion_service.dart','lib/services/call_companion/nova_call_companion_runtime_service.dart','lib/services/reminder/nova_reminder_runtime_service.dart','lib/services/call_instruction/nova_call_instruction_runtime_service.dart','lib/core/voice/nova_voice_output_decision.dart']
    S={path:safe_read(root/path) for path in paths}
    ai=S[paths[0]]; local=S[paths[1]]; single=S[paths[3]]; dash=S[paths[4]]; main=S[paths[5]]; model=S[paths[6]]; gate=S[paths[7]]; api=S[paths[8]]; setup=S[paths[9]]; callcomp=S[paths[10]]; callcomprt=S[paths[11]]; rem=S[paths[12]]; callinstr=S[paths[13]]; voice=S[paths[14]]
    native=method_body(main,'aiSuccessPayload')
    auth_region=single[single.find('bool authorizeSpeech'):single.find('void _ensureCoreProfile')] if 'bool authorizeSpeech' in single else single
    success_files=[]; lms=[]; miss_imports=[]; tts_files=[]; model_files=[]; fallback_files=[]; security_files=[]; methodchannel_files=[]
    for p in text:
        r=rel(root,p); s=safe_read(p)
        if 'AiResponse.success' in s: success_files.append(r)
        if re.search(r'class\s+LocalModelService\b',s): lms.append(r)
        if 'MethodChannel' in s: methodchannel_files.append(r)
        if re.search(r'\.speak\s*\(|\bspeak\s*\(',s): tts_files.append(r)
        if re.search(r'LocalModelService|ModelBridge|Gemma|LiteRT|askAI|nova\.ai',s): model_files.append(r)
        if re.search(r'fallback|static|demo modunda|HazÄ±rÄ±m efendim|operational',s,re.I): fallback_files.append(r)
        if re.search(r'quarantine|security|shield|boundary',s,re.I): security_files.append(r)
        if r.startswith('lib/') and p.suffix=='.dart' and p.stat().st_size<MAX_READ:
            for line in s.splitlines():
                m=re.match(r"\s*import\s+['\"]([^'\"]+)['\"]\s*;",line)
                if not m: continue
                imp=m.group(1)
                if imp.startswith('dart:') or imp.startswith('package:'): continue
                if not (p.parent/imp).resolve().exists(): miss_imports.append({'file':r,'import':imp})
    assets,missing=pubspec_missing(root); external=[x for x in success_files if x!='lib/core/ai/ai_response.dart']
    return {
      'file_count':len(files),'runtime_text_count':len(text),'dart_files':sum(1 for p in rt if p.suffix=='.dart'),'kotlin_files':sum(1 for p in rt if p.suffix=='.kt'),'missing_assets':missing,'local_model_defs':lms,'external_airesponse_success_files':external,
      'ai_has_full_proof_helper': all(x in ai for x in ['hasNativeLocalProof','hasNativeLocalProofInMetadata','nativeProofSuccess','withNativeProofText']),
      'native_payload_full_proof': all(k in native for k in PROOF_KEYS) and 'authorityProofVersion' in native,
      'local_sanitize_requires_proof': re.search(r'!\s*response\.hasNativeLocalProof',local) is not None and 'sanitizeRejectedMissingNativeProof' in local,
      'local_sanitize_preserves_proof': 'withNativeProofText' in local or 'withNativeProofMetadata' in local,
      'local_sanitize_mints_authority': ("'authoritativeLocalBrain': true" in local and 'normalizedNativeProofMetadata' not in local),
      'singlebrain_full_proof': 'response.hasNativeLocalProof' in single and 'modelUsed = !response.isError && response.hasNativeLocalProof' in single,
      'singlebrain_or_proof': 'response.fromLocalModel ||' in single or "metadata['nativeSuccess'] == true ||" in single,
      'tts_full_proof': 'response.hasNativeLocalProof' in auth_region and 'singleBrainAllowed' in auth_region and 'singleBrainAuthority' in auth_region and 'tts_source' in auth_region,
      'tts_or_proof': '|| meta[' in auth_region or "meta['nativeSuccess'] == true ||" in auth_region,
      'dashboard_fake_success':'hotpathResult.aiResponse  AiResponse.success(text: hotpathResult.spokenText)' in dash,
      'api_demo_success':'demo modunda' in api and 'AiResponse.success' in api,
      'setup_token_low': "'maxOutputTokens': isSetupRequest  16" in local or "'maxOutputTokens': isSetupRequest  24" in local,
      'setup_reentrant_raw_speech':'setup_speech_reentrant' in setup and 'return text' in method_body(setup,'_speakSetupNarration'),
      'native_timeout_75_only':'NATIVE_GENERATE_TIMEOUT_MS = 75_000L' in main and 'NATIVE_FAST_GENERATE_TIMEOUT_MS' not in main,
      'native_timeout_split': all(x in main for x in ['NATIVE_FAST_GENERATE_TIMEOUT_MS','NATIVE_SETUP_GENERATE_TIMEOUT_MS','NATIVE_BRAIN_KERNEL_TIMEOUT_MS']),
      'modelbridge_gpu_first': bool(re.search(r'BackendCandidate\("GPU[\s\S]{0,1200}BackendCandidate\("CPU',model)),
      'modelbridge_cpu_first': bool(re.search(r'BackendCandidate\("CPU[\s\S]{0,1200}BackendCandidate\("GPU',model)),
      'asr_high_threshold':'thresholdRms = 980.0' in gate or '640.0' in gate,
      'asr_fixed_threshold':'thresholdRms = 520.0' in gate and '420.0' in gate,
      'call_companion_requires_proof':'hasNativeLocalProof' in callcomp,
      'call_companion_runtime_static_tts_blocked':'NOVA_CALL_COMPANION_OPERATIONAL_TTS_BLOCKED' in callcomprt or 'authority' in callcomprt.lower(),
      'reminder_runtime_static_tts_blocked':'reminder_ai_rewrite_missing_authority' in rem and 'reminder_ai_rewrite_empty' in rem and "return ''" in rem,
      'call_instruction_static_tts_blocked':'call_instruction_ai_rewrite_missing_authority' in callinstr and 'call_instruction_ai_rewrite_empty' in callinstr,
      'voice_policy_full_proof':'hasNativeLocalProof' in voice,
      'missing_imports':miss_imports,'tts_files':tts_files,'model_files':model_files,'fallback_files':fallback_files,'security_files':security_files,'methodchannel_files':methodchannel_files,
      'all_files':[rel(root,p) for p in files],'text_files':[rel(root,p) for p in text]}
def run_sim(f):
    failures=[]; log=[]
    native=f['native_payload_full_proof']; sanitized=native and f['local_sanitize_requires_proof'] and f['local_sanitize_preserves_proof'] and not f['local_sanitize_mints_authority']; single=sanitized and f['singlebrain_full_proof'] and not f['singlebrain_or_proof']; tts=single and f['tts_full_proof'] and not f['tts_or_proof']
    log=[f'FAKE_LOGCAT NOVA_NATIVE_GENERATE_CALLED model=gemma-4-E2B-it.litertlm proof={native}',f'FAKE_FLUTTER LOCAL_MODEL_SANITIZE preservedProof={sanitized}',f'FAKE_FLUTTER SINGLE_BRAIN_DECISION allowed={single}',f'FAKE_TTS AUTH allowed={tts}','FAKE_UI DASHBOARD_UPDATE source=brain_decision_ai_output' if tts else 'FAKE_UI DASHBOARD_BLOCKED reason=missing_full_proof']
    checks={'normal_full_route_speaks':tts,'proof_loss_rejected':f['local_sanitize_requires_proof'],'ui_no_success_without_proof':not f['dashboard_fake_success'] and not f['external_airesponse_success_files'],'tts_without_proof_blocked':f['tts_full_proof'] and not f['tts_or_proof'],'setup_static_shell_blocked':not f['setup_token_low'] and not f['setup_reentrant_raw_speech'],'backup_bypass_closed':len(f['local_model_defs'])==1,'asr_log_replay_peak_554_opens':f['asr_fixed_threshold'] and not f['asr_high_threshold'],'native_timeout_separated':f['native_timeout_split'] and not f['native_timeout_75_only'],'modelbridge_cpu_first':f['modelbridge_cpu_first'] and not f['modelbridge_gpu_first'],'api_static_success_blocked':not f['api_demo_success'],'call_companion_requires_native_proof':f['call_companion_requires_proof'],'call_companion_runtime_static_tts_blocked':f['call_companion_runtime_static_tts_blocked'],'reminder_static_tts_blocked':f['reminder_runtime_static_tts_blocked'],'call_instruction_static_tts_blocked':f['call_instruction_static_tts_blocked'],'voice_policy_full_proof':f['voice_policy_full_proof'],'pubspec_assets_present':not f['missing_assets'],'external_airesponse_success_zero':len(f['external_airesponse_success_files'])==0}
    failures=[k for k,v in checks.items() if not v]
    return {'status':'PASS' if not failures else 'FAIL','checks':checks,'failures':failures,'fake_logcat':log}
def build_risk(f):
    conds={'missing_assets':not f['missing_assets'],'missing_imports':not f['missing_imports'],'duplicate_LocalModelService':len(f['local_model_defs'])==1,'external_AiResponse_success':not f['external_airesponse_success_files'],'native_payload_full_proof':f['native_payload_full_proof'],'singlebrain_full_proof':f['singlebrain_full_proof'],'tts_full_proof':f['tts_full_proof'],'cpu_first':f['modelbridge_cpu_first'],'asr_fixed':f['asr_fixed_threshold']}
    failures=[k for k,v in conds.items() if not v]
    return {'status':'PASS' if not failures else 'FAIL','failures':failures,'missing_assets':f['missing_assets'],'missing_imports':f['missing_imports'],'local_model_defs':f['local_model_defs'],'external_airesponse_success_files':f['external_airesponse_success_files']}
def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--raw',required=True); ap.add_argument('--candidate',required=True); ap.add_argument('--outdir',required=True); args=ap.parse_args()
    raw=Path(args.raw); cand=Path(args.candidate); out=Path(args.outdir); out.mkdir(parents=True,exist_ok=True)
    report={'generated_at':time.strftime('%Y-%m-%d %H:%M:%S'),'baseline':'raw JARVÄ°Å.zip + pubspec.yaml','patches_assumed_applied':[]}
    for label,root in [('raw',raw),('candidate',cand)]:
        f=quick_features(root); sim=run_sim(f); br=build_risk(f)
        report[label]={'features':f,'simulation':sim,'build_risk':br,'file_count':f['file_count'],'runtime_text_count':f['runtime_text_count']}
        with open(out/f'nova_v27_{label}_fake_logcat.txt','w',encoding='utf-8') as fh: fh.write('\n'.join(sim['fake_logcat']))
    report['final_status']='PASS' if report['raw']['simulation']['status']=='FAIL' and report['candidate']['simulation']['status']=='PASS' and report['candidate']['build_risk']['status']=='PASS' else 'FAIL'
    (out/'nova_v27_logic_liftoff_report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    summary={'final_status':report['final_status'],'raw_simulation':report['raw']['simulation']['status'],'raw_build_risk':report['raw']['build_risk']['status'],'raw_failures':report['raw']['simulation']['failures']+report['raw']['build_risk']['failures'],'candidate_simulation':report['candidate']['simulation']['status'],'candidate_build_risk':report['candidate']['build_risk']['status'],'candidate_failures':report['candidate']['simulation']['failures']+report['candidate']['build_risk']['failures']}
    (out/'nova_v27_logic_liftoff_summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(summary,ensure_ascii=False,indent=2))
if __name__=='__main__': main()
