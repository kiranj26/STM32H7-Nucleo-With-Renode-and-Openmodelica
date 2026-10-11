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
| Ubuntu base | 22.04 (`@sha256:5ec03bb3…`) | Docker Hub `ubuntu`, linux/amd64 | 2026-10-10 |
| OpenModelica | 1.27.1 (`omc`, no GUI) | build.openmodelica.org versioned apt repo (`releases/1.27.1 jammy release`) | 2026-10-10 |
| Modelica Standard Library | 4.0.0 (`4.0.0+maint.om`, with ModelicaServices/Complex 4.0.0) | OMC `installPackage(..., exactMatch=true)` at image build; build fails unless `getVersion` = 4.0.0; `make doctor` compares too | 2026-10-11 (was silently 4.1.0 before) |
| Renode | 1.17.0 linux-portable (sha256 checked) | github.com/renode/renode releases | 2026-10-10 |
| Arm GNU Toolchain | 15.3.rel2 = build arm-15.180, same as host (sha256 checked) | gitlab.arm.com generic packages | 2026-10-10 |
| Python | 3.11.16, uv 0.12.20 managed, venv `/opt/venv` | `ghcr.io/astral-sh/uv` | 2026-10-10 |
| robotframework / fmpy / OMPython | 6.1 (Renode's pin) / 0.3.32 / 4.1.0; all 45 packages in `requirements.txt` | `requirements.in` → `uv pip compile` | 2026-10-10 |
| CMake / Ninja | 4.4.4 / 1.13.2 (pip), same CMake as host | `requirements.txt` | 2026-10-10 |
| clang-format | 14.0.0 | Ubuntu jammy apt | 2026-10-10 |
| Arm GNU Toolchain (host) | 15.3.rel2 cask (reports 15.3.Rel1, build arm-15.180) | Homebrew `gcc-arm-embedded` | 2026-10-10 |
| CMake / Ninja (host) | 4.4.4 / 1.13.2 | Homebrew | 2026-10-10 |
| STM32CubeMX (host) | 6.18 | st.com | 2026-10-10 |
| STM32CubeH7 pack (host) | FW_H7 V1.13.0 | CubeMX package manager | 2026-10-10 |

## Which build is canonical
The macOS host and the container compile the **same code** with the same compiler build, but the `.bin` files are **not byte-identical**: Arm's `libc_nano.a` is packaged with a different member order on macOS than on Linux, so the linker places C-library functions (`printf`, `malloc`, …) at different addresses. Sizes and the function set are identical; only the layout differs. Therefore the **container-built ELF is the canonical firmware**: `make fw` runs in the container, and the host only flashes the files in `build/` (bind mount). Evidence: P0 README, "Problems hit".

## Upgrade policy
Upgrade only between projects, never in the middle of one. Record the upgrade in an ADR if it changes behavior (for example a Renode platform change).
