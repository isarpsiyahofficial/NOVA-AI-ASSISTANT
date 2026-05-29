#!/usr/bin/env python3
from pathlib import Path
import re,json,argparse

def read(p): return p.read_text(errors='ignore')
def rel(p,r): return str(p.relative_to(r)).replace('\\','/')
def main():
 ap=argparse.ArgumentParser(); ap.add_argument('--root',required=True); ap.add_argument('--out',required=True); args=ap.parse_args(); root=Path(args.root); out=Path(args.out); out.parent.mkdir(parents=True,exist_ok=True)
 failures=[]
 # relative imports line-anchored only
 missing=[]
 for p in (root/'lib').rglob('*.dart'):
  for line in read(p).splitlines():
   m=re.match(r"^\s*import\s+['\"]([^'\"]+)['\"]",line)
   if not m: continue
   imp=m.group(1)
   if imp.startswith(('dart:','package:')) or '://' in imp: continue
   if not (p.parent/imp).resolve().exists(): missing.append({'file':rel(p,root),'import':imp})
 if missing: failures.append('missing_imports')
 # specific broken single-line string found in v27
 lm=root/'lib/services/local_model/local_model_service.dart'
 broken=False
 if lm.exists():
  txt=read(lm)
  broken = "text = '$text\n\nUygunsa" in txt  # real newline inside quoted string
  escaped_ok = "text = '$text\\n\\nUygunsa" in txt
  if broken or not escaped_ok: failures.append('local_model_privacy_string_not_escaped')
 else: failures.append('local_model_missing')
 # adjacent duplicate named args except nested child
 dup=[]
 for p in (root/'lib').rglob('*.dart'):
  lines=read(p).splitlines()
  for i in range(len(lines)-1):
   m1=re.match(r'(\s*)([A-Za-z_][A-Za-z0-9_]*)\s*:',lines[i]); m2=re.match(r'(\s*)([A-Za-z_][A-Za-z0-9_]*)\s*:',lines[i+1])
   if m1 and m2 and m1.group(1)==m2.group(1) and m1.group(2)==m2.group(2) and m1.group(2) not in {'child'}:
    dup.append({'file':rel(p,root),'line':i+1,'arg':m1.group(2)})
 if dup: failures.append('duplicate_named_args_adjacent')
 # assets
 miss_assets=[]; pub=root/'pubspec.yaml'
 if pub.exists():
  in_assets=False
  for line in read(pub).splitlines():
   if re.match(r'^\s*assets\s*:',line): in_assets=True; continue
   if in_assets and line.strip().startswith('-'):
    item=line.split('-',1)[1].strip().strip('"\'')
    if item and not (root/item).exists(): miss_assets.append(item)
   elif in_assets and line and not line.startswith(' '): in_assets=False
 else: miss_assets.append('pubspec.yaml')
 if miss_assets: failures.append('missing_assets')
 # known forbidden patterns
 def has(path,pat):
  p=root/path; return p.exists() and re.search(pat,read(p),re.S)
 checks={
  'external_airesponse_success': [rel(p,root) for p in (root/'lib').rglob('*.dart') if 'AiResponse.success' in read(p) and rel(p,root)!='lib/core/ai/ai_response.dart'],
  'duplicate_localmodel': [rel(p,root) for p in root.rglob('*.dart') if 'class LocalModelService' in read(p)],
  'dashboard_fake_success': bool(has(Path('lib/ui/dashboard/dashboard_page.dart'),r'hotpathResult\.aiResponse\s*\?\?\s*AiResponse\.success')),
  'api_demo_success': bool(has(Path('lib/services/api/api_service.dart'),r'API yanÄ±tÄ± ÅŸu an demo|AiResponse\.success')),
  'backup_raw_askai': bool(has(Path('lib/services/backup/backup_service.dart'),r"MethodChannel\([^)]*nova\.ai|invokeMethod<[^>]+>\(\s*['\"]askAI")),
  'native_75s': bool(has(Path('android/app/src/main/kotlin/com/example/nova/MainActivity.kt'),r'75_000L')),
  'asr_old_thresholds': bool(has(Path('android/app/src/main/kotlin/com/example/nova/NovaStreamingVoiceGate.kt'),r'980\.0|640\.0')),
 }
 if checks['external_airesponse_success']: failures.append('external_airesponse_success')
 if checks['duplicate_localmodel'] != ['lib/services/local_model/local_model_service.dart']: failures.append('duplicate_localmodel')
 if any(v for k,v in checks.items() if isinstance(v,bool)): failures.append('forbidden_patterns')
 report={'status':'PASS' if not failures else 'FAIL','failures':failures,'missing_imports':missing,'broken_privacy_string':broken,'duplicate_named_args':dup,'missing_assets':miss_assets,'checks':checks}
 Path(out).write_text(json.dumps(report,indent=2,ensure_ascii=False)); print(json.dumps(report,indent=2,ensure_ascii=False))
if __name__=='__main__': main()
