#!/usr/bin/env python3
"""PostToolUse: auto-format hand-written source after an edit.

- C/H in fw/common/** and fw/pN_*/app/**    -> clang-format -i (needs repo .clang-format)
- Python in tools/**, tests/**, projects/** -> ruff format
CubeMX-generated files are never touched. A missing formatter is silently skipped,
because the macOS host may not have one installed (the devcontainer does).
"""

from __future__ import annotations

import re
import shutil
import subprocess

from _hooklib import allow, changed_files, project_dir, read_event, rel_path

C_OWNED = re.compile(r"^fw/(common/|p\d+_[^/]+/app/).*\.(c|h)$")
PY_OWNED = re.compile(r"^(tools|tests|projects)/.*\.py$")


def run(cmd: list) -> None:
    subprocess.run(cmd, cwd=project_dir(), capture_output=True, timeout=25)


def main() -> None:
    for fp in changed_files(read_event()):
        rel = rel_path(fp)
        if not rel:
            continue
        if C_OWNED.match(rel) and shutil.which("clang-format") and (project_dir() / ".clang-format").exists():
            run(["clang-format", "-i", "--style=file", rel])
        elif PY_OWNED.match(rel) and shutil.which("ruff"):
            run(["ruff", "format", "--quiet", rel])
    allow()


if __name__ == "__main__":
    try:
        main()
    except Exception:
        allow()
