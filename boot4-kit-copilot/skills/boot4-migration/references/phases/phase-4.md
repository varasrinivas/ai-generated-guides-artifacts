# Phase 4 — Starters and runtime fixes (Tier 2: won't run)

**Goal:** From "compiles" to "starts clean" — this is where missing modular starters and
removed auto-configuration surface.

**How to run:** Agentic loop with the app itself in the loop: start it, read the failure,
fix, restart. Check references/boot4-notes.md Tier 2 before diagnosing from scratch.

**Steps:**
1. Start the app with the local profile; fix startup failures one at a time.
2. Check modular starters FIRST for each failure: `starter-webmvc`, `starter-restclient`
   / `starter-webclient`, `starter-micrometer-metrics`, `starter-opentelemetry`,
   `starter-security-test`, `starter-batch-jdbc`.
3. Batch apps: add `starter-batch-jdbc` NOW, before any job runs anywhere — the in-memory
   default silently stops persisting job history.
4. Verify actuator endpoints: health (probes are on by default now), and confirm metrics
   actually appear — "no errors but metrics disappeared" is a known failure mode.

**Gate — done when:** the app starts clean on the local profile, health is UP, and
metrics are visibly flowing.

**Stop & escalate:** 3-strikes rule. Any fix that changes data-affecting configuration
(Batch metadata storage, transaction semantics) is a MANDATORY HUMAN PAUSE.
