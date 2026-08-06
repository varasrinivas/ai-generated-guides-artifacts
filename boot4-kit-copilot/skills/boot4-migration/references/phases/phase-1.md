# Phase 1 — Stabilize on 3.5.x

**Goal:** Land on the latest 3.5.x with zero deprecation warnings, so the 4.x bump starts
from a clean baseline.

**How to run:** The agentic loop (build → read warnings → fix → rebuild). Session-approved
tools (`--allow-tool 'shell(./mvnw:*)' --allow-tool write`, or approve each for the
session when prompted) are fine here; the fixes are mechanical.

**Steps:**
1. Upgrade to the latest Spring Boot 3.5.x.
2. Find every deprecation warning the build and IDE surface; fix them one category at a
   time, committing per category.
3. Add `spring-boot-properties-migrator` as a runtime dependency, boot the app with the
   local profile, fix every property it reports, then REMOVE the migrator dependency.

**Gate — done when:** `./mvnw clean verify` is green with zero deprecation warnings and
the properties migrator has been removed again.

**Stop & escalate:** 3-strikes rule — if the same warning category survives three fix
attempts, stop and report instead of trying a fourth.
