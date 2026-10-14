# P1: Thermal chamber with PID

> Status: 🚧 in progress (scaffolded 2026-10-13, 0/7 milestones) · Time spent: ~__ h

## 1. Goal
The first closed loop, with the simplest possible coupling. A thermal chamber (heater, thermal mass, loss to ambient, nonlinear NTC sensor) is modeled in OpenModelica from scratch and exported as a co-simulation FMU. A discrete PID in `fw/common/ctrl/` (HAL-free, unit-tested on the host) runs from a timer ISR at a fixed Ts on the STM32H743. Each Ts the firmware sends its actuation over a COBS+CRC16 link on USART2; a Python bridge steps the FMU by Ts and replies with the sensor value (firmware-driven stepping, [ADR-0005](../../docs/adr/0005-time-model.md)). The same Robot suite checks the loop in Renode and then on the real board. The analysis compares three PIDs on one plot (Modelica continuous, firmware in Renode, firmware on the board) and explains the differences: ZOH delay, Ts, and quantization.

## 2. Platform
| Item | Value |
|---|---|
| SYSCLK / timer clock | 400 MHz / 200 MHz (same clock tree as P0; see `fw/p1_thermal/CUBEMX.md`) |
| Control Ts | ___ ms (TIMx, PSC=___, ARR=___) 🎓 chosen from the plant τ |
| Plant link | USART2 ↔ socket :4321 (Renode) / VCP or USART2 (HW, decided in milestone 7) |
| Console | USART3 → ST-LINK VCP (as in P0) |
| Renode | 1.17.0, overlay `renode/p1_overlay.repl` (start from P0's DBGMCU fix) |
| Plant FMU | `Lab.Thermal.Chamber`, CS, CVODE, validated max err ___ ([run](results/)) |
| Plant I/O contract | inputs: heater duty ___ [1, 0..1] · outputs: NTC temperature ___ [°C, range ___] |

## 3. Features used
🎓 = a first use or derivation the roadmap reserves for me. Who actually did each one goes in §8.

**Features to learn (from [ROADMAP P1](../../docs/ROADMAP.md#p1-thermal-chamber-with-pid)):**

| Tool | Feature | Where |
|---|---|---|
| OpenModelica | 🎓 Heater, thermal mass and ambient loss written from scratch (`C·dT/dt = P − G·(T − Tₐ)`) | |
| OpenModelica | 🎓 Nonlinear NTC sensor (β model) | |
| OpenModelica | Parameters, initial conditions, solver and tolerance study | |
| OpenModelica | 🎓 `buildModelFMU` (CS, `s:cvode`) + validation against `simulate()` (`fmu-export-validate` skill) | |
| OpenModelica | Reference closed loop with MSL `LimPID` | |
| Renode | 🎓 `CreateServerSocketTerminal` on USART2 for the plant link | |
| Renode | 🎓 `logLevel`, `sysbus LogPeripheralAccess` to see what the HAL does to the USART (deferred from P0) | |
| Robot | 🎓 Suite Setup/Teardown that start Renode and the bridge | |
| Robot | Variables for setpoint and ambient; `${TARGET}` switching (renode / hw) | |
| Robot | Requirement: `\|T − SP\| < 1 °C after 300 s virtual` | |
| Control | 🎓 Discrete PID: derivative on measurement with a filter, back-calculation anti-windup, bumpless setpoint change | |
| Control | 🎓 Choice of Ts and gains from the plant model | |
| STM32 | Timer-ISR control tick at fixed Ts; UART IT/DMA ring buffer for the link | |
| Host | `fw/common/ctrl/pid.c` + host unit tests (`make unit`); COBS+CRC16 link in C and Python; `tools/labkit` | |

## 4. How to run
```sh
make fw   P=p1
make unit                              # ctrl/ and labkit tests (from milestone 4)
make sim  P=p1
make fmu  P=p1
make test P=p1 TAGS=smoke              # Renode
make hw   P=p1                         # macOS host, board attached
```

## 5. Results
<!-- Every number links to a dated run folder in results/. Label the level: MIL / SIL / Renode / HW. -->
| Metric | Requirement | MIL | Renode | HW |
|---|---|---|---|---|
| \|T − SP\| after 300 s | < 1 °C | | | |
| FMU vs. `simulate()` max error | ___ | | N/A | N/A |

## 6. Problems hit
<!-- symptom → root cause → fix (link) → lesson. The most valuable section. -->
Carried over from P0 (open): the board clock is ~1.3 % fast ([P0 §6](../p0_blinky/README.md#6-problems-hit)); it matters for the 300 s HW run.

## 7. What I'd do differently
<!-- Written by me, not generated. -->

## 8. 🎓 Steps (done by hand)
Milestones from the roadmap, in order. 🎓 = mine to do; Claude explains and reviews.
- [ ] CubeMX: create `p1_thermal.ioc` and generate CMake ([CUBEMX.md](../../fw/p1_thermal/CUBEMX.md))
- [ ] 1. 🎓 `Lab.Thermal.Chamber` model and its bench (energy balance + NTC β model; τ = C/G, ΔT_ss = P/G)
- [ ] 2. 🎓 FMU export and validation (`fmu-export-validate` skill)
- [ ] 3. Reference closed loop with Modelica `LimPID`
- [ ] 4. 🎓 `ctrl/pid.c` with host unit tests (derive the discrete PID; choose Ts)
- [ ] 5. Link protocol (COBS+CRC16) and the bridge; 🎓 first socket terminal in Renode
- [ ] 6. 🎓 Robot suite on Renode (Suite Setup/Teardown with processes)
- [ ] 7. The same suite on the board (`TARGET:hw`, serial transport)
