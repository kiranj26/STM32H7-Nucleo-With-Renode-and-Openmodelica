# `.claude/`: how Claude Code works in this repo

This folder configures Claude Code for the STM32H7 + Renode + OpenModelica + Robot curriculum. It works like a product team's engineering handbook: shared guardrails, specialist reviewers, and repeatable workflows. Everything here is version-controlled except the files marked *personal*.

```
CLAUDE.md                     ← always loaded: what the repo is, commands, hard rules, definition of done, current status
CLAUDE.local.md               ← personal notes (gitignored; template: CLAUDE.local.md.example)
.claude/
├── README.md                 ← this file
├── settings.json             ← shared permissions + hooks
├── settings.local.json       ← personal overrides (gitignored; template: settings.local.json.example)
├── rules/                    ← conventions that load only when matching files are touched
├── agents/                   ← specialist subagents (reviewers / experts)
├── skills/                   ← repeatable workflows, invoked as /<name>
├── output-styles/mentor.md   ← "teach me" mode
└── hooks/                    ← guardrail scripts + their tests
```

## Day-to-day workflow
| When | Do |
|---|---|
| Start of a session | `/status` gives the active project, progress, and the one next step |
| Starting P0…P6 | `/start-project 1 thermal` |
| Before touching the `.ioc` | `/cubemx-setup 1 add TIM2 PWM`, then apply it in CubeMX on the Mac |
| After pressing GENERATE CODE | `/cubemx-regen 1` |
| Writing a plant model | `/modelica-model Lab.Thermal.Chamber` |
| Model changed | `/fmu-export-validate 1 Lab.Thermal.Chamber 0.1` |
| Designing or tuning a controller | `/controller-design 1 pid` |
| Firmware hangs in Renode | `/renode-triage 0 stuck in SystemClock_Config` |
| Need a new emulated peripheral (P3+) | `/renode-peripheral 3 QuadEncoder 0x40000400 30` |
| Writing tests | `/robot-suite 1 settles within 1 degC` |
| Running tests | `/run-suite 1 TAGS=smoke archive` |
| On the real board (Mac terminal) | `/flash-board 1 robot` |
| Figured something out | `/learning-log 1` |
| "How does X work?" | `/explain renode snapshots` (and `/output-style mentor`) |
| Big technical choice | `/adr use lockstep co-simulation` |
| Project finished | `/close-project 1` (gates, audit, `p1-done` tag) |

Skills marked `disable-model-invocation` (`start-project`, `close-project`, `flash-board`) only run when **you** type them. Claude won't start them on its own, because they create branches or tags or touch hardware.

## Agents (subagents)
Claude delegates to these automatically when the task matches. You can also ask for one by name ("have the firmware-reviewer look at this diff").

| Agent | Use for | Edits files? |
|---|---|---|
| `firmware-reviewer` | Review `fw/**` diffs: ISR safety, H7 cache/DMA, CubeMX discipline, portability | No |
| `renode-specialist` | `.resc`/`.repl`, hangs, custom peripherals, GDB, time sync, profiling | Yes |
| `modelica-modeler` | Models, `.mos`, initialization and event debugging, `linearize`, FMU export | Yes |
| `controls-engineer` | Controller design, discretization, gain headers, metric interpretation | Yes |
| `test-engineer` | Robot suites, keyword libraries, failure triage, traceability | Yes |
| `devenv-ci-engineer` | Dockerfile, Makefile, GitHub Actions, host setup | Yes |
| `learning-reviewer` | "Is this project portfolio-ready?" audit before `pN-done` | No |

## Rules (`rules/`)
These load automatically when Claude works on matching paths, so `CLAUDE.md` stays short.

| File | Applies to |
|---|---|
| `firmware-c.md` | `fw/**/*.c,h`, CMake |
| `cubemx.md` | `fw/p*/**`, `*.ioc` |
| `renode.md` | `*.resc`, `*.repl`, `renode/**` |
| `modelica.md` | `*.mo`, `*.mos`, `models/**` |
| `robot.md` | `*.robot`, `*.resource`, `tests/**` |
| `python-labkit.md` | `tools/**`, project and test Python |
| `ci-devenv.md` | `.devcontainer/**`, workflows, Makefile |
| `docs-results.md` | project READMEs, `results/**`, `docs/**` |

## Guardrails (`hooks/` + `settings.json`)
| Hook | Event | What it does |
|---|---|---|
| `guard_generated_code.py` | before Edit/Write | Blocks edits to CubeMX output outside `USER CODE` blocks, any edit to `Drivers/` and `cmake/stm32cubemx/`, and hand edits of `.ioc` |
| `guard_results.py` | before Edit/Write | Blocks overwriting committed `projects/*/results/**` evidence |
| `guard_bash.py` | before Bash | Blocks force-push, board mass-erase, `sed` on `.ioc`, deleting results, and long wall-clock `sleep` |
| `ctrl_hal_free.py` | after Edit/Write | Reports HAL, CMSIS, or register use in `fw/common/ctrl/` (it must build on the host) |
| `format_changed.py` | after Edit/Write | clang-format or ruff on hand-written code only (skipped if the tool isn't installed) |
| `session_context.py` | session start | Tells Claude: host vs. container, branch, completed projects, missing tools |

Every hook command is written as `[ -f script ] || exit 0; python3 script`, so a missing or renamed script **never blocks the session**. Hooks are Python 3.9-compatible because they also run with macOS system Python.

**Test the hooks** after changing them:
```sh
python3 -m unittest discover -s .claude/hooks/tests -v
```

**Permissions:**
- *Allowed* without asking: builds, unit tests, simulation, Robot, read-only git.
- *Ask first*: flashing, Docker, commits, tags, pushes, installs.
- *Denied*: force-push, chip erase, editing `Drivers/`.

Personal loosening, for example auto-allowing `make hw`, goes in `settings.local.json`.

## Extending this setup
- **New workflow:** add `skills/<name>/SKILL.md` with `name` and `description` frontmatter. The description decides when Claude uses it automatically, so be specific. Put templates next to it.
- **New specialist:** add `agents/<name>.md` with `name`, `description`, `tools`, and `model` frontmatter. Make reviewers read-only (no Edit or Write in `tools`).
- **New convention:** add it to the matching `rules/*.md`, or create one with a `paths:` glob. Keep `CLAUDE.md` for things that apply everywhere.
- **New guardrail:** add a hook script, a test in `hooks/tests/test_hooks.py`, and the `settings.json` entry, in that order. Writing the settings entry first can block every tool call.
- **Review cadence:** at each `pN-done`, skim this folder and delete anything stale. A wrong instruction is worse than a missing one.
