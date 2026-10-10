#!/usr/bin/env python3
"""PostToolUse: keep fw/common/ctrl/ portable (CLAUDE.md, hard rule 2).

If an edited file under fw/common/ctrl/ includes HAL/CMSIS headers, calls HAL_*, or touches
registers, report it back to Claude (exit 2 on PostToolUse = feedback; the edit already happened).
"""

from __future__ import annotations

import re
from pathlib import Path

from _hooklib import allow, block, changed_files, read_event, rel_path

CTRL = re.compile(r"^fw/common/ctrl/.*\.(c|h)$")
FORBIDDEN = [
    (re.compile(r'#\s*include\s*[<"](stm32\w*|main|core_cm\w*|cmsis\w*)\.h[>"]'), "HAL/CMSIS include"),
    (re.compile(r"\bHAL_\w+\s*\("), "HAL_* call"),
    (re.compile(r"\b(__disable_irq|__enable_irq|__DSB|__ISB|NVIC_\w+)\b"), "CMSIS intrinsic"),
    (re.compile(r"\b(TIM|USART|GPIO[A-K]?|ADC|RCC)\d*\s*->"), "direct register access"),
]


def main() -> None:
    problems = []
    for fp in changed_files(read_event()):
        rel = rel_path(fp)
        if not rel or not CTRL.match(rel) or not Path(fp).exists():
            continue
        for n, line in enumerate(Path(fp).read_text(errors="replace").splitlines(), 1):
            for pattern, what in FORBIDDEN:
                if pattern.search(line):
                    problems.append(f"  {rel}:{n}: {what}: {line.strip()}")
    if problems:
        block(
            "[ctrl-portability] fw/common/ctrl/ must stay HAL-free so it builds on the host "
            "(make unit, P6 SIL). Move hardware access to fw/common/bsp/ or app/ and pass "
            "values in as plain arguments:\n" + "\n".join(problems)
        )
    allow()


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception:
        allow()
