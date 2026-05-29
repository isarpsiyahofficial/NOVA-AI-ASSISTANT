# GEMMA8615 stale Qwen/cache cleanup
# Run from C:\Projects\nova after applying the patch.
# This does NOT remove Gemma .litertlm, Sherpa ASR/TTS, or voice engines.

$ErrorActionPreference = "SilentlyContinue"

$paths = @(
  ".gradle",
  "build",
  "android\.gradle",
  "android\build",
  "android\app\build",
  "android\app\src\main\assets\qwen.gguf",
  "android\app\src\main\assets\model.gguf"
)

foreach ($p in $paths) {
  if (Test-Path $p) {
    Write-Host "Removing $p"
    Remove-Item -LiteralPath $p -Recurse -Force
  }
}

$assetRoot = "android\app\src\main\assets"
if (Test-Path $assetRoot) {
  Get-ChildItem -Path $assetRoot -Recurse -Force -File -Include "qwen.gguf","model.gguf","*.gguf" | ForEach-Object {
    Write-Host "Removing stale GGUF asset $($_.FullName)"
    Remove-Item -LiteralPath $_.FullName -Force
  }
}

Write-Host "GEMMA8615 cleanup complete. Gemma .litertlm and Sherpa assets were preserved."
