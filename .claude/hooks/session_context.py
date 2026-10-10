#!/usr/bin/env python3
"""SessionStart: tell Claude where the session runs and how far the curriculum is.

stdout from a SessionStart hook is added to Claude's context, so keep it short.
"""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

from _hooklib import project_dir

TOOLS = ["arm-none-eabi-gcc", "cmake", "omc", "renode", "robot", "st-flash", "clang-format", "ruff"]


def git(*args: str) -> str:
    r = subprocess.run(["git", *args], cwd=project_dir(), capture_output=True, text=True)
    return r.stdout.strip()


def main() -> None:
    in_container = Path("/.dockerenv").exists() or Path("/run/.containerenv").exists()
    done = sorted(t for t in git("tag", "--list", "p*-done").splitlines() if t)
    present = [t for t in TOOLS if shutil.which(t)]
    missing = [t for t in TOOLS if t not in present]
    where = (
        "devcontainer (no USB: no flashing/serial/CubeMX here)"
        if in_container
        else "macOS host (CubeMX, flashing, serial live here; OpenModelica/Renode/Robot run in the devcontainer)"
    )
    lines = [
        f"[session] environment: {where}",
        f"[session] branch: {git('rev-parse', '--abbrev-ref', 'HEAD') or '?'}; "
        f"completed projects: {', '.join(done) if done else 'none'}",
        f"[session] tools on PATH: {', '.join(present) or 'none'}; missing: {', '.join(missing) or 'none'}",
    ]
    dirty = git("status", "--porcelain")
    if dirty:
        lines.append(f"[session] working tree has {len(dirty.splitlines())} uncommitted change(s)")
    print("\n".join(lines))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
