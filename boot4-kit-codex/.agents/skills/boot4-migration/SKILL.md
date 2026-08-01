---
name: boot4-migration
description: Migrate a Spring Boot 3.5.x service to 4.x using
  our phased playbook. Use when asked to upgrade, bump, or
  migrate Spring Boot in any repo.
---
Follow the phases IN ORDER; do not skip the behavioral phase.
Each phase has a detailed rule file — goal, how to run, steps,
gate, stop rules — in references/phases/phase-<n>.md; read it
before starting that phase and hold to its gate:
1. Assess with /plan against references/boot4-notes.md
2. Latest 3.5.x + deprecations + properties migrator
3. Java 21 baseline (no new language features)
4. Bump to 4.x; fix Tier-1 by category, commit per category
5. Startup loop for Tier-2 (check modular starters first)
6. Run scripts/capture-goldens.sh on the pre-bump branch,
   then characterization tests on the migration branch;
   every JSON diff is a finding, not an accident to accept
7. Test migration via the test-migrator subagent
8. /clear, skeptic review, PR + rollback note

Consult references/gotchas.md before declaring any phase done.
