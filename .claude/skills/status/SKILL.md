---
name: status
description: Answer "where am I and what's next?" for this curriculum - active project, done-when progress, open problems, and the single next concrete step. Use at the start of a work session or when the owner asks for status/next steps.
---

# Status: where am I, what's next

1. **Gather facts (read-only):**
   - `git tag --list 'p*-done'`, `git branch --show-current`, `git status --short`, `git log --oneline -10`
   - the `CLAUDE.md` "Current status" section
   - `docs/ROADMAP.md`: the section for the active project
   - `projects/pN_*/README.md` for the active project, if it exists: unchecked `- [ ]` items, empty sections, and 🎓 steps
   - `docs/feature-checklist.md`: rows for the active project not yet ticked
   - whether `build/robot/pN/output.xml` exists, and its pass/fail counts if so
2. **Work out progress** against the active project's milestones in the roadmap and the definition of done in `CLAUDE.md`.
3. **Report** in this format, in under 25 lines:

```
## Status: <date>
Active: P<N> <name> (branch <b>), <k>/<n> milestones
Done: p0-done, ...

### Progress
- [x] milestone ...
- [ ] milestone ...  ← next

### Open problems
- ... (from README "Problems hit" without a fix, failing tests, TODOs)

### Next step (one)
<concrete action, the command to run, or the 🎓 step for the owner, plus which skill or agent helps>
```

Recommend exactly one next step. If it's a 🎓 step, say so and offer to explain rather than do it.
