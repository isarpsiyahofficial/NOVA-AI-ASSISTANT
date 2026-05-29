@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0nova_verify.ps1" %*
set EXITCODE=%ERRORLEVEL%
echo.
echo Nova verifier finished with exit code %EXITCODE%.
echo Reports are under: %~dp0nova_verify_out
exit /b %EXITCODE%
