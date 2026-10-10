# ADR-0001: Firmware from STM32CubeMX with CMake output

- **Status:** Accepted
- **Date:** 2026-10-10
- **Project:** P0

## Context
The firmware needs STM32H7 HAL/LL drivers, a correct clock tree, pin muxing, and interrupt setup. STM32CubeMX 6.18 is already installed on the macOS host. The build must also run headless in a Linux container and in CI, without an IDE. The curriculum aims at industry-relevant STM32 skills, and wants register-level visibility in Renode (`LogPeripheralAccess`).

## Decision
Each project's firmware is a CubeMX project (`fw/pN_<name>/<name>.ioc`) started from the NUCLEO-H743ZI2 board selector and generated with the **CMake** toolchain option. The `.ioc` file and all generated code are committed. Hand-written code lives only in USER CODE blocks, `app/`, and `fw/common/`. The container builds the generated CMake project with arm-none-eabi-gcc.

## Alternatives considered
- **HAL as a git submodule plus a hand-written CMake setup:** more control, but it duplicates what CubeMX gets right (the clock tree) and skips an industry tool.
- **Zephyr:** good Renode integration, but a second large learning curve, and it hides registers.
- **Bare metal / CMSIS only:** the most insight, but too much boilerplate for a controls-focused curriculum.

## Consequences
- **Easier:** correct clock and peripheral init; fast peripheral additions; standard project layout.
- **Harder:** generated-code discipline is required (enforced by `.claude/hooks/guard_generated_code.py`); `.ioc` changes are GUI-only on the host.
- **Revisit when:** STM32CubeMX2 supports the H7 and offers better CLI or headless generation.
