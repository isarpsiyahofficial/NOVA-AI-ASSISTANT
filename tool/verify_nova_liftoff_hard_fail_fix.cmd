@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0verify_nova_liftoff_hard_fail_fix.ps1" -ProjectRoot "%cd%"
exit /b %ERRORLEVEL%

