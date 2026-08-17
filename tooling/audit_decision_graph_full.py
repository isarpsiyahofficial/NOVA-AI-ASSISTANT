#!/usr/bin/env python3
"""Correct full-source entrypoint for the NOVA decision graph audit.

The first audit version excluded every directory literally named ``runtime`` in
an attempt to avoid generated call-lab evidence. NOVA has real source packages
under ``lib/core/runtime`` and ``lib/services/runtime``; excluding them would
invalidate an exhaustive decision audit. This entrypoint preserves those source
packages and excludes only ``infra/call-bridge/runtime`` evidence.
"""

from __future__ import annotations

import sys
from pathlib import Path

import audit_decision_graph as audit


def full_is_source(path: Path) -> bool:
    if not path.is_file():
        return False
    relative = path.relative_to(audit.ROOT)
    excluded = set(audit.EXCLUDED_PARTS) - {"runtime"}
    if any(part in excluded for part in relative.parts):
        return False
    if relative.parts[:3] == ("infra", "call-bridge", "runtime"):
        return False
    if path.suffix.lower() in audit.BINARY_OR_MODEL_SUFFIXES:
        return False
    return (
        path.suffix.lower() in audit.SOURCE_SUFFIXES
        or path.name in audit.SPECIAL_SOURCE_NAMES
    )


def main() -> int:
    audit.is_source = full_is_source
    return audit.main()


if __name__ == "__main__":
    sys.exit(main())
