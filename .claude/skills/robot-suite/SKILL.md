---
name: robot-suite
description: Design and scaffold Robot Framework tests or keyword libraries for a project - requirement-named tests, data-driven templates, tags, target switching, a Python keyword library wrapping labkit, and pytest for the logic. Use when adding tests or a new keyword library.
argument-hint: "<N> <what to verify>"
---

# Robot tests for P$ARGUMENTS

1. **Requirements → tests.** List the requirements (from the roadmap, the README, or `requirements.yaml` in P5+). One test per requirement, named as the requirement. Thresholds become `*** Variables ***` with units.
2. **Pick a pattern:**
   - **A single behavior:** a plain test.
   - **The same check over many inputs:** `Test Template` with a table (P2+).
   - **Robustness sweeps:** a template plus a listener or library that aggregates results (P4).
   - **Faults:** snapshot fork per case with `Execute Command  Load @snap/...` in `Test Setup` (P5).
3. **Keywords.** Reuse `tests/common/renode.resource` first. New domain keywords (`Overshoot Should Be Below`, ...) go in a Python library, `tests/common/<Area>.py`, written as thin wrappers over `tools/labkit`, with pytest for the logic in `tools/labkit/tests/`.
4. **Tags:** `pN`, plus exactly one of `smoke` or `long`, plus `hw` if it needs the board, plus `REQ-*` from P5.
5. **Dry run:** `robot --dryrun projects/pN_*/robot/` checks syntax and keyword resolution without running anything.
6. **Real run** via the `run-suite` skill.

🎓 **P0–P1:** the owner writes the first tests; Claude reviews them and explains the Robot constructs.
