# P0 CubeMX configuration (STM32CubeMX 6.18)

Firmware needs for P0 (from [ROADMAP P0](../../docs/ROADMAP.md#p0-toolchain-warm-up)): blink LD1 (PB0) and print `Hello <n>` on USART3 at 115200 8N1. No control timer, no plant UART, no ADC/DMA. Keep the init code small, because every peripheral that gets initialized is one more thing Renode has to model.

The owner does the clicking (🎓). Claude doesn't edit the `.ioc`.

## 0. Prerequisite
- Help → Manage embedded software packages → STM32H7 → install the latest **STM32Cube FW_H7** pack. Record the version in [dev-environment.md](../../docs/dev-environment.md) (pin table).

## 1. New project
- File → New Project → **Board Selector** → Commercial Part Number `NUCLEO-H743ZI2` → select → Start Project.
- "Initialize all peripherals with their default Mode?" → **Yes**.
  This keeps USART3 on PD8/PD9 (the ST-LINK VCP), LD1 PB0 / LD2 PE1 / LD3 PB14, and B1 on PC13 already labeled.
- If asked about MPU/cache defaults (CORTEX_M7), keep the defaults for P0.

## 2. Pinout & Configuration: trim to what P0 needs
| Peripheral | Setting | Why |
|---|---|---|
| Connectivity → **ETH** | Mode: **Disable** | The board default enables RMII. Its init touches the ETH MAC and DMA, which P0 doesn't need and Renode may not model. |
| Connectivity → **USB_OTG_FS** | Mode: **Disable** | Same reason. It also needs the 48 MHz clock, which would constrain the clock tree. |
| Connectivity → **USART3** | Mode Asynchronous, 115200, 8 bit, None, 1 stop | VCP console. Leave NVIC off for P0: `HAL_UART_Transmit` (polling) is fine because there's no control path yet. |
| System Core → **GPIO** | PB0 = GPIO_Output, label `LD1` (should already be set) | Blinky |
| System Core → **SYS** | Debug: **Serial Wire**; Timebase Source: **SysTick** | SWD for flashing and debugging later; SysTick drives `HAL_Delay`/`HAL_GetTick`. |
| System Core → **RCC** | HSE: **BYPASS Clock Source** | On the ZI2, the ST-LINK feeds an 8 MHz MCO into PH0 (no crystal by default). |
| System Core → **CORTEX_M7** | Leave ICache/DCache **disabled** for P0 | Caches matter once there's DMA (P3). Renode doesn't model them anyway. |

## 3. Clock Configuration tab
Target **SYSCLK = 400 MHz** at VOS1. Not 480 MHz: 480 MHz needs VOS0, which adds an overdrive step for no benefit in P0.

| Field | Value | Result |
|---|---|---|
| PLL Source Mux | HSE (8 MHz) | |
| DIVM1 | /1 | PLL1 input 8 MHz (range 8–16 MHz) |
| DIVN1 | ×100 | VCO 800 MHz |
| DIVP1 | /2 | **SYSCLK 400 MHz** |
| System Clock Mux | PLLCLK | |
| D1CPRE | /1 | CPU 400 MHz |
| HPRE | /2 | HCLK (AXI/AHB) 200 MHz |
| D1PPRE, D2PPRE1, D2PPRE2, D3PPRE | /2 each | APB1–4 = 100 MHz |
| (resulting) APB1/APB2 timer clocks | | **200 MHz** (the APB prescaler ≠ 1, so timers run at 2×PCLK) |

- In RCC Parameters, check **Power Regulator Voltage Scale = Scale 1**. CubeMX sets the flash latency automatically; note the value it picks.
- **USART3 kernel clock** (Clock tab, USART2/3/4/5/7/8 mux): `PCLK1` = 100 MHz. BRR = 100 000 000 / 115 200 ≈ 868, an error of about 0.01 %.
- If any box is red, fix it before generating. Record SYSCLK and the timer clock in the project README §2.

## 4. Project Manager
- Project → Project Name: `p0_blinky`. Project Location: `<repo>/fw/` (so the result is `fw/p0_blinky/p0_blinky.ioc`; `fw/p0_blinky/app/` already exists and won't be touched).
- Toolchain / IDE: **CMake**
- Code Generator:
  - "Copy only the necessary library files" ✓
  - "Generate peripheral initialization as a pair of '.c/.h' files per peripheral" ✓
  - "Keep User Code when re-generating" ✓
  - "Delete previously generated files when not re-generated" ✓
- Advanced Settings: HAL for GPIO and USART3 (the default).
- **GENERATE CODE.**

## 5. After generating (owner, then Claude verifies)
- In `Core/Src/main.c`, inside USER CODE blocks only:
  - `/* USER CODE BEGIN Includes */` → `#include "app.h"`
  - `/* USER CODE BEGIN 2 */` → `app_init();`
  - `/* USER CODE BEGIN 3 */` (inside `while (1)`) → `app_loop();`
- In the generated top-level `fw/p0_blinky/CMakeLists.txt` user sections (not `cmake/stm32cubemx/**`), add `app/app.c` to the sources and `app/` to the include dirs.
- Run the `cubemx-regen` skill. It checks that the USER CODE blocks survived, that `app/` is wired in, and that the CMake build works.

## 6. Renode implications
| Choice | What Renode must do | Expectation |
|---|---|---|
| HSE bypass + PLL1 + VOS1 | `SystemClock_Config` (and the supply setup before it) wait in loops on ready/status flags in PWR and RCC. | **Expected pitfall: this is milestone 4 (🎓).** If a flag the HAL waits on isn't modeled, the firmware spins forever before reaching `main`'s loop. Starting point: run, pause, `cpu PC`, then `sysbus LogPeripheralAccess <peripheral> true` (use `peripherals` to list names). |
| USART3 polling TX | The USART model must set TXE/TC so `HAL_UART_Transmit` completes. | USART is well modeled on STM32 in Renode, so it should work. If the output stops after one byte, that's a status-flag issue, the same pattern as above. |
| SysTick / `HAL_Delay` | SysTick is part of the Renode NVIC model. | Its frequency comes from the **platform `.repl`**, not from your RCC writes. Question to answer in milestone 5: does the blink period in virtual time match what you'd expect at 400 MHz? |
| GPIO PB0 | The GPIO model records ODR writes. | Visible via `LogPeripheralAccess` on `gpioPortB`, or an LED model in an overlay. |
| ETH/USB disabled | (nothing) | This is why they're disabled. |
| Caches disabled | (nothing) | `SCB_EnableDCache` is a no-op in Renode, so cache bugs **can't** be reproduced in emulation. That's a P3 lesson. |

## Cross-check
- Timer clock math: no timers are used in P0. Timer clocks are 200 MHz, and that value is reused in P1 for the control tick.
- Pins: PD8/PD9 (USART3 VCP) and PB0 (LD1) are the Nucleo defaults, so no solder-bridge changes are needed.
- Interrupt priorities: only SysTick is used. Leave it at the CubeMX default.
