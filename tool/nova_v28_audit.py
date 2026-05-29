#!/usr/bin/env python3
from pathlib import Path
import re, json, csv, hashlib, argparse
REVIEW={'.dart','.kt','.kts','.gradle','.yaml','.yml','.xml','.json','.properties','.cmd','.ps1','.py','.md','.txt'}
def read(p): return p.read_text(errors='ignore')
def rel(p,root): return str(p.relative_to(root)).replace('\\','/')
def sha(p):
 h=hashlib.sha256(); f=open(p,'rb')
 for b in iter(lambda:f.read(1048576),b''): h.update(b)
 f.close(); return h.hexdigest()
def missing_imports(root):
 out=[]
 for p in (root/'lib').rglob('*.dart'):
  for m in re.finditer(r"import\s+['\"]([^'\"]+)['\"]", read(p)):
   imp=m.group(1)
   if imp.startswith(('dart:','package:')) or '://' in imp: continue
   if not (p.parent/imp).resolve().exists(): out.append({'file':rel(p,root),'import':imp})
 return out
def assets(root):
 p=root/'pubspec.yaml'; miss=[]; a=[]
 if not p.exists(): return ['pubspec.yaml'],[]
 active=False
 for line in read(p).splitlines():
  if re.match(r'^\s*assets\s*:',line): active=True; continue
  if active:
   if line.strip().startswith('-'):
    item=line.split('-',1)[1].strip().strip('"\'')
    if item: a.append(item); miss += ([] if (root/item).exists() else [item])
   elif line and not line.startswith(' '): active=False
 return miss,a
def string_issues(root):
 issues=[]
 for p in root.rglob('*.dart'):
  t=read(p); line=1; i=0; in_s=None; triple=False; esc=False; start=1; block=False
  while i<len(t):
   ch=t[i]; two=t[i:i+2]
   if ch=='\n':
    if in_s and not triple:
     issues.append({'file':rel(p,root),'line':start,'reason':'newline_in_single_line_string'}); in_s=None; esc=False
    line+=1; i+=1; continue
   if block:
    if two=='*/': block=False; i+=2; continue
    i+=1; continue
   if not in_s:
    if two=='//':
     j=t.find('\n',i); i=len(t) if j<0 else j; continue
    if two=='/*': block=True; i+=2; continue
    if t[i:i+3] in ("'''",'"""'):
     in_s=ch; triple=True; start=line; i+=3; continue
    if ch in ("'",'"'):
     in_s=ch; triple=False; start=line; esc=False; i+=1; continue
    i+=1; continue
   if esc: esc=False; i+=1; continue
   if ch=='\\': esc=True; i+=1; continue
   if triple:
    if t[i:i+3]==in_s*3: in_s=None; triple=False; i+=3; continue
    i+=1; continue
   else:
    if ch==in_s: in_s=None
    i+=1
  if in_s and not triple: issues.append({'file':rel(p,root),'line':start,'reason':'unterminated_string'})
 return issues
def adjacent_dup_named(root):
 out=[]
 for p in (root/'lib').rglob('*.dart'):
  lines=read(p).splitlines()
  for i in range(len(lines)-1):
   m1=re.match(r'(\s*)([A-Za-z_][A-Za-z0-9_]*)\s*:',lines[i]); m2=re.match(r'(\s*)([A-Za-z_][A-Za-z0-9_]*)\s*:',lines[i+1])
   if m1 and m2 and m1.group(1)==m2.group(1) and m1.group(2)==m2.group(2) and m1.group(2)!='child':
    out.append({'file':rel(p,root),'line':i+1,'arg':m1.group(2),'snippet':lines[i].strip()+' / '+lines[i+1].strip()})
 return out
def main():
 ap=argparse.ArgumentParser(); ap.add_argument('--root',required=True); ap.add_argument('--out',required=True); args=ap.parse_args(); root=Path(args.root); out=Path(args.out); out.mkdir(parents=True,exist_ok=True)
 all_files=[p for p in root.rglob('*') if p.is_file()]
 miss_imp=missing_imports(root); miss_assets, asset_list=assets(root)
 ext_success=[rel(p,root) for p in (root/'lib').rglob('*.dart') if 'AiResponse.success' in read(p) and rel(p,root)!='lib/core/ai/ai_response.dart']
 dup_lms=[rel(p,root) for p in root.rglob('*.dart') if 'class LocalModelService' in read(p)]
 s_issues=string_issues(root); dup_named=adjacent_dup_named(root)
 def has(path,pat):
  p=root/path; return p.exists() and re.search(pat,read(p),re.S)!=None
 patterns={
  'dashboard_fake_success':has(Path('lib/ui/dashboard/dashboard_page.dart'),r'hotpathResult\.aiResponse\s*\?\?\s*AiResponse\.success'),
  'backup_raw_askAI':has(Path('lib/services/backup/backup_service.dart'),r"MethodChannel\([^)]*nova\.ai|invokeMethod<[^>]+>\(\s*['\"]askAI"),
  'api_success':has(Path('lib/services/api/api_service.dart'),r'AiResponse\.success|API yanÄ±tÄ± ÅŸu an demo'),
  'native_75s':has(Path('android/app/src/main/kotlin/com/example/nova/MainActivity.kt'),r'75_000L'),
  'setup_16':has(Path('lib/services/local_model/local_model_service.dart'),r'maxOutputTokens[^\n]+\?\s*16'),
  'asr_640_or_980':has(Path('android/app/src/main/kotlin/com/example/nova/NovaStreamingVoiceGate.kt'),r'640\.0|980\.0'),
 }
 mb=root/'android/app/src/main/kotlin/com/example/nova/ModelBridge.kt'; gpu_first=False
 if mb.exists():
  t=read(mb); gpu=t.find('BackendCandidate("GPU"'); cpu=t.find('BackendCandidate("CPU'); gpu_first=gpu!=-1 and (cpu==-1 or gpu<cpu)
 patterns['gpu_first']=gpu_first
 failures=[]
 if miss_imp: failures.append('missing_imports')
 if miss_assets: failures.append('missing_assets')
 if ext_success: failures.append('external_airesponse_success')
 if dup_lms!=['lib/services/local_model/local_model_service.dart']: failures.append('duplicate_local_model_service')
 if s_issues: failures.append('string_syntax_issues')
 if dup_named: failures.append('duplicate_named_args')
 if any(patterns.values()): failures.append('forbidden_patterns')
 report={'status':'PASS' if not failures else 'FAIL','failures':failures,'counts':{'all_files':len(all_files),'review_files':len([p for p in all_files if p.suffix.lower() in REVIEW]),'dart':len(list((root/'lib').rglob('*.dart'))),'kotlin':len(list(root.rglob('*.kt')))},'missing_imports':miss_imp,'missing_assets':miss_assets,'asset_list':asset_list,'external_airesponse_success':ext_success,'duplicate_localmodel':dup_lms,'string_issues':s_issues,'duplicate_named_args':dup_named,'forbidden_patterns':patterns}
 (out/'nova_v28_audit.json').write_text(json.dumps(report,indent=2,ensure_ascii=False))
 with (out/'nova_v28_file_review.csv').open('w',newline='') as f:
  w=csv.writer(f); w.writerow(['file','type','size','sha256','script_result'])
  for p in all_files:
   r=rel(p,root); res='PASS'
   if any(x.get('file')==r for x in s_issues): res='FAIL_STRING_SYNTAX'
   if r in ext_success: res='FAIL_EXTERNAL_AI_RESPONSE_SUCCESS'
   if r in dup_lms and r!='lib/services/local_model/local_model_service.dart': res='FAIL_DUP_LOCAL_MODEL'
   w.writerow([r,p.suffix.lower(),p.stat().st_size,sha(p),res])
 print(json.dumps(report,indent=2,ensure_ascii=False))
if __name__=='__main__': main()
