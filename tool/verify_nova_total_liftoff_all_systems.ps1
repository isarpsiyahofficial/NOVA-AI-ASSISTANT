param([string]$ProjectRoot = (Get-Location).Path)
$ErrorActionPreference = 'Stop'
function Join-Root([string]$rel) { Join-Path $ProjectRoot $rel }
function Read-Utf8([string]$p) { [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8) }
$reportDir = Join-Root 'build\nova_total_liftoff_all_systems_verify'
if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Force -Path $reportDir | Out-Null }
$fail = New-Object System.Collections.Generic.List[string]
$warn = New-Object System.Collections.Generic.List[string]
$ok = 0
function OK([string]$m){ $script:ok++ }
function FAIL([string]$m){ $script:fail.Add($m) | Out-Null }
function WARN([string]$m){ $script:warn.Add($m) | Out-Null }
function Exists([string]$rel){ Test-Path (Join-Root $rel) }
function Text([string]$rel){ $p=Join-Root $rel; if(!(Test-Path $p)){return ''}; return Read-Utf8 $p }
function Has([string]$rel,[string]$needle){ return (Text $rel).Contains($needle) }
function NotHas([string]$rel,[string]$needle){ return -not (Has $rel $needle) }
function RegexHas([string]$rel,[string]$pat){ return [regex]::IsMatch((Text $rel), $pat, [Text.RegularExpressions.RegexOptions]::Singleline) }

if (Exists 'pubspec.yaml') { OK 'root pubspec' } else { FAIL 'pubspec.yaml missing / wrong root' }

# Gemma/model/motor strict checks.
if (Exists 'android\app\src\main\assets\models\llm\gemma-4-E2B-it.litertlm') { OK 'Gemma 4 asset exists' } else { FAIL 'Gemma 4 asset missing' }
$assetDir = Join-Root 'android\app\src\main\assets\models\llm'
$assetModels = @()
if (Test-Path $assetDir) { $assetModels = @(Get-ChildItem -LiteralPath $assetDir -Filter '*.litertlm' -File -ErrorAction SilentlyContinue) }
if ($assetModels.Count -eq 1 -and $assetModels[0].Name -eq 'gemma-4-E2B-it.litertlm') { OK 'only Gemma 4 asset model' } else { FAIL "asset model mismatch: $($assetModels.Name -join ',')" }
if (Exists 'third_party\litertlm_android\litertlm-android-0.11.0-rc1.aar') { OK 'local LiteRT AAR exists' } else { FAIL 'local LiteRT AAR missing' }
if (Has 'android\app\build.gradle.kts' 'implementation(files("../../third_party/litertlm_android/litertlm-android-0.11.0-rc1.aar"))') { OK 'Gradle local AAR' } else { FAIL 'Gradle local LiteRT AAR reference missing' }
if (NotHas 'android\app\build.gradle.kts' 'latest.release') { OK 'no latest.release' } else { FAIL 'latest.release still present' }
if (NotHas 'android\app\build.gradle.kts' 'com.google.ai.edge.litertlm:litertlm-android') { OK 'no remote LiteRT Maven dep' } else { FAIL 'remote LiteRT Maven dependency still present' }
if (Has 'android\app\src\main\kotlin\com\example\nova\MainActivity.kt' 'PRIMARY_LITERTLM_MODEL_FILE_NAME = "gemma-4-E2B-it.litertlm"') { OK 'MainActivity primary Gemma 4' } else { FAIL 'MainActivity primary model not Gemma 4' }
if (Has 'android\app\src\main\kotlin\com\example\nova\MainActivity.kt' 'NOVA_GEMMA4_NON_PRIMARY_MODEL_PURGE') { OK 'non-primary .litertlm purge' } else { WARN 'non-primary .litertlm purge marker missing' }

# ModelBridge warm engine and timing.
$bridge = Text 'android\app\src\main\kotlin\com\example\nova\ModelBridge.kt'
$cancel = [regex]::Match($bridge, 'fun\s+cancelGeneration\s*\([^)]*\)\s*:\s*Boolean\s*\{(?<body>.*?)\n\s*\}', [Text.RegularExpressions.RegexOptions]::Singleline)
if ($cancel.Success) { $body=$cancel.Groups['body'].Value; if ($body -match 'close\s*\(' -or $body -match 'gemmaEngine\s*=\s*null' -or $body -match 'loadedGemmaPath\s*=\s*null') { FAIL 'cancelGeneration destroys warm engine/path' } else { OK 'cancelGeneration preserves warm engine/path' } } else { FAIL 'cancelGeneration body not found' }
foreach($m in @('engineInitMs','warmReuse','decodeMs','totalMs','modelBytes','NOVA_LITERT_GENERATE_START','NOVA_LITERT_GENERATE_DONE')) { if ($bridge.Contains($m)) { OK "ModelBridge marker $m" } else { FAIL "ModelBridge marker missing: $m" } }

# AI/static fallback proof.
if (Has 'lib\core\ai\ai_response.dart' "String quickReply = ''") { OK 'AiResponse.error silent quickReply' } else { FAIL 'AiResponse.error still has speakable quickReply' }
if (Has 'lib\services\local_model\local_model_service.dart' 'if (!success) {') { OK 'native success false hard rejected' } else { FAIL 'LocalModelService accepts native success=false text' }
if (Has 'lib\services\local_model\local_model_service.dart' 'rawStringNativeModelBlocked') { OK 'raw string native output blocked' } else { FAIL 'raw string native output can be accepted as authoritative' }
if (Has 'lib\core\voice\nova_voice_output_decision.dart' 'bool _isAuthoritativeAiSpeech') { OK 'Voice policy authority gate' } else { FAIL 'Voice policy authority gate missing' }
if (Has 'lib\core\voice\nova_voice_output_decision.dart' 'if (response.isError) return false;') { OK 'Voice policy blocks AI error speech' } else { FAIL 'Voice policy may speak AI error output' }
if (Has 'lib\core\ai\nova_ai_service.dart' 'api_recovery_blocked_requires_local_model') { OK 'API/no-local recovery blocked' } else { FAIL 'API/no-local recovery success path not blocked' }
if (Has 'lib\core\ai\nova_ai_service.dart' 'no_model_recovery_blocked') { OK 'no-model recovery blocked' } else { FAIL 'no-model recovery success path not blocked' }
if (Has 'lib\core\ai\nova_ai_service.dart' "rescueResponse.metadata['nativeSuccess'] == true") { OK 'strict rescue requires native proof' } else { FAIL 'strict rescue can accept fallback output' }
if (Has 'lib\services\speech_runtime\nova_speech_runtime_service.dart' 'SingleBrainAuthority dışı fallback TTS engellendi') { OK 'TTS fallback blocked' } else { FAIL 'TTS fallback block marker missing' }

# ASR + voice identity + authorization chain.
foreach($f in @(
 'lib\services\asr\nova_streaming_asr_runtime_service.dart',
 'lib\services\asr\nova_streaming_asr_bridge_service.dart',
 'lib\services\asr\nova_streaming_transcript_router_service.dart',
 'lib\services\audio_runtime\nova_listening_router_service.dart',
 'lib\services\audio_runtime\nova_stt_runtime_service.dart',
 'lib\services\identity\voice_authorization_runtime_service.dart',
 'lib\services\identity\voice_authorization_service.dart',
 'lib\services\identity\voice_identity_registry_service.dart',
 'lib\services\identity\nova_recent_speaker_service.dart',
 'lib\services\identity\nova_daily_voice_session_service.dart',
 'lib\services\system\nova_continuous_listening_runtime_service.dart',
 'lib\services\call_companion\nova_call_companion_runtime_service.dart'
)) { if (Exists $f) { OK "ASR/auth file exists $f" } else { FAIL "missing ASR/auth file $f" } }
$asr = Text 'lib\services\asr\nova_streaming_asr_runtime_service.dart'
if ($asr.Contains('NOVA_ASR_SINGLE_SESSION_OWNER_GUARD_V2')) { OK 'ASR single session owner marker' } else { FAIL 'ASR single session owner guard marker missing' }
if ($asr.Contains('_owner') -and $asr.Contains('_transitionInFlight') -and $asr.Contains('NOVA_STREAMING_ASR_OWNER_REJECTED')) { OK 'ASR owner/transition guard state exists' } else { FAIL 'ASR owner/transition guard state incomplete' }
if ([regex]::IsMatch($asr, 'OWNER_REJECTED[\s\S]{0,500}return\s+false\s*;', [Text.RegularExpressions.RegexOptions]::Singleline)) { OK 'ASR owner collision returns false, not fake success' } else { FAIL 'ASR owner collision may be reported as successful start' }
if ($asr.Contains('return _started && _owner == normalizedOwner;')) { OK 'ASR transition collision does not fake ownership' } else { FAIL 'ASR transition collision guard missing' }
$router = Text 'lib\services\audio_runtime\nova_listening_router_service.dart'
foreach($m in @('ringingCall','activeCall','companionOwnsCall','callCompanionListening','fullyShutdown','wakeOnlyListening')) { if ($router.Contains($m)) { OK "listening router $m" } else { FAIL "listening router missing $m" } }
$continuous = Text 'lib\services\system\nova_continuous_listening_runtime_service.dart'
foreach($m in @('inspectPreferContinuityThenFresh','recentSpeakerService.remember','dailyVoiceSessionService','VoiceAccessLevel.owner','VoiceAccessLevel.authorizedGuest','_lastAuthorizedVoiceId','_softSpeakerIdentityUntil','_authorizedConversationUntil')) { if ($continuous.Contains($m)) { OK "continuous voice auth marker $m" } else { FAIL "continuous voice auth missing $m" } }
$companion = Text 'lib\services\call_companion\nova_call_companion_runtime_service.dart'
foreach($m in @('inspectPreferContinuityThenFresh','recentSpeakerService.remember','dailyVoiceSessionService.rememberTrustedSpeaker','_trustedSpeakerVoiceId','VoiceAccessLevel.owner','VoiceAccessLevel.authorizedGuest')) { if ($companion.Contains($m)) { OK "call companion voice auth marker $m" } else { FAIL "call companion voice auth missing $m" } }
$auth = Text 'lib\services\identity\voice_authorization_runtime_service.dart'
foreach($m in @('NovaVoiceAuthSyntheticPlaybackGuardService','identifyFromFreshExternalSample','authorizationService.decide','inspectPreferContinuityThenFresh','_inspectOwnerContinuity','recentSpeakerService.bestConversationCandidate','dailyVoiceSessionService.loadActiveTrustedSessions')) { if ($auth.Contains($m)) { OK "voice authorization marker $m" } else { FAIL "voice authorization missing $m" } }
if (Has 'lib\services\identity\voice_identity_registry_service.dart' 'nova_known_voice_identities_v1') { OK 'voice identity registry persistent memory' } else { FAIL 'voice identity registry storage key missing' }
if (Has 'android\app\src\main\AndroidManifest.xml' 'android.permission.RECORD_AUDIO') { OK 'Android RECORD_AUDIO permission' } else { FAIL 'RECORD_AUDIO permission missing' }
if (Has 'android\app\src\main\AndroidManifest.xml' 'FOREGROUND_SERVICE_MICROPHONE') { OK 'Android foreground microphone permission' } else { WARN 'FOREGROUND_SERVICE_MICROPHONE permission missing' }
if (Has 'android\app\src\main\kotlin\com\example\nova\asr\NovaStreamingAsrBridgePlugin.kt' 'nova/streaming_asr_bridge') { OK 'native streaming ASR channel exists' } else { FAIL 'native streaming ASR bridge channel missing' }
if (Has 'android\app\src\main\kotlin\com\example\nova\NovaVoiceIdentityBridgePlugin.kt' 'nova/voice_identity_bridge') { OK 'native voice identity channel exists' } else { FAIL 'native voice identity bridge missing' }
if (Has 'lib\services\audio_runtime\nova_audio_session_coordinator_service.dart' 'NOVA_AUDIO_SESSION_PRIORITY_GUARD_V2') { OK 'audio session priority guard' } else { FAIL 'audio session priority guard missing' }

# Full source unexpected pattern scan.
$allowedExt = @('.dart','.kt','.kts','.gradle','.xml','.yaml','.yml','.json','.properties','.md','.txt','.java','.cpp','.c','.h','.hpp','.cmake')
$excluded = @('\build\','\.gradle\','\.dart_tool\','\.git\','\audit_')
$files = Get-ChildItem -LiteralPath $ProjectRoot -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
  $allowedExt -contains $_.Extension.ToLowerInvariant() -and (($excluded | Where-Object { $_ -and $_.Length -gt 0 -and $_.FullName -like "*$_*" }).Count -eq 0)
}
$inventory = New-Object System.Collections.Generic.List[string]
$suspicious = New-Object System.Collections.Generic.List[string]
foreach ($f in $files) {
  $rel = $f.FullName.Substring($ProjectRoot.TrimEnd('\').Length + 1)
  $inventory.Add($rel) | Out-Null
  try { $txt = Read-Utf8 $f.FullName } catch { continue }
  if ($txt -match 'gemma-3n|gemma-3|qwen\.gguf|latest\.release|no_model_recovery_reply|api_recovery_reply|Buyurun efendim\.\.\.|allowFallbackSpeech:\s*true|singleBrainFallback.*true') { $suspicious.Add($rel) | Out-Null }
}
$inventory | Set-Content -Encoding UTF8 (Join-Path $reportDir 'source_inventory.txt')
$suspicious | Sort-Object -Unique | Set-Content -Encoding UTF8 (Join-Path $reportDir 'suspicious_sources.txt')
if ($inventory.Count -gt 500) { OK "full source inventory count=$($inventory.Count)" } else { WARN "source inventory count low=$($inventory.Count)" }
if ($suspicious.Count -eq 0) { OK 'no suspicious broad source pattern' } else { WARN "suspicious source patterns remain count=$($suspicious.Count), see suspicious_sources.txt" }

$report = New-Object System.Collections.Generic.List[string]
$report.Add('NOVA TOTAL LIFTOFF ALL SYSTEMS VERIFY') | Out-Null
$report.Add("Project: $ProjectRoot") | Out-Null
$report.Add("OK=$ok WARN=$($warn.Count) FAIL=$($fail.Count)") | Out-Null
$report.Add('') | Out-Null
foreach($w in $warn){ $report.Add("[WARN] $w") | Out-Null }
foreach($f in $fail){ $report.Add("[FAIL] $f") | Out-Null }
$report | Set-Content -Encoding UTF8 (Join-Path $reportDir 'NOVA_TOTAL_LIFTOFF_ALL_SYSTEMS_VERIFY_REPORT.txt')
if ($fail.Count -eq 0) {
  Write-Host "NOVA_TOTAL_LIFTOFF_ALL_SYSTEMS_VERIFY_OK OK=$ok WARN=$($warn.Count) FAIL=0"
  Write-Host "Report: $reportDir\NOVA_TOTAL_LIFTOFF_ALL_SYSTEMS_VERIFY_REPORT.txt"
  exit 0
}
Write-Host "NOVA_TOTAL_LIFTOFF_ALL_SYSTEMS_VERIFY_FAIL OK=$ok WARN=$($warn.Count) FAIL=$($fail.Count)"
Write-Host "Report: $reportDir\NOVA_TOTAL_LIFTOFF_ALL_SYSTEMS_VERIFY_REPORT.txt"
exit 1
