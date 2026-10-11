# Troubleshooting registry

Issues likely to come up more than once. Add a row whenever a project's "Problems hit" entry would help a later project. The entries marked *(expected)* are predictions from planning and haven't been verified yet. Replace them with real findings.

| # | Symptom | Root cause | Fix | Seen in |
|---|---|---|---|---|
| T1 | Firmware stuck in `HAL_RCC_OscConfig` / `HAL_PWREx_ConfigSupply` in Renode, but fine on the board | RCC or PWR ready flags (PLLxRDY, ACTVOSRDY, VOSRDY) not modeled by the Renode H743 platform | Overlay `.repl` returning the ready bits; see the `renode-triage` skill | **Did not occur in P0** with Renode 1.17.0: upstream stubs PWR (always ready) and models RCC. Keep for other Renode versions/platforms |
| T2 | FMU result drifts from `simulate()`, or is unstable at larger steps | The default OpenModelica CS FMU solver is explicit Euler | Export with `--fmiFlags=s:cvode`, then validate with the `fmu-export-validate` skill | *(expected)* P1 |
| T3 | `st-flash`/serial "no device" from inside the container | Docker on macOS has no USB passthrough | Flash and use serial from the macOS host (`make hw`) | *(expected)* P0 |
| T4 | Works in Renode, garbage DMA data on the board | D-cache coherency: Renode doesn't model the cache | Non-cacheable MPU region, or clean/invalidate; buffers not in DTCM | *(expected)* P3 |
| T5 | Bridge connects but sees no data after a snapshot `Load` | External socket connections aren't part of the snapshot | Re-create the terminal and reconnect after `Load` | *(expected)* P2 |
| T6 | Modelica initialization fails with friction or stiction | Over- or under-determined initial system, or conflicting `fixed=true` | `-d=initialization`, the transformational debugger; explicit `initial equation` | *(expected)* P3 |
| T7 | Robot test flaky only on CI | Host-time dependence (sleep or wall-clock timeout) | Assert on virtual time; `Wait For ...` with virtual timeouts | *(expected)* |
| T8 | `resource busy: /dev/tty.usbmodem…` when opening the VCP | Another process (often a detached `screen`) still holds the port | `lsof /dev/tty.usbmodem*`, then `screen -S <pid> -X quit`; quit `screen` with `Ctrl-A K`, not by closing the window | P0 |
| T9 | First lines of a VCP capture are old output, all with one timestamp | Bytes sent before the capture/reset sat in the USB VCP buffer | Drain the port before resetting the target ([capture_uart.pl](../projects/p0_blinky/scripts/capture_uart.pl)) | P0 |
| T10 | Code in `main.c` vanishes after CubeMX regeneration | It was placed between two USER CODE blocks, not inside one | Keep it strictly between `USER CODE BEGIN x` and `USER CODE END x` | P0 (caught before regen) |
| T11 | Renode boot shows `ReadDoubleWord from non existing peripheral at 0x5C001000`, then a write to the GPV AXI-matrix tag | DBGMCU unmodeled: IDCODE reads 0, `SystemInit` takes the silicon rev-Y errata path | Overlay with a DBGMCU identity stub (`p0_overlay.repl`) | P0 |
| T12 | Cycle counts (DWT CYCCNT) in Renode don't match the board while `HAL_Delay` and timers are right | `stm32h7.repl` fixes DWT at 250 MHz; the RCC model re-times SysTick and TIMx from the firmware's clocks, but not DWT (measured: TIM2 200 MHz, DWT 250 MHz vs. 400 MHz CPU) | Set the `dwt` `frequency` in the project overlay to the CPU clock; re-measure with `projects/p0_blinky/scripts/renode_clock_check.sh` | P0 (measured), matters in P3 |
