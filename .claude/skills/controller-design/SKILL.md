---
name: controller-design
description: Model-based controller design pipeline - operating point → linearize (OMC/OMPython) → design (PID/scheduling/cascade/LQR/KF) in python-control → discretize at Ts → generate gains header for firmware → verify against MIL reference with labkit.metrics. Use when (re)designing or retuning any controller.
argument-hint: "<N> <controller type>"
---

# Controller design pipeline: $ARGUMENTS

Hand the design reasoning to the **controls-engineer** agent. This skill fixes the *pipeline*, so every project produces the same artifacts.

## Artifacts
| Step | File |
|---|---|
| Design script | `projects/pN_*/scripts/design_<ctrl>.py` |
| Linearization results | `build/design/pN/lin_<op>.npz` |
| Generated header | `fw/pN_*/app/gains_generated.h` (committed) |
| Design report | `projects/pN_*/results/YYYY-MM-DD_design/` (Bode/step/pole plots plus `meta.json`) |

## Steps
1. **Requirements:** take them from the Robot suite thresholds (settling, overshoot, steady-state error) and the actuator limits. Write them at the top of the design script.
2. **Operating points:** pick steady states, and justify them (setpoint range, worst case).
3. **Linearize:** OMPython `ModelicaSystem(...).linearize()` or `omc` `linearize()`. Check that the eigenvalues match the expected physics.
4. **Design** in continuous time or directly in discrete time, using `python-control`. Print the margins and closed-loop poles.
5. **Discretize** at the firmware Ts (Tustin unless there's a stated reason otherwise). Check stability of the discrete loop, including **one sample of computational delay**.
6. **Generate the header.** Its banner holds: script path, git SHA, date, Ts, operating points, and method. Values are `static const float` with units in the names. Never hand-edit it; regenerate.
7. **Verify in MIL:** run the same discrete controller in Python against the FMU (or a Modelica discrete block), and compute `labkit.metrics` against the requirements.
8. **Report:** a table of design targets vs. predicted vs. MIL-achieved, plus plots. Renode and HW comparisons come later in `run-suite`.

🎓 **Default:** the owner does steps 4–5 (the math); Claude builds the scaffolding and checks. Ask if unsure.
