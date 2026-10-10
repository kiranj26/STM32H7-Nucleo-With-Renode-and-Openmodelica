---
name: run-suite
description: Run a project's Robot suite (by tags/target), summarize output.xml (pass/fail, failing keyword, key metrics), and optionally archive the evidence into a dated results folder. Use whenever tests should be run or their results interpreted.
argument-hint: "<N> [TAGS=smoke|long|...] [TARGET=renode|sil|mil] [archive]"
---

# Run Robot suite: $ARGUMENTS

1. **Run** in the container: `make test P=pN TAGS=<tags> TARGET=<target>`. The defaults are `TAGS=smoke` and `TARGET=renode`. `hw` goes through the `flash-board` skill on the host.
2. **Summarize** from `build/robot/pN/output.xml`. Parse it (`robot.api.ExecutionResult`) rather than eyeballing the HTML.
   ```
   P<N> | target=<t> | tags=<tags> | <pass>/<total> passed | <duration> | <virtual time simulated>
   | Test | Result | Key metric(s) | Threshold |
   ```
   For failures, give the first failing keyword, its message, and the last 10 lines of relevant log (UART output, Renode warnings).
3. **Classify each failure:** product, test, environment, or flaky. Hand off to the **test-engineer** agent if the cause isn't obvious within one step of investigation. **Never** modify thresholds to get to green.
4. **Archive**, only if requested or if this is the run being cited in the README. Copy to `projects/pN_*/results/YYYY-MM-DD_<target>_<tags>/`:
   - `report.html`, `log.html`, `output.xml`
   - the run CSV(s) under 2 MB, and `meta.json` (from `labkit.runlog`)
   - plots via `labkit.plots`

   Then update the README Results table with links. The results guard hook prevents overwriting older runs.
5. **Compare with the last archived run** if one exists. Report metric deltas, and call out regressions over 10%.
