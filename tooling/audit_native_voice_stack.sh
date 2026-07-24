#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

failures=0
warn() { printf 'WARN  %s\n' "$*"; }
pass() { printf 'PASS  %s\n' "$*"; }
fail() { printf 'FAIL  %s\n' "$*"; failures=$((failures + 1)); }

file_size() {
  if [[ -f "$1" ]]; then
    stat -c '%s' "$1"
  else
    printf '0'
  fi
}

printf '=== NOVA NATIVE VOICE STACK AUDIT ===\n'
printf 'commit=%s\n' "$(git rev-parse HEAD 2>/dev/null || echo unknown)"
printf 'date_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

AAR="android/app/libs/sherpa-onnx.aar"
if [[ -s "$AAR" ]]; then
  aar_size="$(file_size "$AAR")"
  pass "sherpa-onnx AAR exists bytes=$aar_size"
  if command -v unzip >/dev/null 2>&1; then
    printf '%s\n' '--- AAR ABI inventory ---'
    unzip -l "$AAR" | awk '/jni\// {print $4}' | sort -u || true
    for abi in arm64-v8a armeabi-v7a x86_64; do
      if unzip -l "$AAR" | grep -q "jni/$abi/"; then
        pass "AAR contains ABI $abi"
      else
        warn "AAR does not contain ABI $abi"
      fi
    done

    printf '%s\n' '--- AAR speech API classes ---'
    tmp_classes="$(mktemp --suffix=.jar)"
    unzip -p "$AAR" classes.jar > "$tmp_classes"
    jar tf "$tmp_classes" | grep -E 'com/k2fsa/sherpa/onnx/(OfflineTts|GenerationConfig|GeneratedAudio|OnlineRecognizer|OfflineRecognizer|SpeakerEmbedding|SileroVad|VoiceActivity)' | sort || true
    if command -v javap >/dev/null 2>&1; then
      for klass in \
        com.k2fsa.sherpa.onnx.OfflineTts \
        com.k2fsa.sherpa.onnx.OfflineTtsConfig \
        com.k2fsa.sherpa.onnx.OfflineTtsModelConfig \
        com.k2fsa.sherpa.onnx.OfflineTtsVitsModelConfig \
        com.k2fsa.sherpa.onnx.GenerationConfig \
        com.k2fsa.sherpa.onnx.GeneratedAudio \
        com.k2fsa.sherpa.onnx.OnlineRecognizer \
        com.k2fsa.sherpa.onnx.SpeakerEmbeddingExtractor; do
        printf '%s\n' "--- javap $klass ---"
        javap -classpath "$tmp_classes" -public "$klass" 2>&1 || true
      done
    fi
    rm -f "$tmp_classes"
  fi
else
  fail "missing or empty $AAR"
fi

printf '%s\n' '--- Native assets ---'
if [[ -d android/app/src/main/assets ]]; then
  find android/app/src/main/assets -type f -printf '%p|%s\n' | sort
else
  fail "android/app/src/main/assets directory missing"
fi

printf '%s\n' '--- Flutter assets ---'
if [[ -d assets ]]; then
  find assets -type f -printf '%p|%s\n' | sort
else
  warn "Flutter assets directory missing"
fi

printf '%s\n' '--- JNI libraries ---'
if [[ -d android/app/src/main/jniLibs ]]; then
  find android/app/src/main/jniLibs -type f -printf '%p|%s\n' | sort
else
  warn "android/app/src/main/jniLibs directory missing; AAR must carry all JNI libraries"
fi

require_any() {
  local label="$1"
  shift
  local found=""
  for path in "$@"; do
    if [[ -s "$path" ]]; then
      found="$path"
      break
    fi
  done
  if [[ -n "$found" ]]; then
    pass "$label => $found bytes=$(file_size "$found")"
  else
    fail "$label missing; checked: $*"
  fi
}

require_any "ASR encoder" \
  android/app/src/main/assets/sherpa_asr/tiny-encoder.int8.onnx \
  android/app/src/main/assets/sherpa_asr/encoder.onnx \
  assets/models/asr/tiny-encoder.int8.onnx \
  assets/models/asr/encoder.onnx

require_any "ASR decoder" \
  android/app/src/main/assets/sherpa_asr/tiny-decoder.int8.onnx \
  android/app/src/main/assets/sherpa_asr/decoder.onnx \
  assets/models/asr/tiny-decoder.int8.onnx \
  assets/models/asr/decoder.onnx

require_any "ASR tokens" \
  android/app/src/main/assets/sherpa_asr/tiny-tokens.txt \
  android/app/src/main/assets/sherpa_asr/tokens.txt \
  assets/models/asr/tiny-tokens.txt \
  assets/models/asr/tokens.txt

require_any "ASR config" \
  android/app/src/main/assets/sherpa_asr/config.json \
  assets/models/asr/config.json

require_any "Speaker ID model" \
  android/app/src/main/assets/speaker_id/nemo_en_titanet_small.onnx \
  android/app/src/main/assets/models/speaker_id/nemo_en_titanet_small.onnx \
  assets/models/speaker_id/nemo_en_titanet_small.onnx

require_any "Turkish TTS model" \
  android/app/src/main/assets/sherpa_tts/model.onnx \
  android/app/src/main/assets/sherpa_tts/tr_TR-dfki-medium.onnx \
  assets/models/tts/tr_TR-dfki-medium.onnx

require_any "Turkish TTS tokens" \
  android/app/src/main/assets/sherpa_tts/tokens.txt \
  assets/models/tts/tokens.txt

require_any "Piper espeak-ng data" \
  android/app/src/main/assets/sherpa_tts/espeak-ng-data/phontab \
  assets/models/tts/espeak-ng-data/phontab

printf '%s\n' '--- Native implementation references ---'
grep -RIn --include='*.kt' --include='*.java' \
  -E 'OfflineRecognizer|OnlineRecognizer|SpeakerEmbedding|OfflineTts|createVoiceClone|SpeechRecognizer' \
  android/app/src/main/kotlin android/app/src/main/java 2>/dev/null || true

printf '%s\n' '--- Duplicate engine declarations ---'
grep -RIn --include='*.kt' --include='*.dart' \
  -E 'class .*Asr|class .*Stt|class .*Tts|class .*Voice.*Identity|class .*Clone.*Engine' \
  android/app/src/main/kotlin lib 2>/dev/null || true

printf 'audit_failures=%d\n' "$failures"
if [[ "$failures" -ne 0 ]]; then
  exit 1
fi
