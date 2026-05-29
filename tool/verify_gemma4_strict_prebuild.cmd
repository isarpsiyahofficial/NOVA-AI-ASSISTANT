@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0verify_gemma4_strict_prebuild.ps1" -ProjectRoot "%CD%"
exit /b %ERRORLEVEL%
