@echo off
setlocal
cd /d "%~dp0"
python tool\nova_v34_static_runtime_gate.py
if errorlevel 1 (
  echo NOVA_V34_STATIC_RUNTIME_GATE failed.
  exit /b 1
)
echo NOVA_V34_STATIC_RUNTIME_GATE passed.
