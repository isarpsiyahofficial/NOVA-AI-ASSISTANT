$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$errors = @()
$ModelPath = "android\app\src\main\assets\models\llm\gemma-4-E2B-it.litertlm"
$OldModelPath = "android\app\src\main\assets\models\llm\gemma-3n-E2B-it-int4.litertlm"
$AarPath = "third_party\litertlm_android\litertlm-android-0.11.0-rc1.aar"

if (!(Test-Path $ModelPath)) { $errors += "Missing Gemma 4 model: $ModelPath" }
if (Test-Path $OldModelPath) { $errors += "Old Gemma 3n model still exists in assets: $OldModelPath" }
if (!(Test-Path $AarPath)) { $errors += "Missing local LiteRT-LM AAR: $AarPath" }

$GradleText = Get-Content "android\app\build.gradle.kts" -Raw
if ($GradleText -match "latest\.release") { $errors += "build.gradle.kts still contains latest.release" }
if ($GradleText -match "com\.google\.ai\.edge\.litertlm:litertlm-android") { $errors += "build.gradle.kts still contains Maven LiteRT-LM dependency" }
if ($GradleText -notmatch "litertlm-android-0\.11\.0-rc1\.aar") { $errors += "build.gradle.kts is not wired to local LiteRT-LM AAR" }

$Refs = Select-String -Path "android\app\src\main\kotlin\**\*.kt","lib\**\*.dart" -Pattern "gemma-3n-E2B-it-int4|gemma-3n-E2B-it" -ErrorAction SilentlyContinue
if ($Refs) {
  Write-Host "LEGACY_MODEL_REFERENCES_FOUND_FOR_PURGE_OR_REVIEW"
  $Refs | ForEach-Object { Write-Host "$($_.Path):$($_.LineNumber):$($_.Line.Trim())" }
}

if ($errors.Count -gt 0) {
  Write-Host "NOVA_GEMMA4_PATCH_VERIFY_FAIL"
  $errors | ForEach-Object { Write-Host "- $_" }
  exit 1
}

Write-Host "NOVA_GEMMA4_PATCH_VERIFY_OK"
Write-Host "Gemma 4 asset, local LiteRT-LM AAR reference, and Maven latest removal are aligned."
