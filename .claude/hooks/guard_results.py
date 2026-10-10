#!/usr/bin/env python3
"""PreToolUse guard: committed results are evidence (CLAUDE.md, hard rule 6).

Overwriting a file under projects/*/results/ that git already tracks is blocked.
New files (new dated runs) are fine.
"""

from __future__ import annotations

import re
import subprocess
from pathlib import Path

from _hooklib import allow, block, project_dir, read_event, rel_path

RESULTS = re.compile(r"^projects/p\d+_[^/]+/results/")


def is_tracked(rel: str) -> bool:
    r = subprocess.run(
        ["git", "ls-files", "--error-unmatch", rel],
        cwd=project_dir(),
        capture_output=True,
    )
    return r.returncode == 0


def main() -> None:
    event = read_event()
    file_path = (event.get("tool_input", {}) or {}).get("file_path", "")
    rel = rel_path(file_path) if file_path else None
    if rel and RESULTS.match(rel) and Path(file_path).exists() and is_tracked(rel):
        block(
            f"[guard] {rel} is committed evidence. Write a new dated run "
            "(results/YYYY-MM-DD_<desc>/) instead of overwriting it, "
            "or ask the owner to approve replacing it."
        )
    allow()


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception:
        allow()
