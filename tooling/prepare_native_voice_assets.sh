#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SHERPA_VERSION="${SHERPA_ONNX_VERSION:-1.13.2}"
CACHE_DIR="${NOVA_MODEL_CACHE_DIR:-$ROOT_DIR/.cache/nova-native-voice}"
ASSET_ROOT="$ROOT_DIR/android/app/src/main/assets"
AAR_DIR="$ROOT_DIR/android/app/libs"
API_ROOT="https://api.github.com/repos/k2-fsa/sherpa-onnx/releases/tags"
mkdir -p "$CACHE_DIR" "$ASSET_ROOT" "$AAR_DIR"

for cmd in curl jq tar find sha256sum stat; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Required command is missing: $cmd" >&2
    exit 1
  }
done

curl_headers=(
  -H "Accept: application/vnd.github+json"
  -H "X-GitHub-Api-Version: 2022-11-28"
)
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  curl_headers+=( -H "Authorization: Bearer ${GITHUB_TOKEN}" )
fi

release_json() {
  local tag="$1"
  local target="$CACHE_DIR/release-${tag//\//_}.json"
  if [[ ! -s "$target" ]]; then
    curl --fail --location --retry 4 --retry-delay 2 \
      "${curl_headers[@]}" "$API_ROOT/$tag" -o "$target"
  fi
  printf '%s' "$target"
}

asset_info() {
  local tag="$1"
  local regex="$2"
  local prefer_regex="${3:-}"
  local json
  json="$(release_json "$tag")"

  local filter='.assets[] | select(.name | test($regex; "i"))'
  if [[ -n "$prefer_regex" ]]; then
    jq -r --arg regex "$regex" --arg prefer "$prefer_regex" \
      "[$filter] | sort_by((.name | test(\$prefer; \"i\")) | not) | .[0] | [.name, .browser_download_url, (.digest // \"\")] | @tsv" \
      "$json"
  else
    jq -r --arg regex "$regex" \
      "[$filter] | .[0] | [.name, .browser_download_url, (.digest // \"\")] | @tsv" \
      "$json"
  fi
}

download_asset() {
  local tag="$1"
  local regex="$2"
  local prefer_regex="${3:-}"
  local info name url digest
  info="$(asset_info "$tag" "$regex" "$prefer_regex")"
  if [[ -z "$info" || "$info" == "null" ]]; then
    echo "No release asset matched tag=$tag regex=$regex" >&2
    exit 1
  fi
  IFS=$'\t' read -r name url digest <<< "$info"
  if [[ -z "$name" || -z "$url" || "$name" == "null" || "$url" == "null" ]]; then
    echo "Invalid release asset response tag=$tag regex=$regex" >&2
    exit 1
  fi

  local target="$CACHE_DIR/$name"
  if [[ ! -s "$target" ]]; then
    echo "Downloading $name"
    curl --fail --location --retry 5 --retry-all-errors --retry-delay 2 \
      "${curl_headers[@]}" "$url" -o "$target.part"
    mv "$target.part" "$target"
  fi

  if [[ "$digest" == sha256:* ]]; then
    local expected="${digest#sha256:}"
    local actual
    actual="$(sha256sum "$target" | awk '{print $1}')"
    if [[ "$actual" != "$expected" ]]; then
      echo "SHA256 mismatch for $name expected=$expected actual=$actual" >&2
      rm -f "$target"
      exit 1
    fi
  fi

  printf '%s\t%s\t%s\n' "$target" "$url" "$digest"
}

extract_archive() {
  local archive="$1"
  local output="$2"
  rm -rf "$output"
  mkdir -p "$output"
  case "$archive" in
    *.tar.bz2|*.tbz2) tar -xjf "$archive" -C "$output" ;;
    *.tar.gz|*.tgz) tar -xzf "$archive" -C "$output" ;;
    *) echo "Unsupported archive: $archive" >&2; exit 1 ;;
  esac
}

copy_required_file() {
  local source="$1"
  local target="$2"
  local label="$3"
  if [[ -z "$source" || ! -s "$source" ]]; then
    echo "Missing $label after extraction" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$target")"
  cp -f "$source" "$target"
  echo "Installed $label -> ${target#$ROOT_DIR/} bytes=$(stat -c '%s' "$target")"
}

# 1) Native runtime AAR. Pinning one official version prevents Java/JNI drift.
IFS=$'\t' read -r aar_file aar_url aar_digest < <(
  download_asset "v${SHERPA_VERSION}" "^sherpa-onnx-${SHERPA_VERSION//./\\.}\\.aar$"
)
copy_required_file "$aar_file" "$AAR_DIR/sherpa-onnx.aar" "sherpa-onnx AAR"

# 2) Turkish multilingual STT baseline: Whisper Tiny INT8.
IFS=$'\t' read -r asr_archive asr_url asr_digest < <(
  download_asset "asr-models" '^sherpa-onnx-whisper-tiny\\.tar\\.bz2$'
)
asr_extract="$CACHE_DIR/extracted-whisper-tiny"
extract_archive "$asr_archive" "$asr_extract"
asr_encoder="$(find "$asr_extract" -type f -name 'tiny-encoder.int8.onnx' -print -quit)"
asr_decoder="$(find "$asr_extract" -type f -name 'tiny-decoder.int8.onnx' -print -quit)"
asr_tokens="$(find "$asr_extract" -type f -name 'tiny-tokens.txt' -print -quit)"
copy_required_file "$asr_encoder" "$ASSET_ROOT/sherpa_asr/encoder.onnx" "Whisper Tiny INT8 encoder"
copy_required_file "$asr_decoder" "$ASSET_ROOT/sherpa_asr/decoder.onnx" "Whisper Tiny INT8 decoder"
copy_required_file "$asr_tokens" "$ASSET_ROOT/sherpa_asr/tokens.txt" "Whisper tokens"
cat > "$ASSET_ROOT/sherpa_asr/config.json" <<'JSON'
{
  "model_type": "whisper",
  "encoder": "encoder.onnx",
  "decoder": "decoder.onnx",
  "tokens": "tokens.txt",
  "language": "tr",
  "task": "transcribe",
  "num_threads": 2,
  "provider": "cpu"
}
JSON

# 3) Lightweight local VAD to avoid continuously decoding silence.
IFS=$'\t' read -r vad_file vad_url vad_digest < <(
  download_asset "asr-models" '^silero_vad\\.onnx$'
)
copy_required_file "$vad_file" "$ASSET_ROOT/sherpa_vad/silero_vad.onnx" "Silero VAD"

# 4) Speaker verification / owner identity.
IFS=$'\t' read -r speaker_asset speaker_url speaker_digest < <(
  download_asset "speaker-recongition-models" 'nemo.*titanet.*(tar\\.bz2|onnx)$' 'small'
)
speaker_model=""
if [[ "$speaker_asset" == *.onnx ]]; then
  speaker_model="$speaker_asset"
else
  speaker_extract="$CACHE_DIR/extracted-speaker-id"
  extract_archive "$speaker_asset" "$speaker_extract"
  speaker_model="$(find "$speaker_extract" -type f -name 'nemo_en_titanet_small.onnx' -print -quit)"
  if [[ -z "$speaker_model" ]]; then
    speaker_model="$(find "$speaker_extract" -type f -iname '*titanet*small*.onnx' -print -quit)"
  fi
fi
copy_required_file "$speaker_model" "$ASSET_ROOT/speaker_id/nemo_en_titanet_small.onnx" "TitaNet speaker ID model"

# 5) Deterministic offline Turkish TTS. Prefer the medium DFKI Piper voice.
IFS=$'\t' read -r tts_archive tts_url tts_digest < <(
  download_asset "tts-models" '^vits-piper-tr_TR-.*-medium\\.tar\\.bz2$' 'dfki'
)
tts_extract="$CACHE_DIR/extracted-turkish-tts"
extract_archive "$tts_archive" "$tts_extract"
tts_model="$(find "$tts_extract" -type f -iname 'tr_TR-*.onnx' -print -quit)"
if [[ -z "$tts_model" ]]; then
  tts_model="$(find "$tts_extract" -type f -name '*.onnx' -print -quit)"
fi
tts_tokens="$(find "$tts_extract" -type f -name 'tokens.txt' -print -quit)"
tts_espeak="$(find "$tts_extract" -type d -name 'espeak-ng-data' -print -quit)"
copy_required_file "$tts_model" "$ASSET_ROOT/sherpa_tts/model.onnx" "Turkish Piper TTS model"
copy_required_file "$tts_tokens" "$ASSET_ROOT/sherpa_tts/tokens.txt" "Turkish Piper TTS tokens"
if [[ -z "$tts_espeak" || ! -d "$tts_espeak" ]]; then
  echo "Missing espeak-ng-data in Turkish TTS archive" >&2
  exit 1
fi
rm -rf "$ASSET_ROOT/sherpa_tts/espeak-ng-data"
cp -R "$tts_espeak" "$ASSET_ROOT/sherpa_tts/espeak-ng-data"

mkdir -p "$ASSET_ROOT/nova_voice_manifest"
jq -n \
  --arg sherpaVersion "$SHERPA_VERSION" \
  --arg aarUrl "$aar_url" \
  --arg aarSha "$(sha256sum "$AAR_DIR/sherpa-onnx.aar" | awk '{print $1}')" \
  --arg asrUrl "$asr_url" \
  --arg asrSha "$(sha256sum "$asr_archive" | awk '{print $1}')" \
  --arg vadUrl "$vad_url" \
  --arg vadSha "$(sha256sum "$vad_file" | awk '{print $1}')" \
  --arg speakerUrl "$speaker_url" \
  --arg speakerSha "$(sha256sum "$speaker_asset" | awk '{print $1}')" \
  --arg ttsUrl "$tts_url" \
  --arg ttsSha "$(sha256sum "$tts_archive" | awk '{print $1}')" \
  '{
    schema: 1,
    generatedBy: "tooling/prepare_native_voice_assets.sh",
    sherpaOnnxVersion: $sherpaVersion,
    artifacts: {
      aar: {url: $aarUrl, sha256: $aarSha},
      asr: {url: $asrUrl, sha256: $asrSha, type: "whisper-tiny-int8", language: "tr"},
      vad: {url: $vadUrl, sha256: $vadSha, type: "silero"},
      speakerId: {url: $speakerUrl, sha256: $speakerSha, type: "nemo-titanet-small"},
      tts: {url: $ttsUrl, sha256: $ttsSha, type: "piper-vits", language: "tr-TR"}
    }
  }' > "$ASSET_ROOT/nova_voice_manifest/manifest.json"

echo "Native voice assets are prepared and checksum verified."
