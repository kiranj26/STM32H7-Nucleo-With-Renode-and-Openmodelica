---
paths:
  - "projects/*/README.md"
  - "projects/*/results/**"
  - "docs/**"
---

# Docs and results (the "proof of learning")

## Project README (template: `docs/templates/PROJECT_README.md`)
These sections are required and must stay in this order:
1. **Goal**: one paragraph.
2. **Platform**: CubeMX clock and peripheral choices, the Renode overlay, the FMU solver, and Ts.
3. **Features used**: a table of `Tool | Feature | Where (link to file#line)`.
4. **How to run**: the exact `make` commands.
5. **Results**: plots and a metric table. Each number links to the run folder it came from.
6. **Problems hit**: symptom, then root cause, then fix, then what it taught. This is the most valuable section; never leave it empty.
7. **What I'd do differently.**
8. **🎓 steps**: what the owner did by hand, as opposed to what Claude assisted with.

## Results
- Layout is `projects/pN_*/results/YYYY-MM-DD_<short-desc>/` with `report.html`, `log.html`, `*.png`, `run.csv` (if under about 2 MB), and `meta.json`.
- Committed results are never overwritten (a hook enforces this). Superseded runs stay, and the README links the current ones.
- Every plot says which level it came from (MIL/SIL/Renode/HW) in its title or legend.

## Writing style
- Be specific and honest. "Renode hung in `HAL_PWREx_ConfigSupply` because PWR_CSR1.ACTVOSRDY isn't modeled" beats "had clock issues".
- Never present emulation results as hardware results.
- `docs/feature-checklist.md` is updated in the same commit as the feature's first use.
