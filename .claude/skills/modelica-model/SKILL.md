---
name: modelica-model
description: Create or extend a Modelica plant model following repo conventions - Lab package placement, SI units, explicit initialization, documented assumptions, FMU-ready interfaces, a test bench, and a .mos script that simulates and plots it. Use when adding a new plant or component.
argument-hint: "<Lab.Package.ModelName> [short description]"
---

# New Modelica model: $ARGUMENTS

1. **Contract first.** Agree on these with the owner (ask if unclear), and write them down:
   - the physical scope and assumptions (lumped, isothermal, ...)
   - states, inputs, and outputs with units and ranges (these become the FMU interface)
   - parameter values with their sources (datasheet, textbook, or estimate, and why)
   - the dominant time constants, which drive the controller's Ts
2. **Place it.** Reusable components go in `models/Lab/<Package>/<Model>.mo`; update `package.order`. The test bench goes in `projects/pN_*/model/<Model>Bench.mo` and uses `extends` or instantiation.
3. **Write it** per `.claude/rules/modelica.md`:
   - `Modelica.Units.SI` types
   - `fixed=true` / `initial equation`
   - regularized nonlinearities
   - `RealInput`/`RealOutput` ports
   - a `documentation(info="<html>...</html>")` annotation with the equations
   - `experiment(StopTime=..., Tolerance=...)` on the bench

   🎓 **P0–P2:** the owner writes the equations, and Claude reviews and explains.
4. **Script it.** `projects/pN_*/scripts/<model>.mos`: load MSL and Lab, `checkModel`, then `simulate` with an explicit method and tolerance and CSV output, with `getErrorString()` after each call.
5. **Run it:** `omc projects/pN_*/scripts/<model>.mos`. If it fails, show the errors and hand off to the **modelica-modeler** agent for initialization or event problems.
6. **Sanity checks**, each stated in the README:
   - steady state matches the hand calculation
   - time constants match the expectation
   - energy and mass balance where applicable
7. **Plot** with `labkit.plots` into `build/` for review. Only commit the chosen plots, to `results/`.
