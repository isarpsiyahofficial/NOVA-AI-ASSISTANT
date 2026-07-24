#!/usr/bin/env bash
set -euo pipefail

APK_PATH="${1:-build/app/outputs/flutter-apk/app-debug.apk}"
PACKAGE="com.example.nova"
RECEIVER="$PACKAGE/com.example.nova.testing.NovaDebugControlReceiver"
ACTION="com.example.nova.DEBUG_CALL_CONTROL"
OUT_DIR="${NOVA_TELECOM_E2E_OUT:-build/telecom-e2e}"
mkdir -p "$OUT_DIR"

adb wait-for-device
adb install -r -t "$APK_PATH" | tee "$OUT_DIR/install.log"

permissions=(
  android.permission.RECORD_AUDIO
  android.permission.POST_NOTIFICATIONS
  android.permission.READ_PHONE_STATE
  android.permission.READ_PHONE_NUMBERS
  android.permission.READ_CALL_LOG
  android.permission.WRITE_CALL_LOG
  android.permission.ANSWER_PHONE_CALLS
  android.permission.CALL_PHONE
  android.permission.READ_CONTACTS
  android.permission.WRITE_CONTACTS
  android.permission.MODIFY_AUDIO_SETTINGS
)
for permission in "${permissions[@]}"; do
  adb shell pm grant "$PACKAGE" "$permission" >/dev/null 2>&1 || true
done

adb shell cmd role add-role-holder --user 0 android.app.role.DIALER "$PACKAGE" \
  | tee "$OUT_DIR/dialer-role.log"
adb shell cmd role get-role-holders --user 0 android.app.role.DIALER \
  | tee -a "$OUT_DIR/dialer-role.log" \
  | grep -q "$PACKAGE"

adb shell am force-stop "$PACKAGE"
adb shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 \
  | tee "$OUT_DIR/launch.log"
sleep 4

broadcast_control() {
  local command="$1"
  local target="$OUT_DIR/control-${command}.log"
  adb shell am broadcast \
    -n "$RECEIVER" \
    -a "$ACTION" \
    --es command "$command" \
    | tee "$target"
}

control_required() {
  local command="$1"
  broadcast_control "$command"
  local target="$OUT_DIR/control-${command}.log"
  grep -q 'result=0' "$target"
  grep -q '\\"success\\":true\|"success":true' "$target"
}

control_speaker_off_capability_aware() {
  local target="$OUT_DIR/control-speaker_off.log"
  broadcast_control speaker_off
  if grep -q 'result=0' "$target" &&
     grep -q '\\"success\\":true\|"success":true' "$target"; then
    printf '%s\n' 'speaker_off=passed' > "$OUT_DIR/speaker-off-capability.txt"
    return 0
  fi
  if grep -q 'Uygun ses çıkış noktası bulunamadı' "$target" &&
     grep -q '\\"availableEndpoints\\":\[\\"speaker\\"\]\|"availableEndpoints":\["speaker"\]' "$target"; then
    printf '%s\n' \
      'speaker_off=capability_skipped; emulator exposes only the speaker endpoint; physical-device gate remains mandatory' \
      > "$OUT_DIR/speaker-off-capability.txt"
    return 0
  fi
  echo 'speaker_off failed for a reason other than the known speaker-only emulator capability' >&2
  return 1
}

snapshot() {
  local name="$1"
  adb shell dumpsys telecom > "$OUT_DIR/telecom-${name}.txt"
  adb shell dumpsys phone > "$OUT_DIR/phone-${name}.txt" 2>/dev/null || true
  adb logcat -d -v threadtime > "$OUT_DIR/logcat-${name}.txt"
}

wait_for_telecom() {
  local pattern="$1"
  local name="$2"
  for _ in $(seq 1 45); do
    adb shell dumpsys telecom > "$OUT_DIR/telecom-${name}.txt"
    if grep -Eiq "$pattern" "$OUT_DIR/telecom-${name}.txt"; then
      return 0
    fi
    sleep 1
  done
  echo "Telecom state did not match: $pattern" >&2
  return 1
}

adb emu gsm call 5551234 | tee "$OUT_DIR/gsm-call.log"
wait_for_telecom 'RINGING|STATE_RINGING|5551234' ringing
control_required state
control_required answer
wait_for_telecom 'ACTIVE|STATE_ACTIVE|5551234' active
snapshot active

control_required mute_on
control_required mute_off
control_required speaker_on
control_speaker_off_capability_aware
control_required hangup

for _ in $(seq 1 30); do
  adb shell dumpsys telecom > "$OUT_DIR/telecom-ended.txt"
  if ! grep -Eiq 'RINGING|STATE_RINGING|ACTIVE|STATE_ACTIVE|5551234' "$OUT_DIR/telecom-ended.txt"; then
    break
  fi
  sleep 1
done

adb emu gsm cancel 5551234 >/dev/null 2>&1 || true
snapshot ended
adb shell run-as "$PACKAGE" cat shared_prefs/nova_debug_control.xml \
  > "$OUT_DIR/nova-debug-control.xml"
grep -q 'hangup' "$OUT_DIR/nova-debug-control.xml"
grep -q '&quot;success&quot;:true\|"success":true' "$OUT_DIR/nova-debug-control.xml"

grep 'NOVA_DEBUG_CONTROL' "$OUT_DIR/logcat-ended.txt" \
  > "$OUT_DIR/nova-debug-control.log" || true

python3 - "$OUT_DIR" <<'PY'
from pathlib import Path
import json, sys
out = Path(sys.argv[1])
required = ["answer", "mute_on", "mute_off", "speaker_on", "hangup"]
missing = [name for name in required if not (out / f"control-{name}.log").exists()]
capability = (out / "speaker-off-capability.txt").read_text().strip()
summary = {
    "success": not missing and bool(capability),
    "required_commands": required,
    "missing": missing,
    "speaker_off": capability,
    "physical_device_speaker_off_still_required": "capability_skipped" in capability,
    "proof": "adb emu gsm call -> Android Telecom -> NOVA native call bridge -> dumpsys telecom",
}
(out / "NOVA_ANDROID_TELECOM_E2E_RESULT.json").write_text(
    json.dumps(summary, indent=2), encoding="utf-8"
)
print(json.dumps(summary, indent=2))
if not summary["success"]:
    raise SystemExit(1)
PY

echo "NOVA Android Telecom emulator E2E passed."
