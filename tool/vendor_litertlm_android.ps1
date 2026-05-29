$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Version = "0.11.0-rc1"
$TargetDir = Join-Path $ProjectRoot "third_party\litertlm_android"
$TargetAar = Join-Path $TargetDir "litertlm-android-$Version.aar"
$CacheRoot = Join-Path $env:USERPROFILE ".gradle\caches\modules-2\files-2.1\com.google.ai.edge.litertlm\litertlm-android\$Version"

New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

$SourceAar = Get-ChildItem -Path $CacheRoot -Filter "*.aar" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -eq $SourceAar) {
  Write-Host "LITERT_LOCAL_AAR_NOT_FOUND"
  Write-Host "Expected cache root: $CacheRoot"
  Write-Host "Run once while Maven access is available, or manually place litertlm-android-$Version.aar into: $TargetDir"
  exit 1
}

Copy-Item -Path $SourceAar.FullName -Destination $TargetAar -Force
$Size = (Get-Item $TargetAar).Length
Write-Host "LITERT_LOCAL_AAR_READY"
Write-Host "Source: $($SourceAar.FullName)"
Write-Host "Target: $TargetAar"
Write-Host "Bytes: $Size"
