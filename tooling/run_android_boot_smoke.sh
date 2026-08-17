#!/usr/bin/env bash
set -euo pipefail

APK_PATH="${1:-build/app/outputs/flutter-apk/app-debug.apk}"
PACKAGE="com.example.nova"
ACTIVITY="$PACKAGE/.MainActivity"
OUT_DIR="${NOVA_BOOT_SMOKE_OUT:-build/boot-smoke}"
mkdir -p "$OUT_DIR"

adb wait-for-device
adb install -r -t "$APK_PATH" | tee "$OUT_DIR/install.log"

# Boot acceptance is about NOVA itself, not Android runtime-permission UI. Grant
# the setup-essential runtime permissions before launch so PermissionController
# cannot temporarily become the focused activity and create a false failure.
for permission in \
  android.permission.RECORD_AUDIO \
  android.permission.POST_NOTIFICATIONS; do
  adb shell pm grant "$PACKAGE" "$permission" >/dev/null 2>&1 || true
done

# The manifest intentionally contains additional launcher-facing activities for
# phone/contacts surfaces. A package-only monkey launch is therefore not proof
# that the Flutter NOVA root opened. Always target MainActivity explicitly.
adb shell am force-stop "$PACKAGE"
adb logcat -c
adb shell am start -W -n "$ACTIVITY" | tee "$OUT_DIR/launch.log" || true

# Capture Android's real screen before interpreting am-start status. A slow
# Flutter cold start can make `am start -W` report Status: timeout even when the
# requested MainActivity/process exists. The visual evidence must survive that
# condition so boot regressions are inspectable rather than opaque.
adb exec-out screencap -p > "$OUT_DIR/nova-after-launch.png" || true

# Verify the requested target rather than requiring ActivityManager's timing
# status to be `ok`; foreground/process probes below are the actual boot proof.
grep -q "Activity: $ACTIVITY" "$OUT_DIR/launch.log"

focused=0
pid=''
for _ in $(seq 1 30); do
  pid="$(adb shell pidof "$PACKAGE" | tr -d '\r' | awk '{print $1}')"
  adb shell dumpsys window windows > "$OUT_DIR/window.txt"
  adb shell dumpsys activity activities > "$OUT_DIR/activity.txt"
  if [[ -n "$pid" ]] &&
     grep -Eq "mCurrentFocus=.*${PACKAGE}/\.MainActivity|mFocusedApp=.*${PACKAGE}/\.MainActivity" "$OUT_DIR/window.txt"; then
    focused=1
    break
  fi
  sleep 1
done

if [[ "$focused" != "1" || -z "$pid" ]]; then
  echo 'NOVA MainActivity never became the focused live process.' >&2
  cat "$OUT_DIR/launch.log" >&2 || true
  cat "$OUT_DIR/window.txt" >&2 || true
  adb exec-out screencap -p > "$OUT_DIR/nova-focus-failure.png" || true
  adb logcat -d -v threadtime > "$OUT_DIR/logcat-all.txt" || true
  exit 1
fi

# Capture the actual Flutter surface once MainActivity is demonstrably focused.
adb exec-out screencap -p > "$OUT_DIR/nova-main-initial.png"
test -s "$OUT_DIR/nova-main-initial.png"

# Keep it alive long enough to catch bootstrap/plugin crashes that happen after
# Android reports a successful Activity launch.
sleep 12
live_pid="$(adb shell pidof "$PACKAGE" | tr -d '\r' | awk '{print $1}')"
if [[ -z "$live_pid" ]]; then
  echo 'NOVA process died during the post-launch stability window.' >&2
  adb exec-out screencap -p > "$OUT_DIR/nova-process-death.png" || true
  adb logcat -d -v threadtime > "$OUT_DIR/logcat-all.txt" || true
  exit 1
fi

adb shell dumpsys window windows > "$OUT_DIR/window-after-stability.txt"
adb shell dumpsys activity activities > "$OUT_DIR/activity-after-stability.txt"
adb shell dumpsys gfxinfo "$PACKAGE" > "$OUT_DIR/gfxinfo.txt" || true
adb logcat --pid "$live_pid" -d -v threadtime > "$OUT_DIR/logcat-app.txt" || true
adb logcat -d -v threadtime > "$OUT_DIR/logcat-all.txt" || true

if ! grep -Eq "mCurrentFocus=.*${PACKAGE}/\.MainActivity|mFocusedApp=.*${PACKAGE}/\.MainActivity" "$OUT_DIR/window-after-stability.txt"; then
  echo 'NOVA MainActivity lost foreground before boot acceptance completed.' >&2
  adb exec-out screencap -p > "$OUT_DIR/nova-foreground-loss.png" || true
  exit 1
fi

if grep -Eq 'FATAL EXCEPTION|E/flutter.*Unhandled Exception|Dart Error|Lost connection to device' "$OUT_DIR/logcat-app.txt"; then
  echo 'NOVA emitted a fatal/unhandled runtime error during boot.' >&2
  adb exec-out screencap -p > "$OUT_DIR/nova-runtime-failure.png" || true
  grep -E 'FATAL EXCEPTION|E/flutter.*Unhandled Exception|Dart Error|Lost connection to device' "$OUT_DIR/logcat-app.txt" >&2 || true
  exit 1
fi

frames="$(awk -F': ' '/Total frames rendered:/ {gsub(/[^0-9]/, "", $2); print $2; exit}' "$OUT_DIR/gfxinfo.txt")"
if [[ -n "$frames" ]] && [[ "$frames" =~ ^[0-9]+$ ]] && (( frames < 1 )); then
  echo 'NOVA Activity is alive but Android reports zero rendered frames.' >&2
  adb exec-out screencap -p > "$OUT_DIR/nova-zero-frame.png" || true
  exit 1
fi

# Capture a second proof after the stability window. This is the preferred
# screenshot for visual review because it is taken only after the process has
# survived bootstrap and the fatal-log scan.
adb exec-out screencap -p > "$OUT_DIR/nova-main-stable.png"
test -s "$OUT_DIR/nova-main-stable.png"
adb shell uiautomator dump /sdcard/nova-main-stable.xml >/dev/null 2>&1 || true
adb pull /sdcard/nova-main-stable.xml "$OUT_DIR/nova-main-stable.xml" >/dev/null 2>&1 || true

cat > "$OUT_DIR/NOVA_ANDROID_BOOT_SMOKE_RESULT.json" <<EOF
{
  "success": true,
  "package": "$PACKAGE",
  "activity": "$ACTIVITY",
  "pid": "$live_pid",
  "stability_seconds": 12,
  "rendered_frames": "${frames:-unknown}",
  "activity_manager_status": "$(awk -F': ' '/^Status:/ {print $2; exit}' "$OUT_DIR/launch.log")",
  "screenshots": ["nova-after-launch.png", "nova-main-initial.png", "nova-main-stable.png"],
  "proof": "explicit MainActivity target + foreground focus + live process + fatal-log scan + rendered-frame probe + real emulator screenshots"
}
EOF

cat "$OUT_DIR/NOVA_ANDROID_BOOT_SMOKE_RESULT.json"
echo 'NOVA Android boot smoke passed.'
