#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LAB_DIR="$ROOT_DIR/infra/call-bridge"
cd "$LAB_DIR"

rm -rf runtime
mkdir -p runtime/sounds runtime/recordings runtime/reports runtime/logs
chmod -R 0777 runtime

compose=(docker compose -f docker-compose.yml)

cleanup() {
  local exit_code=$?
  "${compose[@]}" ps -a > runtime/logs/docker-compose-ps.log 2>&1 || true
  "${compose[@]}" logs --no-color > runtime/logs/docker-compose.log 2>&1 || true
  "${compose[@]}" exec -T asterisk asterisk -rx "core show channels verbose" > runtime/logs/asterisk-channels.log 2>&1 || true
  "${compose[@]}" exec -T asterisk asterisk -rx "module show like audiosocket" > runtime/logs/asterisk-audiosocket-modules.log 2>&1 || true
  "${compose[@]}" exec -T asterisk asterisk -rx "dialplan show nova-call-test" > runtime/logs/asterisk-dialplan.log 2>&1 || true
  if [[ "${NOVA_KEEP_CALL_LAB:-false}" != "true" ]]; then
    "${compose[@]}" down -v --remove-orphans >/dev/null 2>&1 || true
  fi
  exit "$exit_code"
}
trap cleanup EXIT

"${compose[@]}" down -v --remove-orphans >/dev/null 2>&1 || true
"${compose[@]}" build --progress=plain 2>&1 | tee runtime/logs/docker-compose-build.log
"${compose[@]}" up -d 2>&1 | tee runtime/logs/docker-compose-up.log
"${compose[@]}" ps -a | tee runtime/logs/docker-compose-ps-start.log

media_ready=false
for _ in $(seq 1 90); do
  if curl -fsS http://127.0.0.1:18080/health > runtime/logs/media-health.json 2>/dev/null && \
    grep -Eq '"ready"[[:space:]]*:[[:space:]]*true' runtime/logs/media-health.json; then
    media_ready=true
    break
  fi
  sleep 2
done
if [[ "$media_ready" != "true" ]]; then
  echo "NOVA media gateway did not become ready" >&2
  cat runtime/logs/media-health.json >&2 2>/dev/null || true
  exit 1
fi
cat runtime/logs/media-health.json

for _ in $(seq 1 60); do
  if "${compose[@]}" exec -T asterisk asterisk -rx "core show uptime" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
"${compose[@]}" exec -T asterisk asterisk -rx "core show uptime" \
  | tee runtime/logs/asterisk-uptime.log

"${compose[@]}" exec -T asterisk asterisk -rx "module show like audiosocket" \
  | tee runtime/logs/asterisk-audiosocket-modules.log
grep -q 'app_audiosocket.so' runtime/logs/asterisk-audiosocket-modules.log
grep -q 'res_audiosocket.so' runtime/logs/asterisk-audiosocket-modules.log

control_ready=false
for _ in $(seq 1 60); do
  if curl -fsS http://127.0.0.1:18090/health > runtime/logs/control-health.json 2>/dev/null && \
    grep -Eq '"ready"[[:space:]]*:[[:space:]]*true' runtime/logs/control-health.json; then
    control_ready=true
    break
  fi
  sleep 1
done
if [[ "$control_ready" != "true" ]]; then
  echo "NOVA call control did not become ready" >&2
  cat runtime/logs/control-health.json >&2 2>/dev/null || true
  exit 1
fi
cat runtime/logs/control-health.json

"${compose[@]}" exec -T media-gateway \
  python /app/launcher.py synthesize \
    --text "Nova gerçek çift yönlü çağrı testini doğrula" \
    --output /shared/sounds/nova-test-command-source.wav \
  2>&1 | tee runtime/logs/fixture-generation.json

test -s runtime/sounds/nova-test-command-source.wav
# Piper's Turkish model emits 22.05 kHz PCM. Asterisk Playback expects a
# telephony-rate WAV for this deterministic Local-channel caller, so create an
# explicit 8 kHz, mono, signed 16-bit fixture before reloading the dialplan.
"${compose[@]}" exec -T asterisk \
  sox /shared/sounds/nova-test-command-source.wav \
    -r 8000 -c 1 -b 16 -e signed-integer \
    /shared/sounds/nova-test-command.wav
"${compose[@]}" exec -T asterisk \
  soxi /shared/sounds/nova-test-command.wav \
  | tee runtime/logs/fixture-format.log
test -s runtime/sounds/nova-test-command.wav
grep -q 'Sample Rate    : 8000' runtime/logs/fixture-format.log
grep -q 'Channels       : 1' runtime/logs/fixture-format.log

"${compose[@]}" exec -T asterisk asterisk -rx "dialplan reload" \
  | tee runtime/logs/dialplan-reload.log
"${compose[@]}" exec -T asterisk asterisk -rx "dialplan show nova-call-test" \
  | tee runtime/logs/asterisk-dialplan.log
grep -q 'AudioSocket' runtime/logs/asterisk-dialplan.log

originate_output="$(
  "${compose[@]}" exec -T asterisk \
    asterisk -rx "channel originate Local/9000@nova-test-caller extension 7000@nova-call-test"
)"
printf '%s\n' "$originate_output" | tee runtime/logs/originate.log

completed=false
for _ in $(seq 1 90); do
  if curl -fsS http://127.0.0.1:18080/sessions/latest > runtime/logs/latest-session.json 2>/dev/null; then
    if python3 - <<'PY'
import json
from pathlib import Path
p = Path('runtime/logs/latest-session.json')
try:
    data = json.loads(p.read_text())
except Exception:
    raise SystemExit(1)
raise SystemExit(0 if data.get('completed_at', 0) and data.get('outgoing_bytes', 0) > 0 else 1)
PY
    then
      completed=true
      break
    fi
  fi
  sleep 2
done

if [[ "$completed" != "true" ]]; then
  echo "NOVA AudioSocket call session did not complete" >&2
  exit 1
fi

"${compose[@]}" exec -T media-gateway \
  python /app/service.py assert-latest \
    --report-dir /reports \
    --expect-token nova \
    --expect-token gercek \
    --expect-token cift \
    --min-incoming-bytes 6000 \
    --min-outgoing-bytes 6000 \
    --min-rms 30 \
  | tee runtime/logs/assert-session.json

"${compose[@]}" exec -T media-gateway \
  python /app/service.py inspect-wav \
    --directory /shared/recordings \
    --pattern 'test-caller-*.wav' \
    --min-duration 2.0 \
    --min-rms 15 \
  | tee runtime/logs/assert-caller-recording.json

python3 - <<'PY'
import json
from pathlib import Path
session = json.loads(Path('runtime/logs/latest-session.json').read_text())
summary = {
    'success': bool(session.get('success')),
    'session_id': session.get('session_id'),
    'transcript': session.get('transcript'),
    'reply': session.get('reply'),
    'incoming_bytes': session.get('incoming_bytes'),
    'outgoing_bytes': session.get('outgoing_bytes'),
    'incoming_rms': session.get('incoming_rms'),
    'outgoing_rms': session.get('outgoing_rms'),
    'stt_ms': session.get('stt_ms'),
    'ai_ms': session.get('ai_ms'),
    'tts_ms': session.get('tts_ms'),
    'proof': 'Asterisk AudioSocket caller PCM -> Whisper -> AI decision -> Piper TTS -> same caller channel',
}
Path('runtime/NOVA_CALL_BRIDGE_E2E_RESULT.json').write_text(
    json.dumps(summary, ensure_ascii=False, indent=2),
    encoding='utf-8',
)
print(json.dumps(summary, ensure_ascii=False, indent=2))
if not summary['success']:
    raise SystemExit(1)
PY

echo "NOVA bidirectional call bridge E2E passed."
