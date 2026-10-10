# ADR-0003: HAL-free, host-buildable control layer

- **Status:** Accepted
- **Date:** 2026-10-10
- **Project:** P1

## Context
P6 runs the same controller at the MIL, SIL, PIL, and HW levels. Controllers also need fast unit tests without the emulator. If control code calls HAL or touches registers, every one of those uses needs the target or Renode.

## Decision
All control algorithms (PID, filters, scheduling, LQR, observers, FSMs, SOC estimation) live in `fw/common/ctrl/` as pure C99 using only standard headers. State is held in structs passed by pointer. The code builds for arm (firmware) and for the host (`make unit`, P6 SIL). Hardware access stays in `fw/common/bsp/` and `fw/pN_*/app/`.

## Alternatives considered
- **Controller inside `app/` with direct HAL calls:** simpler at first, but there's no SIL and no host tests, and P6 would need a rewrite.
- **C++ templates/classes:** fine on the M7, but they add language overhead to a C-centric HAL codebase and to Modelica source-FMU interop.

## Consequences
- **Easier:** unit tests in milliseconds; SIL for free; the same code in every comparison plot.
- **Harder:** a little more plumbing (values passed in and out explicitly). Enforced by `.claude/hooks/ctrl_hal_free.py`.
- **Revisit when:** never expected to change.
