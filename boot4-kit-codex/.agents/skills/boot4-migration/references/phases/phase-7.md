# Phase 7 — Review & PR

**Goal:** A skeptical fresh-context review of the whole migration, then a PR a human can
actually review.

**How to run:** `/clear` FIRST — a fresh context reviews more honestly than the session
that wrote the code. Strongest model tier for the review.

**Steps:**
1. In a fresh context, review the full migration diff as a skeptic. Hunt specifically
   for: weakened or deleted test assertions (the classic AI-migration failure mode),
   behavior changes smuggled in as "fixes", unrelated refactors, and TODOs left behind.
2. Generate the PR package: migration summary (per phase, from
   docs/migration/changelog.md), the
   Tier-3 findings table with dispositions, and a rollback note (how to revert safely,
   including any data-format implications).
3. Open the PR with phase-per-commit history intact — no squashing away reviewability.

**Gate — done when:** the PR is open with summary + rollback note, and review is handed
to a human.

**Stop & escalate:** The PR boundary is where automation ENDS by design. Merge is a human
decision, always.
