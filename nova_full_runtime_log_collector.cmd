@echo off
setlocal EnableExtensions

REM Nova full runtime log collector
REM Usage:
REM   nova_full_runtime_log_collector.cmd
REM   nova_full_runtime_log_collector.cmd com.example.nova
REM Stop with ENTER inside this window.

set "PKG=com.example.nova"
if not "%~1"=="" set "PKG=%~1"

where adb >nul 2>nul
if errorlevel 1 (
  echo ADB bulunamadi. Android platform-tools PATH icinde olmali.
  pause
  exit /b 1
)

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TS=%%i"

set "OUTDIR=%CD%\nova_logs"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

set "LOG=%OUTDIR%\nova_full_runtime_%TS%.txt"
set "TEMPLOG=%OUTDIR%\nova_logcat_stream_%TS%.tmp"

echo ============================================================ > "%LOG%"
echo NOVA FULL RUNTIME LOG >> "%LOG%"
echo Package: %PKG% >> "%LOG%"
echo Started: %DATE% %TIME% >> "%LOG%"
echo Output: %LOG% >> "%LOG%"
echo ============================================================ >> "%LOG%"
echo. >> "%LOG%"

echo [1/8] ADB server/device kontrol ediliyor...
adb start-server >> "%LOG%" 2>&1
echo. >> "%LOG%"
echo ===== ADB DEVICES ===== >> "%LOG%"
adb devices -l >> "%LOG%" 2>&1

echo. >> "%LOG%"
echo ===== DEVICE INFO ===== >> "%LOG%"
adb shell getprop ro.product.manufacturer >> "%LOG%" 2>&1
adb shell getprop ro.product.brand >> "%LOG%" 2>&1
adb shell getprop ro.product.model >> "%LOG%" 2>&1
adb shell getprop ro.build.version.release >> "%LOG%" 2>&1
adb shell getprop ro.build.version.sdk >> "%LOG%" 2>&1
adb shell getprop ro.hardware >> "%LOG%" 2>&1
adb shell getprop ro.board.platform >> "%LOG%" 2>&1

echo. >> "%LOG%"
echo ===== PACKAGE / PERMISSION SNAPSHOT BEFORE START ===== >> "%LOG%"
adb shell dumpsys package %PKG% >> "%LOG%" 2>&1
echo. >> "%LOG%"
echo ===== APP OPS BEFORE START ===== >> "%LOG%"
adb shell cmd appops get %PKG% >> "%LOG%" 2>&1

echo [2/8] Eski logcat temizleniyor...
adb logcat -c >> "%LOG%" 2>&1

echo. >> "%LOG%"
echo ===== FORCE STOP + FRESH LAUNCH ===== >> "%LOG%"
adb shell am force-stop %PKG% >> "%LOG%" 2>&1

echo [3/8] Logcat akisi baslatiliyor...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p = Start-Process -FilePath adb -ArgumentList @('logcat','-v','threadtime') -RedirectStandardOutput '%TEMPLOG%' -RedirectStandardError '%OUTDIR%\nova_logcat_error_%TS%.tmp' -PassThru; Set-Content -Path '%OUTDIR%\nova_logcat_pid_%TS%.txt' -Value $p.Id"

echo [4/8] Nova aciliyor...
adb shell monkey -p %PKG% -c android.intent.category.LAUNCHER 1 >> "%LOG%" 2>&1

echo.
echo ============================================================
echo LOG ALMA BASLADI
echo Nova'i telefonda normal sekilde kullan:
echo - Ilk acilis / setup
echo - Mikrofon / ASR
echo - Model cevap denemesi
echo - TTS konusma
echo - Dashboard / companion / call ekranlari
echo.
echo Bitirmek icin bu pencerede ENTER'a bas.
echo Log dosyasi:
echo %LOG%
echo ============================================================
echo.

pause >nul

echo [5/8] Logcat durduruluyor...
for /f %%p in (%OUTDIR%\nova_logcat_pid_%TS%.txt) do (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Stop-Process -Id %%p -Force -ErrorAction SilentlyContinue } catch {}"
)

timeout /t 1 >nul

echo. >> "%LOG%"
echo ============================================================ >> "%LOG%"
echo ===== LIVE LOGCAT STREAM ===== >> "%LOG%"
echo ============================================================ >> "%LOG%"
type "%TEMPLOG%" >> "%LOG%" 2>&1

echo. >> "%LOG%"
echo ============================================================ >> "%LOG%"
echo ===== PACKAGE / RUNTIME SNAPSHOT AFTER TEST ===== >> "%LOG%"
echo ============================================================ >> "%LOG%"
adb shell pidof %PKG% >> "%LOG%" 2>&1
adb shell dumpsys activity activities >> "%LOG%" 2>&1
adb shell dumpsys activity services %PKG% >> "%LOG%" 2>&1
adb shell dumpsys meminfo %PKG% >> "%LOG%" 2>&1
adb shell dumpsys cpuinfo >> "%LOG%" 2>&1

echo. >> "%LOG%"
echo ============================================================ >> "%LOG%"
echo ===== AUDIO / MEDIA / POWER SNAPSHOT AFTER TEST ===== >> "%LOG%"
echo ============================================================ >> "%LOG%"
adb shell dumpsys audio >> "%LOG%" 2>&1
adb shell dumpsys media_session >> "%LOG%" 2>&1
adb shell dumpsys power >> "%LOG%" 2>&1
adb shell dumpsys deviceidle >> "%LOG%" 2>&1

echo. >> "%LOG%"
echo ============================================================ >> "%LOG%"
echo ===== APP OPS AFTER TEST ===== >> "%LOG%"
echo ============================================================ >> "%LOG%"
adb shell cmd appops get %PKG% >> "%LOG%" 2>&1

echo. >> "%LOG%"
echo ============================================================ >> "%LOG%"
echo Finished: %DATE% %TIME% >> "%LOG%"
echo ============================================================ >> "%LOG%"

del "%TEMPLOG%" >nul 2>nul
del "%OUTDIR%\nova_logcat_error_%TS%.tmp" >nul 2>nul
del "%OUTDIR%\nova_logcat_pid_%TS%.txt" >nul 2>nul

echo.
echo Bitti.
echo Tek log dosyasi:
echo %LOG%
echo.
pause
