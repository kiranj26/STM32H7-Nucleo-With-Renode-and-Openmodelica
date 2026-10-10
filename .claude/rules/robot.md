---
paths:
  - "**/*.robot"
  - "**/*.resource"
  - "tests/**"
---

# Robot Framework rules

## Structure
- Shared keywords live in `tests/common/renode.resource` (boot, load, bridge, teardown) and `tests/common/*.py` libraries (`LabKit.py`, `MotorMetrics.py`, ...).
- Project suites live in `projects/pN_*/robot/`. A suite contains test intent; implementation detail belongs in keywords.
- Python keyword libraries are thin wrappers over `tools/labkit`, with no logic of their own, so the logic is unit-tested with pytest.

## Targets and variables
- Every suite honors `${TARGET}` (`renode`, `hw`, `sil`, `mil`) from P1 on, and switches only in `Suite Setup`.
- Thresholds are suite-level `*** Variables ***` with units in the name (`${SETTLE_MAX_S}`). They are **requirements**: change one only with a reason in the commit message.

## Tags
- `smoke` runs in CI on every push and must finish in under 2 minutes in total.
- `long` runs nightly.
- `hw` needs the physical board and never runs in CI.
- `REQ-<AREA>-<NN>` marks a requirement ID (P5+); `pN` marks the project.

## Timing
- Assert on virtual time. Use `Wait For Line On Uart` with `timeout=` in virtual seconds, or metrics computed from the run CSV. Never use `Sleep` to wait for behavior.

## Evidence
- Each run writes `output.xml`, `log.html`, and `report.html` to `build/robot/pN/`. The `run-suite` skill copies selected reports into `projects/pN_*/results/YYYY-MM-DD_<desc>/`.
- Failing tests are investigated, not skipped. `Skip` is only for `hw` tests when no board is attached.
