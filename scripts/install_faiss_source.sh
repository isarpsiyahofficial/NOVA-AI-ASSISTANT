#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CPP_DIR="$ROOT_DIR/android/app/src/main/cpp"
TARGET_DIR="$CPP_DIR/third_party/faiss"
mkdir -p "$TARGET_DIR"
SRC="${1:-$ROOT_DIR/faiss-1.14.1.zip}"
if [[ -d "$SRC" ]]; then
  rm -rf "$TARGET_DIR/faiss-1.14.1"
  cp -R "$SRC" "$TARGET_DIR/faiss-1.14.1"
  echo "FAISS kaynak klasörü kopyalandı -> $TARGET_DIR/faiss-1.14.1"
  exit 0
fi
if [[ ! -f "$SRC" ]]; then
  echo "Kaynak bulunamadı: $SRC" >&2
  exit 1
fi
rm -rf "$TARGET_DIR/faiss-1.14.1"
unzip -q "$SRC" -d "$TARGET_DIR"
echo "FAISS kaynak zip açıldı -> $TARGET_DIR"
