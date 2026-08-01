# Phase 0 — Assessment

**Goal:** Convert "unknown risk" into a scored, reviewable scope before a single line changes.

**How to run:** Plan Mode, extended thinking ("think hard"), strongest model tier. No edits
in this phase — its only output is a document.

**Steps:**
1. Read references/boot4-notes.md end to end, then analyze the repository against it.
2. Inventory every hit: removed/renamed starters, Security DSL usage, Jackson
   customizations, Batch jobs, `@MockBean`/`@SpyBean` counts, in-house auto-configuration,
   Spring Cloud dependencies.
3. Score the 12-point risk card (see the guide's scorecard) and classify each finding
   Tier 1 (won't compile) / Tier 2 (won't run) / Tier 3 (runs wrong).
4. Write `docs/migration/assessment.md`: findings, tier per finding, phase-by-phase
   scope, and the
   repo-specific items Phase 6 must audit.

**Gate — done when:** `docs/migration/assessment.md` is committed and a human has
signed it off.

**Stop & escalate:** This gate is a MANDATORY HUMAN PAUSE — never proceed to Phase 1
without explicit sign-off.
