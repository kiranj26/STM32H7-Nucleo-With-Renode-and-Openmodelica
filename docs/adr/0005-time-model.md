# ADR-0005: Firmware-driven stepping first, orchestrator lockstep from P4

- **Status:** Accepted
- **Date:** 2026-10-10
- **Project:** P1 (first stage), P4 (second stage)

## Context
Renode runs firmware in virtual time, and the FMU advances only when stepped. If the bridge steps the FMU on host time, the plant and firmware drift apart, and results depend on host speed. True lockstep needs an orchestrator that controls Renode's virtual time, which is itself a P4 learning goal.

## Decision
- **P1–P3:** use firmware-driven stepping. Every control period, the firmware sends `{seq, actuation}`. The bridge steps the FMU by exactly Ts and replies `{seq, sensors}`. Plant time is tied to firmware control ticks, so it's implicitly synchronized to virtual time, and fine for slow plants.
- **P4 onward:** the orchestrator owns time. It calls `emulation RunFor Ts`, reads actuators from peripheral registers, calls FMU `doStep(Ts)`, and writes sensor values into peripheral models. Virtual time and host time are logged side by side.

## Alternatives considered
- **Lockstep from P1:** correct, but it front-loads the hardest Renode topic into the first closed loop.
- **Free-running bridge on host time:** simple, but results aren't reproducible, and it teaches the wrong habit.

## Consequences
- **Easier:** P1–P3 stay simple and still deterministic.
- **Harder:** in P1–P3 the firmware gates plant time, so a firmware stall freezes the plant and hides timing faults. P4 exists to expose exactly that.
- **Revisit when:** P4 is done. Decide whether P5 and P6 use lockstep everywhere.
