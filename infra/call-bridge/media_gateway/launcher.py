#!/usr/bin/env python3
"""Start the NOVA media gateway with the supported Sherpa speech runtime."""

from __future__ import annotations

import service
from speech_runtime import VerifiedSherpaSpeechEngine


def main() -> int:
    service.SherpaSpeechEngine = VerifiedSherpaSpeechEngine
    return service.main()


if __name__ == "__main__":
    raise SystemExit(main())
