"""P0: compare the `Hello` period on the board (two ELFs) with Renode and with theory.

Inputs are committed evidence only:
  results/2026-10-10_hw_hello/uart.log          HW, Mac-built ELF (host timestamps)
  results/2026-10-10_hw_container_elf/uart.log  HW, canonical container ELF
  results/2026-10-10_renode_robot/robot_output.xml  Renode, "period_ms=..." test message
Usage (repo root):  python projects/p0_blinky/scripts/plot_hello_period.py <out_dir>
"""

from __future__ import annotations

import itertools
import json
import re
import statistics
import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

RESULTS = Path("projects/p0_blinky/results")
EXPECTED_MS = 501.0  # HAL_Delay(500) = 501 SysTick ticks; UART TX adds ~0.9 ms on HW


def hw_intervals_ms(log: Path) -> list[float]:
    """Intervals between consecutive `Hello n` lines (n >= 1) of a capture_uart.pl log."""
    times = []
    for line in log.read_text().splitlines():
        stamp, _, text = line.partition(" ")
        if re.fullmatch(r"Hello [1-9]\d*", text.strip()):
            times.append(float(stamp))
    return [(b - a) * 1e3 for a, b in itertools.pairwise(times)]


def renode_period_ms(output_xml: Path) -> float:
    match = re.search(r"period_ms=([0-9.]+)", output_xml.read_text())
    if match is None:
        raise SystemExit(f"error: no period_ms in {output_xml}")
    return float(match.group(1))


def main() -> int:
    out_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("build/plots/p0")
    out_dir.mkdir(parents=True, exist_ok=True)

    hw_mac = hw_intervals_ms(RESULTS / "2026-10-10_hw_hello/uart.log")
    hw_cont = hw_intervals_ms(RESULTS / "2026-10-10_hw_container_elf/uart.log")
    renode = renode_period_ms(RESULTS / "2026-10-10_renode_robot/robot_output.xml")

    fig, ax = plt.subplots(figsize=(8, 4.5))
    ax.plot(range(1, len(hw_mac) + 1), hw_mac, "o-", ms=3, label="HW, Mac-built ELF")
    ax.plot(range(1, len(hw_cont) + 1), hw_cont, "s-", ms=3, label="HW, container ELF")
    ax.axhline(
        renode, color="tab:green", label=f"Renode (virtual time) {renode:.3f} ms"
    )
    ax.axhline(
        EXPECTED_MS, color="k", linestyle=":", label=f"theory {EXPECTED_MS:.0f} ms"
    )
    ax.set_xlabel("interval index (Hello n-1 → Hello n)")
    ax.set_ylabel("period [ms]")
    ax.set_title(
        "P0 Hello period - HW vs. Renode (HW timestamps: host clock, ±3 ms USB jitter)"
    )
    ax.legend(loc="center right")
    ax.grid(True, alpha=0.3)
    fig.tight_layout()
    fig.savefig(out_dir / "hello_period.png", dpi=150)

    metrics = {
        "expected_ms": EXPECTED_MS,
        "renode_ms": renode,
        "hw_mac_elf_mean_ms": statistics.fmean(hw_mac),
        "hw_container_elf_mean_ms": statistics.fmean(hw_cont),
        # Renode sends UART bytes instantly; on HW each ~10-char line also blocks
        # ~0.9 ms in HAL_UART_Transmit at 115200 baud, so the fair HW reference is ~501.9 ms.
        "hw_vs_renode_pct": 100 * (statistics.fmean(hw_cont) / renode - 1),
        "hw_expected_with_tx_ms": EXPECTED_MS + 0.9,
        "hw_vs_hw_expected_pct": 100
        * (statistics.fmean(hw_cont) / (EXPECTED_MS + 0.9) - 1),
        "n_intervals": [len(hw_mac), len(hw_cont)],
    }
    (out_dir / "metrics.json").write_text(json.dumps(metrics, indent=2) + "\n")
    print(json.dumps(metrics, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
