---
name: start-project
description: Scaffold a new curriculum project (pN) - branch, projects/pN_name folders, README from template, Robot suite, .resc, .mos stubs, firmware app/ folder, roadmap/checklist wiring, and the CubeMX checklist. Use when beginning P0..P6.
argument-hint: "<N> <short_name>   e.g. 1 thermal"
disable-model-invocation: true
---

# Start project P$ARGUMENTS

Arguments: `N` (0–6) and `name` (snake_case, for example `thermal`, `tanks`, `motor`, `pendulum`, `bms`, `capstone`).

## Preconditions
- The previous project has a `p<N-1>-done` tag (except P0). If not, warn and ask whether to continue anyway.
- The working tree is clean.

## Steps
1. **Branch:** `git switch -c pN/scaffold`.
2. **Folders.** Create:
   ```
   projects/pN_<name>/{model,scripts,renode,robot,results}/
   fw/pN_<name>/app/
   ```
   Put a `.gitkeep` in each empty folder.
3. **README:** copy `docs/templates/PROJECT_README.md` to `projects/pN_<name>/README.md`. Fill in the Goal and the "Features to learn" table from the pN section of `docs/ROADMAP.md`. Mark 🎓 steps: by default, the derivations and the first use of each new tool feature are 🎓.
4. **Stubs from `templates/`** in this skill folder. Replace `{{N}}`, `{{name}}`, and `{{Name}}`:
   - `pN.resc.tmpl` → `projects/pN_<name>/renode/pN.resc`
   - `suite.robot.tmpl` → `projects/pN_<name>/robot/pN_<name>.robot`
   - `sim.mos.tmpl` → `projects/pN_<name>/scripts/pN.mos`
   - `app.c.tmpl` / `app.h.tmpl` → `fw/pN_<name>/app/`
5. **CubeMX checklist:** run the `cubemx-setup` skill for pN and save its output as `fw/pN_<name>/CUBEMX.md`. The owner creates the `.ioc` and generates code; Claude doesn't.
6. **Wiring:** add pN to the Makefile project list if the Makefile has one, and add pN rows to `docs/feature-checklist.md` (unticked).
7. **Status:** update `CLAUDE.md` "Current status" → Active: PN.
8. **Report:** show the created tree. Then list the owner's next actions, in order:
   1. CubeMX (follow `fw/pN_<name>/CUBEMX.md`)
   2. the first 🎓 step
   3. which skill or agent helps

Don't commit. Offer a commit message instead: `chore(pN): scaffold project`.
