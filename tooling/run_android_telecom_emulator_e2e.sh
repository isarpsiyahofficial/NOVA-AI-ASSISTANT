#!/usr/bin/env bash
set -euo pipefail

APK_PATH="${1:-build/app/outputs/flutter-apk/app-debug.apk}"
PACKAGE="com.example.nova"
RECEIVER="$PACKAGE/com.example.nova.testing.NovaDebugControlReceiver"
ACTION="com.example.nova.DEBUG_CALL_CONTROL"
ACCOUNT_COMPONENT="$PACKAGE/com.example.nova.NovaCompanionConnectionService"
ACCOUNT_ID="nova_telecom_e2e"
TEST_NUMBER="5551234"
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
  shift || true
  adb shell am broadcast \
    -n "$RECEIVER" \
    -a "$ACTION" \
    --es command "$command" \
    "$@" \
    | tee "$target"
}

control_required() {
  local command="$1"
  shift || true
  broadcast_control "$command" "$@"
  local target="$OUT_DIR/control-${command}.log"
  grep -q 'result=0' "$target"
  grep -q '\\"success\\":true\|"success":true' "$target"
}

read_state() {
  adb shell am broadcast \
    -n "$RECEIVER" \
    -a "$ACTION" \
    --es command state
}

wait_for_bridge_state() {
  local expected="$1"
  local name="$2"
  for _ in $(seq 1 60); do
    read_state > "$OUT_DIR/control-state-${name}.log"
    if grep -q "\\\"state\\\":\\\"${expected}\\\"\|\"state\":\"${expected}\"" "$OUT_DIR/control-state-${name}.log" &&
       grep -q '\\"inCallServiceReady\\":true\|"inCallServiceReady":true' "$OUT_DIR/control-state-${name}.log"; then
      adb shell dumpsys telecom > "$OUT_DIR/telecom-${name}.txt"
      grep -q "$TEST_NUMBER" "$OUT_DIR/telecom-${name}.txt"
      return 0
    fi
    sleep 1
  done
  echo "Nova Telecom bridge did not reach state=$expected" >&2
  cat "$OUT_DIR/control-state-${name}.log" >&2 || true
  return 1
}

wait_for_bridge_ended() {
  for _ in $(seq 1 45); do
    read_state > "$OUT_DIR/control-state-ended.log"
    if grep -q '\\"inCall\\":false\|"inCall":false' "$OUT_DIR/control-state-ended.log" &&
       grep -q '\\"hasOngoingCall\\":false\|"hasOngoingCall":false' "$OUT_DIR/control-state-ended.log"; then
      return 0
    fi
    sleep 1
  done
  echo 'Nova Telecom bridge did not reach ended state' >&2
  return 1
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

cleanup() {
  broadcast_control unregister_test_account >/dev/null 2>&1 || true
}
trap cleanup EXIT

control_required register_test_account
if ! adb shell telecom help > "$OUT_DIR/telecom-help.txt" 2>&1; then
  adb shell cmd telecom help > "$OUT_DIR/telecom-help.txt" 2>&1 || true
fi
phone_account_args=("$ACCOUNT_COMPONENT" "$ACCOUNT_ID")
if grep -q '<USER_SN>' "$OUT_DIR/telecom-help.txt"; then
  # API 34+ TelecomShellCommand requires the Android user serial number.
  # The GitHub emulator uses the primary system user, whose serial is 0.
  phone_account_args+=(0)
fi
if ! adb shell telecom set-phone-account-enabled "${phone_account_args[@]}" \
  > "$OUT_DIR/phone-account-enable.log" 2>&1; then
  adb shell cmd telecom set-phone-account-enabled "${phone_account_args[@]}" \
    >> "$OUT_DIR/phone-account-enable.log" 2>&1
fi
adb shell telecom wait-on-handlers >> "$OUT_DIR/phone-account-enable.log" 2>&1 || \
  adb shell cmd telecom wait-on-handlers >> "$OUT_DIR/phone-account-enable.log" 2>&1 || true
adb shell dumpsys telecom > "$OUT_DIR/telecom-account-registered.txt"
grep -q "$ACCOUNT_ID" "$OUT_DIR/telecom-account-registered.txt"
grep -q "$ACCOUNT_COMPONENT" "$OUT_DIR/telecom-account-registered.txt"

# Older emulator GSM injection (`adb emu gsm call`) is intentionally not used:
# API 35 can return OK without creating a Telecom Call. The debug-only
# ConnectionService path below creates a real managed Telecom call instead.
control_required inject_incoming_call --es number "$TEST_NUMBER"
wait_for_bridge_state ringing ringing
control_required state
control_required answer
wait_for_bridge_state active active
snapshot active

control_required mute_on
control_required mute_off
control_required speaker_on
control_speaker_off_capability_aware
control_required hangup
wait_for_bridge_ended
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
required = [
    "register_test_account",
    "inject_incoming_call",
    "answer",
    "mute_on",
    "mute_off",
    "speaker_on",
    "hangup",
]
missing = [name for name in required if not (out / f"control-{name}.log").exists()]
capability = (out / "speaker-off-capability.txt").read_text().strip()
ringing = (out / "control-state-ringing.log").read_text()
active = (out / "control-state-active.log").read_text()
ended = (out / "control-state-ended.log").read_text()
state_failures = []
if 'state\\\":\\\"ringing' not in ringing and '"state":"ringing"' not in ringing:
    state_failures.append("ringing")
if 'state\\\":\\\"active' not in active and '"state":"active"' not in active:
    state_failures.append("active")
if 'inCall\\\":false' not in ended and '"inCall":false' not in ended:
    state_failures.append("ended")
summary = {
    "success": not missing and not state_failures and bool(capability),
    "required_commands": required,
    "missing": missing,
    "state_failures": state_failures,
    "speaker_off": capability,
    "physical_device_speaker_off_still_required": "capability_skipped" in capability,
    "proof": "debug-only PhoneAccount -> TelecomManager.addNewIncomingCall -> ConnectionService -> InCallService -> NOVA native call bridge -> dumpsys telecom",
}
(out / "NOVA_ANDROID_TELECOM_E2E_RESULT.json").write_text(
    json.dumps(summary, indent=2), encoding="utf-8"
)
print(json.dumps(summary, indent=2))
if not summary["success"]:
    raise SystemExit(1)
PY

echo "NOVA Android Telecom emulator E2E passed."
