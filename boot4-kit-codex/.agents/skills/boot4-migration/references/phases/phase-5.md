# Phase 5 — Test migration

**Goal:** Full test suite green on Boot 4 idioms — without a single weakened assertion.

**How to run:** Delegate to the test-migrator subagent, one module per dispatch (its own
context window per module). For large multi-module repos, run modules in parallel.

**Steps:**
1. Dispatch the test-migrator subagent per module (e.g. api, service, persistence,
   batch): `@MockBean`/`@SpyBean` → `@MockitoBean`/`@MockitoSpyBean` (review each — not
   1:1), JUnit idiom updates, slice-annotation repair (`@AutoConfigureMockMvc`,
   `@AutoConfigureTestRestTemplate`, `starter-security-test` for `@WithMockUser`).
2. Collect each module's summary: tests migrated, tests still red, and any Tier-3
   findings the subagent refused to auto-fix.
3. Consolidate the Tier-3 findings into docs/migration/changelog.md — they are Phase 6
   input, not
   Phase 5 failures.

**Gate — done when:** `./mvnw clean verify` is green across all modules and the combined
summary is in `docs/migration/changelog.md`.

**Stop & escalate:** A test that fails for a behavioral reason is NEVER "fixed" by
relaxing its assertion — it is reported. That rule lives in the subagent itself on
purpose.
