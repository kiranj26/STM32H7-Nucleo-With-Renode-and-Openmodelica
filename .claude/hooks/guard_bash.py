#!/usr/bin/env python3
"""PreToolUse guard for Bash: catch the mistakes permission prefixes can't express."""

from __future__ import annotations

import re

from _hooklib import allow, block, read_event

RULES = [
    (
        re.compile(r"\bgit\s+push\b.*\s(--force(-with-lease)?|-f)\b"),
        "Force-push is not allowed. Rewrite history only with the owner's explicit OK.",
    ),
    (
        re.compile(r"\brm\s+-[a-zA-Z]*r[a-zA-Z]*\s+.*projects/[^ ]*/results"),
        "projects/*/results/ is committed evidence; don't delete it.",
    ),
    (
        re.compile(r"\b(st-flash|STM32_Programmer_CLI)\b.*(\berase\b|-e\s+all|--erase)"),
        "Mass-erase of the board is not allowed from Claude. Ask the owner.",
    ),
    (
        re.compile(r"\bsed\s+-i\b.*\.ioc\b"),
        ".ioc files are changed in the CubeMX GUI only, never by sed.",
    ),
    (
        re.compile(r"(^|[;&|]\s*)sleep\s+\d{2,}"),
        "Don't wait on wall-clock time. Use virtual time (emulation RunFor) or a Robot "
        "'Wait For ...' keyword with a timeout.",
    ),
]


def main() -> None:
    cmd = (read_event().get("tool_input", {}) or {}).get("command", "")
    for pattern, reason in RULES:
        if pattern.search(cmd):
            block(f"[guard] {reason}\nCommand: {cmd}")
    allow()


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception:
        allow()
