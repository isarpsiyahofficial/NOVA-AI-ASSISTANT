#!/usr/bin/env python3
"""Classify NOVA Dart files by active import reachability and quarantine dormant decision roots.

The classifier treats lib/main.dart plus explicit Dart VM entry points as roots,
resolves relative and package:nova imports/exports/parts, and keeps a checked-in
quarantine manifest. A dormant decision file re-entering the active graph breaks
strict CI until it is intentionally removed from the manifest after review.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, asdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"
DEFAULT_MANIFEST = ROOT / "tooling" / "nova_decision_quarantine_manifest.json"
IMPORT_RE = re.compile(r"^\s*(?:import|export|part)\s+['\"]([^'\"]+)['\"]", re.MULTILINE)
DECISION_RE = re.compile(
    r"(?:decision|authority|policy|brain|orchestrator|router|executor|guard|gate|"
    r"manager|controller|planner|reasoner|classifier|resolver|runtime|companion|"
    r"call|phone|action|speech|tts|stt|asr)",
    re.IGNORECASE,
)
DECISION_CONTENT_RE = re.compile(
    r"\b(?:class|enum)\s+Nova\w*(?:Decision|Authority|Policy|Brain|Orchestrator|"
    r"Router|Executor|Guard|Gate|Manager|Controller|Planner|Reasoner|Resolver)",
    re.IGNORECASE,
)

@dataclass(frozen=True)
class Classification:
    path: str
    active: bool
    decision_surface: bool
    incoming_active_imports: int
    bytes: int
    lines: int
    category: str


def dart_files() -> dict[str, str]:
    result: dict[str, str] = {}
    for path in sorted(LIB.rglob("*.dart")):
        rel = path.relative_to(ROOT).as_posix()
        result[rel] = path.read_text(encoding="utf-8", errors="replace")
    return result


def resolve_import(source: str, imported: str, all_paths: set[str]) -> str | None:
    if imported.startswith("dart:") or imported.startswith("package:flutter"):
        return None
    if imported.startswith("package:nova/"):
        candidate = "lib/" + imported[len("package:nova/"):]
    elif imported.startswith("package:"):
        return None
    else:
        try:
            candidate = (ROOT / Path(source).parent / imported).resolve().relative_to(ROOT).as_posix()
        except ValueError:
            return None
    return candidate if candidate in all_paths else None


def build_graph(texts: dict[str, str]) -> tuple[dict[str, list[str]], dict[str, int]]:
    paths = set(texts)
    graph: dict[str, list[str]] = {}
    incoming = {path: 0 for path in paths}
    for source, text in texts.items():
        edges = []
        for imported in IMPORT_RE.findall(text):
            target = resolve_import(source, imported, paths)
            if target and target not in edges:
                edges.append(target)
                incoming[target] += 1
        graph[source] = sorted(edges)
    return graph, incoming


def roots(texts: dict[str, str]) -> list[str]:
    result = ["lib/main.dart"] if "lib/main.dart" in texts else []
    for path, text in texts.items():
        if path == "lib/main.dart":
            continue
        if "@pragma('vm:entry-point')" in text or '@pragma("vm:entry-point")' in text:
            result.append(path)
    return sorted(set(result))


def reachable(graph: dict[str, list[str]], start: list[str]) -> set[str]:
    seen: set[str] = set()
    stack = list(start)
    while stack:
        item = stack.pop()
        if item in seen:
            continue
        seen.add(item)
        stack.extend(graph.get(item, ()))
    return seen


def is_decision_surface(path: str, text: str) -> bool:
    name = Path(path).stem
    return bool(DECISION_RE.search(name) or DECISION_CONTENT_RE.search(text))


def category(active: bool, decision: bool, incoming: int, text: str) -> str:
    if active:
        return "active_decision_graph" if decision else "active_support"
    if decision:
        if incoming == 0 and len(text.splitlines()) < 180:
            return "archive_candidate"
        return "dormant_decision"
    if incoming == 0:
        return "delete_review_candidate"
    return "dormant_support"


def load_manifest(path: Path) -> set[str]:
    if not path.exists():
        return set()
    raw = json.loads(path.read_text(encoding="utf-8"))
    values = raw.get("quarantinedDecisionFiles", []) if isinstance(raw, dict) else []
    return {str(value) for value in values}


def write_manifest(path: Path, quarantined: list[str]) -> None:
    payload = {
        "schema": 1,
        "policy": "A listed dormant decision file may not re-enter the active Dart import graph without explicit architectural review.",
        "quarantinedDecisionFiles": quarantined,
    }
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--write-manifest", action="store_true")
    parser.add_argument("--manifest", default=str(DEFAULT_MANIFEST.relative_to(ROOT)))
    parser.add_argument("--output-dir", default="build/nova-quarantine-audit")
    args = parser.parse_args()

    texts = dart_files()
    graph, incoming = build_graph(texts)
    active = reachable(graph, roots(texts))
    rows: list[Classification] = []
    for path, text in texts.items():
        decision = is_decision_surface(path, text)
        is_active = path in active
        rows.append(Classification(
            path=path,
            active=is_active,
            decision_surface=decision,
            incoming_active_imports=sum(1 for source in active if path in graph.get(source, ())),
            bytes=len(text.encode("utf-8")),
            lines=len(text.splitlines()),
            category=category(is_active, decision, incoming[path], text),
        ))

    dormant_decisions = sorted(row.path for row in rows if not row.active and row.decision_surface)
    manifest_path = ROOT / args.manifest
    if args.write_manifest:
        write_manifest(manifest_path, dormant_decisions)
    manifest = load_manifest(manifest_path)
    reactivated = sorted(manifest & active)
    missing_manifest_files = sorted(manifest - set(texts))

    counts: dict[str, int] = {}
    for row in rows:
        counts[row.category] = counts.get(row.category, 0) + 1
    report = {
        "schema": 1,
        "roots": roots(texts),
        "summary": {
            "dartFiles": len(rows),
            "activeDartGraph": len(active),
            "dormantDecisionFiles": len(dormant_decisions),
            "quarantineManifestEntries": len(manifest),
            "reactivatedQuarantineViolations": len(reactivated),
            "missingManifestFiles": len(missing_manifest_files),
            **counts,
        },
        "reactivatedQuarantineViolations": reactivated,
        "missingManifestFiles": missing_manifest_files,
        "files": [asdict(row) for row in sorted(rows, key=lambda row: row.path)],
        "activeImportGraph": {path: graph[path] for path in sorted(active)},
    }
    output = ROOT / args.output_dir
    output.mkdir(parents=True, exist_ok=True)
    (output / "NOVA_QUARANTINE_CLASSIFICATION.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    md = [
        "# NOVA Dormant Decision Quarantine",
        "",
        f"- Dart files: **{len(rows)}**",
        f"- Active Dart graph: **{len(active)}**",
        f"- Dormant decision files: **{len(dormant_decisions)}**",
        f"- Reactivated quarantine violations: **{len(reactivated)}**",
        "",
    ]
    if reactivated:
        md += ["## Blocking reactivations", ""] + [f"- `{path}`" for path in reactivated]
    (output / "NOVA_QUARANTINE_CLASSIFICATION.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    print(json.dumps(report["summary"], ensure_ascii=False, indent=2))
    return 1 if args.strict and reactivated else 0

if __name__ == "__main__":
    sys.exit(main())
