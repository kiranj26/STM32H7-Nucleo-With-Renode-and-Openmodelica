# Glossary

| Term | Meaning in this repo |
|---|---|
| **MIL**, Model-in-the-Loop | Controller and plant both run as models (Modelica, or Python plus FMU). There is no firmware. |
| **SIL**, Software-in-the-Loop | The real controller C code (`fw/common/ctrl`), compiled for the host, against the plant FMU. |
| **PIL**, Processor-in-the-Loop | The real firmware ELF running in Renode (an emulated Cortex-M7) against the plant FMU. |
| **HW / HIL-lite** | The real firmware on the physical Nucleo board, with the plant FMU on the host over the USB VCP. |
| **FMU / FMI** | Functional Mock-up Unit: a zip with a compiled model plus XML, following the FMI 2.0 standard. **CS** (co-simulation) FMUs include their own solver; **ME** (model exchange) FMUs need an external one. |
| **`.repl`** | Renode platform description: the CPU, memory map, peripherals, and interrupt wiring. |
| **`.resc`** | Renode script: monitor commands that create a machine, load the platform and ELF, and set up connections. |
| **Overlay** | An extra `.repl` loaded after the upstream platform, used to add or fix peripherals without editing upstream files. |
| **Virtual time** | Time as seen by the emulated machine. Independent of host (wall-clock) time. |
| **Quantum** | The maximum chunk of virtual time Renode advances before synchronizing. It affects co-sim timing fidelity and speed. |
| **Lockstep** | Co-simulation where the emulator and plant alternately advance by exactly Ts. |
| **Ts** | Controller sample period. |
| **ZOH** | Zero-order hold: the actuator value stays constant between samples. It adds an effective delay of about Ts/2. |
| **Anti-windup** | Stops the integrator from accumulating while the actuator is saturated (back-calculation, clamping). |
| **Gain scheduling** | Controller gains change with the operating point, chosen from linearizations at several points. |
| **LQR** | Linear-Quadratic Regulator: optimal state-feedback gain K that minimizes ∫(xᵀQx + uᵀRu). |
| **KF / EKF** | Kalman filter / Extended Kalman filter: optimal state estimator (EKF linearizes a nonlinear model at each step). |
| **SOC** | State of charge of a battery cell (0–1). |
| **USER CODE block** | `/* USER CODE BEGIN x */ ... /* USER CODE END x */` regions that CubeMX preserves when regenerating. |
| **VCP** | Virtual COM port: the ST-LINK's USB serial bridge, wired to USART3 (PD8/PD9) on the Nucleo-H743ZI2. |
| **🎓 step** | A task the owner does personally for learning; Claude explains and reviews but doesn't solve it. |
