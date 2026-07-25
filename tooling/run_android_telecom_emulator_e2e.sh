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

assert_dumpsys_has_call() {
  local target="$1"
  python3 - "$target" <<'PY'
from pathlib import Path
import sys

lines = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace").splitlines()
start = next((i for i, line in enumerate(lines) if line.strip().startswith("mCalls:")), None)
if start is None:
    raise SystemExit("dumpsys telecom mCalls section is missing")
end = next(
    (i for i in range(start + 1, len(lines)) if lines[i].strip().startswith("mCallAudioManager:")),
    len(lines),
)
body = [line.strip() for line in lines[start + 1:end] if line.strip()]
if not body:
    raise SystemExit("dumpsys telecom mCalls section is empty")
PY
}

wait_for_bridge_state() {
  local expected="$1"
  local name="$2"
  for _ in $(seq 1 60); do
    read_state > "$OUT_DIR/control-state-${name}.log"
    if grep -q "\\\"state\\\":\\\"${expected}\\\"\|\"state\":\"${expected}\"" "$OUT_DIR/control-state-${name}.log" &&
       grep -q '\\"inCallServiceReady\\":true\|"inCallServiceReady":true' "$OUT_DIR/control-state-${name}.log"; then
      adb shell dumpsys telecom > "$OUT_DIR/telecom-${name}.txt"
      assert_dumpsys_has_call "$OUT_DIR/telecom-${name}.txt"
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

control_speaker_on_capability_aware() {
  local target="$OUT_DIR/control-speaker_on.log"
  local active_state="$OUT_DIR/control-state-active.log"

  broadcast_control speaker_on
  if grep -q 'result=0' "$target" &&
     grep -q '\\"success\\":true\|"success":true' "$target"; then
    printf '%s\n' 'speaker_on=passed' > "$OUT_DIR/speaker-on-capability.txt"
    return 0
  fi

  # Some API-35 emulator images expose no CallEndpoint inventory even though
  # Telecom reports the active call is already routed to speaker. Accept only
  # that exact, fail-closed capability condition; a physical-device run remains
  # mandatory for proving an actual endpoint transition.
  if grep -q 'Uygun ses çıkış noktası bulunamadı' "$target" &&
     grep -q '\\"availableEndpoints\\":\[\]\|"availableEndpoints":\[\]' "$target" &&
     grep -q '\\"isSpeakerOn\\":true\|"isSpeakerOn":true' "$active_state" &&
     grep -q '\\"state\\":\\"active\\"\|"state":"active"' "$active_state" &&
     grep -q '\\"inCallServiceReady\\":true\|"inCallServiceReady":true' "$active_state"; then
    printf '%s\n' \
      'speaker_on=capability_skipped; emulator exposes no CallEndpoint inventory while Telecom already reports speaker route; physical-device gate remains mandatory' \
      > "$OUT_DIR/speaker-on-capability.txt"
    return 0
  fi

  echo 'speaker_on failed for a reason other than the known endpoint-less emulator capability' >&2
  cat "$target" >&2 || true
  return 1
}

control_speaker_off_capability_aware() {
  local speaker_on_result="$OUT_DIR/control-speaker_on.log"
  local speaker_on_capability="$OUT_DIR/speaker-on-capability.txt"
  local active_state="$OUT_DIR/control-state-active.log"
  local target="$OUT_DIR/control-speaker_off.log"

  # If the emulator exposed no endpoint inventory, neither speaker-on nor
  # speaker-off can request an endpoint transition. Preserve the active-state
  # evidence and make the physical-device requirement explicit.
  if grep -q 'speaker_on=capability_skipped' "$speaker_on_capability"; then
    cp "$active_state" "$target"
    printf '%s\n' \
      'speaker_off=capability_skipped; emulator exposes no alternate CallEndpoint; physical-device gate remains mandatory' \
      > "$OUT_DIR/speaker-off-capability.txt"
    return 0
  fi

  # A speaker-only endpoint inventory likewise cannot prove a route away from
  # speaker on the emulator.
  if grep -q '\\"availableEndpoints\\":\[\\"speaker\\"\]\|"availableEndpoints":\["speaker"\]' "$speaker_on_result"; then
    cp "$speaker_on_result" "$target"
    printf '%s\n' \
      'speaker_off=capability_skipped; emulator exposes only the speaker endpoint; physical-device gate remains mandatory' \
      > "$OUT_DIR/speaker-off-capability.txt"
    return 0
  fi

  broadcast_control speaker_off
  if grep -q 'result=0' "$target" &&
     grep -q '\\"success\\":true\|"success":true' "$target"; then
    printf '%s\n' 'speaker_off=passed' > "$OUT_DIR/speaker-off-capability.txt"
    return 0
  fi
  echo 'speaker_off failed on an emulator that advertised an alternate endpoint' >&2
  cat "$target" >&2 || true
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
# Android 35 redacts PhoneAccount IDs as *** in dumpsys. Verify the explicit
# enable result and the unredacted ConnectionService component instead.
grep -q 'enabled\.' "$OUT_DIR/phone-account-enable.log"
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
control_speaker_on_capability_aware
control_speaker_off_capability_aware
control_required hangup
wait_for_bridge_ended
snapshot ended

adb shell run-as "$PACKAGE" cat shared_prefs/nova_debug_control.xml \
  > "$OUT_DIR/nova-debug-control.xml"
# wait_for_bridge_ended intentionally polls the debug `state` command after
# hangup, so SharedPreferences must end on the verified idle snapshot rather
# than the earlier hangup command. The hangup result itself is already enforced
# by control_required and retained in control-hangup.log.
grep -q '\"success\":true\|"success":true' "$OUT_DIR/control-hangup.log"
grep -q '<string name="last_command">state</string>' "$OUT_DIR/nova-debug-control.xml"
grep -q '&quot;success&quot;:true' "$OUT_DIR/nova-debug-control.xml"
grep -q '&quot;inCall&quot;:false' "$OUT_DIR/nova-debug-control.xml"
grep -q '&quot;hasOngoingCall&quot;:false' "$OUT_DIR/nova-debug-control.xml"

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
speaker_on_capability = (out / "speaker-on-capability.txt").read_text().strip()
speaker_off_capability = (out / "speaker-off-capability.txt").read_text().strip()
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
    "success": not missing and not state_failures and bool(speaker_on_capability) and bool(speaker_off_capability),
    "required_commands": required,
    "missing": missing,
    "state_failures": state_failures,
    "speaker_on": speaker_on_capability,
    "speaker_off": speaker_off_capability,
    "physical_device_audio_route_still_required": (
        "capability_skipped" in speaker_on_capability
        or "capability_skipped" in speaker_off_capability
    ),
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
