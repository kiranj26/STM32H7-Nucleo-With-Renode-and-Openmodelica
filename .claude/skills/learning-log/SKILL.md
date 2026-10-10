---
name: learning-log
description: Capture learning into the project README and feature checklist right after something was figured out - a problem solved, a tool feature used for the first time, a result obtained. Use at the end of a work session or after any "aha" / fix.
argument-hint: "<N> [what just happened]"
---

# Learning log: P$ARGUMENTS

Goal: nothing learned in a session is lost. Write it down while it's fresh, **in the owner's voice, with facts from this session only**.

1. **Harvest from this session:**
   - **Problems solved:** symptom, root cause, fix, and the evidence (log line, register, commit).
   - **Tool features used for the first time:** Renode commands, OMC functions, Robot constructs, controller techniques. Each needs a file#line link.
   - **Results obtained:** metrics and plots, with links to run folders.
   - **Open questions or things that confused the owner.**
2. **Update `projects/pN_*/README.md`:**
   - **Problems hit:** add entries as `**<symptom>**: cause → fix ([link]). *Lesson:* ...`
   - **Features used:** add rows to the table.
   - **Results:** only with archived evidence links.
3. **Update `docs/feature-checklist.md`:** tick features now demonstrated, with links.
4. **Recurring issues** go into `docs/troubleshooting.md` as well.
5. **Open questions** go to `docs/notes/questions.md` with the date, so the `explain` skill can pick them up later.
6. **Show the diff** to the owner. They should read it and fix anything that doesn't match their understanding. That reading is part of the learning.

Never invent problems or lessons that didn't happen. If the session produced nothing new, say so.
