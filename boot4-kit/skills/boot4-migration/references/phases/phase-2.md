# Phase 2 — Java 21 baseline

**Goal:** Move the toolchain to Java 21 without touching application semantics.

**How to run:** Agentic loop, auto-accept. Small, boring diff by design.

**Steps:**
1. Update Maven compiler/toolchain configuration (or Gradle equivalents) to Java 21;
   update CI images/toolchain files if present in-repo.
2. Fix anything the stricter compiler surfaces.
3. Do NOT adopt new language features (records, pattern matching, etc.) — keep migration
   diffs boring and reviewable; modernize later, after the migration lands.

**Gate — done when:** `./mvnw clean verify` is green on Java 21.

**Stop & escalate:** If a dependency cannot run on 21, stop and report — that is scope
the assessment missed, and a human re-plans it.
