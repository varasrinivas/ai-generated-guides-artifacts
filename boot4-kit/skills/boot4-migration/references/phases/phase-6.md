# Phase 6 — Behavioral verification (Tier 3: runs wrong)

**Goal:** Catch what compiles, starts, and silently returns different results. This phase
is the reason the playbook exists; it is never skipped.

**How to run:** Two independent probes — golden fixtures (mechanical) and the read-only
behavior-auditor subagent (semantic, "think harder", strongest model tier).

**Steps:**
1. Goldens: run scripts/capture-goldens.sh on the PRE-bump branch (fixtures should
   already be committed there); run the same characterization requests on the migration
   branch; diff.
2. Every JSON diff is a finding to disposition — date formats, key ordering,
   unknown-property tolerance are the expected Jackson 3 suspects, but "expected" does
   not mean "accepted": externally-consumed API contracts treat JSON shape as public API.
3. Dispatch the behavior-auditor subagent for the semantic audit: Jackson customizations
   vs new defaults, effective Security 7 authorization before/after, PropertyMapper null
   handling, Batch metadata persistence.
4. Record every finding in docs/migration/changelog.md with evidence; nothing is silently "fixed".

**Gate — done when:** every golden diff and every auditor finding has a human
disposition (accept / fix / defer-with-ticket) recorded in docs/migration/changelog.md.

**Stop & escalate:** Any golden-output diff and any Security 7 behavior change is a
MANDATORY HUMAN PAUSE — stop, report, wait.
