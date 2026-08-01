# Phase 3 — The bump + compile fixes (Tier 1: won't compile)

**Goal:** Bump to Boot 4.x and get back to a clean compile, one reviewable category at a
time.

**How to run:** Agentic loop. Auto-accept for mechanical categories (imports, package
moves, starter renames); confirm-each-edit for Security DSL rewrites — Security 7
defaults can silently change endpoint behavior.

**Steps:**
1. Bump spring-boot to 4.x in the parent/BOM; pin Spring Cloud to 2025.1.1+ (2025.1.0 is
   incompatible with Boot 4.0.1+).
2. Compile. Group the errors into categories (starter renames, `tools.jackson` imports,
   Security DSL, removed APIs — see references/boot4-notes.md Tier 1).
3. Fix ONE category at a time; commit per category with a message naming the category.
4. Security DSL rewrites are their own category, reviewed edit by edit, never batched.

**Gate — done when:** the project compiles clean, with one commit per fixed category.

**Stop & escalate:** 3-strikes rule per error. Any fix that would change authorization
behavior (not just syntax) is a MANDATORY HUMAN PAUSE.
