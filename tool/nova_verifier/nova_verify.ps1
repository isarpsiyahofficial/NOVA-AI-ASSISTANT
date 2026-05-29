
param(
  [string]$Package = "com.example.nova",
  [string]$Activity = "com.example.nova/.MainActivity",
  [int]$DurationSec = 180,
  [switch]$Bugreport,
  [switch]$NoLaunch
)

$ErrorActionPreference = "Continue"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Out = Join-Path $Root "nova_verify_out"
$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$Run = Join-Path $Out "run_$Stamp"
New-Item -ItemType Directory -Force -Path $Run | Out-Null

$FullLog = Join-Path $Run "01_live_logcat_all_buffers.txt"
$Timeline = Join-Path $Run "02_timeline.txt"
$ActivityTop = Join-Path $Run "03_activity_top_final.txt"
$Services = Join-Path $Run "04_services_package_final.txt"
$AppOps = Join-Path $Run "05_appops_final.txt"
$PackageDump = Join-Path $Run "06_package_final.txt"
$MemInfo = Join-Path $Run "07_meminfo_final.txt"
$DropboxCrash = Join-Path $Run "08_dropbox_app_crash.txt"
$DropboxNative = Join-Path $Run "09_dropbox_native_crash.txt"
$DropboxTombstone = Join-Path $Run "10_dropbox_tombstone.txt"
$ModelFilter = Join-Path $Run "11_model_filtered.txt"
$ErrorFilter = Join-Path $Run "12_error_filtered.txt"
$Result = Join-Path $Run "NOVA_VERIFY_RESULT.txt"
$ResultJson = Join-Path $Run "NOVA_VERIFY_RESULT.json"

function Write-Step($msg) {
  $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')  $msg"
  Write-Host $line
  Add-Content -Path $Timeline -Value $line
}

function Run-AdbText($Args, $Path) {
  try {
    & adb @Args 2>&1 | Out-File -FilePath $Path -Encoding utf8
  } catch {
    "ADB_COMMAND_EXCEPTION: $($_.Exception.Message)" | Out-File -FilePath $Path -Encoding utf8
  }
}

function Read-TextSafe($Path) {
  if (Test-Path $Path) { return [System.IO.File]::ReadAllText($Path) }
  return ""
}

function Has($Text, $Pattern) {
  return [regex]::IsMatch($Text, $Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

Write-Step "NOVA VERIFY START"
Write-Step "Package=$Package Activity=$Activity DurationSec=$DurationSec NoLaunch=$NoLaunch Bugreport=$Bugreport"

# Check adb.
$devices = (& adb devices 2>&1) -join "`n"
$devices | Out-File -FilePath (Join-Path $Run "00_adb_devices.txt") -Encoding utf8
if (-not (Has $devices "`tdevice")) {
  "FAIL: ADB device not found.`n$devices" | Out-File -FilePath $Result -Encoding utf8
  Write-Host "FAIL: ADB device not found."
  exit 2
}

Write-Step "Resize and clear logcat"
& adb logcat -G 256M 2>&1 | Out-File -FilePath (Join-Path $Run "00_logcat_resize.txt") -Encoding utf8
& adb logcat -c 2>&1 | Out-File -FilePath (Join-Path $Run "00_logcat_clear.txt") -Encoding utf8

Write-Step "Force-stop package"
& adb shell am force-stop $Package 2>&1 | Out-File -FilePath (Join-Path $Run "00_force_stop.txt") -Encoding utf8

Write-Step "Capture before-state"
Run-AdbText @("shell","cmd","appops","get",$Package) (Join-Path $Run "00_before_appops.txt")
Run-AdbText @("shell","dumpsys","package",$Package) (Join-Path $Run "00_before_package.txt")
Run-AdbText @("shell","ps","-A") (Join-Path $Run "00_before_ps_all.txt")

Write-Step "Start live logcat"
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "adb"
$psi.Arguments = "logcat -v threadtime -b all"
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.CreateNoWindow = $true

$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $psi
$null = $proc.Start()

$stdoutTask = $proc.StandardOutput.ReadToEndAsync()
$stderrTask = $proc.StandardError.ReadToEndAsync()

Start-Sleep -Seconds 2

if (-not $NoLaunch) {
  Write-Step "Launch exact MainActivity via adb shell am start"
  & adb shell am start -W -n $Activity 2>&1 | Out-File -FilePath (Join-Path $Run "00_launch_result.txt") -Encoding utf8
} else {
  Write-Step "NoLaunch enabled: open Nova manually now"
}

Write-Step "Runtime observation started"
$deadline = (Get-Date).AddSeconds($DurationSec)
$iteration = 0
while ((Get-Date) -lt $deadline) {
  $iteration++
  $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
  Add-Content $Timeline "`n===== SAMPLE $iteration $now ====="
  (& adb shell pidof $Package 2>&1) | Add-Content $Timeline
  (& adb shell dumpsys activity top 2>&1 | Select-String -Pattern "ACTIVITY|mResumed|topResumedActivity|$Package" -SimpleMatch:$false) | ForEach-Object { Add-Content $Timeline $_.Line }
  (& adb shell cmd appops get $Package 2>&1 | Select-String -Pattern "RECORD_AUDIO|START_FOREGROUND|ACCESS_RESTRICTED_SETTINGS|SYSTEM_ALERT_WINDOW|BIND_ACCESSIBILITY_SERVICE" -SimpleMatch:$false) | ForEach-Object { Add-Content $Timeline $_.Line }

  # Early stop only if hard success is visible in logcat dump snapshot.
  $snapshotPath = Join-Path $Run "tmp_snapshot.txt"
  & adb logcat -d -v threadtime -b all 2>&1 | Out-File -FilePath $snapshotPath -Encoding utf8
  $snap = Read-TextSafe $snapshotPath
  if ((Has $snap "NOVA_SINGLE_BRAIN_DECISION.*allowed=true.*modelUsed=true") -and
      (Has $snap "NOVA_RAW_MODEL_OUTPUT") -and
      (-not (Has $snap "local_model_failed_strict|AI_REQUIRED_BLOCK|NOVA_SETUP_TTS_BLOCKED_EMPTY_SINGLE_BRAIN"))) {
    Write-Step "Early success markers found; waiting 5 more seconds for TTS/UI markers"
    Start-Sleep -Seconds 5
    break
  }

  Start-Sleep -Seconds 5
}

Write-Step "Stop live logcat"
try {
  if (-not $proc.HasExited) {
    $proc.Kill()
  }
} catch {}
Start-Sleep -Seconds 1

try {
  $liveOut = $stdoutTask.Result
  $liveErr = $stderrTask.Result
  [System.IO.File]::WriteAllText($FullLog, $liveOut, [System.Text.Encoding]::UTF8)
  if ($liveErr.Trim().Length -gt 0) {
    [System.IO.File]::AppendAllText($FullLog, "`n===== LOGCAT STDERR =====`n$liveErr", [System.Text.Encoding]::UTF8)
  }
} catch {
  "LOGCAT_CAPTURE_EXCEPTION: $($_.Exception.Message)" | Out-File -FilePath $FullLog -Encoding utf8
}

Write-Step "Capture final dumps"
Run-AdbText @("logcat","-d","-v","threadtime","-b","all") (Join-Path $Run "01b_dump_logcat_all_buffers.txt")
Run-AdbText @("shell","dumpsys","activity","top") $ActivityTop
Run-AdbText @("shell","dumpsys","activity","services",$Package) $Services
Run-AdbText @("shell","cmd","appops","get",$Package) $AppOps
Run-AdbText @("shell","dumpsys","package",$Package) $PackageDump
Run-AdbText @("shell","dumpsys","meminfo",$Package) $MemInfo
Run-AdbText @("shell","dumpsys","dropbox","--print","data_app_crash") $DropboxCrash
Run-AdbText @("shell","dumpsys","dropbox","--print","data_app_native_crash") $DropboxNative
Run-AdbText @("shell","dumpsys","dropbox","--print","SYSTEM_TOMBSTONE") $DropboxTombstone
Run-AdbText @("shell","dumpsys","audio") (Join-Path $Run "13_audio.txt")
Run-AdbText @("shell","dumpsys","media.audio_flinger") (Join-Path $Run "14_audio_flinger.txt")
Run-AdbText @("shell","dumpsys","media.audio_policy") (Join-Path $Run "15_audio_policy.txt")
Run-AdbText @("shell","run-as",$Package,"find","files","-maxdepth","4","-type","f","-ls") (Join-Path $Run "16_run_as_files_find.txt")

if ($Bugreport) {
  Write-Step "Capture bugreport"
  & adb bugreport (Join-Path $Run "bugreport") 2>&1 | Out-File -FilePath (Join-Path $Run "17_bugreport_command.txt") -Encoding utf8
}

Write-Step "Create filters"
$all = (Read-TextSafe $FullLog) + "`n" + (Read-TextSafe (Join-Path $Run "01b_dump_logcat_all_buffers.txt"))
$modelPattern = "Nova|NOVA|SingleBrain|BrainDecision|LocalModel|ModelBridge|Gemma|Qwen|llama|LiteRT|litert|native|generate|inference|modelPath|model_path|raw_model_output|RAW_MODEL_OUTPUT|chars|token|timeout|exception|AI_REQUIRED_BLOCK|local_model_failed_strict|modelUsed|requireModel|opening_micro_inference|setup|gate|ready|prepared|prepare|brain_kernel|verifyLocalBrainKernelForBoot|JvCore|identity|askAI|runLiteRtGenerateWithTimeout|NATIVE_GENERATE|NOVA_NATIVE_GENERATE_CALLED|NOVA_MODEL|NOVA_BOOT|NOVA_RAW_MODEL_OUTPUT|TTS|Speech|speak"
$errorPattern = "error|exception|fatal|failed|fail|timeout|denied|blocked|SecurityException|IllegalStateException|MissingPluginException|native JNI|SIGSEGV|SIGABRT|OutOfMemory|lowmemory|lmkd|killed|tombstone|ANR|crash|local_model_failed_strict|AI_REQUIRED_BLOCK|NOVA_SETUP_TTS_BLOCKED_EMPTY_SINGLE_BRAIN"

[regex]::Matches($all, "^.*($modelPattern).*$", "IgnoreCase,Multiline") | ForEach-Object { $_.Value } | Out-File -FilePath $ModelFilter -Encoding utf8
[regex]::Matches($all, "^.*($errorPattern).*$", "IgnoreCase,Multiline") | ForEach-Object { $_.Value } | Out-File -FilePath $ErrorFilter -Encoding utf8

Write-Step "Analyze"
$text = $all
$activityText = Read-TextSafe $ActivityTop
$servicesText = Read-TextSafe $Services
$appopsText = Read-TextSafe $AppOps
$dropNativeText = Read-TextSafe $DropboxNative
$tombText = Read-TextSafe $DropboxTombstone
$memText = Read-TextSafe $MemInfo

$checks = [ordered]@{}

$checks["app_main_activity_visible"] = Has $activityText "$Package/\.MainActivity|$Package/.MainActivity|mResumed=true"
$checks["record_audio_allowed"] = Has $appopsText "RECORD_AUDIO:\s+allow|RECORD_AUDIO:\s+foreground"
$checks["foreground_allowed"] = Has $appopsText "START_FOREGROUND:\s+allow"
$checks["native_generate_called"] = Has $text "NOVA_NATIVE_GENERATE_CALLED|NATIVE_GENERATE_CALLED|runLiteRtGenerateWithTimeout|ModelBridge.*generate"
$checks["raw_model_output_seen"] = Has $text "NOVA_RAW_MODEL_OUTPUT|RAW_MODEL_OUTPUT|raw_model_output"
$checks["single_brain_success"] = Has $text "NOVA_SINGLE_BRAIN_DECISION.*allowed=true.*modelUsed=true|BrainDecision.*modelUsed=true"
$checks["tts_not_empty"] = -not (Has $text "NOVA_SETUP_TTS_BLOCKED_EMPTY_SINGLE_BRAIN|textChars=0")
$checks["no_strict_local_model_fail"] = -not (Has $text "local_model_failed_strict|AI_REQUIRED_BLOCK")
$checks["no_internal_format_leak"] = -not (Has $text "SINGLE_BRAIN_FAST_DECISION|CoreProfileHash|NovaCoreProfile|Runtime KatmanÄ±|Runtime Katmani")
$checks["no_timeout"] = -not (Has $text "TimeoutException|timeout.*setupMicro|NOVA_.*TIMEOUT")
$checks["no_native_crash"] = (-not (Has $dropNativeText "Process: $Package|$Package")) -and (-not (Has $tombText "Process: $Package|$Package"))
$checks["no_oom_or_lmk_kill"] = -not (Has $text "OutOfMemory|lowmemorykiller|lmkd.*$Package|killing.*$Package|Process $Package.*has died")
$checks["asr_service_not_crashed"] = -not (Has $text "ForegroundServiceDidNotStartInTimeException.*NovaAsrForegroundService|NovaAsrForegroundService.*ForegroundServiceDidNotStartInTimeException")

# Confidence grade.
$hardPass = $checks["native_generate_called"] -and
            $checks["raw_model_output_seen"] -and
            $checks["single_brain_success"] -and
            $checks["no_strict_local_model_fail"] -and
            $checks["no_internal_format_leak"] -and
            $checks["no_timeout"] -and
            $checks["no_native_crash"] -and
            $checks["no_oom_or_lmk_kill"]

$softBlockers = @()
foreach ($key in $checks.Keys) {
  if (-not $checks[$key]) { $softBlockers += $key }
}

$status = if ($hardPass) { "PASS" } else { "FAIL" }

$summary = @()
$summary += "===== NOVA VERIFY RESULT ====="
$summary += "STATUS=$status"
$summary += "TIME=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')"
$summary += "PACKAGE=$Package"
$summary += "ACTIVITY=$Activity"
$summary += ""
$summary += "Criteria:"
foreach ($key in $checks.Keys) {
  $summary += ("{0}={1}" -f $key, $checks[$key])
}
$summary += ""
if ($hardPass) {
  $summary += "Nova passed hard model-brain criteria: native generate, raw output, modelUsed=true, no strict fail, no internal leak, no timeout/native crash."
} else {
  $summary += "Nova did NOT pass hard model-brain criteria."
  $summary += "Blockers:"
  foreach ($b in $softBlockers) { $summary += "- $b" }
}
$summary += ""
$summary += "Important files:"
$summary += "01_live_logcat_all_buffers.txt"
$summary += "11_model_filtered.txt"
$summary += "12_error_filtered.txt"
$summary += "NOVA_VERIFY_RESULT.json"

$summary -join "`n" | Out-File -FilePath $Result -Encoding utf8

$jsonObj = [ordered]@{
  status = $status
  package = $Package
  activity = $Activity
  durationSec = $DurationSec
  checks = $checks
  blockers = $softBlockers
}
$jsonObj | ConvertTo-Json -Depth 5 | Out-File -FilePath $ResultJson -Encoding utf8

Write-Host ""
Write-Host "===== NOVA VERIFY RESULT ====="
Get-Content $Result | Write-Host

Write-Step "Compress reports"
$ZipPath = Join-Path $Out "nova_verify_latest.zip"
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
Compress-Archive -Path (Join-Path $Run "*") -DestinationPath $ZipPath -Force

Write-Step "NOVA VERIFY END zip=$ZipPath"

if ($hardPass) { exit 0 } else { exit 2 }
