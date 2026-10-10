---
name: adr
description: Write an Architecture Decision Record in docs/adr/ for a significant technical choice (toolchain, protocol, time model, peripheral modeling approach, test strategy). Use when a decision is made or reversed, or when the owner says "record this decision".
argument-hint: "<short decision title>"
---

# ADR: $ARGUMENTS

1. List `docs/adr/` and take the next number (4 digits, for example `0006`).
2. Copy `docs/adr/0000-template.md` to `docs/adr/NNNN-<kebab-title>.md`.
3. Fill each section from the conversation and the code. If something is unknown, ask; don't invent it.
   - **Status:** Proposed, Accepted, or Superseded by NNNN
   - **Context:** the forces at play, including constraints like no USB in Docker or what Renode lacks
   - **Decision:** one paragraph, in the active voice
   - **Alternatives considered:** each with a one-line reason it lost
   - **Consequences:** what gets easier, what gets harder, and what is revisited at which project
4. If this supersedes an ADR, edit the old one's Status to `Superseded by NNNN`. That's the only edit allowed to an accepted ADR.
5. Add a row to the index table in `docs/adr/README.md`.
6. Keep it under about 60 lines. ADRs record decisions; they aren't tutorials.
