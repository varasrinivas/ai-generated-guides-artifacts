---
name: migrate-boot4
description: Orchestrate the full Boot 3.5 -> 4.x migration,
  phases 0-7, with a verify-and-commit gate after each phase.
---
Drive the migration end to end. First read docs/migration/changelog.md and
resume at the earliest unfinished phase — never redo a phase
whose gate commit exists.

For each phase 0-7 in order:
1. Run it exactly as the migrate-phase skill does (same rules,
   same gate: ./mvnw clean verify green, then a phase commit and
   a docs/migration/changelog.md entry).
2. Phase 5: delegate per-module test work to the test-migrator
   subagent; collect each module's summary.
3. Phase 6: delegate the audit to the read-only behavior-auditor
   subagent; every finding is recorded in docs/migration/changelog.md,
   never
   silently "fixed".

MANDATORY HUMAN PAUSES — stop, report, and wait:
- after Phase 0 (assessment sign-off)
- before accepting any Security 7 default change
- on any golden-output diff from Phase 6

If the same error survives three fix attempts, stop and report
your analysis instead of trying a fourth.
