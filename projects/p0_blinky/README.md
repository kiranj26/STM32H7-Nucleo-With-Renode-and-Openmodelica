# P0: Toolchain warm-up (Blinky)

> Status: 🚧 in progress · Time spent: ~__ h

## 1. Goal
Get every tool producing output **independently** before connecting anything. CubeMX generates a CMake project for the NUCLEO-H743ZI2 that blinks LD1 (PB0) and prints `Hello <n>` on USART3 (ST-LINK VCP, 115200 baud). The same ELF boots in Renode, where a Robot suite waits for `Hello`, and then runs on the real board. Separately, OpenModelica simulates an RC circuit twice: once drawn in OMEdit and once as text equations, with the results compared. There's no closed loop yet; the point is to know what each tool does on its own, and where the Renode H743 platform model stops matching the silicon.

## 2. Platform
| Item | Value |
|---|---|
| SYSCLK / timer clock | 400 MHz / 200 MHz (HCLK 200, APB1–4 100; see [`fw/p0_blinky/CUBEMX.md`](../../fw/p0_blinky/CUBEMX.md)) |
| Clock source / power | HSE bypass 8 MHz (ST-LINK MCO) → PLL1 M=1 N=100 P=2 (VCO 800 MHz, wide); LDO supply, VOS1; flash 2 WS; rev V |
| CubeMX / HAL | STM32CubeMX 6.18, STM32Cube FW_H7 V1.13.0, CMake + GCC |
| Firmware size (Debug) | text 23 848 B, data 96 B, bss 2 056 B (flash 1.14 %, DTCM 1.64 %); Arm GNU Toolchain 15.3.Rel1 on macOS host, 2026-10-10 |
| Control Ts | N/A in P0 (no control loop) |
| Console | USART3 (PD8/PD9) → ST-LINK VCP / Renode `sysbus.usart3` |
| Plant link | N/A in P0 (starts in P1) |
| Renode | version ___, overlay `renode/p0_overlay.repl` (created by the RCC/PWR fix) |
| Plant FMU | N/A in P0 (RC model is simulated with `simulate()` only) |
| RC model | R = ___ Ω, C = ___ F, τ = ___ s, solver ___, tolerance ___ |

## 3. Features used
🎓 = done by hand by me (first use of the feature, or a derivation). "Where" is filled in as each one lands.

| Tool | Feature | Where |
|---|---|---|
| STM32 | 🎓 CubeMX board selector (NUCLEO-H743ZI2), clock tree, CMake generation | `fw/p0_blinky/p0_blinky.ioc` |
| STM32 | USER CODE blocks: `app_init()` / `app_loop()` wired from `main.c` | [app.h](../../fw/p0_blinky/app/app.h) |
| Renode | 🎓 `.resc`: `mach create`, `LoadPlatformDescription`, `sysbus LoadELF` | [p0.resc](renode/p0.resc) |
| Renode | 🎓 `showAnalyzer` on USART3 | `renode/p0_gui.resc` |
| Renode | 🎓 Reading and annotating the H743 `.repl` line by line (models vs. tags, missing peripherals) | `renode/stm32h743_annotated.repl` |
| Renode | 🎓 `LogPeripheralAccess` + `cpu PC` to find a hang; overlay `.repl` fix | `renode/p0_overlay.repl` |
| OpenModelica | 🎓 RC circuit, graphical (OMEdit) | `model/RC_Graphical.mo` |
| OpenModelica | 🎓 RC circuit, text equations | `model/RC_Equations.mo` |
| OpenModelica | `.mos` scripting; comparing the two results | [p0.mos](scripts/p0.mos) |
| Robot | 🎓 `Create Terminal Tester`, `Wait For Line On Uart` | [p0_blinky.robot](robot/p0_blinky.robot) |
| Robot | Reading `log.html` / `report.html` | `results/` |
| Control | (none in P0) | |

## 4. How to run
```sh
make doctor                            # container: tool versions (milestone 1)
make fw   P=p0
make sim  P=p0                         # RC graphical vs. equations
make test P=p0 TAGS=smoke              # Renode
make hw   P=p0                         # macOS host, board attached
```
(The Makefile is built during P0; these targets don't exist yet.)

## 5. Results
<!-- Every number links to a dated run folder in results/. Label the level: Renode / HW. -->
| Metric | Requirement | Renode | HW |
|---|---|---|---|
| `Hello` on USART3 after boot | ≤ 5 s virtual | | ✅ boot banner + `Hello <n>` on VCP, LD1 blinking ([run](results/2026-10-10_hw_hello/)) |
| `Hello` period (HAL_Delay(500) → 501 ticks + TX) | ≈ 501–502 ms | | ⚠️ 495.1 ms mean, n=39, ±3 ms jitter: ~1.3 % fast, cause open ([run](results/2026-10-10_hw_hello/meta.json)) |
| RC graphical vs. equations max \|Δv\| | ≈ 0 (same equations) | (MIL) | N/A |

![](results/YYYY-MM-DD_desc/plot.png)

## 6. Problems hit
<!-- symptom → root cause → fix (link) → lesson. The most valuable section. -->
- **Board `Hello` period is 495 ms, not ~501 ms (HW)**: cause _open_ ([run](results/2026-10-10_hw_hello/meta.json)). *Lesson:* ...
- **<symptom>**: cause → fix ([link]). *Lesson:* ...

## 7. What I'd do differently
<!-- Written by me, not generated. -->

## 8. 🎓 Steps (done by hand)
- [ ] Create `p0_blinky.ioc` in CubeMX and generate CMake ([CUBEMX.md](../../fw/p0_blinky/CUBEMX.md))
- [ ] Write the first `.resc` boot and get the ELF loading in Renode
- [ ] Find the RCC/PWR ready-flag hang with `LogPeripheralAccess` + `cpu PC`, fix it in `p0_overlay.repl`, write it up in §6
- [ ] Annotate a copy of `stm32h743.repl`: memory map, NVIC wiring, real models vs. tags, missing peripherals (sets P3 scope)
- [ ] Draw `RC_Graphical.mo` in OMEdit; write `RC_Equations.mo` by hand; pick R, C and stopTime from τ
- [ ] Write the first Robot test that waits for `Hello`
- [ ] Flash the same ELF to the board and confirm the same output
