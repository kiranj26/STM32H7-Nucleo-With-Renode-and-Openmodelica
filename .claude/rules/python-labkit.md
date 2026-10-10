---
paths:
  - "tools/**/*.py"
  - "projects/**/*.py"
  - "tests/**/*.py"
---

# Python (labkit, bridges, scripts)

- **Python 3.11** in the container. Hook scripts in `.claude/hooks/` are the exception: they must also run on macOS system Python 3.9.
- `tools/labkit` is an installable package (`pip install -e tools/labkit`). Scripts in `projects/**` import from it rather than copy code.
- Type hints on public functions. `ruff` handles lint and formatting; the hook formats automatically.
- **Tests:** pytest in `tools/labkit/tests/`. `metrics.py` is tested against analytic responses (first- and second-order step) with known overshoot, rise time, and settling time.
- **Timing:** co-simulation never uses `time.sleep` for synchronization. Progress is driven by virtual time (FMU `doStep` and Renode `RunFor`) or by protocol request/response.
- **Run logging:** every experiment writes through `labkit.runlog`, producing a CSV with SI units in column names (`t_virtual_s`, `T_degC`, `duty_pct`) plus a `meta.json` containing the git SHA, parameters, FMU hash, and tool versions.
- **Plots:** use `labkit.plots` for a consistent style. Save PNG at 150 dpi with labeled axes and units, and a title that names the project and the experiment.
- **Transports:** `labkit.link` speaks TCP (Renode) and serial (board) through the same interface. Port numbers and device paths come from arguments or environment variables, never constants.
