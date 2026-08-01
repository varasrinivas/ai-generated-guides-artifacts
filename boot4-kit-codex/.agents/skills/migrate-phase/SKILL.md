---
name: migrate-phase
description: Run one phase (0-7) of the Boot 4 migration playbook,
  gated on a green build. Use when asked to run, redo, or resume a
  specific migration phase — the phase number comes from the request.
---
You are executing ONE phase of the Spring Boot 4 migration.

First, determine N — the phase number 0-7 — from the request
("run phase 3", "redo the bump phase"). If the request names no
phase, read docs/migration/changelog.md and take the earliest
unfinished one. If it is still ambiguous, ask; never guess.

1. Gather state before acting:
   - if docs/migration/changelog.md does not exist yet, create it
     with a "# Migration changelog" heading; this is a first run
   - otherwise run `tail -20 docs/migration/changelog.md` and read
     the result
   - read docs/migration/assessment.md (Phase 0 writes it; for any
     later phase its absence means Phase 0 has not been signed off,
     so stop and say so)
   - read this skill's sibling rule file
     `../boot4-migration/references/phases/phase-<N>.md`
     (goal, steps, gate, and stop rules for this phase)
   Confirm the previous phase's gate commit exists before
   touching anything.
2. Execute ONLY phase N, respecting its tier discipline and the
   3-strikes stop rule: if the same error survives three fix
   attempts, stop and report your analysis instead of trying a
   fourth time.
3. Gate: ./mvnw clean verify must be green. Then commit as
   "phase N: <summary>" and append what changed, what was
   deferred, and any Tier-3 findings to docs/migration/changelog.md.

Stop after the gate. Do not start the next phase.
