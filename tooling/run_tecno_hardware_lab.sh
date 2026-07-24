#!/usr/bin/env bash
set -euo pipefail

APK_PATH="${1:-build/app/outputs/flutter-apk/app-debug.apk}"
OUT_DIR="${NOVA_TECNO_LAB_OUT:-build/tecno-device-lab}"
PACKAGE="com.example.nova"
ACTION="com.example.nova.DEBUG_CALL_CONTROL"
RECEIVER="$PACKAGE/com.example.nova.testing.NovaDebugControlReceiver"
TARGET_SERIAL="${NOVA_TECNO_ADB_SERIAL:-}"
WAIT_SECONDS="${NOVA_TECNO_BACKGROUND_SECONDS:-1800}"
mkdir -p "$OUT_DIR"

adb_target=(adb)
if [[ -n "$TARGET_SERIAL" ]]; then
  adb_target+=( -s "$TARGET_SERIAL" )
fi

adb_cmd() { "${adb_target[@]}" "$@"; }

fail() {
  echo "TECNO LAB FAILURE: $*" >&2
  exit 1
}

wait_for_device() {
  adb_cmd wait-for-device
  local model manufacturer android_version sdk
  model="$(adb_cmd shell getprop ro.product.model | tr -d '\r')"
  manufacturer="$(adb_cmd shell getprop ro.product.manufacturer | tr -d '\r')"
  android_version="$(adb_cmd shell getprop ro.build.version.release | tr -d '\r')"
  sdk="$(adb_cmd shell getprop ro.build.version.sdk | tr -d '\r')"
  printf 'model=%s\nmanufacturer=%s\nandroid=%s\nsdk=%s\n' \
    "$model" "$manufacturer" "$android_version" "$sdk" \
    | tee "$OUT_DIR/device.properties"
  [[ "${manufacturer,,}" == *tecno* || "${NOVA_ALLOW_NON_TECNO_DEVICE:-false}" == "true" ]] \
    || fail "Connected device is not TECNO: manufacturer=$manufacturer model=$model"
}

install_and_prepare() {
  adb_cmd install -r -t "$APK_PATH" | tee "$OUT_DIR/install.log"
  local permissions=(
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
    adb_cmd shell pm grant "$PACKAGE" "$permission" >/dev/null 2>&1 || true
  done
  adb_cmd shell cmd role add-role-holder --user 0 android.app.role.DIALER "$PACKAGE" \
    | tee "$OUT_DIR/dialer-role.log"
  adb_cmd shell cmd role get-role-holders --user 0 android.app.role.DIALER \
    | tee -a "$OUT_DIR/dialer-role.log" | grep -q "$PACKAGE"
  adb_cmd shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 \
    | tee "$OUT_DIR/launch.log"
  sleep 5
}

control() {
  local command="$1"
  local target="$OUT_DIR/control-${command}.log"
  adb_cmd shell am broadcast -n "$RECEIVER" -a "$ACTION" --es command "$command" \
    | tee "$target"
  grep -q 'result=0' "$target"
  grep -q '\\"success\\":true\|"success":true' "$target"
}

telecom_snapshot() {
  local name="$1"
  adb_cmd shell dumpsys telecom > "$OUT_DIR/telecom-${name}.txt"
  adb_cmd shell dumpsys telephony.registry > "$OUT_DIR/telephony-${name}.txt" 2>/dev/null || true
  adb_cmd shell dumpsys audio > "$OUT_DIR/audio-${name}.txt" 2>/dev/null || true
}

wait_for_call_state() {
  local pattern="$1"
  local name="$2"
  local timeout="${3:-90}"
  for _ in $(seq 1 "$timeout"); do
    telecom_snapshot "$name"
    if grep -Eiq "$pattern" "$OUT_DIR/telecom-${name}.txt"; then
      return 0
    fi
    sleep 1
  done
  return 1
}

trigger_real_call() {
  if [[ -n "${NOVA_REAL_SIM_TRIGGER_SCRIPT:-}" ]]; then
    "$NOVA_REAL_SIM_TRIGGER_SCRIPT" \
      "${NOVA_TECNO_PHONE_NUMBER:?NOVA_TECNO_PHONE_NUMBER is required}" \
      | tee "$OUT_DIR/real-call-trigger.log"
    return
  fi
  if [[ -n "${NOVA_REAL_CALL_TRIGGER_URL:-}" ]]; then
    curl --fail --show-error --location \
      --request POST \
      --header "Authorization: Bearer ${NOVA_REAL_CALL_TRIGGER_TOKEN:-}" \
      --header 'Content-Type: application/json' \
      --data "{\"to\":\"${NOVA_TECNO_PHONE_NUMBER:?NOVA_TECNO_PHONE_NUMBER is required}\",\"test\":\"nova-real-sim-e2e\"}" \
      "$NOVA_REAL_CALL_TRIGGER_URL" \
      | tee "$OUT_DIR/real-call-trigger.log"
    return
  fi
  fail "Set NOVA_REAL_SIM_TRIGGER_SCRIPT or NOVA_REAL_CALL_TRIGGER_URL for a real incoming SIM call"
}

run_real_sim_call() {
  adb_cmd logcat -c
  trigger_real_call
  wait_for_call_state 'RINGING|STATE_RINGING' real-ringing 120 \
    || fail "Real SIM call did not reach ringing state"
  control state
  control answer
  wait_for_call_state 'ACTIVE|STATE_ACTIVE' real-active 60 \
    || fail "NOVA did not produce an active real SIM call"
  control mute_on
  control mute_off
  control speaker_on
  control speaker_off
  control hangup
  sleep 3
  telecom_snapshot real-ended
  adb_cmd logcat -d -v threadtime > "$OUT_DIR/logcat-real-sim.txt"
  grep -q 'NOVA_DEBUG_CONTROL' "$OUT_DIR/logcat-real-sim.txt"
}

run_sip_media_probe() {
  if [[ -z "${NOVA_CALL_BRIDGE_HEALTH_URL:-}" ]]; then
    fail "NOVA_CALL_BRIDGE_HEALTH_URL is required"
  fi
  curl --fail --show-error "$NOVA_CALL_BRIDGE_HEALTH_URL/health" \
    | tee "$OUT_DIR/call-bridge-health.json" \
    | grep -q '"ready"[[:space:]]*:[[:space:]]*true'

  if [[ -n "${NOVA_SIP_DEVICE_TEST_TRIGGER_SCRIPT:-}" ]]; then
    "$NOVA_SIP_DEVICE_TEST_TRIGGER_SCRIPT" \
      "${NOVA_TECNO_PHONE_NUMBER:?NOVA_TECNO_PHONE_NUMBER is required}" \
      | tee "$OUT_DIR/sip-device-trigger.log"
  elif [[ -n "${NOVA_SIP_DEVICE_TEST_TRIGGER_URL:-}" ]]; then
    curl --fail --show-error --location \
      --request POST \
      --header "Authorization: Bearer ${NOVA_SIP_DEVICE_TEST_TRIGGER_TOKEN:-}" \
      --header 'Content-Type: application/json' \
      --data "{\"to\":\"${NOVA_TECNO_PHONE_NUMBER:?NOVA_TECNO_PHONE_NUMBER is required}\",\"scenario\":\"nova-sip-media-device-e2e\"}" \
      "$NOVA_SIP_DEVICE_TEST_TRIGGER_URL" \
      | tee "$OUT_DIR/sip-device-trigger.log"
  else
    fail "Set NOVA_SIP_DEVICE_TEST_TRIGGER_SCRIPT or NOVA_SIP_DEVICE_TEST_TRIGGER_URL"
  fi

  wait_for_call_state 'RINGING|STATE_RINGING' sip-ringing 120 \
    || fail "SIP/PSTN bridge call did not reach TECNO"
  control answer
  wait_for_call_state 'ACTIVE|STATE_ACTIVE' sip-active 60 \
    || fail "SIP/PSTN bridge call was not active"
  sleep "${NOVA_SIP_MEDIA_LISTEN_SECONDS:-20}"
  control hangup
  curl --fail --show-error "$NOVA_CALL_BRIDGE_HEALTH_URL/sessions/latest" \
    > "$OUT_DIR/sip-latest-session.json"
  python3 - "$OUT_DIR/sip-latest-session.json" <<'PY'
import json, sys
from pathlib import Path
path = Path(sys.argv[1])
data = json.loads(path.read_text())
errors = []
if not data.get('success'):
    errors.append('success=false')
if data.get('incoming_bytes', 0) < 6000:
    errors.append('incoming audio missing')
if data.get('outgoing_bytes', 0) < 6000:
    errors.append('outgoing audio missing')
if data.get('incoming_rms', 0) < 20:
    errors.append('incoming RMS too low')
if data.get('outgoing_rms', 0) < 20:
    errors.append('outgoing RMS too low')
if errors:
    raise SystemExit('; '.join(errors))
PY
}

run_screen_lock_background() {
  adb_cmd shell input keyevent KEYCODE_HOME
  adb_cmd shell input keyevent KEYCODE_SLEEP
  local started now elapsed
  started="$(date +%s)"
  while true; do
    now="$(date +%s)"
    elapsed=$((now - started))
    adb_cmd shell dumpsys activity services "$PACKAGE" \
      > "$OUT_DIR/services-${elapsed}.txt" 2>/dev/null || true
    adb_cmd shell pidof "$PACKAGE" \
      > "$OUT_DIR/pid-${elapsed}.txt" 2>/dev/null || true
    [[ -s "$OUT_DIR/pid-${elapsed}.txt" ]] || fail "NOVA process died after ${elapsed}s under screen lock"
    if (( elapsed >= WAIT_SECONDS )); then
      break
    fi
    sleep 60
  done
  adb_cmd shell input keyevent KEYCODE_WAKEUP
  adb_cmd shell wm dismiss-keyguard >/dev/null 2>&1 || true
  adb_cmd shell dumpsys deviceidle > "$OUT_DIR/deviceidle.txt" 2>/dev/null || true
  adb_cmd shell dumpsys power > "$OUT_DIR/power.txt"
}

collect_metrics() {
  adb_cmd shell dumpsys meminfo "$PACKAGE" > "$OUT_DIR/meminfo.txt"
  adb_cmd shell dumpsys batterystats "$PACKAGE" > "$OUT_DIR/batterystats.txt" 2>/dev/null || true
  adb_cmd shell dumpsys cpuinfo | grep "$PACKAGE" > "$OUT_DIR/cpuinfo.txt" || true
  adb_cmd shell dumpsys package "$PACKAGE" > "$OUT_DIR/package.txt"
  adb_cmd logcat -d -v threadtime > "$OUT_DIR/logcat-final.txt"
}

write_evidence() {
  local model manufacturer android_version sdk commit_sha apk_sha pss_kb
  model="$(adb_cmd shell getprop ro.product.model | tr -d '\r')"
  manufacturer="$(adb_cmd shell getprop ro.product.manufacturer | tr -d '\r')"
  android_version="$(adb_cmd shell getprop ro.build.version.release | tr -d '\r')"
  sdk="$(adb_cmd shell getprop ro.build.version.sdk | tr -d '\r')"
  commit_sha="${GITHUB_SHA:-$(git rev-parse HEAD)}"
  apk_sha="$(sha256sum "$APK_PATH" | awk '{print $1}')"
  pss_kb="$(awk '/TOTAL PSS:/ {print $3; exit} /^TOTAL[[:space:]]/ {print $2; exit}' "$OUT_DIR/meminfo.txt" || true)"
  python3 - "$OUT_DIR/NOVA_TECNO_DEVICE_EVIDENCE.json" <<PY
import json, time, pathlib
payload = {
  "schema": 1,
  "commit_sha": ${commit_sha@Q},
  "apk_sha256": ${apk_sha@Q},
  "device_model": ${model@Q},
  "device_manufacturer": ${manufacturer@Q},
  "android_version": ${android_version@Q},
  "android_sdk": ${sdk@Q},
  "sim_call_passed": True,
  "sip_media_passed": True,
  "screen_lock_passed": True,
  "background_30m_passed": int(${WAIT_SECONDS@Q}) >= 1800,
  "metrics": {
    "background_seconds": int(${WAIT_SECONDS@Q}),
    "total_pss_kb": ${pss_kb@Q},
  },
  "created_at_epoch": int(time.time()),
  "evidence_files": sorted(str(p.name) for p in pathlib.Path(${OUT_DIR@Q}).iterdir()),
}
path = pathlib.Path(__import__('sys').argv[1])
path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(payload, ensure_ascii=False, indent=2))
PY
  sha256sum "$OUT_DIR/NOVA_TECNO_DEVICE_EVIDENCE.json" \
    > "$OUT_DIR/NOVA_TECNO_DEVICE_EVIDENCE.sha256"
}

wait_for_device
install_and_prepare
run_real_sim_call
run_sip_media_probe
run_screen_lock_background
collect_metrics
write_evidence

NOVA_REAL_DEVICE_EVIDENCE="$OUT_DIR/NOVA_TECNO_DEVICE_EVIDENCE.json" \
  python3 tooling/verify_nova_acceptance.py --strict --require-hardware

echo "NOVA real TECNO hardware lab passed."
