param([string]$ProjectRoot = (Get-Location).Path)
$ErrorActionPreference = 'Stop'
function Join-Root([string]$rel){ Join-Path $ProjectRoot $rel }
function Text([string]$rel){ $p=Join-Root $rel; if(!(Test-Path $p)){ return '' }; [System.IO.File]::ReadAllText($p,[System.Text.Encoding]::UTF8) }
$ok=0; $warn=@(); $fail=@()
function OK($m){ $script:ok++ }
function WARN($m){ $script:warn += $m }
function FAIL($m){ $script:fail += $m }
$local=Text 'lib\services\local_model\local_model_service.dart'
$ai=Text 'lib\core\ai\ai_response.dart'
$voice=Text 'lib\core\voice\nova_voice_output_decision.dart'
$speech=Text 'lib\services\speech_runtime\nova_speech_runtime_service.dart'
$main=Text 'android\app\src\main\kotlin\com\example\nova\MainActivity.kt'
$bridge=Text 'android\app\src\main\kotlin\com\example\nova\ModelBridge.kt'
$gradle=Text 'android\app\build.gradle.kts'
if($local.Contains('if (!success) {')){ OK 'native success=false is rejected unconditionally' } else { FAIL 'native success=false can still pass when text exists' }
if($local.Contains('rawStringNativeModelBlocked') -and $local.Contains('NOVA_LOCAL_MODEL_DART_RAW_STRING_RESULT_BLOCKED')){ OK 'raw string native output blocked' } else { FAIL 'raw string native output block missing' }
if($local -match "return\s+AiResponse\.success\([\s\S]{0,450}'rawNativeLocalModel':\s*true[\s\S]{0,250}\);\s*\}\s*String\s+_extractNativeText") { FAIL 'raw string success tail still exists before _extractNativeText' } else { OK 'raw string success tail absent' }
if($ai -notmatch "quickReply\s*=\s*'Buyurun efendim\.\.\.'") { OK 'AiResponse.error has no spoken static quickReply' } else { FAIL 'AiResponse.error still carries static quickReply' }
if($voice.Contains('NOVA_VOICE_POLICY_AUTHORITATIVE_MODEL_ONLY_V1') -and $voice.Contains('NOVA_TTS_FALLBACK_SPEECH_BLOCKED_V3') -and $voice.Contains('rawStringNativeModelBlocked') -and $voice.Contains('shouldSpeak: false')){ OK 'voice policy blocks non-authoritative/static/error speech' } else { FAIL 'voice policy authority/static block missing' }
if($speech.Contains('NOVA_TTS_FALLBACK_SPEECH_BLOCKED_V3')){ OK 'speech runtime fallback block marker present' } else { FAIL 'speech runtime fallback block marker missing' }
if($speech -match 'buildFastReply\(normalizedText\)' -or $speech -match 'fallbackText'){ FAIL 'speech runtime can still generate fallbackText' } else { OK 'generated fallback speech path absent' }
if($speech -match 'usedFallback:\s*true'){ WARN 'speech runtime still contains usedFallback:true elsewhere; inspect manually if build/runtime fails' } else { OK 'speech runtime has no usedFallback:true' }
if($main.Contains('gemma-4-E2B-it.litertlm')){ OK 'Gemma 4 main model reference' } else { FAIL 'Gemma 4 main model missing' }
if($main -match 'gemma-3n|gemma-3|model\.litertlm|gemma\.litertlm'){ FAIL 'legacy model reference remains in MainActivity' } else { OK 'no legacy model reference in MainActivity' }
if($gradle.Contains('implementation(files("../../third_party/litertlm_android/litertlm-android-0.11.0-rc1.aar"))')){ OK 'local AAR dependency' } else { FAIL 'local AAR dependency missing' }
if($gradle -match 'latest\.release|com\.google\.ai\.edge\.litertlm:litertlm-android'){ FAIL 'remote/latest LiteRT dependency remains' } else { OK 'no remote/latest LiteRT dependency' }
$cancel=[regex]::Match($bridge,'fun\s+cancelGeneration[\s\S]*?\n\s*\}',[Text.RegularExpressions.RegexOptions]::Singleline)
if($cancel.Success -and $cancel.Value -notmatch 'close\s*\(' -and $cancel.Value -notmatch 'gemmaEngine\s*=\s*null' -and $cancel.Value -notmatch 'loadedGemmaPath\s*=\s*null'){ OK 'cancelGeneration preserves engine' } else { FAIL 'cancelGeneration may destroy engine' }
$reportDir=Join-Root 'build\nova_liftoff_hard_fail_fix'
if(!(Test-Path $reportDir)){ New-Item -ItemType Directory -Force -Path $reportDir | Out-Null }
$report=@('NOVA LIFTOFF HARD FAIL FIX VERIFY',"Project: $ProjectRoot","OK=$ok WARN=$($warn.Count) FAIL=$($fail.Count)",'')
foreach($w in $warn){ $report += "[WARN] $w" }
foreach($f in $fail){ $report += "[FAIL] $f" }
$report | Set-Content -Encoding UTF8 (Join-Path $reportDir 'NOVA_LIFTOFF_HARD_FAIL_FIX_VERIFY_REPORT.txt')
if($fail.Count -eq 0){ Write-Host "NOVA_LIFTOFF_HARD_FAIL_FIX_VERIFY_OK OK=$ok WARN=$($warn.Count) FAIL=0"; Write-Host "Report: $reportDir\NOVA_LIFTOFF_HARD_FAIL_FIX_VERIFY_REPORT.txt"; exit 0 }
Write-Host "NOVA_LIFTOFF_HARD_FAIL_FIX_VERIFY_FAIL OK=$ok WARN=$($warn.Count) FAIL=$($fail.Count)"; Write-Host "Report: $reportDir\NOVA_LIFTOFF_HARD_FAIL_FIX_VERIFY_REPORT.txt"; exit 1
