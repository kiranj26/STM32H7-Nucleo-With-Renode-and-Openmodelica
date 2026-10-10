---
name: cubemx-setup
description: Produce an exact, click-by-click STM32CubeMX 6.x checklist (board, clock tree, pins, peripherals, NVIC, DMA, project manager settings) for a project's firmware needs, plus the Renode implications of each choice. Use before creating or changing a .ioc - Claude never edits .ioc files directly.
argument-hint: "<N> [what peripheral/change is needed]"
---

# CubeMX setup checklist for P$ARGUMENTS

The owner clicks; Claude writes the checklist. The output goes to `fw/pN_<name>/CUBEMX.md` (or the change section of it).

## 1. Derive requirements
From `docs/ROADMAP.md` (the pN section), the project README, and the firmware design, list what's needed:
- control tick timer and Ts
- PWM channels and frequency
- UARTs and baud rates (USART3 = logs/VCP, a second UART for the plant link)
- ADC/encoder inputs, DMA, and interrupt priorities

## 2. Write the checklist
Use this structure. Be exact: menu paths, field names, and numeric values, with the math shown for prescalers.

```markdown
# P<N> CubeMX configuration (STM32CubeMX 6.18)

## New project
- File → New Project → Board Selector → NUCLEO-H743ZI2 → "Initialize all peripherals with their default Mode?" → **Yes**
  (Keeps USART3 VCP on PD8/PD9, LEDs PB0/PE1/PB14, B1 PC13. Disable USB_OTG_FS and ETH if not needed: less init code to emulate.)

## Clock (Clock Configuration tab)
- HSE: BYPASS (8 MHz MCO from ST-LINK) | PLL1: M=?, N=?, P=? → SYSCLK = ? MHz
- Power: VOS? ; record APB1/APB2 timer clocks = ? MHz (used for timer math below)

## Peripherals
- TIMx (control tick): Clock Source Internal; PSC = ?, ARR = ?  → f = f_timclk / ((PSC+1)(ARR+1)) = ? Hz
  NVIC: TIMx global interrupt ✓, preemption priority ?
- USART2 (plant link): Asynchronous, 115200 8N1, pins ?, NVIC ✓ / DMA RX circular?
- ...

## Project Manager
- Project name p<N>_<name>, location fw/
- Toolchain/IDE: **CMake**
- Code Generator: "Copy only the necessary library files" ✓, "Generate peripheral initialization as a pair of '.c/.h' files per peripheral" ✓, "Keep User Code when re-generating" ✓

## Renode implications
- <each choice → which registers firmware will poll / which peripheral models must exist; expected gaps>
```

## 3. Cross-check
- Timer frequencies are computed from the actual timer clock (H7 timers run at 2×APBx when the APB prescaler isn't 1; verify this in the Clock tab).
- No pin conflicts with Nucleo solder-bridge defaults. Note anything that needs an SB change.
- Interrupt priorities: control tick above the comms ISRs. Never use priority 0 for application ISRs.

## 4. Hand-off
Tell the owner: apply the checklist, press **GENERATE CODE**, then run the `cubemx-regen` skill.
