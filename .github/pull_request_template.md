## What & why
<!-- One or two sentences. Link the project (P0–P6) and any ADR. -->

**Project:** P_ · **Type:** feat / fix / model / test / docs / ci / devenv

## Evidence
<!-- Paste the summary line(s) from `make test`, or link the results/ run folder. Say the level: MIL / SIL / Renode / HW. -->

## Checklist
- [ ] `make lint unit` passes
- [ ] `make fw P=pN` builds; size delta noted if significant
- [ ] `make test P=pN TAGS=smoke` passes in Renode
- [ ] CubeMX: generated code changed only through GUI regeneration; user code in USER CODE blocks / `app/`
- [ ] `fw/common/ctrl/` stays HAL-free, and new functions have host unit tests
- [ ] Plant model changed → FMU re-validated against `simulate()`
- [ ] No test thresholds loosened (or the reason is given below)
- [ ] Project README updated (Features used / Problems hit / Results)
- [ ] `docs/feature-checklist.md` updated if a feature was used for the first time
- [ ] Hardware run done, or N/A: ___

## Learned
<!-- One line for the learning log. -->
