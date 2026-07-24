#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"
WRAPPER_DIR="$ANDROID_DIR/gradle/wrapper"
GRADLE_TAG="v8.13.0"
RAW_ROOT="https://raw.githubusercontent.com/gradle/gradle/${GRADLE_TAG}"

mkdir -p "$WRAPPER_DIR"

for cmd in curl git; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Required command is missing: $cmd" >&2
    exit 1
  }
done

fetch_verified_blob() {
  local relative_path="$1"
  local target_path="$2"
  local expected_git_blob_sha="$3"
  local temp_path="${target_path}.part"

  if [[ -s "$target_path" ]]; then
    local current_sha
    current_sha="$(git hash-object "$target_path")"
    if [[ "$current_sha" == "$expected_git_blob_sha" ]]; then
      echo "Gradle wrapper file already verified: ${target_path#$ROOT_DIR/}"
      return
    fi
  fi

  mkdir -p "$(dirname "$target_path")"
  curl --fail --location --retry 5 --retry-all-errors --retry-delay 2 \
    "$RAW_ROOT/$relative_path" -o "$temp_path"

  local actual_sha
  actual_sha="$(git hash-object "$temp_path")"
  if [[ "$actual_sha" != "$expected_git_blob_sha" ]]; then
    rm -f "$temp_path"
    echo "Gradle wrapper Git blob mismatch for $relative_path expected=$expected_git_blob_sha actual=$actual_sha" >&2
    exit 1
  fi

  mv "$temp_path" "$target_path"
  echo "Installed verified Gradle wrapper file: ${target_path#$ROOT_DIR/}"
}

# These Git blob IDs are from the official gradle/gradle v8.13.0 tag.
fetch_verified_blob "gradlew" "$ANDROID_DIR/gradlew" \
  "d24fc200c47ebdfa6f663f088eb0530e401a47ae"
fetch_verified_blob "gradlew.bat" "$ANDROID_DIR/gradlew.bat" \
  "640d68685c14950470c82031e02198e220b96e62"
fetch_verified_blob "gradle/wrapper/gradle-wrapper.jar" \
  "$WRAPPER_DIR/gradle-wrapper.jar" \
  "9bbc975c742b298b441bfb90dbc124400a3751b9"

cat > "$WRAPPER_DIR/gradle-wrapper.properties" <<'PROPERTIES'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionSha256Sum=20f1b1176237254a6fc204d8434196fa11a4cfb387567519c61556e8710aed78
distributionUrl=https\://services.gradle.org/distributions/gradle-8.13-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
PROPERTIES

chmod +x "$ANDROID_DIR/gradlew"

echo "Gradle 8.13 wrapper is ready and pinned for AGP 8.11.1."
