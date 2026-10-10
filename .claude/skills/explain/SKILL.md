---
name: explain
description: Teach a concept or tool feature (Renode, OpenModelica, Robot, STM32H7, control theory) using this repo's own files as the example, check understanding with a couple of questions, and save a short note to docs/notes/. Use when the owner asks "how does X work", "why", or "explain".
argument-hint: "<topic>"
---

# Explain: $ARGUMENTS

1. **Anchor in the repo.** Find where the topic appears (or will appear) in this repo: a `.repl` block, a `.mos` line, a Robot keyword, a register access in HAL, or a PID line. Explain through that concrete example first, then generalize.
2. **Structure** (about 1 screen):
   - **What it is**, in one or two sentences.
   - **How it works here**, walking through the repo example with `file:line` links.
   - **Why it matters** for this project: what breaks if it's misunderstood.
   - **Try it:** one small command or experiment the owner can run to see it, for example a monitor command or an omc one-liner.
   - **Go deeper:** one or two official doc links (Renode docs, the OpenModelica user's guide, the Robot user guide, RM0433 section). Verify the links exist.
3. **Check understanding:** ask the owner one or two short questions, and wait for their answers before moving on.
4. **Save** a condensed note to `docs/notes/<topic-kebab>.md` (what it is, the repo example, the gotchas, links). Link it from `docs/notes/README.md`.
5. If the topic came from `docs/notes/questions.md`, mark that question answered with a link to the note.

Prefer the **mentor** output style for these sessions (`/output-style mentor`).
