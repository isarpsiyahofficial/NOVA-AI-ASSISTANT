@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0verify_nova_total_liftoff_all_systems.ps1" -ProjectRoot "%cd%"
exit /b %ERRORLEVEL%

