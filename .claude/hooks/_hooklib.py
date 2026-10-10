"""Shared helpers for this repo's Claude Code hooks.

Hook contract (Claude Code):
  - JSON event arrives on stdin (tool_name, tool_input, cwd, ...).
  - exit 0            -> allow / nothing to report
  - exit 2 + stderr   -> block (PreToolUse) or feed stderr back to Claude (PostToolUse)
Hooks must never crash the session: unexpected errors fall through to exit 0.
Keep this file compatible with Python 3.9 (macOS system python runs it on the host).
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import Any, Dict, Iterator, List, Optional, Tuple


def project_dir() -> Path:
    return Path(os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())).resolve()


def read_event() -> Dict[str, Any]:
    try:
        return json.load(sys.stdin)
    except Exception:
        return {}


def rel_path(file_path: str) -> Optional[str]:
    """Repo-relative POSIX path, or None if the file is outside the repo."""
    try:
        return Path(file_path).resolve().relative_to(project_dir()).as_posix()
    except (ValueError, OSError):
        return None


def edits_of(event: Dict[str, Any]) -> Iterator[Tuple[str, str, bool]]:
    """Yield (old_string, new_string, replace_all) for Edit and MultiEdit events."""
    ti = event.get("tool_input", {}) or {}
    if "edits" in ti:
        for e in ti.get("edits") or []:
            yield e.get("old_string", ""), e.get("new_string", ""), bool(e.get("replace_all"))
    elif "old_string" in ti:
        yield ti.get("old_string", ""), ti.get("new_string", ""), bool(ti.get("replace_all"))


def block(reason: str) -> None:
    print(reason, file=sys.stderr)
    sys.exit(2)


def allow() -> None:
    sys.exit(0)


def changed_files(event: Dict[str, Any]) -> List[str]:
    fp = (event.get("tool_input", {}) or {}).get("file_path")
    return [fp] if fp else []
