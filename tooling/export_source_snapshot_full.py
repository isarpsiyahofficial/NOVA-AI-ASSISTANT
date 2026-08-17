#!/usr/bin/env python3
"""Export every UTF-8 source/config file, including NOVA runtime packages."""

from __future__ import annotations

import hashlib
import json
import tarfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "build" / "nova-decision-audit"
SOURCE_SUFFIXES = {
    ".dart", ".kt", ".kts", ".java", ".py", ".cpp", ".cc", ".c",
    ".h", ".hpp", ".xml", ".yaml", ".yml", ".sh", ".gradle",
    ".properties", ".conf", ".template", ".txt", ".md",
}
SOURCE_NAMES = {
    "Dockerfile", "CMakeLists.txt", "pubspec.yaml", "analysis_options.yaml",
}
EXCLUDED_PARTS = {
    ".git", ".dart_tool", ".gradle", "build", ".cache", "node_modules",
    ".idea", "assets", "generated",
}
EXCLUDED_NAMES = {".env", "local.properties", "key.properties"}


def included(path: Path) -> bool:
    if not path.is_file():
        return False
    relative = path.relative_to(ROOT)
    if any(part in EXCLUDED_PARTS for part in relative.parts):
        return False
    if relative.parts[:3] == ("infra", "call-bridge", "runtime"):
        return False
    if path.name in EXCLUDED_NAMES or path.name.startswith(".env."):
        return False
    return path.suffix.lower() in SOURCE_SUFFIXES or path.name in SOURCE_NAMES


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    manifest: list[dict[str, object]] = []
    archive_path = OUT / "NOVA_COMPLETE_SOURCE_SNAPSHOT.tar.gz"
    with tarfile.open(archive_path, "w:gz", compresslevel=9) as archive:
        for path in sorted(ROOT.rglob("*")):
            if not included(path):
                continue
            raw = path.read_bytes()
            try:
                raw.decode("utf-8")
            except UnicodeDecodeError:
                continue
            relative = path.relative_to(ROOT).as_posix()
            archive.add(path, arcname=relative, recursive=False)
            manifest.append({
                "path": relative,
                "bytes": len(raw),
                "sha256": hashlib.sha256(raw).hexdigest(),
            })
    (OUT / "NOVA_COMPLETE_SOURCE_SNAPSHOT_MANIFEST.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(json.dumps({
        "files": len(manifest),
        "archive": str(archive_path.relative_to(ROOT)),
        "archive_bytes": archive_path.stat().st_size,
        "runtime_sources_included": sum(
            1 for item in manifest
            if str(item["path"]).startswith(("lib/core/runtime/", "lib/services/runtime/"))
        ),
    }, indent=2))


if __name__ == "__main__":
    main()
