"""P0 milestone 6: compare the two RC models with each other and with the analytic solution.

Reads the CSVs written by scripts/p0.mos (build/sim/p0/), writes a plot and metrics.json.
Usage (devcontainer, repo root):  python projects/p0_blinky/scripts/rc_compare.py [sim_dir]
"""

from __future__ import annotations

import csv
import json
import math
import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")  # headless: no display in the container
import matplotlib.pyplot as plt

R_OHM = 1e3
C_F = 1e-6
V0_V = 3.3
TAU_S = R_OHM * C_F


def read_column(path: Path, column: str) -> tuple[list[float], list[float]]:
    """Return (time, column) from an OpenModelica CSV result file."""
    with path.open(newline="") as f:
        rows = list(csv.DictReader(f))
    return [float(r["time"]) for r in rows], [float(r[column]) for r in rows]


def main() -> int:
    sim_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("build/sim/p0")
    t_g, v_g = read_column(sim_dir / "rc_graphical_res.csv", "capacitor.v")
    t_e, v_e = read_column(sim_dir / "rc_equations_res.csv", "v")
    if t_g != t_e:
        print("error: the two results are on different time grids", file=sys.stderr)
        return 1

    v_a = [V0_V * (1.0 - math.exp(-t / TAU_S)) for t in t_g]
    d_models = [g - e for g, e in zip(v_g, v_e)]
    d_analytic = [e - a for e, a in zip(v_e, v_a)]
    i_tau = min(range(len(t_g)), key=lambda i: abs(t_g[i] - TAU_S))

    metrics = {
        "level": "MIL",
        "R_ohm": R_OHM,
        "C_F": C_F,
        "V0_V": V0_V,
        "tau_s": TAU_S,
        "solver": "dassl",
        "tolerance": 1e-6,
        "n_points": len(t_g),
        "max_abs_graphical_minus_equations_V": max(abs(d) for d in d_models),
        "max_abs_equations_minus_analytic_V": max(abs(d) for d in d_analytic),
        "v_at_tau_V": v_e[i_tau],
        "v_at_tau_expected_V": V0_V * (1.0 - math.exp(-1.0)),
        "v_final_V": v_e[-1],
    }

    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(8, 6), sharex=True)
    t_ms = [t * 1e3 for t in t_g]
    ax1.plot(t_ms, v_g, label="RC_Graphical (MSL components)", linewidth=3, alpha=0.5)
    ax1.plot(t_ms, v_e, "--", label="RC_Equations (hand-written ODE)")
    ax1.plot(t_ms, v_a, ":", color="k", label="analytic $V_0(1-e^{-t/\\tau})$")
    ax1.axvline(TAU_S * 1e3, color="grey", linewidth=0.8)
    ax1.annotate(
        "t = τ → 63.2 %",
        (TAU_S * 1e3, v_e[i_tau]),
        xytext=(5, -15),
        textcoords="offset points",
    )
    ax1.set_ylabel("capacitor voltage v [V]")
    ax1.set_title("P0 RC circuit - MIL (OpenModelica 1.27.1, DASSL, rtol 1e-6)")
    ax1.legend(loc="lower right")
    ax1.grid(True, alpha=0.3)

    ax2.plot(t_ms, [d * 1e6 for d in d_models], label="graphical - equations")
    ax2.plot(t_ms, [d * 1e6 for d in d_analytic], label="equations - analytic")
    ax2.set_xlabel("time [ms]")
    ax2.set_ylabel("difference [µV]")
    ax2.legend(loc="upper right")
    ax2.grid(True, alpha=0.3)

    fig.tight_layout()
    fig.savefig(sim_dir / "rc_compare.png", dpi=150)
    (sim_dir / "metrics.json").write_text(json.dumps(metrics, indent=2) + "\n")
    print(json.dumps(metrics, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
