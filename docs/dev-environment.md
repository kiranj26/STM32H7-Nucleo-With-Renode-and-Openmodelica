# Development environment

Two environments, each with a clear job:

| | macOS host (Apple Silicon) | Devcontainer (`linux/amd64` under Rosetta) |
|---|---|---|
| STM32CubeMX (GUI) | ✅ | ❌ |
| Flashing, ST-LINK, serial VCP | ✅ (USB) | ❌ (no USB passthrough on macOS) |
| arm-none-eabi-gcc, CMake, Ninja | optional | ✅ |
| OpenModelica (omc, OMPython) | ❌ (no maintained macOS build) | ✅ |
| Renode | optional (macOS build exists) | ✅ |
| Robot Framework, FMPy, labkit | for `TARGET:hw` only | ✅ |
| GitHub Actions | | ✅ (same image) |

The repository is bind-mounted into the container, so `build/` artifacts (ELFs, FMUs) are visible on both sides.

## macOS host setup
1. **Container runtime:** OrbStack (recommended) or Colima, with Rosetta/x86 emulation enabled.
2. **STM32CubeMX:** 6.18 is installed at `/Applications/STMicroelectronics/STM32CubeMX.app`. Install the **STM32CubeH7** firmware pack from Help → Manage embedded software packages. It lands in `~/STM32Cube/Repository`.
3. **Flashing and serial:**
   ```sh
   brew install stlink open-ocd
   python3 -m pip install --user pyserial
   ```
   Optionally install STM32CubeProgrammer from st.com.
4. **Optional:** the Arm GNU toolchain (for host-side `arm-none-eabi-gdb`, used with Cortex-Debug in VS Code): `brew install --cask gcc-arm-embedded`.
5. **Personal settings:** copy `.claude/settings.local.json.example` to `.claude/settings.local.json` and set `NUCLEO_SERIAL_PORT`.

## Devcontainer
- Open the repo in VS Code and choose **Reopen in Container**. Or from the CLI: `docker build --platform linux/amd64 -t h7lab .devcontainer && docker run --rm -it --platform linux/amd64 -v "$PWD":/work -w /work h7lab`.
- Smoke check inside: `make doctor`, which prints the versions of all tools.

## Pinned versions
Fill this table when the Dockerfile is written; update it on every upgrade, with the date.

| Tool | Version | Source | Pinned on |
|---|---|---|---|
| Ubuntu base | | | |
| OpenModelica | | build.openmodelica.org apt | |
| Modelica Standard Library | 4.0.0 | bundled / `installPackage` | |
| Renode | | github.com/renode/renode releases | |
| Arm GNU Toolchain | | developer.arm.com | |
| Python | 3.11 | | |
| robotframework / fmpy / OMPython / pyrenode3 | | `requirements.txt` | |
| STM32CubeMX (host) | 6.18 | st.com | 2026-10-10 |
| STM32CubeH7 pack (host) | FW_H7 V1.13.0 | CubeMX package manager | 2026-10-10 |

## Upgrade policy
Upgrade only between projects, never in the middle of one. Record the upgrade in an ADR if it changes behavior (for example a Renode platform change).
