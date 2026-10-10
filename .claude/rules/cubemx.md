---
paths:
  - "fw/p*/**"
  - "**/*.ioc"
---

# CubeMX-generated projects

- **Ownership:**
  - CubeMX owns `Core/` (outside USER CODE blocks), `Drivers/`, `cmake/stm32cubemx/`, the startup `.s`, and `.mxproject`.
  - You own the USER CODE blocks, `app/`, and the root `CMakeLists.txt` "user sources" sections.
- **Hook enforcement:** a hook blocks edits outside USER CODE blocks, any edit to `Drivers/` or `cmake/stm32cubemx/`, and hand edits to `.ioc` files.
- **Peripheral, pin, clock, or NVIC changes:** these happen in the CubeMX GUI on the macOS host. Claude's job is to write the **exact** click path and values, for example: *Pinout → TIM2 → Channel1: PWM Generation CH1; Parameter Settings → Prescaler 239, Counter Period 999; NVIC → TIM2 global interrupt ✓*. The owner applies it and regenerates. Then run the `cubemx-regen` skill.
- **Generation settings** are fixed for every project:
  - Toolchain **CMake**
  - "Copy only necessary library files"
  - "Generate peripheral initialization as a pair of .c/.h files"
  - "Keep User Code when re-generating" ✓
- **Board baseline:** start each project from the **NUCLEO-H743ZI2** board selector and keep the defaults: USART3 = ST-LINK VCP on PD8/PD9, LD1 PB0, LD2 PE1, LD3 PB14, B1 PC13.
- **Clock-tree choices are Renode-relevant.** HSE source, PLL settings, and VOS level all determine which RCC/PWR ready flags the startup code polls. Record them in the project README's "Platform" section.
- **What to commit:** the `.ioc` plus all generated output, so the container can build without CubeMX.
