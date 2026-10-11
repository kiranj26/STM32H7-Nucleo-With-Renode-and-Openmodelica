# CLAUDE.md

This file holds shared, version-controlled instructions for Claude Code in this repository. Personal overrides go in `CLAUDE.local.md`, which is gitignored.

## What this repo is
This is a 7-project learning curriculum (P0–P6) on the **STM32 Nucleo-H743ZI2**. It uses:
- **Renode** for emulation
- **OpenModelica** for plant modeling and FMU export
- **Robot Framework** for test automation
- a control concept that gets deeper in each project

**The product is evidence of learning.** Firmware that works is necessary but not enough. Every project must also ship its models, scripts, tests, committed reports, plots, and an honest "What I learned" README.

The full roadmap is in `docs/ROADMAP.md`. Read it before starting work on a new project.

## How to work with me (the owner)
- **This is a learning repo, so pair with me rather than replace me.** Steps marked 🎓 in a project README are mine to do: for example annotating the `.repl` file, deriving gains, or debugging a Renode hang. For those steps, explain, point to docs, and review. Don't produce the finished answer unless I ask for it.
- **Explain the "why" in one or two sentences** when you use a tool feature for the first time in the repo, such as a Renode monitor command, an OMC scripting function, or a Robot construct.
- **Prefer scripts over GUI steps.** If something was done by clicking (OMEdit, CubeMX), record it in a script or README so it can be reproduced.
- **Be honest about verification.** Say whether a step ran in Renode, ran on the physical board, or was only compiled. Never claim hardware results from emulation.

## Repository map
```
fw/common/ctrl/      pure C99 control code: NO HAL includes, builds for arm AND host
fw/common/bsp/       thin HAL/LL helpers shared across projects
fw/common/link/      COBS+CRC16 frame protocol (C side)
fw/pN_<name>/        CubeMX project: <name>.ioc + generated Core/ Drivers/ cmake/ + app/
models/Lab/          shared Modelica package (Lab.Thermal, Lab.Hydraulics, ...)
tools/labkit/        Python: fmu, renode, bridge, link, metrics, runlog, plots (+ tests/)
tests/common/        Robot resources (renode.resource) and keyword libraries
projects/pN_<name>/  model/ scripts/ renode/ robot/ results/ README.md
docs/                ROADMAP.md, feature-checklist.md, dev-environment.md, troubleshooting.md, glossary.md, adr/, notes/, templates/
.devcontainer/       the single toolchain image (OpenModelica, Renode, arm-gcc, Robot, Python)
.claude/             rules (path-scoped), agents, skills, hooks. See .claude/README.md
```

## Where to look first
- **What to do next:** the `/status` skill, or `docs/ROADMAP.md`
- **A firmware hang in Renode:** the `/renode-triage` skill and `docs/troubleshooting.md`
- **Why something is built this way:** `docs/adr/`
- **Every workflow and agent:** `.claude/README.md`

## Commands (always go through the Makefile)
| Task | Command | Where |
|---|---|---|
| Check that all tools are present | `make doctor` | container |
| Lint (ruff, clang-format check) | `make lint` | container |
| Build firmware | `make fw P=p1` | container |
| Host unit tests for `ctrl/` and `labkit` | `make unit` | container |
| Simulate models / build FMU | `make sim P=p1` / `make fmu P=p1` | container |
| Robot suite | `make test P=p1 [TAGS=smoke] [TARGET=renode]` | container |
| Flash and run on the board | `make hw P=p1` | **macOS host** (needs USB) |

There is no USB passthrough into Docker on macOS. **CubeMX, flashing, and serial access run natively on the Mac**; everything else runs in the devcontainer. If a command fails because a tool is missing, check which side you're on before installing anything.

## Hard rules
1. **CubeMX-generated code:**
   - Edit `fw/pN_*/Core/**` only inside `/* USER CODE BEGIN … */ … /* USER CODE END … */` blocks.
   - Never edit `Drivers/**`, `cmake/stm32cubemx/**`, or the `.ioc` by hand. Change the `.ioc` in the CubeMX GUI and regenerate.
   - Put new code in `app/` or `fw/common/`.
   - A hook enforces all of this.
2. **`fw/common/ctrl/` must stay HAL-free** and compile on the host (`make unit`). This is what makes SIL in P6 possible.
3. **Control loops run from a timer ISR at a fixed Ts.** No `HAL_Delay`, `printf`, or blocking I/O on the control path.
4. **Time:** test assertions use **virtual** (emulated) time, never wall-clock sleeps. Robot timeouts are the exception, and only as a safety net.
5. **Plant FMUs are validated** against `simulate()` output before any closed-loop test relies on them.
6. **Results are evidence.** Don't delete or overwrite committed `projects/*/results/**`. Add new dated runs instead.
7. **Don't edit tests to make them pass.** Thresholds in Robot suites are requirements. Change one only with a written reason in the commit message.

## Conventions
- **Commits** follow Conventional Commits, with the project as the scope: `feat(p1): discrete PID with back-calc anti-windup`. Other scopes are `labkit`, `ci`, `devenv`, `docs`, `models`, and `common`.
- **Branches** are named `pN/<topic>`. Each finished project gets the git tag `pN-done`.
- **Architecture decisions** go in `docs/adr/NNNN-title.md` (see the `adr` skill).
- **Style:**
  - C: `.clang-format` (LLVM-based, 4-space).
  - Python: 3.11, `ruff`, type hints, and pytest.
  - Modelica: one class per file inside `models/Lab/`, with units on every variable.

## Definition of done (per project)
- [ ] `make fw`, `make unit`, `make fmu`, and `make test TAGS=smoke` pass in the container
- [ ] The CI job for the project is green
- [ ] The hardware run was done (or is marked N/A with a reason) and recorded in the README
- [ ] `results/` contains `report.html`, `log.html`, and 2–4 plots
- [ ] The project README has Goal, Features used (linked), Problems hit and fixes, Results, and What I'd do differently
- [ ] `docs/feature-checklist.md` is updated, and the `pN-done` tag is created (via the `/close-project` skill)

Note: the Makefile, devcontainer and `tests/common` exist since P0 (`make doctor/lint/fw/sim/test/hw`). `make unit` and `make fmu` are stubs until P1, and `tools/labkit` doesn't exist yet (P1). The **container-built ELF is canonical**: `make fw` refuses to run on the host (see `docs/dev-environment.md`).

## Current status
<!-- Updated by the close-project skill. -->
- Active project: **P0: Toolchain warm-up**: all milestones done on `p0/scaffold` (PR #3); remaining: owner review, README §7, merge, `p0-done` tag
- Completed: none
