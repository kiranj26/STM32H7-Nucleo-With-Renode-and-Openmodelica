---
name: close-project
description: Definition-of-done gate for a curriculum project - runs builds/tests, the learning-reviewer audit, updates the feature checklist and CLAUDE.md status, and (with owner approval) tags pN-done. Use only when the owner says a project is finished.
argument-hint: "<N>"
disable-model-invocation: true
---

# Close project P$ARGUMENTS

The steps run in order. **Stop at the first failing gate** and report what's missing. Never loosen a test or skip a gate to get through.

## Gate 1: builds and tests (container)
Run each command and record its result:
- `make lint`
- `make unit`
- `make fw P=pN`
- `make fmu P=pN`
- `make test P=pN TAGS=smoke`
- `make test P=pN TAGS=long`. If it takes over 15 minutes, ask the owner first.

## Gate 2: CI
`gh run list --branch <current> --limit 3`. The latest run must be green for this commit. If `gh` isn't available, ask the owner to confirm.

## Gate 3: hardware
The project README "Results" must contain a hardware run (`TARGET:hw`), or "HW: N/A, <reason>". Claude can't produce this from the container, so ask the owner if it's missing.

## Gate 4: learning audit
Launch the **learning-reviewer** agent on pN and paste its table. Every "Must fix" item blocks closing.

## Gate 5: evidence
`projects/pN_*/results/` has at least one dated run folder containing `report.html`, `log.html`, `meta.json`, and 2+ PNGs, and the README links to it.

## Close
1. Tick the pN rows in `docs/feature-checklist.md`, with links.
2. Update `CLAUDE.md` "Current status": move pN to Completed and set Active to P(N+1).
3. Show the owner a summary of all gates, then **ask** before running:
   - `git commit -m "docs(pN): close project"` (with the repo's attribution trailer)
   - `git tag -a pN-done -m "PN <name> complete: <one-line result>"`
4. Suggest that the owner writes a short reflection: one paragraph, written by them and not by Claude, at the top of the README "What I'd do differently" section.
