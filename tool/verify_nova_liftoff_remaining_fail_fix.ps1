param([string]$ProjectRoot = (Get-Location).Path)
$ErrorActionPreference = 'Stop'
function Join-Root([string]$rel){ Join-Path $ProjectRoot $rel }
function Text([string]$rel){ $p=Join-Root $rel; if(!(Test-Path $p)){ return '' }; [System.IO.File]::ReadAllText($p,[System.Text.Encoding]::UTF8) }
$fail=@(); $warn=@(); $ok=0
function OK($m){ $script:ok++ }
function FAIL($m){ $script:fail += $m }
function WARN($m){ $script:warn += $m }
$local=Text 'lib\services\local_model\local_model_service.dart'
$speech=Text 'lib\services\speech_runtime\nova_speech_runtime_service.dart'
$voice=Text 'lib\core\voice\nova_voice_output_decision.dart'
$main=Text 'android\app\src\main\kotlin\com\example\nova\MainActivity.kt'
$bridge=Text 'android\app\src\main\kotlin\com\example\nova\ModelBridge.kt'
$gradle=Text 'android\app\build.gradle.kts'
if($local.Contains('if (!success) {')){ OK 'native false rejected before text acceptance' } else { FAIL 'LocalModelService still has conditional success=false branch' }
if($local.Contains('rawStringNativeModelBlocked') -and $local.Contains('NOVA_LOCAL_MODEL_DART_RAW_STRING_RESULT_BLOCKED')){ OK 'raw string native output blocked' } else { FAIL 'raw string native output block missing' }
if($local -match "rawNativeLocalModel': true[\s\S]{0,200}\}\,\s*\)\;\s*\}\s*String _extractNativeText") { FAIL 'raw string success tail still exists before _extractNativeText' } else { OK 'raw string success tail absent' }
if($speech.Contains('NOVA_TTS_FALLBACK_SPEECH_BLOCKED_V2') -and $speech.Contains('SingleBrainAuthority dışı fallback TTS engellendi.')){ OK 'TTS fallback block marker present' } else { FAIL 'TTS fallback block marker missing' }
if($speech -match 'ttsService\.speak\(\s*fallbackText' -or $speech -match 'buildFastReply\(normalizedText\)'){ FAIL 'speech runtime can still build/speak generated fallbackText' } else { OK 'generated fallback speech path absent' }
if($voice.Contains('bool _isAuthoritativeAiSpeech') -and $voice.Contains('rawStringNativeModelBlocked') -or $voice.Contains('blocked_non_ai_speech')){ OK 'voice policy contains authority/blocking path' } else { WARN 'voice policy blocking marker weak/missing' }
if($main.Contains('gemma-4-E2B-it.litertlm')){ OK 'Gemma4 main model reference' } else { FAIL 'Gemma4 main model missing' }
if($main -match 'gemma-3n|gemma-3|model\.litertlm|gemma\.litertlm'){ FAIL 'legacy model reference remains in MainActivity' } else { OK 'no legacy model reference in MainActivity' }
if($gradle.Contains('implementation(files("../../third_party/litertlm_android/litertlm-android-0.11.0-rc1.aar"))')){ OK 'local AAR dependency' } else { FAIL 'local AAR dependency missing' }
if($gradle -match 'latest\.release|com\.google\.ai\.edge\.litertlm:litertlm-android'){ FAIL 'remote/latest LiteRT dependency remains' } else { OK 'no remote/latest LiteRT dependency' }
$cancel=[regex]::Match($bridge,'fun\s+cancelGeneration[\s\S]*?\n\s*\}',[Text.RegularExpressions.RegexOptions]::Singleline)
if($cancel.Success -and $cancel.Value -notmatch 'close\s*\(' -and $cancel.Value -notmatch 'gemmaEngine\s*=\s*null' -and $cancel.Value -notmatch 'loadedGemmaPath\s*=\s*null'){ OK 'cancelGeneration preserves engine' } else { FAIL 'cancelGeneration may destroy engine' }
$reportDir=Join-Root 'build\nova_liftoff_remaining_fail_fix'
if(!(Test-Path $reportDir)){ New-Item -ItemType Directory -Force -Path $reportDir | Out-Null }
$report=@('NOVA LIFTOFF REMAINING FAIL FIX VERIFY',"Project: $ProjectRoot","OK=$ok WARN=$($warn.Count) FAIL=$($fail.Count)",'')
foreach($w in $warn){ $report += "[WARN] $w" }
foreach($f in $fail){ $report += "[FAIL] $f" }
$report | Set-Content -Encoding UTF8 (Join-Path $reportDir 'NOVA_LIFTOFF_REMAINING_FAIL_FIX_VERIFY_REPORT.txt')
if($fail.Count -eq 0){ Write-Host "NOVA_LIFTOFF_REMAINING_FAIL_FIX_VERIFY_OK OK=$ok WARN=$($warn.Count) FAIL=0"; Write-Host "Report: $reportDir\NOVA_LIFTOFF_REMAINING_FAIL_FIX_VERIFY_REPORT.txt"; exit 0 }
Write-Host "NOVA_LIFTOFF_REMAINING_FAIL_FIX_VERIFY_FAIL OK=$ok WARN=$($warn.Count) FAIL=$($fail.Count)"; Write-Host "Report: $reportDir\NOVA_LIFTOFF_REMAINING_FAIL_FIX_VERIFY_REPORT.txt"; exit 1
