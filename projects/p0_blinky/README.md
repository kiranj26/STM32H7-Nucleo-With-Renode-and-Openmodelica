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
| STM32 | 🎓 CubeMX board selector (NUCLEO-H743ZI2), clock tree (HSE bypass → PLL1 → 400 MHz), CMake generation | [p0_blinky.ioc](../../fw/p0_blinky/p0_blinky.ioc), [CUBEMX.md](../../fw/p0_blinky/CUBEMX.md) |
| STM32 | USER CODE blocks: `app_init()` / `app_loop()` wired from `main.c`, survived a regeneration | [main.c#L25-L27](../../fw/p0_blinky/Core/Src/main.c#L25-L27), [#L95-L97](../../fw/p0_blinky/Core/Src/main.c#L95-L97), [#L104-L105](../../fw/p0_blinky/Core/Src/main.c#L104-L105) |
| STM32 | Root `CMakeLists.txt` user sections + `cmake --preset Debug` cross-build | [CMakeLists.txt#L46-L55](../../fw/p0_blinky/CMakeLists.txt#L46-L55) |
| STM32 | Flash with `st-flash`, SWD reset, timestamped VCP capture | [capture_uart.pl](scripts/capture_uart.pl), [run](results/2026-10-10_hw_hello/) |
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
make fw   P=p0                         # devcontainer only (canonical ELF)
make sim  P=p0                         # RC graphical vs. equations
make test P=p0 TAGS=smoke              # Renode
make hw   P=p0 HW_DESC=<desc>          # macOS host, board attached: flash + 20 s capture + meta.json
```
Working now: `doctor`, `fw` (container), `hw` (host). `sim` and `test` are stubs until steps G and F.

## 5. Results
<!-- Every number links to a dated run folder in results/. Label the level: Renode / HW. -->
| Metric | Requirement | Renode | HW |
|---|---|---|---|
| `Hello` on USART3 after boot | ≤ 5 s virtual | | ✅ boot banner + `Hello <n>` on VCP, LD1 blinking: Mac-built ELF ([run](results/2026-10-10_hw_hello/)) and canonical container ELF `50ac07ca…` ([run](results/2026-10-10_hw_container_elf/)) |
| `Hello` period (HAL_Delay(500) → 501 ticks + TX) | ≈ 501–502 ms | | ⚠️ 495.1 ms (Mac ELF, [run](results/2026-10-10_hw_hello/meta.json)) and 495.3 ms (container ELF, [run](results/2026-10-10_hw_container_elf/)), n=39 each: ~1.3 % fast, reproducible across both builds, cause open |
| RC graphical vs. equations max \|Δv\| | ≈ 0 (same equations) | (MIL) | N/A |

![](results/YYYY-MM-DD_desc/plot.png)

## 6. Problems hit
<!-- symptom → root cause → fix (link) → lesson. The most valuable section. -->
- **CubeMX showed no error with DIVN1 = ×129**: 8 MHz × 129 = 1032 MHz VCO is out of range, but the System Clock Mux was still on HSI, so PLL1 wasn't used and its outputs were greyed out instead of red → set DIVN1 = 100 *before* switching the mux to PLLCLK ([CUBEMX.md §3](../../fw/p0_blinky/CUBEMX.md)). *Lesson:* CubeMX only validates clock paths that are actually in use; check the VCO by hand.
- **`app_loop()` would have been deleted on the next regeneration**: I pasted it between `USER CODE END WHILE` and `USER CODE BEGIN 3`, which is outside every block → moved it inside block 3 ([main.c#L104-L105](../../fw/p0_blinky/Core/Src/main.c#L104-L105)); it then survived a regeneration. *Lesson:* only text strictly between a BEGIN/END pair is mine; the gap between two blocks still belongs to CubeMX.
- **`screen -L -Logfile …` → "Unknown option Logfile"**: macOS ships `screen` 4.00.03 (2006); `-Logfile` came in 4.06 → captured with `stty` + a Perl reader instead ([capture_uart.pl](scripts/capture_uart.pl)). *Lesson:* check the tool version (`screen -v`) before trusting docs for the current release.
- **`zsh: resource busy: /dev/tty.usbmodem31403`**: two detached `screen` sessions from earlier still held the port (`lsof /dev/tty.usbmodem*` showed them) → `screen -S <pid> -X quit`. *Lesson:* a serial port has one owner; closing a terminal window detaches `screen`, it doesn't kill it (`Ctrl-A K` kills).
- **First capture started with `Hello 9`…`Hello 39`, all with the same timestamp, before the boot banner**: bytes sent before the reset were still buffered in the USB VCP path → the script drains the port for 0.7 s before resetting ([capture_uart.pl](scripts/capture_uart.pl)). *Lesson:* identical timestamps on many lines mean "buffered", not "sent together".
- **`uart.log` didn't show in `git status`**: a global `*.log` rule in `.gitignore` hid my evidence → added `!projects/*/results/**/*.log`. *Lesson:* run `git check-ignore -v <file>` when a file you expect is missing from `git status`.
- **Mac-built and container-built `.bin` differ (2 161 bytes) despite identical size**: Arm's prebuilt `libc_nano.a` has a different member order on macOS than on Linux (e.g. `nano-svfprintf.o` is member 126 on the Mac vs 248 on Linux), so the linker places `printf`/`malloc` at different addresses. The first differing instruction is `bl _svfiprintf_r` in `snprintf` (→ 0x08005488 on the Mac vs 0x08005674 in the container); the function set and sizes are identical. Pinning the same compiler build (15.3.rel2 = arm-15.180) didn't change it → the container-built ELF is canonical, the Mac only flashes ([dev-environment.md](../../docs/dev-environment.md)). *Lesson:* "same compiler version" doesn't mean "same binary"; compare `.bin` hashes, then `nm` and `objdump` to find *what* differs before deciding whether it matters.
- **Board `Hello` period is 495.1 ms, not ~501 ms (HW)**: expected 501 ticks (`HAL_Delay` adds one tick) + ~0.9 ms TX. Short means the CPU runs *faster* than HAL assumes, which points at an HSE input of ≈ 8.1 MHz from the ST-LINK MCO instead of exactly 8 MHz. Reproduced with the container-built ELF (495.3 ms), so it follows the board, not the build. Cause _open_, not yet tested (MCO1 on PA8 with a scope, or HSI A/B test) ([run](results/2026-10-10_hw_hello/meta.json)). *Lesson:* the MCU can't detect its own clock error; only an external reference shows it. I first guessed "lower than 8 MHz", which has the direction backwards.

## 7. What I'd do differently
<!-- Written by me, not generated. -->

## 8. 🎓 Steps (done by hand)
- [x] Create `p0_blinky.ioc` in CubeMX and generate CMake ([CUBEMX.md](../../fw/p0_blinky/CUBEMX.md)), 2026-10-10
- [ ] Write the first `.resc` boot and get the ELF loading in Renode
- [ ] Find the RCC/PWR ready-flag hang with `LogPeripheralAccess` + `cpu PC`, fix it in `p0_overlay.repl`, write it up in §6
- [ ] Annotate a copy of `stm32h743.repl`: memory map, NVIC wiring, real models vs. tags, missing peripherals (sets P3 scope)
- [ ] Draw `RC_Graphical.mo` in OMEdit; write `RC_Equations.mo` by hand; pick R, C and stopTime from τ
- [ ] Write the first Robot test that waits for `Hello`
- [ ] Flash the same ELF to the board and confirm the same output (HW half done with the canonical ELF via `make hw`, [run](results/2026-10-10_hw_container_elf/); Renode half pending)
