---
paths:
  - "fw/**/*.c"
  - "fw/**/*.h"
  - "fw/**/CMakeLists.txt"
  - "fw/cmake/**"
---

# Firmware C rules (STM32H743, Cortex-M7)

## Layering
- `fw/common/ctrl/`: pure C99. Only `<stdint.h>`, `<stdbool.h>`, `<stddef.h>`, `<math.h>`, `<string.h>`, and its own headers. No HAL, CMSIS, or registers. It must build with the host compiler (`make unit`), and a hook flags violations.
- `fw/common/bsp/`: the only shared place that touches HAL/LL. Keep it thin, with one concern per file (`bsp_tick.c`, `bsp_uart.c`, `bsp_pwm.c`).
- `fw/pN_*/app/`: wiring and project logic. `main.c` calls `app_init()` and `app_loop()` from USER CODE blocks and nothing else.
- `fw/common/link/`: COBS + CRC16 framing. Its byte layout must match `tools/labkit/link.py`, and a change to one requires the same change to the other plus a round-trip test.

## Real-time rules
- The control step runs from a TIM update ISR at fixed Ts. The ISR either computes the step itself or sets a flag consumed by `app_loop()`; pick one per project and say which in the README.
- No `HAL_Delay`, `printf`, `malloc`, or blocking HAL calls on the control path. Use DMA or IT variants with ring buffers.
- Data shared between an ISR and the main loop is `volatile`. Multi-word shared state is copied with interrupts masked (`bsp_critical_enter/exit`) or is double-buffered.
- Controller state (integrator, filter memory, limits) lives in a struct passed by pointer, never in file-scope statics, so multiple loops and host tests work.

## H7-specific traps
- **D-cache and DMA:** DMA buffers live in a non-cacheable MPU region, or are cleaned and invalidated with `SCB_CleanDCache_by_Addr` / `SCB_InvalidateDCache_by_Addr`. Renode does not model the cache, so a bug here passes in emulation and fails on the board.
- **DTCM** (0x2000_0000) is not reachable by DMA1/DMA2. Put DMA buffers in AXI SRAM or D2 SRAM through a linker section.
- **Clock config:** `SystemClock_Config` belongs to CubeMX. If Renode hangs in it, fix the emulated platform (`.repl` overlay), not the firmware.

## Style
- Use `stdint` types, single-precision `float` (the M7 has an FPU), and `f`-suffixed literals (`0.5f`). Units go in names: `temp_degC`, `duty_pct`, `ts_s`.
- Every HAL call that returns `HAL_StatusTypeDef` is checked. Failures go to `bsp_fault(code)`.
- Formatting comes from the repo `.clang-format`; a hook formats `fw/common/**` and `app/**` automatically.

## Tests
- Every new function in `ctrl/` gets a host unit test in `fw/common/ctrl/tests/`, covering at least a nominal case, saturation, and reset behavior.
