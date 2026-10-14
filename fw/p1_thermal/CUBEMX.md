# P1 CubeMX configuration (STM32CubeMX 6.18)

Firmware needs for P1 (from [ROADMAP P1](../../docs/ROADMAP.md#p1-thermal-chamber-with-pid)):
- a **control tick timer** at a fixed Ts (the PID runs in its ISR)
- a **plant link UART** (USART2) carrying COBS+CRC16 frames: actuation out, sensor value in, once per Ts
- the **console** on USART3 (ST-LINK VCP), as in P0
- LD1 heartbeat (as in P0)

There's no PWM, ADC or real heater: the plant is an FMU on the other end of the link, in Renode *and* on the board (milestone 7 uses a serial transport). The clock tree is **identical to P0**, so the timer maths below uses P0's 200 MHz timer clock.

The owner does the clicking (🎓). Claude doesn't edit the `.ioc`.

## 1. New project
- File → New Project → **Board Selector** → `NUCLEO-H743ZI2` → Start Project.
- "Initialize all peripherals with their default Mode?" → **Yes**.
- Same trimming as P0 ([P0 CUBEMX.md §2](../p0_blinky/CUBEMX.md#2-pinout--configuration-trim-to-what-p0-needs)): **ETH → Disable**, **USB_OTG_FS → Disable**, SYS Debug = **Serial Wire**, Timebase = **SysTick**, RCC HSE = **BYPASS**, CORTEX_M7 caches **disabled**.

## 2. Clock Configuration tab (same as P0)
| Field | Value | Result |
|---|---|---|
| PLL Source Mux | HSE (8 MHz bypass) | |
| DIVM1 / DIVN1 / DIVP1 | /1 / ×100 / /2 | VCO 800 MHz, **SYSCLK 400 MHz** |
| D1CPRE / HPRE | /1 / /2 | CPU 400 MHz, HCLK 200 MHz |
| D1PPRE, D2PPRE1, D2PPRE2, D3PPRE | /2 each | APB1–4 = 100 MHz |
| APB1 timer clock | | **200 MHz** (APB prescaler ≠ 1 → timers run at 2×PCLK1). Confirm in the Clock tab: this number is the input to all timer maths below. |
| Power Regulator Voltage Scale | Scale 1 | |
| USART2/3 kernel clock mux | **PCLK1** = 100 MHz | BRR = 100 000 000 / 115 200 ≈ 868 (≈ 0.01 % error), same as P0 |

## 3. Peripherals

### TIM6: control tick (Timers → TIM6)
TIM6 is a **basic timer**: no channels, no pins, just a counter and an update interrupt. That's all a periodic tick needs, and it leaves TIM2–TIM5 free for later projects. It sits on APB1, so f_timclk = 200 MHz. It's 16-bit, so PSC and ARR are each ≤ 65 535.

| Field | Value | Maths |
|---|---|---|
| Activated | ✓ | |
| Prescaler (PSC) | **19999** | 200 MHz / (19999 + 1) = **10 kHz** count rate → 0.1 ms resolution |
| Counter Period (ARR) | **🎓 your choice**: ARR = Ts[s] × 10 000 − 1 | f_tick = 200 MHz / ((PSC+1)(ARR+1)). Max ARR 65 535 → Ts ≤ 6.55 s |
| auto-reload preload | Enable | so a later ARR change takes effect at the next update, not mid-period |
| NVIC Settings → TIM6 global interrupt (`TIM6_DAC_IRQn`) | ✓ | |

> **Ts is the open 🎓 question** (τ ≈ 200 s: is it 10 ms, 1 s or 60 s?). Derive it, write it in [README §2](../../projects/p1_thermal/README.md#2-platform), then fill in ARR. You can change ARR later in CubeMX and regenerate; the USER CODE survives.

### USART2: plant link (Connectivity → USART2)
| Field | Value | Why |
|---|---|---|
| Mode | Asynchronous | |
| Baud / word / parity / stop | 115200, 8 bit, None, 1 | |
| Pins | **PD5 = USART2_TX, PD6 = USART2_RX** (in the Pinout view, click the pin and choose the function; CubeMX may default to PA2/PA3) | PA2 is ETH_MDIO on the Nucleo-144. PD5/PD6 are free and brought out on CN9 (Zio). |
| NVIC Settings → USART2 global interrupt | ✓ | RX by interrupt into a ring buffer; frames end at COBS's `0x00` delimiter |
| DMA | **none** | DMA1/2 can't access DTCM (where `.bss` lives) and need cache maintenance on the H7. That's the P3 lesson; interrupt RX is plenty at 115200 baud. |

### USART3: console (already set by the board defaults)
115200 8N1 on PD8/PD9, **NVIC off**. Same as P0: polling TX, called only from `app_loop()`, never from the control ISR (CLAUDE.md hard rule 3).

### GPIO
- PB0 = `LD1` heartbeat (as in P0).
- *Optional:* PE1 = `LD2` "controller output saturated". Lighting it while the anti-windup is active is a cheap way to *see* windup on the board.

### NVIC (System Core → NVIC)
Keep the default priority group (4 bits pre-emption). Lower number = higher priority, and **never use 0** for application ISRs.

| Interrupt | Preemption priority | Why |
|---|---|---|
| TIM6 global (`TIM6_DAC_IRQn`) | **2** | The control tick wins over comms: a late byte must never delay the PID. |
| USART2 global | **3** | It fills the RX ring buffer; the tick ISR reads the latest complete frame. |
| System tick timer | default (**0**, `TICK_INT_PRIORITY`; same as P0) | Leave it: the SysTick ISR only increments a counter (well under 1 µs), so it can't noticeably delay the tick. `HAL_GetTick`/`HAL_Delay` are used only in the background loop. |

## 4. Project Manager
- Project Name: `p1_thermal`, Project Location: `<repo>/fw/` → `fw/p1_thermal/p1_thermal.ioc` (`fw/p1_thermal/app/` already exists and won't be touched)
- Toolchain / IDE: **CMake**
- Code Generator:
  - "Copy only the necessary library files" ✓
  - "Generate peripheral initialization as a pair of '.c/.h' files per peripheral" ✓
  - "Keep User Code when re-generating" ✓
  - "Delete previously generated files when not re-generated" ✓
- **GENERATE CODE**

## 5. After generating (same wiring as P0)
- `Core/Src/main.c`, USER CODE blocks only: `#include "app.h"` (Includes), `app_init();` (2), `app_loop();` (3, inside `while (1)`).
- Root `fw/p1_thermal/CMakeLists.txt` user sections: add `app/app.c` and the `app/` include dir. `fw/common/ctrl` and `fw/common/link` come later (milestones 4–5).
- Run the **`cubemx-regen`** skill.

## 6. Renode implications
Checked against `/opt/renode/platforms/cpus/stm32h7.repl` (Renode 1.17.0) in the devcontainer.

| Choice | What Renode must do | Expectation |
|---|---|---|
| Clock tree (same as P0) | Same PWR/RCC flags as P0 | Boots, *provided* the P1 `.resc` loads a DBGMCU overlay like [P0's](../../projects/p0_blinky/renode/p0_overlay.repl); otherwise `SystemInit` takes the rev-Y path again. |
| TIM6 tick | `timer6: Timers.STM32_Timer` at 0x40001000, IRQ → `nvic@54` (= `TIM6_DAC_IRQn`). The `.repl` starts it at **250 MHz**. | P0 measured that TIM2 is re-timed by the RCC model to 200 MHz once the firmware configures the clocks; TIM6 is registered with the RCC the same way, so 200 MHz is **expected but not yet verified**. The first P1 Robot check should measure the tick period in virtual time. |
| USART2 link | `usart2: UART.STM32F7_USART` at 0x40004400, IRQ via `exti@27`. Bridged with `emulation CreateServerSocketTerminal 4321 "plant" false` + `connector Connect sysbus.usart2 plant` (already in [p1.resc](../../projects/p1_thermal/renode/p1.resc), commented). | RXNE interrupts are modeled. **Bytes arrive instantly**, whatever the baud rate (the `.repl` gives a fixed 125 MHz UART clock; BRR doesn't matter). On the board, a ~10-byte frame takes ~0.9 ms at 115200 baud, which is one source of Renode-vs-HW difference for the analysis plot. |
| COBS `0x00` delimiter rather than UART IDLE detection | No IDLE-line flag needed | Whether `STM32F7_USART` models IDLE is unverified, so the framing doesn't rely on it. |
| No DMA, caches off | (nothing) | Avoids the H7 DMA/D-cache/DTCM pitfalls, which can't be reproduced in Renode anyway (P3). |

## Cross-check
- Timer maths uses the **APB1 timer clock (200 MHz)**, not PCLK1 (100 MHz). Re-read it in the Clock tab before trusting PSC = 19999.
- Pins: PD5/PD6 (USART2), PD8/PD9 (USART3 VCP) and PB0/PE1 (LEDs) are free on the Nucleo defaults with ETH disabled, so no solder-bridge changes are needed.
- Priorities: TIM6 (2) above USART2 (3), SysTick lowest, none at 0.
- **Open for milestone 7:** on the board, the link needs either a USB-UART adapter on CN9 (PD5/PD6) or the plant link moved onto the VCP (USART3, giving up the console). Decide then and record it in an ADR.
