---
name: migrate-phase
description: Run one phase of the Boot 4 migration playbook,
  gated on a green build. Use when asked to run, redo, or
  resume a specific migration phase.
argument-hint: [phase-number 0-7]
allowed-tools: Read, Edit, Bash(./mvnw *), Bash(git *)
---
You are executing phase $1 of the Spring Boot 4 migration.

Recent migration state: !`tail -20 docs/migration/changelog.md 2>/dev/null || echo "(none yet — first run)"`

1. Read @docs/migration/assessment.md and this plugin's per-phase
   rule file:
   skills/boot4-migration/references/phases/phase-$1.md
   (goal, steps, gate, and stop rules for this phase). Confirm
   the previous phase's gate commit exists before touching
   anything. If docs/migration/assessment.md is missing on any
   phase after 0, Phase 0 has not been signed off — stop and
   say so.
2. Execute ONLY phase $1, respecting its tier discipline and
   the 3-strikes stop rule: if the same error survives three
   fix attempts, stop and report your analysis instead of
   trying a fourth time.
3. Gate: ./mvnw clean verify must be green. Then commit as
   "phase $1: <summary>" and append what changed, what was
   deferred, and any Tier-3 findings to
   docs/migration/changelog.md (create it if this is the first
   phase to run).

Stop after the gate. Do not start the next phase.
