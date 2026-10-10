---
paths:
  - "**/*.mo"
  - "**/*.mos"
  - "models/**"
  - "tools/labkit/fmu.py"
---

# Modelica / OpenModelica rules

## Structure
- Shared, reusable classes go in the package `models/Lab/` (`Lab.Thermal`, `Lab.Hydraulics`, `Lab.Motor`, `Lab.Pendulum`, `Lab.Battery`, `Lab.Control`, `Lab.Sensors`). Use one class per file and keep `package.order` files up to date.
- Project-specific experiments (test benches) go in `projects/pN_*/model/` and `extends` or instantiate `Lab.*` classes.
- Every model has a `documentation(info=...)` annotation stating its purpose, its assumptions, and the reference for the equations.

## Modeling conventions
- **Units on every variable and parameter.** Use `Modelica.Units.SI` types (MSL 4.x). Physical parameters carry `min`, and `nominal` where scaling matters.
- Initial conditions are explicit: `fixed=true` on states, or an `initial equation` section. Avoid relying on default `start` values.
- **Nonlinearities near singular points get regularized**, for example `sqrt` at h→0 or friction at ω→0, using `smooth`, `noEvent`, or a regularized function. Comment why each one is there.
- Inputs and outputs that become FMU ports use `Modelica.Blocks.Interfaces.RealInput/RealOutput` with descriptive names and units (`duty`, `T_meas_degC`).

## Scripting (no GUI-only results)
- Every result in a README comes from a `.mos` script under `projects/pN_*/scripts/`. The script runs `loadModel(Modelica, {"4.0.0"})`, `loadFile(...)`, `simulate(..., stopTime=, tolerance=, method=, outputFormat="csv")`, and checks `getErrorString()` after each call.
- Solver, tolerance, and step size are stated in the script and the README, never left as defaults by accident.

## FMU export
- Use `buildModelFMU(Model, version="2.0", fmuType="cs", fileNamePrefix="<name>", platforms={"static"})`.
- Use CVODE for co-simulation: `setCommandLineOptions("--fmiFlags=s:cvode")`. The default CS solver is explicit Euler, a known accuracy trap.
- **Validate before use:** run the `fmu-export-validate` skill to compare FMU stepping (FMPy) against `simulate()` output. A max-error threshold is stated per project.

## Debugging
- On initialization failures, use `-d=initialization`, `-d=infoXmlOperations`, and the OMEdit transformational debugger. Write down what the problem was in the project README under "Problems hit".
