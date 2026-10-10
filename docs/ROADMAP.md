# Roadmap: Renode, OpenModelica, Robot Framework and control on the Nucleo-H743ZI2

This is a **sequence, not a menu.** Each project forces you into specific features of all three tools plus one new control concept, and builds on the previous one. By the end, the repository shows that the tools were learned properly, not used as black boxes.

| # | Project | New control concept | Est. time | Tag |
|---|---|---|---|---|
| P0 | Toolchain warm-up | (none) | 1–1.5 wk | `p0-done` |
| P1 | Thermal chamber | Discrete PID, anti-windup, derivative filter | 2 wk | `p1-done` |
| P2 | Coupled water tanks | Linearization, gain scheduling, feedforward | 2–3 wk | `p2-done` |
| P3 | DC motor servo | Cascaded current/speed/position loops | 3 wk | `p3-done` |
| P4 | Inverted pendulum | LQR + Kalman filter, lockstep co-sim | 3 wk | `p4-done` |
| P5 | Battery management system | Protection FSM, balancing, SOC (Coulomb + EKF) | 2–3 wk | `p5-done` |
| P6 | Capstone MIL→SIL→PIL→HW + CI | Quantization, delay, fixed-point effects | 3 wk | `p6-done` |

Architecture decisions behind this plan are recorded in [`adr/`](adr/README.md).

---

## Cross-cutting architecture (set up in P0/P1, reused everywhere)
1. **Firmware layering.**
   - `fw/common/ctrl/` is pure C99 and HAL-free, so it builds for arm and for the host. This is what makes the P6 SIL level almost free.
   - `fw/common/bsp/` is the HAL glue.
   - `fw/pN_*/app/` is the project wiring.
   - Each project's firmware is a CubeMX CMake project; see [ADR-0001](adr/0001-cubemx-cmake-firmware.md).
2. **One link protocol.** COBS framing plus CRC16 plus a message ID and sequence number, implemented once in C (`fw/common/link`) and once in Python (`tools/labkit/link.py`). The transport is pluggable: TCP to Renode, or serial to the real board. See [ADR-0004](adr/0004-cobs-link-protocol.md).
3. **Time model, evolving on purpose.**
   - **P1–P3:** firmware-driven stepping. Each Ts the firmware sends `{seq, actuation}`; the bridge steps the FMU by Ts and replies `{seq, sensors}`.
   - **P4+:** orchestrator-driven lockstep (`RunFor` Ts, then FMU `doStep` Ts), with sensors injected through peripheral models.

   See [ADR-0005](adr/0005-time-model.md).
4. **`tools/labkit`**, a Python package with these modules:
   - `fmu`: FMPy wrapper
   - `renode`: process and monitor control, snapshots
   - `bridge` and `link`: protocol plus FMU stepping
   - `metrics`: rise time, overshoot, settling time, steady-state error, IAE/ISE
   - `runlog`: CSV plus `meta.json`
   - `plots`

   Robot libraries are thin wrappers over it.
5. **Robot structure.** `tests/common/renode.resource` plus keyword libraries. `${TARGET}` (`renode|hw|sil|mil`) is selected in Suite Setup from P1 onward.
6. **Environment.** A single `linux/amd64` devcontainer runs locally and in CI. CubeMX, flashing, and serial access run on the macOS host. See [ADR-0002](adr/0002-devcontainer-amd64.md) and [dev-environment.md](dev-environment.md).

---

## P0: Toolchain warm-up
**Goal:** get every tool producing output independently before connecting anything.

| Tool | Features |
|---|---|
| CubeMX | Board selector (NUCLEO-H743ZI2), clock tree, CMake generation, USER CODE blocks |
| Renode | `.resc` (`mach create`, `LoadPlatformDescription`, `sysbus LoadELF`), `showAnalyzer`, reading the H743 `.repl` line by line, `LogPeripheralAccess` |
| OpenModelica | An RC circuit twice, graphical (OMEdit) and as text equations; `.mos` scripting; comparing results |
| Robot | `Create Terminal Tester`, `Wait For Line On Uart`, `log.html` |

**Milestones**
1. Build the devcontainer and check `omc`, `renode`, `robot`, and `arm-none-eabi-gcc` versions.
2. In CubeMX, install the STM32CubeH7 pack, create `fw/p0_blinky/p0_blinky.ioc` from the board selector, and generate CMake. Add a blinky on LD1 (PB0) plus `Hello <n>` on USART3 at 115200 baud.
3. Boot it in Renode with `projects/p0_blinky/renode/p0.resc`.
4. 🎓 **Expected pitfall:** the startup code hangs polling RCC or PWR ready flags. Find the hang with `LogPeripheralAccess` and `cpu PC`, fix it in an overlay `.repl`, and write it up.
5. 🎓 Annotate a copy of `stm32h743.repl`: memory map, NVIC wiring, real models vs. tags, and **missing peripherals** (this sets the scope of P3).
6. Write `RC_Graphical.mo` and `RC_Equations.mo`, plus an `rc.mos` that simulates both and plots the difference.
7. Write `hello.robot`, which boots and waits for `Hello`.
8. Flash the same ELF to the board and confirm the same output.

**Done when:** `make test P=p0` produces a green `log.html` in the container; CI runs it; the board prints `Hello`.

---

## P1: Thermal chamber with PID
**Goal:** the first closed loop, with the simplest possible coupling.

| Tool | Features |
|---|---|
| OpenModelica | Heater, thermal mass, and ambient loss written from scratch; nonlinear NTC (β model) sensor; parameters, initial conditions, solver and tolerance choice; `.mos` with `loadModel`/`simulate`/`buildModelFMU` (CS, `s:cvode`) |
| Renode | `CreateServerSocketTerminal` on USART2 for the plant link; `logLevel`; `sysbus LogPeripheralAccess` to see what the HAL does to the USART |
| Robot | Suite Setup/Teardown that start Renode and the bridge; variables for setpoint and ambient; assertion `\|T−SP\| < 1 °C after 300 s virtual` |
| Controller | Discrete PID: derivative on measurement with a filter, back-calculation anti-windup, bumpless setpoint change |

**Milestones:**
1. The `Lab.Thermal.Chamber` model and its bench.
2. The FMU, validated with the `fmu-export-validate` skill.
3. A reference closed loop using Modelica `LimPID`.
4. `ctrl/pid.c` with host unit tests.
5. The link protocol and the bridge.
6. A Robot suite running on Renode.
7. The same suite on the board (`TARGET:hw`, serial transport).

**Analysis:** one plot overlays the Modelica continuous PID, the Renode firmware PID, and the hardware firmware PID. The README explains the differences: ZOH delay, Ts, and quantization.

---

## P2: Coupled water tanks (nonlinear plant)
**Goal:** learn OpenModelica's model analysis features.

| Tool | Features |
|---|---|
| OpenModelica | Two tanks with Torricelli outflow (regularized √), a pump, and a valve; `linearize()` at 3–5 operating points; linear vs. nonlinear comparison; parameter sweeps with OMPython `ModelicaSystem` |
| Renode | Snapshots (`Save`/`Load`): boot once and fork every test from the snapshot. Measure the suite time saved |
| Robot | `Test Template` (data-driven setpoint and disturbance rows); `smoke`/`long` tags |
| Controller | Gain scheduling from the linearizations plus inverse-Torricelli feedforward, generated into a C header |

**Done when:** a results table and plot show that the scheduled controller beats the fixed-gain PI from P1 on IAE across operating points.

---

## P3: DC motor servo (peripheral modeling)
**Goal:** stop bypassing the hardware; firmware talks to real peripheral registers. This is the deep Renode project.

| Tool | Features |
|---|---|
| Renode | A C# quadrature encoder peripheral fed by the FMU; an ADC current-sense channel (Python first, then C#); PWM read from TIM1 CCR/ARR; `machine StartGdbServer 3333` and stepping through ISRs; `cpu AddHook` to log control-ISR runs; extending the platform with an overlay `.repl` |
| OpenModelica | Multi-domain model: `Modelica.Electrical` (R, L, EMF) with `Mechanics.Rotational` (inertia, gear, friction); stiction events; 🎓 the transformational debugger when initialization fails |
| Robot | A custom Python keyword library: `Overshoot Should Be Below`, `Rise Time ...`, `Settling Time ...`, `Steady State Error ...` |
| Controller | Cascaded current (10–20 kHz), speed (1 kHz), and position (100 Hz) loops, tuned from model parameters (pole-zero cancellation, symmetric optimum, bandwidth separation) |

**Hardware:** no motor is assumed. A `PLANT_VIA_UART` build flag runs the loops against the FMU over the VCP. Measure ISR load with DWT->CYCCNT and compare it with the Renode profiler.

---

## P4: Inverted pendulum (time-synchronized co-simulation)
**Goal:** an unstable plant that punishes timing sloppiness, which forces proper co-simulation.

| Tool | Features |
|---|---|
| OpenModelica | A MultiBody cart-pole with 3D animation, cross-checked against hand-derived equations; `linearize()` at upright → A, B → LQR |
| Renode | Lockstep virtual-time sync (`emulation RunFor` 1 ms ↔ FMU `doStep` 1 ms); global quantum and `SetAdvanceImmediately`; virtual vs. host time; `machine EnableProfiler`; execution tracing |
| Robot | Robustness sweeps (mass ±30 %, noise σ, Ts ∈ {1, 2, 5} ms) feeding a stability-map heatmap; nightly `long` runs |
| Controller | LQR plus a discrete Kalman filter (encoder plus a simulated IMU) |

**Experiment:** offset sampling by one step on purpose and show it destabilizes the loop.

---

## P5: Battery management system with fault injection
**Goal:** verification engineering, which is what Robot does best.

| Tool | Features |
|---|---|
| OpenModelica | A 4-cell pack (`Modelica.Electrical.Batteries` or a 2RC Thevenin cell) with OCV(SOC) and thermal behavior; faults as parameters plus `when` events (drift, open wire, thermal rise) exposed as FMU inputs |
| Renode | Fault injection from the monitor (memory and register writes, a frozen peripheral value, a watchdog reset); a multi-machine "charger" node over `CreateUARTHub` |
| Robot | A requirements-traceability matrix (`REQ-OV-01: overvoltage cut-off ≤ 100 ms` ...); each fault scenario forks from a healthy snapshot; `traceability.md` generated from `output.xml` |
| Controller | Protection state machine, passive balancing, SOC estimation with Coulomb counting and an EKF |

---

## P6: Capstone, MIL → SIL → PIL → HW with CI
**Goal:** tie everything together into an engineering workflow.

| Tool | Features |
|---|---|
| OpenModelica | The controller written in Modelica with clocked synchronous blocks; full MIL; exported as a source-code FMU |
| Renode | Headless in GitHub Actions; code coverage from the emulator |
| Robot | One suite, four targets (`TARGET:mil\|sil\|pil\|hw`), the same thresholds, and a per-level tolerance table; reports published as CI artifacts |
| Controller | Quantization (float vs. Q15/Q31), sampling delay, and ADC bit depth, quantified at every level |

---

## Proof of learning (every project)
- Each project folder has its own `.mo` files, `.mos` scripts, `.resc`/`.repl` files, firmware, and Robot suite.
- Each has a README built from [`templates/PROJECT_README.md`](templates/PROJECT_README.md), covering features used, problems hit, results, and reflection.
- Committed `report.html`, `log.html`, plots, and `meta.json` go in dated `results/` folders.
- [`feature-checklist.md`](feature-checklist.md) is updated as features are first used.
- Each finished project is tagged `pN-done`.

## Risks
| Risk | Mitigation |
|---|---|
| The Renode H743 platform lacks peripherals (ADC, encoder TIM, RCC behavior) | Expected. Audit in P0; overlays and custom peripherals in P3 are the planned answer |
| Renode and OpenModelica are slow under Rosetta | Short virtual runs for `smoke`, snapshots, `long` tests nightly |
| FMU solver accuracy (the default CS solver is Euler) | `--fmiFlags=s:cvode`, and validate every FMU against `simulate()` |
| No USB in Docker on macOS | Board work runs natively (`make hw`); the bridge is transport-agnostic |
| Scope creep (about 5–6 months part-time) | A "done when" per project; stretch ideas go to README "future work" |
