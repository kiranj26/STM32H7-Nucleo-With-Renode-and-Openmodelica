<p align="center">
  <img src="docs/images/banner.svg" alt="STM32H7 Control Lab: closed-loop embedded control from model to emulator to silicon" width="100%">
</p>

<p align="center">
  <img alt="MCU" src="https://img.shields.io/badge/MCU-STM32H743ZI%20(Cortex--M7)-03234B?logo=stmicroelectronics&logoColor=white">
  <img alt="Board" src="https://img.shields.io/badge/board-Nucleo--H743ZI2-3CB4E6">
  <img alt="Emulator" src="https://img.shields.io/badge/emulation-Renode-F97316">
  <img alt="Modeling" src="https://img.shields.io/badge/modeling-OpenModelica%20%2B%20FMI%202.0-3B82F6">
  <img alt="Tests" src="https://img.shields.io/badge/tests-Robot%20Framework-22C55E?logo=robotframework&logoColor=white">
  <img alt="Status" src="https://img.shields.io/badge/status-P0%20done%20%C2%B7%20P1%20next-brightgreen">
  <a href="https://github.com/kiranj26/STM32H7-Nucleo-With-Renode-and-Openmodelica/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/kiranj26/STM32H7-Nucleo-With-Renode-and-Openmodelica/actions/workflows/ci.yml/badge.svg"></a>
</p>

<p align="center">
  <b>A 7-project curriculum for building and verifying closed-loop control firmware on an STM32H7.</b><br>
  Physical plants are modeled in <b>OpenModelica</b>, firmware runs unmodified in the <b>Renode</b> emulator and on a real <b>Nucleo-H743ZI2</b>,<br>
  and <b>Robot Framework</b> checks every result against written requirements.
</p>

<p align="center">
  <a href="#-the-idea">Idea</a> ·
  <a href="#-how-it-fits-together">Architecture</a> ·
  <a href="#-roadmap">Roadmap</a> ·
  <a href="#-whats-in-each-project">Projects</a> ·
  <a href="#-getting-started">Getting started</a> ·
  <a href="#-repository-layout">Layout</a> ·
  <a href="#-documentation">Docs</a>
</p>

---

## 💡 The idea

Most embedded control projects stop at "it works on my board". This repo goes further. The **same controller** is checked at four levels of realism, and each project leaves evidence that can be reproduced:

- 🧪 **Model the physics properly.** Thermal chambers, nonlinear tanks, DC motors, an inverted pendulum, and a battery pack are written in Modelica, then exported as FMUs.
- 🖥️ **Run the real firmware without hardware.** The firmware runs in Renode on an emulated STM32H743, with the plant in the loop and timing in deterministic virtual time.
- 🔌 **Then run it on silicon.** The same ELF runs on a Nucleo-H743ZI2, with the plant model connected over USB.
- ✅ **Verify like a product team.** Tests are named after requirements, tagged smoke, long, and hardware, traced to requirement IDs, and run in CI.
- 📈 **Use control theory, not trial and error.** Gains come from scripts that use the model's linearization: PID, gain scheduling, cascaded loops, LQR, Kalman filter, and EKF.

> **Status (2026-10-11):** **P0 (toolchain warm-up) is complete.** One firmware binary (`sha256 50ac07ca…`), built in a pinned devcontainer, runs on the Nucleo-H743ZI2 and in Renode with 5/5 Robot tests green in CI; OpenModelica reproduces an RC circuit within 3.8 µV of the exact solution. Results, findings and how to reproduce them: **[projects/p0_blinky](projects/p0_blinky/README.md)**. **P1 (thermal chamber, first closed loop) is next.**

---

## 🧩 How it fits together

<p align="center">
  <img src="docs/images/architecture.svg" alt="Robot Framework orchestrates an OpenModelica plant FMU, the Python labkit bridge, and STM32H743 firmware in Renode or on the Nucleo board" width="100%">
</p>

| Piece | Role |
|---|---|
| **OpenModelica** | Plant models (`models/Lab/…`) scripted with `.mos`, linearized for controller design, and exported as FMI 2.0 co-simulation FMUs (CVODE inside). |
| **labkit** (Python) | Steps the FMU, speaks a COBS + CRC16 binary protocol to the firmware over TCP (Renode) or serial (board), and logs runs with metadata. |
| **Renode** | Emulates the STM32H743 so the **unmodified firmware ELF** runs with real registers, ISRs, and timers. Custom peripherals are added where needed (encoder, ADC). |
| **Firmware** | STM32CubeMX-generated HAL project. Control algorithms sit in a HAL-free C layer, so the same code also builds on the host for SIL. |
| **Robot Framework** | Boots the stack, runs requirement-style tests in virtual time, and produces `log.html` / `report.html`. |

The time model evolves on purpose. In **P1–P3** the firmware drives stepping, one FMU step per control tick. From **P4** an orchestrator runs Renode and the FMU in lockstep. The reasons are written up in [ADR-0005](docs/adr/0005-time-model.md).

### One suite, four levels

<p align="center">
  <img src="docs/images/verification-ladder.svg" alt="MIL to SIL to PIL to HW verification ladder" width="100%">
</p>

---

## 🗺️ Roadmap

| | Project | Plant | Control concept | Key tool features | Status |
|---|---|---|---|---|---|
| **P0** | Toolchain warm-up | RC circuit | (none) | `.resc`/`.repl` + overlay, Modelica components vs. equations, first Robot tests, devcontainer + CI | ✅ [done](projects/p0_blinky/README.md) |
| **P1** | Thermal chamber | Heater + thermal mass + NTC | Discrete PID, anti-windup, D-filter | `.mos` scripting, FMU export, socket bridge, Suite Setup | ⏳ next |
| **P2** | Coupled water tanks | Torricelli outflow, pump, valve | Gain scheduling + feedforward | `linearize()`, OMPython sweeps, Renode snapshots, test templates | ⬜ |
| **P3** | DC motor servo | Electrical + rotational + friction | Cascaded current/speed/position loops | Custom C# peripherals, GDB, CPU hooks, transformational debugger | ⬜ |
| **P4** | Inverted pendulum | MultiBody cart-pole | LQR + Kalman filter | Lockstep virtual-time co-sim, profiler, robustness sweeps | ⬜ |
| **P5** | Battery management | 4-cell pack with fault modes | Protection FSM, balancing, SOC (EKF) | Fault injection, multi-machine, requirement traceability | ⬜ |
| **P6** | Capstone | (any of the above) | Quantization, delay, fixed-point | Clocked Modelica, MIL→SIL→PIL→HW, CI with coverage | ⬜ |

Full detail, including milestones, done-when criteria, and risks: **[docs/ROADMAP.md](docs/ROADMAP.md)**.

---

## 🔬 What's in each project

<details>
<summary><b>P0: Toolchain warm-up</b>: every tool producing output on its own</summary>

- CubeMX project from the NUCLEO-H743ZI2 board preset (HSE bypass → PLL1 → 400 MHz), generated as CMake: blinky plus `Hello` on the ST-LINK VCP (USART3).
- A pinned `linux/amd64` devcontainer and a Makefile (`doctor`, `lint`, `fw`, `sim`, `test`, `hw`); the container-built ELF is the one canonical binary, flashed from the Mac via the bind mount.
- The ELF boots in Renode from a hand-written `.resc` plus an overlay (DBGMCU reports silicon rev V, so the emulated boot takes the same path as the board); the H743 platform is annotated line by line, including which clocks Renode re-times (SysTick, timers) and which it doesn't (DWT).
- The same RC circuit in OpenModelica from library components and as a hand-written ODE: identical to 0.0 V, and within 3.8 µV of the analytic solution.
- 5 requirement-style Robot tests in virtual time (boot, Hello counter, chip identity, 501 ms period, LD1 toggling), 4 of them `smoke`, in CI on every push.
- Findings with evidence: the board's clock runs ~1.3 % fast (open), Mac vs. container binaries differ only in C-library layout, and the predicted Renode boot hang didn't happen.
</details>

<details>
<summary><b>P1: Thermal chamber with PID</b>: the first closed loop</summary>

- Heater, thermal mass, and ambient-loss model with a nonlinear NTC sensor, fully scripted in `.mos` and exported as an FMU.
- Firmware PID with derivative-on-measurement filtering and back-calculation anti-windup, unit-tested on the host.
- A Python bridge exchanges temperature and duty cycle with the firmware over a Renode socket terminal, and with the real board over USB serial.
- A comparison of the continuous Modelica PID, the Renode firmware PID, and the hardware PID: what discretization changes.
</details>

<details>
<summary><b>P2: Coupled water tanks</b>: nonlinear plant, model analysis</summary>

- A square-root (Torricelli) nonlinearity, linearized at several operating points with `linearize()`, then compared linear vs. nonlinear.
- Gain-scheduled PI plus feedforward, generated from the linearizations into a C header.
- Renode snapshots: boot once, then fork every test from the saved state.
- Data-driven Robot tests (`Test Template`) with `smoke` and `long` tags.
</details>

<details>
<summary><b>P3: DC motor servo</b>: real peripheral modeling</summary>

- A multi-domain model: armature R, L, and back-EMF coupled to inertia, gearbox, and friction with stiction events.
- Custom Renode peripherals (a quadrature encoder and an ADC current sense) fed from the FMU. PWM duty is read straight from timer compare registers.
- GDB attached to the emulator, CPU hooks timing the control ISR, and platform extensions in an overlay `.repl`.
- Cascaded current, speed, and position loops tuned from model parameters, with a custom metrics keyword library (overshoot, rise time, settling time).
</details>

<details>
<summary><b>P4: Inverted pendulum</b>: an unstable plant that exposes any timing error</summary>

- A MultiBody cart-pole with 3D animation, linearized at upright to get the matrices for LQR design.
- True lockstep co-simulation: Renode `RunFor(1 ms)` ↔ FMU `doStep(1 ms)`, with virtual and host time logged side by side.
- LQR plus a Kalman filter on simulated encoder and IMU data. A robustness sweep over mass, noise, and sample rate produces a stability map.
</details>

<details>
<summary><b>P5: Battery management system</b>: verification engineering</summary>

- A 4-cell equivalent-circuit pack with injectable faults: a drifting cell, an open sense wire, a thermal rise.
- Fault injection from the Renode monitor, watchdog resets, and a second emulated "charger" machine on a UART hub.
- A requirement-traced test matrix (`REQ-OV-01: overvoltage cut-off ≤ 100 ms`) with a generated traceability report.
- A protection state machine, passive balancing, and SOC estimation with Coulomb counting and an EKF.
</details>

<details>
<summary><b>P6: Capstone</b>: MIL → SIL → PIL → HW with CI</summary>

- The controller written in Modelica with clocked blocks, and exported as a source-code FMU.
- One Robot suite runs against every level by switching `${TARGET}`, with headless Renode and coverage in GitHub Actions.
- Quantization, sampling delay, and float vs. fixed point, each measured at every level.
</details>

---

## 🧰 Tech stack

| Area | Tools |
|---|---|
| Hardware | STM32 Nucleo-H743ZI2 (STM32H743ZI, Cortex-M7 @ 480 MHz, FPU, D-cache) |
| Firmware | STM32CubeMX 6.x, STM32Cube HAL/LL, CMake + Ninja, Arm GNU Toolchain |
| Emulation | Renode (STM32H743 platform + project overlays, custom C# peripherals) |
| Modeling | OpenModelica 1.27.1 (OMC, OMEdit, OMPython), Modelica Standard Library 4.0.0 (exact pin), FMI 2.0 |
| Co-simulation | Python 3.11, FMPy, the `labkit` bridge and orchestrator |
| Testing | Robot Framework + Renode keywords, pytest, host unit tests for C |
| Control design | python-control, NumPy, SciPy |
| Environment | `linux/amd64` devcontainer (same image locally and in CI), GitHub Actions |

---

## 🚀 Getting started

> **Works today (P0):** `make doctor`, `lint`, `fw`, `sim`, `test` (devcontainer) and `make hw` (macOS host). `make fmu` and `make unit` arrive in P1. Every command with its expected output: **[P0 README §4](projects/p0_blinky/README.md#4-how-to-run-and-what-to-expect)**.

**Host (macOS):** STM32CubeMX with the STM32CubeH7 pack, `stlink`, `pyserial`, and OrbStack or Colima. **Everything else** runs in the devcontainer.

```sh
# once, on the Mac (repo root): build the devcontainer image, then open a shell in it
docker build --platform linux/amd64 -f .devcontainer/Dockerfile -t h7lab:dev .
docker run --rm -it --platform linux/amd64 -v "$PWD":/work -w /work h7lab:dev

# inside the devcontainer
make doctor                          # every tool version, incl. the exact Modelica library pin
make fw   P=p0                       # build the canonical firmware -> build/fw/p0_blinky/
make sim  P=p0                       # OpenModelica RC study -> build/sim/p0/rc_compare.png
make test P=p0 TAGS=smoke            # Robot suite against Renode -> build/robot/p0/log.html

# on the macOS host, board connected
make hw   P=p0 HW_DESC=my_run        # flash the container-built binary + capture UART evidence
```

---

## 📁 Repository layout

```
fw/
  common/ctrl/        HAL-free control algorithms (build for arm + host)   [from P1]
  common/bsp/         thin HAL helpers                                     [from P1]
  common/link/        COBS + CRC16 protocol (C side)                      [from P1]
  pN_<name>/          CubeMX project per project (.ioc + generated code + app/)
models/Lab/           shared Modelica package                              [from P1]
tools/labkit/         Python: FMU, Renode control, bridge, metrics, run logging, plots  [from P1]
tools/doctor.sh       tool-version check behind `make doctor`
tests/common/         shared Robot resources and keyword libraries
projects/pN_<name>/   model/ scripts/ renode/ robot/ results/ + README ("What I learned")
docs/                 roadmap, ADRs, environment, troubleshooting, glossary, notes
.claude/              Claude Code workspace: rules, specialist agents, workflow skills, guard hooks
```

---

## 📚 Documentation

| Doc | What's inside |
|---|---|
| [Roadmap](docs/ROADMAP.md) | The full curriculum: per-project features, milestones, done-when criteria, risks |
| [Architecture decisions](docs/adr/README.md) | Why CubeMX + CMake, the amd64 devcontainer, the HAL-free control layer, the link protocol, and the time model |
| [Dev environment](docs/dev-environment.md) | Host vs. container split, setup steps, pinned versions |
| [Feature checklist](docs/feature-checklist.md) | Which Renode, OpenModelica, Robot, and control features are demonstrated, with links |
| [Troubleshooting](docs/troubleshooting.md) | Known problems, their root causes, and their fixes |
| [Glossary](docs/glossary.md) | MIL/SIL/PIL, FMU, quantum, ZOH, and more |

### How this repo proves the learning
Every project folder ships its models, scripts, Renode files, firmware, and Robot suite, **plus**:
- a README with *features used*, *problems hit (symptom → root cause → fix)*, *results*, and *what I'd do differently*
- committed `report.html` / `log.html`, plots, and run metadata (git SHA, parameters, tool versions)
- a `pN-done` git tag once it passes the [definition of done](CLAUDE.md#definition-of-done-per-project)

### Built with Claude Code
This repo includes a project-specific [Claude Code workspace](.claude/README.md):
- specialist agents (firmware reviewer, Renode specialist, Modelica modeler, controls engineer, ...)
- workflow skills (`/start-project`, `/renode-triage`, `/fmu-export-validate`, `/close-project`, ...)
- hooks that protect CubeMX-generated code and committed results

Learning steps marked 🎓 are done by hand.

---

<p align="center">
  Made by <a href="https://github.com/kiranj26">Kiran Jojare</a>.
</p>
