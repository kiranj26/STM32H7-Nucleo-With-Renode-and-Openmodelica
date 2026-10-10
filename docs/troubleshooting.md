# Troubleshooting registry

Issues likely to come up more than once. Add a row whenever a project's "Problems hit" entry would help a later project. The entries marked *(expected)* are predictions from planning and haven't been verified yet. Replace them with real findings.

| # | Symptom | Root cause | Fix | Seen in |
|---|---|---|---|---|
| T1 | Firmware stuck in `HAL_RCC_OscConfig` / `HAL_PWREx_ConfigSupply` in Renode, but fine on the board | RCC or PWR ready flags (PLLxRDY, ACTVOSRDY, VOSRDY) not modeled by the Renode H743 platform | Overlay `.repl` returning the ready bits; see the `renode-triage` skill | *(expected)* P0 |
| T2 | FMU result drifts from `simulate()`, or is unstable at larger steps | The default OpenModelica CS FMU solver is explicit Euler | Export with `--fmiFlags=s:cvode`, then validate with the `fmu-export-validate` skill | *(expected)* P1 |
| T3 | `st-flash`/serial "no device" from inside the container | Docker on macOS has no USB passthrough | Flash and use serial from the macOS host (`make hw`) | *(expected)* P0 |
| T4 | Works in Renode, garbage DMA data on the board | D-cache coherency: Renode doesn't model the cache | Non-cacheable MPU region, or clean/invalidate; buffers not in DTCM | *(expected)* P3 |
| T5 | Bridge connects but sees no data after a snapshot `Load` | External socket connections aren't part of the snapshot | Re-create the terminal and reconnect after `Load` | *(expected)* P2 |
| T6 | Modelica initialization fails with friction or stiction | Over- or under-determined initial system, or conflicting `fixed=true` | `-d=initialization`, the transformational debugger; explicit `initial equation` | *(expected)* P3 |
| T7 | Robot test flaky only on CI | Host-time dependence (sleep or wall-clock timeout) | Assert on virtual time; `Wait For ...` with virtual timeouts | *(expected)* |
