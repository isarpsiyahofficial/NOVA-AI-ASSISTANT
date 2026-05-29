param(
  [string]$ProjectRoot = (Get-Location).Path
)
$ErrorActionPreference = 'Stop'
$ok = 0
$warn = 0
$fail = 0
$lines = New-Object System.Collections.Generic.List[string]
function Add-Result([string]$status, [string]$name, [string]$detail = '') {
  if ($status -eq 'OK') { $script:ok++ }
  elseif ($status -eq 'WARN') { $script:warn++ }
  else { $script:fail++ }
  $line = "[$status] $name"
  if ($detail -ne '') { $line += " :: $detail" }
  $script:lines.Add($line) | Out-Null
}
function Rel([string]$p) {
  try { return (Resolve-Path $p).Path.Substring((Resolve-Path $ProjectRoot).Path.Length).TrimStart('\','/') } catch { return $p }
}
function ReadText([string]$path) {
  return [System.IO.File]::ReadAllText((Join-Path $ProjectRoot $path))
}
function SourceFiles() {
  $items = New-Object System.Collections.Generic.List[string]
  foreach ($dir in @('android\app\src\main\kotlin','lib')) {
    $full = Join-Path $ProjectRoot $dir
    if (Test-Path $full) {
      Get-ChildItem $full -Recurse -File | Where-Object {
        $_.Extension -in @('.kt','.dart','.kts') -and $_.FullName -notmatch '\\.gradle\\|\\build\\|\\audit_'
      } | ForEach-Object { $items.Add($_.FullName) | Out-Null }
    }
  }
  foreach ($f in @('android\app\build.gradle.kts','android\build.gradle.kts','android\settings.gradle.kts','pubspec.yaml')) {
    $full = Join-Path $ProjectRoot $f
    if (Test-Path $full) { $items.Add($full) | Out-Null }
  }
  return $items
}
function GrepSource([string[]]$patterns) {
  $hits = New-Object System.Collections.Generic.List[string]
  foreach ($file in SourceFiles) {
    $rel = Rel $file
    $content = [System.IO.File]::ReadAllText($file)
    foreach ($pat in $patterns) {
      if ($content -match $pat) { $hits.Add("$rel => $pat") | Out-Null }
    }
  }
  return $hits
}
function ExtractFunctionBody([string]$text, [string]$fnName) {
  $idx = $text.IndexOf($fnName)
  if ($idx -lt 0) { return '' }
  $brace = $text.IndexOf('{', $idx)
  if ($brace -lt 0) { return '' }
  $depth = 0
  for ($i = $brace; $i -lt $text.Length; $i++) {
    $ch = $text[$i]
    if ($ch -eq '{') { $depth++ }
    elseif ($ch -eq '}') {
      $depth--
      if ($depth -eq 0) { return $text.Substring($idx, $i - $idx + 1) }
    }
  }
  return ''
}
$reportDir = Join-Path $ProjectRoot 'audit_gemma4_strict_prebuild'
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
Add-Result 'OK' 'Audit started' $ProjectRoot
foreach ($f in @('pubspec.yaml','android\app\build.gradle.kts','android\app\src\main\kotlin\com\example\nova\MainActivity.kt','android\app\src\main\kotlin\com\example\nova\ModelBridge.kt')) {
  if (Test-Path (Join-Path $ProjectRoot $f)) { Add-Result 'OK' "Required file exists" $f } else { Add-Result 'FAIL' "Required file missing" $f }
}
$assetDir = Join-Path $ProjectRoot 'android\app\src\main\assets\models\llm'
$gemma4 = Join-Path $assetDir 'gemma-4-E2B-it.litertlm'
if (Test-Path $gemma4) {
  $size = (Get-Item $gemma4).Length
  if ($size -eq 2583085056) { Add-Result 'OK' 'Gemma 4 E2B asset exact expected size' "$size bytes" }
  elseif ($size -gt 2000000000 -and $size -lt 3000000000) { Add-Result 'WARN' 'Gemma 4 asset exists but size differs from expected' "$size bytes" }
  else { Add-Result 'FAIL' 'Gemma 4 asset size implausible' "$size bytes" }
} else { Add-Result 'FAIL' 'Gemma 4 E2B asset missing' 'android\app\src\main\assets\models\llm\gemma-4-E2B-it.litertlm' }
if (Test-Path $assetDir) {
  $models = Get-ChildItem $assetDir -File -Filter '*.litertlm'
  if ($models.Count -eq 1 -and $models[0].Name -eq 'gemma-4-E2B-it.litertlm') { Add-Result 'OK' 'Only Gemma 4 .litertlm in asset model directory' $models[0].Name }
  else { Add-Result 'FAIL' 'Unexpected .litertlm asset model set' (($models | ForEach-Object { $_.Name }) -join ', ') }
} else { Add-Result 'FAIL' 'Asset model directory missing' $assetDir }
$bakFiles = Get-ChildItem (Join-Path $ProjectRoot 'android\app\src\main\kotlin') -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\.bak$|gemma3' }
if ($bakFiles.Count -eq 0) { Add-Result 'OK' 'No Kotlin backup/gemma3 cleanup files remain' '' } else { Add-Result 'FAIL' 'Backup/gemma3 cleanup files remain' (($bakFiles | ForEach-Object { Rel $_.FullName }) -join '; ') }
$badRefs = GrepSource @('gemma-3','gemma-3n','gemma\.litertlm','model\.litertlm','qwen','gguf')
if ($badRefs.Count -eq 0) { Add-Result 'OK' 'No legacy model/source engine references in active Kotlin/Dart/Gradle sources' '' } else { Add-Result 'FAIL' 'Legacy model/source engine references remain' ($badRefs -join '; ') }
$main = ReadText 'android\app\src\main\kotlin\com\example\nova\MainActivity.kt'
if ($main -match 'PRIMARY_LITERTLM_MODEL_FILE_NAME\s*=\s*"gemma-4-E2B-it\.litertlm"') { Add-Result 'OK' 'MainActivity primary model file is Gemma 4' '' } else { Add-Result 'FAIL' 'MainActivity primary model file is not Gemma 4' '' }
if ($main -match 'PRIMARY_LITERTLM_MODEL_ASSET_PATH\s*=\s*"models/llm/gemma-4-E2B-it\.litertlm"') { Add-Result 'OK' 'MainActivity primary asset path is Gemma 4' '' } else { Add-Result 'FAIL' 'MainActivity primary asset path is not Gemma 4' '' }
if ($main -match 'candidate\.name\.endsWith\("\.litertlm", ignoreCase = true\)' -and $main -match 'candidate\.name != PRIMARY_LITERTLM_MODEL_FILE_NAME') { Add-Result 'OK' 'MainActivity purges non-primary .litertlm files without legacy names' '' } else { Add-Result 'FAIL' 'MainActivity non-primary .litertlm purge guard missing' '' }
$gradle = ReadText 'android\app\build.gradle.kts'
if ($gradle -notmatch 'latest\.release') { Add-Result 'OK' 'Gradle does not use latest.release' '' } else { Add-Result 'FAIL' 'Gradle still uses latest.release' '' }
if ($gradle -notmatch 'com\.google\.ai\.edge\.litertlm:litertlm-android') { Add-Result 'OK' 'Gradle does not use remote LiteRT-LM Maven dependency' '' } else { Add-Result 'FAIL' 'Gradle still uses remote LiteRT-LM Maven dependency' '' }
if ($gradle -match 'implementation\(files\("\.\./\.\./third_party/litertlm_android/litertlm-android-0\.11\.0-rc1\.aar"\)\)') { Add-Result 'OK' 'Gradle references local LiteRT-LM AAR' '' } else { Add-Result 'FAIL' 'Gradle local LiteRT-LM AAR reference missing' '' }
$aar = Join-Path $ProjectRoot 'third_party\litertlm_android\litertlm-android-0.11.0-rc1.aar'
if (Test-Path $aar) {
  $aarSize = (Get-Item $aar).Length
  if ($aarSize -gt 10000000) { Add-Result 'OK' 'Local LiteRT-LM AAR exists and size plausible' "$aarSize bytes" } else { Add-Result 'FAIL' 'Local LiteRT-LM AAR size too small' "$aarSize bytes" }
  $unpack = Join-Path $reportDir 'aar_unpacked'
  if (Test-Path $unpack) { Remove-Item -Recurse -Force $unpack }
  New-Item -ItemType Directory -Force -Path $unpack | Out-Null
  $zip = Join-Path $reportDir 'litertlm-android-0.11.0-rc1.zip'
  Copy-Item -Force $aar $zip
  try {
    Expand-Archive -Path $zip -DestinationPath $unpack -Force
    if (Test-Path (Join-Path $unpack 'classes.jar')) { Add-Result 'OK' 'AAR contains classes.jar' '' } else { Add-Result 'FAIL' 'AAR missing classes.jar' '' }
    $jni = Get-ChildItem $unpack -Recurse -File -Filter 'liblitertlm_jni.so' -ErrorAction SilentlyContinue
    if ($jni.Count -gt 0) { Add-Result 'OK' 'AAR contains liblitertlm_jni.so' (($jni | ForEach-Object { Rel $_.FullName }) -join '; ') } else { Add-Result 'FAIL' 'AAR missing liblitertlm_jni.so' '' }
    $arm = Get-ChildItem (Join-Path $unpack 'jni\arm64-v8a') -File -Filter '*.so' -ErrorAction SilentlyContinue
    if ($arm.Count -gt 0) { Add-Result 'OK' 'AAR contains arm64-v8a native libs' (($arm | ForEach-Object { $_.Name }) -join ', ') } else { Add-Result 'FAIL' 'AAR missing arm64-v8a native libs' '' }
  } catch { Add-Result 'FAIL' 'AAR unpack failed' $_.Exception.Message }
} else { Add-Result 'FAIL' 'Local LiteRT-LM AAR missing' 'third_party\litertlm_android\litertlm-android-0.11.0-rc1.aar' }
$modelBridge = ReadText 'android\app\src\main\kotlin\com\example\nova\ModelBridge.kt'
$cancel = ExtractFunctionBody $modelBridge 'fun cancelGeneration'
if ($cancel -eq '') { Add-Result 'FAIL' 'cancelGeneration function missing' '' }
else {
  if ($cancel -notmatch '\.close\(') { Add-Result 'OK' 'cancelGeneration does not close engine' '' } else { Add-Result 'FAIL' 'cancelGeneration closes engine' $cancel }
  if ($cancel -notmatch 'gemmaEngine\s*=\s*null') { Add-Result 'OK' 'cancelGeneration does not null gemmaEngine' '' } else { Add-Result 'FAIL' 'cancelGeneration nulls gemmaEngine' $cancel }
  if ($cancel -notmatch 'loadedGemmaPath\s*=\s*null') { Add-Result 'OK' 'cancelGeneration does not clear loadedGemmaPath' '' } else { Add-Result 'FAIL' 'cancelGeneration clears loadedGemmaPath' $cancel }
}
foreach ($marker in @('engineInitMs','warmReuse','decodeMs','totalMs','modelBytes','NOVA_LITERT_GENERATE_START','NOVA_LITERT_GENERATE_DONE')) {
  if ($modelBridge.Contains($marker)) { Add-Result 'OK' "ModelBridge metric marker present" $marker } else { Add-Result 'FAIL' "ModelBridge metric marker missing" $marker }
}
$storage = ReadText 'lib\services\storage\nova_storage_cleanup_service.dart'
if ($storage -match 'non_primary_litertlm_files' -and $storage -match '_nonPrimaryLitertlmBytes') { Add-Result 'OK' 'Storage inspection tracks non-primary .litertlm generically' '' } else { Add-Result 'FAIL' 'Storage inspection generic non-primary .litertlm tracking missing' '' }
$aiServicePath = Join-Path $ProjectRoot 'lib\core\ai\nova_ai_service.dart'
if (Test-Path $aiServicePath) {
  $ai = [System.IO.File]::ReadAllText($aiServicePath)
  if ($ai -match 'local_model_failed_strict' -and $ai -match 'recoverySuppressed') { Add-Result 'OK' 'AI service suppresses success fallback on local model failure' '' } else { Add-Result 'WARN' 'AI service strict local failure markers not found' '' }
}
$lines.Insert(0, "NOVA GEMMA4 STRICT PREBUILD AUDIT`nProject: $ProjectRoot`nOK=$ok WARN=$warn FAIL=$fail`n")
$report = Join-Path $reportDir 'NOVA_GEMMA4_STRICT_PREBUILD_AUDIT_REPORT.txt'
[System.IO.File]::WriteAllLines($report, $lines, [System.Text.UTF8Encoding]::new($false))
foreach ($l in $lines) { Write-Host $l }
if ($fail -gt 0) {
  Write-Host 'NOVA_GEMMA4_STRICT_PREBUILD_AUDIT_FAIL'
  Write-Host "Report: $report"
  exit 1
}
if ($warn -gt 0) { Write-Host 'NOVA_GEMMA4_STRICT_PREBUILD_AUDIT_WARN' } else { Write-Host 'NOVA_GEMMA4_STRICT_PREBUILD_AUDIT_OK' }
Write-Host "Report: $report"
exit 0
