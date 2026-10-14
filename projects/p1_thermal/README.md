# P1: Thermal chamber with PID

> Status: 🚧 in progress: firmware skeleton runs (TIM6 1 Hz tick, verified in Renode); next is milestone 1, the plant model. 0/7 milestones. · Time spent: ~__ h

## 1. Goal
The first closed loop, with the simplest possible coupling. A thermal chamber (heater, thermal mass, loss to ambient, nonlinear NTC sensor) is modeled in OpenModelica from scratch and exported as a co-simulation FMU. A discrete PID in `fw/common/ctrl/` (HAL-free, unit-tested on the host) runs from a timer ISR at a fixed Ts on the STM32H743. Each Ts the firmware sends its actuation over a COBS+CRC16 link on USART2; a Python bridge steps the FMU by Ts and replies with the sensor value (firmware-driven stepping, [ADR-0005](../../docs/adr/0005-time-model.md)). The same Robot suite checks the loop in Renode and then on the real board. The analysis compares three PIDs on one plot (Modelica continuous, firmware in Renode, firmware on the board) and explains the differences: ZOH delay, Ts, and quantization.

## 2. Platform
| Item | Value |
|---|---|
| SYSCLK / timer clock | 400 MHz / 200 MHz: HSE bypass 8 MHz → PLL1 M=1 N=100 P=2, HCLK 200, APB1–4 100, APB1 timers 200 (same tree as P0; [CUBEMX.md](../../fw/p1_thermal/CUBEMX.md)) |
| Control Ts | **1 s**: TIM6, PSC = 19999 (→ 10 kHz), ARR = 9999 → 200 MHz / (20 000 × 10 000) = 1 Hz. NVIC priority 2 |
| Why Ts = 1 s | Plant τ ≈ 200 s, so 1 s gives well over 10–20 samples per closed-loop rise time. 10 ms would mean 30 000 Renode link round trips per 300 s test and a noise-dominated derivative; 60 s reacts up to a minute late on a loop that settles in a few hundred seconds. |
| ISR design | The TIM6 ISR only counts ticks and toggles LD1; `app_loop()` prints. No blocking I/O in the ISR: a ~0.9 ms UART line at priority 2 would block the USART2 RX ISR (priority 3) and overrun the link ([app.c](../../fw/p1_thermal/app/app.c)) |
| Plant link | USART2 on **PD5 (TX) / PD6 (RX)**, 115200 8N1, RX interrupt, priority 3, no DMA ↔ socket :4321 (Renode) / transport on the board decided in milestone 7 |
| Console | USART3 (PD8/PD9) → ST-LINK VCP, polling TX from `app_loop()` only |
| LEDs | LD1 (PB0) toggles every tick; LD2 (PE1) reserved for "controller output saturated" |
| CubeMX / HAL | STM32CubeMX 6.18, FW_H7 V1.13.0, CMake, per-peripheral `.c/.h`, only necessary library files |
| Firmware (Debug) | text 31 196 B, data 96 B, bss 2 280 B (2026-10-13, uncommitted working tree) |
| Renode | 1.17.0, `@platforms/cpus/stm32h743.repl`; DBGMCU overlay **not loaded yet** (boots without it, as P0 showed; add before archiving evidence) |
| Plant FMU | `Lab.Thermal.Chamber`, CS, CVODE, validated max err ___ (milestone 2) |
| Plant I/O contract | inputs: heater duty ___ [1, 0..1] · outputs: NTC temperature ___ [°C, range ___] (milestone 1) |

## 3. Features used
🎓 = a first use or derivation the roadmap reserves for me. Who actually did each one is in §8.

**Used so far:**

| Tool | Feature | Where |
|---|---|---|
| STM32 | CubeMX: TIM6 basic timer as a periodic tick (PSC/ARR from the 200 MHz timer clock), NVIC priorities, USART2 pin remap to PD5/PD6, per-peripheral init files | [p1_thermal.ioc](../../fw/p1_thermal/p1_thermal.ioc), [CUBEMX.md](../../fw/p1_thermal/CUBEMX.md) |
| STM32 | Timer-interrupt tick: `HAL_TIM_Base_Start_IT`, `HAL_TIM_PeriodElapsedCallback`, clearing UIF before start | [app.c](../../fw/p1_thermal/app/app.c) |
| STM32 | ISR → main-loop handoff through a `volatile` counter, read once per loop pass | [app.c](../../fw/p1_thermal/app/app.c) |
| Robot | Period check in virtual time (REQ-P1-02), which also verifies Renode re-times TIM6 to 200 MHz | [p1_thermal.robot](robot/p1_thermal.robot) |

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
| Control | 🎓 Choice of Ts and gains from the plant model | Ts done: §2 |
| STM32 | UART IT ring buffer for the link | |
| Host | `fw/common/ctrl/pid.c` + host unit tests (`make unit`); COBS+CRC16 link in C and Python; `tools/labkit` | |

## 4. How to run (and what to expect)
Same two places as P0 ([P0 §4](../p0_blinky/README.md#4-how-to-run-and-what-to-expect) has the one-time setup): **devcontainer** for build/simulate/test, **macOS host** for anything that needs USB.

```sh
# container shell (from the repo root on the Mac):
docker run --rm -it --platform linux/amd64 -v "$PWD":/work -w /work h7lab:dev
```

| Run where | Command | Expect |
|---|---|---|
| container | `make fw P=p1` | ends with `text 31196  data 96  bss 2280`; files `build/fw/p1_thermal/p1_thermal.{elf,bin,hex}` |
| container | `make test P=p1 TAGS=smoke` | REQ-P1-01 only: banner `P1 thermal boot` within 1 s virtual |
| container | `make test P=p1` | 2 tests pass, one line `period_ms=999.9 (Hello 1 at 1000.00257 ms, Hello 3 at 2999.80257 ms)` (~20 s) |
| **Mac** | `make hw P=p1 HW_DESC=hw_tick` | `Flash written and verified! jolly good!`, then `hw: ~20 Hello lines -> projects/p1_thermal/results/<date>_hw_tick/` (20 s capture, one line per second); LD1 blinks at 0.5 Hz (toggles every 1 s) |
| **Mac** | `screen /dev/cu.usbmodem* 115200` | `Hello <n>` once per second; quit with `Ctrl-A` then `K`, `y` |
| container | `make sim P=p1`, `make fmu P=p1`, `make unit` | not yet (milestones 1, 2, 4) |

Not yet working: the plant link (USART2) carries nothing until milestone 5.

## 5. Results
Every number links to a dated run folder in `results/`. Levels: **HW** = the board, **Renode** = emulation (virtual time), **MIL** = OpenModelica.

| Metric | Requirement | MIL | Renode | HW |
|---|---|---|---|---|
| Boot banner on USART3 | ≤ 1 s virtual (REQ-P1-01) | N/A | ✅ passes (2026-10-13, `build/robot/p1`, not archived yet) | not run |
| Control tick period | 1000 ± 1 ms virtual (REQ-P1-02) | N/A | ✅ 999.9 ms (same run, not archived yet) | not run |
| \|T − SP\| after 300 s | < 1 °C | | | |
| FMU vs. `simulate()` max error | ___ | | N/A | N/A |

## 6. Problems hit
<!-- symptom → root cause → fix (link) → lesson. The most valuable section. -->
- **HSE greyed out in the Clock Configuration tab, everything at 4 MHz on CSI**: the Clock tab only *shows* sources enabled in the Pinout tab, and RCC → HSE was `Disable` (input frequency still CubeMX's generic 25 MHz) → set RCC HSE = **BYPASS Clock Source**, input 8 MHz, then rebuilt P0's PLL tree. *Lesson:* enable a clock source in Pinout first; the Clock tab is downstream of it.
- **Toolchain / IDE was `EWARM`**: CubeMX's default for this setup is IAR, which generates no `CMakeLists.txt` → set **CMake**. *Lesson:* compare Project Manager against the previous project's `.ioc` (`ProjectManager.TargetToolchain=CMake`).
- **USART2 landed on PA2/PA3**: CubeMX's default pins; PA2 is wired to the board's Ethernet PHY (ETH_MDIO) → remapped to **PD5/PD6** ([.ioc](../../fw/p1_thermal/p1_thermal.ioc)). *Lesson:* check every new peripheral's pins against the board's existing wiring, not just "is the pin free in CubeMX".
- **All NVIC priorities were 0**: CubeMX enables an interrupt at priority 0 by default → TIM6 = 2, USART2 = 3. *Lesson:* priorities are a design decision (control tick above comms); never leave application ISRs at 0.
- **Console came from the board BSP (`BSP_COM_Init(COM1)`, 3 × `BSP_LED_Init`, button EXTI) instead of `huart3`**; unticking the BSP features also removed the USART3 and LED pins → re-added USART3 (PD8/PD9) and PB0/PE1 as plain HAL peripherals, like P0. *Lesson:* every extra init (here a button EXTI) is one more thing Renode must model; keep the generated init minimal.
- **`Drivers/` was 81 MB** ("copy all used libraries"); switching to "copy only necessary" left 23 MB of stale CMSIS and an old `Drivers/BSP/` behind → deleted `Drivers/` and regenerated: **9.7 MB**, 20 HAL sources (P0: 9.5 MB). *Lesson:* CubeMX doesn't delete library files it copied under an earlier setting.
- **LD1/LD2 labelled but generated as `GPIO_MODE_ANALOG`**: setting a label doesn't set the pin mode → set both to **GPIO_Output** ([gpio.c](../../fw/p1_thermal/Core/Src/gpio.c)). *Lesson:* Renode's GPIO model records ODR writes regardless of the pin mode, so a "LD1 toggles" test would **pass in Renode while the LED stays dark on the board**; only HW (or reading `GPIOB_MODER`) catches it.
- **First TIM6 interrupt would fire immediately, not after Ts**: `HAL_TIM_Base_Init` writes `EGR.UG` to load PSC/ARR, which also sets UIF, and HAL V1.13.0 doesn't clear it → `__HAL_TIM_CLEAR_FLAG(&htim6, TIM_FLAG_UPDATE)` before `HAL_TIM_Base_Start_IT` ([app.c](../../fw/p1_thermal/app/app.c)). *Lesson:* read what an init function writes to the hardware, not just its name.
- **Boot test waited for `Hello` within 1 s, but the first `Hello` now comes at Ts = 1 s**: the scaffold test predated the tick design → REQ-P1-01 waits for the boot banner instead; the tick has its own test (REQ-P1-02). *Lesson:* a boot test should check boot, not a periodic output whose timing is a separate requirement.
- **Tooling (Claude):** `CUBEMX.md` first said SysTick's default priority is 15; it is **0** (`TICK_INT_PRIORITY 0UL`, same in P0) → corrected. A scripted edit of `main.c` also converted CubeMX's CRLF line endings and rewrote the whole file; caught in the diff and redone byte-preserving (3-line diff). *Lesson:* check the size of a diff on generated files before trusting it.
- **Renode tick period is 999.9 ms, not 1000.0 ms** (inside the 1 ms tolerance): Hello 1 at 1000.003 ms, Hello 3 at 2999.803 ms. Hypothesis: after the first period Renode's `STM32_Timer` reloads after ARR counts instead of ARR+1 (0.1 ms = one count at 10 kHz). _Open: log Hello 2's time to confirm._
- Carried over from P0 (open): the board clock is ~1.3 % fast ([P0 §6](../p0_blinky/README.md#6-problems-hit)); it matters for the 300 s HW run.

## 7. What I'd do differently
<!-- Written by me, not generated. -->

## 8. 🎓 Steps (done by hand)
Milestones from the roadmap, in order. 🎓 = mine to do; Claude explains and reviews.
- [x] CubeMX: create `p1_thermal.ioc` and generate CMake (four generation passes, reviewed with `/cubemx-regen` each time; [CUBEMX.md](../../fw/p1_thermal/CUBEMX.md)), 2026-10-13
- [x] 🎓 Choose Ts = 1 s from τ ≈ 200 s and derive ARR = 9999 (§2), 2026-10-13
- [x] Firmware skeleton: tick ISR + handoff + Renode tests. **Written by Claude at my request** ([app.c](../../fw/p1_thermal/app/app.c), [p1_thermal.robot](robot/p1_thermal.robot)); the ISR design reasoning (no blocking I/O at priority 2) is mine.
- [ ] First flash on the board (`make hw P=p1`)
- [ ] 1. 🎓 `Lab.Thermal.Chamber` model and its bench (energy balance + NTC β model; τ = C/G, ΔT_ss = P/G)
- [ ] 2. 🎓 FMU export and validation (`fmu-export-validate` skill)
- [ ] 3. Reference closed loop with Modelica `LimPID`
- [ ] 4. 🎓 `ctrl/pid.c` with host unit tests (derive the discrete PID)
- [ ] 5. Link protocol (COBS+CRC16) and the bridge; 🎓 first socket terminal in Renode
- [ ] 6. 🎓 Robot suite on Renode (Suite Setup/Teardown with processes)
- [ ] 7. The same suite on the board (`TARGET:hw`, serial transport)
