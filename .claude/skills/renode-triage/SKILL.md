---
name: renode-triage
description: Step-by-step diagnosis when firmware hangs, crashes, or misbehaves in Renode but should work (or works on hardware) - locate PC, find polled register, check whether peripheral is modeled, fix via overlay, record lesson. Use for "stuck in SystemClock_Config", "no UART output in Renode", "HardFault only in emulation", etc.
argument-hint: "<N> <symptom>"
---

# Renode triage: $ARGUMENTS

Do this as a teaching walkthrough: show each command and say what its output means. For the bigger investigation, hand off to the **renode-specialist** agent.

## 1. Reproduce headless
```
renode --disable-xwt --console -e 'include @projects/pN_*/renode/pN.resc; start'
```
Let it run about 2 virtual seconds, then `pause`.

## 2. Where is it?
```
cpu PC
sysbus FindSymbolAt `cpu PC`
cpu Step 20           # repeat; is PC looping in a small range?
```
The symbol name usually gives it away, for example `HAL_RCC_OscConfig`, `HAL_PWREx_ConfigSupply`, or `HAL_UART_Transmit`.

## 3. What is it polling?
```
sysbus LogPeripheralAccess sysbus.rcc true      # or pwr, usart3, tim2 ...
logLevel -1 sysbus.rcc
start ; pause
```
Find the register offset that's read repeatedly, then look up the bit in RM0433 (for example RCC_CR.PLL1RDY, PWR_CSR1.ACTVOSRDY, or PWR_D3CR.VOSRDY).
Unmapped accesses show up as `WARNING: ... read from non existing peripheral` or `unhandled read`.

## 4. Classify
| Finding | Meaning | Fix |
|---|---|---|
| Unmapped address | No model at all | Add a Tag or a Python peripheral in `pN_overlay.repl` |
| Modeled, but the bit never sets | The model is incomplete | Python peripheral or a C# override that returns the ready bit |
| HardFault | Bad memory region, FPU not enabled, or unaligned access | `cpu LogFunctionNames true`, inspect CFSR/HFSR with `sysbus ReadDoubleWord 0xE000ED28` |
| Works but wrong timing | Clock frequency mismatch | Check the `.repl` `frequency` vs. the CubeMX SYSCLK, and timer frequencies |

## 5. Fix in the overlay only
Never edit firmware to work around the emulator, and never edit upstream `.repl` files. Write the minimal overlay entry and reload. Comment it with the register and the RM0433 section.

## 6. Verify and record
- Re-run `make test P=pN TAGS=smoke`.
- Project README "Problems hit": symptom → root cause (register and bit) → fix (link to the overlay line) → lesson.
- Add a row to `docs/troubleshooting.md` if it'll recur in later projects.
