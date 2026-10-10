---
name: fmu-export-validate
description: Export a Modelica plant as an FMI 2.0 co-simulation FMU from OpenModelica (CVODE inside) and validate it against the native simulate() result by stepping it with FMPy at the controller's Ts - reports max error and plots. Use whenever a plant model changes, before any closed-loop test depends on it.
argument-hint: "<N> <Lab.Model> <Ts_seconds>"
---

# Export and validate FMU: $ARGUMENTS

## 1. Export (container)
In `projects/pN_*/scripts/pN_fmu.mos`:
```
loadModel(Modelica,{"4.0.0"}); getErrorString();
loadFile("models/Lab/package.mo"); getErrorString();
setCommandLineOptions("--fmiFlags=s:cvode"); getErrorString();
buildModelFMU(<Model>, version="2.0", fmuType="cs", fileNamePrefix="pN_plant", platforms={"static"}); getErrorString();
```
Output goes to `build/fmu/pN_plant.fmu` (gitignored). Inspect it with `python -m fmpy info build/fmu/pN_plant.fmu`: list the inputs, outputs, and parameters, and check they match the README contract (names and units).

## 2. Reference
Run `simulate(<Model>, ...)` with a defined input profile (a step, or a `CombiTimeTable` with the same profile), method dassl, tolerance 1e-6.

## 3. Step the FMU
In Python (`labkit.fmu`): apply the same input profile held constant over each Ts (ZOH, like the firmware), step from 0 to stopTime, and log through `labkit.runlog`.

## 4. Compare
Interpolate onto common time points and report max |error| and RMS error per output. Set the threshold per project in the README; the default is 1% of output range.
- **Pass:** note "FMU validated, max err X" in the README "Platform" section, with a link to the run folder.
- **Fail:** check the solver flag (Euler vs CVODE), the step size relative to the fastest time constant, event handling, and whether the input interpolation matches ZOH. Explain which one it was.

## 5. Plot
Overlay the reference and FMU outputs, with a residual subplot, saved to the run folder.

A Robot or pytest check (`test_fmu_matches_reference`) should be added so CI catches model regressions.
