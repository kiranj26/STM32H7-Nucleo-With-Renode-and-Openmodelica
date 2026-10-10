# Feature checklist

A running record of **which tool features are demonstrated, and where**. A box is ticked only when a committed file uses the feature; link it. Updated by the `learning-log` and `close-project` skills.

Legend: `[ ]` planned · `[x]` demonstrated (with link)

## Renode
| Feature | Planned in | Status / evidence |
|---|---|---|
| `.resc` script: `mach create`, `LoadPlatformDescription`, `LoadELF` | P0 | [ ] |
| `showAnalyzer` / UART terminal | P0 | [ ] |
| Reading and annotating the platform `.repl` | P0 | [ ] |
| `logLevel`, `LogPeripheralAccess` | P0–P1 | [ ] |
| Overlay `.repl` fixing an unmodeled register | P0 | [ ] |
| Socket terminal (`CreateServerSocketTerminal`) and an external bridge | P1 | [ ] |
| Snapshots `Save`/`Load` | P2 | [ ] |
| Custom C# peripheral | P3 | [ ] |
| Python peripheral | P3 | [ ] |
| GDB server (`StartGdbServer`) | P3 | [ ] |
| CPU hooks (`AddHook`) | P3 | [ ] |
| Lockstep virtual-time co-simulation (`RunFor`, quantum) | P4 | [ ] |
| Profiler / execution tracing | P4 | [ ] |
| Fault injection from the monitor | P5 | [ ] |
| Multi-machine with a UART hub | P5 | [ ] |
| Headless CI and code coverage | P6 | [ ] |

## OpenModelica
| Feature | Planned in | Status / evidence |
|---|---|---|
| OMEdit graphical model | P0 | [ ] |
| Text equations model | P0 | [ ] |
| `.mos` scripting (`loadModel`, `simulate`, `getErrorString`) | P0–P1 | [ ] |
| Solver and tolerance study | P1 | [ ] |
| FMU export (CS, CVODE) and validation | P1 | [ ] |
| `linearize()` | P2 | [ ] |
| Parameter sweeps with OMPython | P2 | [ ] |
| Multi-domain (Electrical + Rotational) | P3 | [ ] |
| Events and friction / stiction | P3 | [ ] |
| Transformational debugger | P3 | [ ] |
| MultiBody plus 3D animation | P4 | [ ] |
| Battery library / equivalent circuit, `when` faults | P5 | [ ] |
| Clocked synchronous blocks | P6 | [ ] |
| Source-code FMU | P6 | [ ] |

## Robot Framework
| Feature | Planned in | Status / evidence |
|---|---|---|
| Renode keywords (`Create Terminal Tester`, `Wait For Line On Uart`) | P0 | [ ] |
| Reading `log.html` / `report.html` | P0 | [ ] |
| Suite Setup/Teardown with processes | P1 | [ ] |
| Variables and `${TARGET}` switching | P1 | [ ] |
| `Test Template` (data-driven) | P2 | [ ] |
| Tags (`smoke`/`long`/`hw`) | P2 | [ ] |
| Custom Python keyword library | P3 | [ ] |
| Sweeps and a result-aggregating listener | P4 | [ ] |
| Requirement tags and a traceability report | P5 | [ ] |
| Multi-target suite (MIL/SIL/PIL/HW) in CI | P6 | [ ] |

## Control
| Concept | Planned in | Status / evidence |
|---|---|---|
| Discrete PID, anti-windup, derivative filter | P1 | [ ] |
| Continuous vs. discrete comparison | P1 | [ ] |
| Gain scheduling and feedforward | P2 | [ ] |
| Cascaded loops, model-based tuning | P3 | [ ] |
| LQR | P4 | [ ] |
| Kalman filter | P4 | [ ] |
| Protection FSM, balancing | P5 | [ ] |
| SOC: Coulomb counting and EKF | P5 | [ ] |
| Quantization, fixed-point, delay study | P6 | [ ] |

## STM32 / firmware
| Feature | Planned in | Status / evidence |
|---|---|---|
| CubeMX board project to CMake | P0 | [ ] |
| Timer-ISR control tick | P1 | [ ] |
| UART DMA/IT ring buffer link | P1 | [ ] |
| PWM generation, encoder mode, ADC | P3 | [ ] |
| D-cache / MPU handling for DMA | P3 | [ ] |
| DWT cycle counting | P3 | [ ] |
| Watchdog | P5 | [ ] |
