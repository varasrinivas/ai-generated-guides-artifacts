# Runbook — executing this playbook on a repo

Distilled from a full field run of every phase against a pilot service (the
run's artifacts — assessment, changelog, goldens, agent reports — live in that
repo's `docs/migration/`). Angle-bracket values are per-repo. Every MANDATORY
PAUSE is where a production run stops for a human; do not script past them.

## Prerequisites (human work, before any agent runs)

1. JDK for the current build and JDK 21 installed (a single JDK 21 works when
   the pom compiles with `--release`; record the deviation).
2. Docker running — Testcontainers and the local database.
3. Baseline is green: `./mvnw clean verify` on the default branch, and the app
   boots on its local profile (`docker compose up -d` first if the repo has
   one). Phase 6's golden capture hard-fails without a runnable pre-bump app.
4. Timezone quirk seen in the field: if Flyway dies with
   `invalid value for parameter "TimeZone"`, pass `-Duser.timezone=UTC` to
   every `spring-boot:run` (surefire usually pins it already).

## Step 0 — install the kit

Plugin path (preferred): add the marketplace stub from `examples/settings.json`
and install `boot4-kit`. Vendored path (no plugin infrastructure):

```bash
# from a checkout of the kit repo
tools/sync-kit.sh <path-to-service-repo>
```

- Vendoring produces branch `chore/boot4-kit-<rev>` with `.claude/skills/` and
  `.claude/agents/`; the PR review is the adoption gate.
- One-time step the script prints: merge `hooks/hooks.json` into the repo's
  `.claude/settings.json` `hooks` block (settings.json is per-repo, never
  overwritten by later syncs).
- The phase rule files land at
  `.claude/skills/boot4-migration/references/phases/phase-0..7.md` — each phase
  below starts by reading its file. (`.claude` is a dot-directory; use
  `git ls-files .claude` if your tree view hides it.)
- New or context-poor repo? Run `/init` and review-then-commit the generated
  `CLAUDE.md` BEFORE Phase 0 — then add what no generator can guess: build/run
  quirks, which contracts are externally consumed, which log lines feed
  compliance, what the dashboards scrape. That is exactly the map Phase 0's
  assessment needs, and every later session (and subagent) starts warmer for it.

## Phase 0 — assessment (Plan Mode, no edits)

1. Read `references/boot4-notes.md` end to end; inventory the repo against it.
2. Score the guide's 12-point risk card; classify findings Tier 1/2/3.
3. Write `docs/migration/assessment.md` including the repo-specific list
   Phase 6 must audit (external JSON contracts, security matchers with intent
   comments, compliance log lines, dashboards fed by metrics).
4. Commit. **MANDATORY PAUSE: human sign-off on the assessment.**

## Phase 1 — latest 3.5.x, zero deprecations

1. Bump to the latest 3.5.x (check `maven-metadata.xml`, not the search index —
   it lags).
2. `./mvnw clean compile -Dmaven.compiler.showDeprecation=true`; fix one
   category per commit. Security DSL modernization to lambda style belongs
   here, on 3.5, where the test matrix can pin behavior before the bump.
3. Properties migrator: add `spring-boot-properties-migrator` (runtime scope),
   boot the local profile, apply the renames/removals it prints, boot again to
   a clean report, REMOVE the migrator.
4. Gate: `./mvnw clean verify` green, zero deprecation warnings.

## Phase 2 — Java 21 baseline

1. `java.version` → 21; update CI images and Dockerfile stages in the same
   commit. No new language features.
2. Gate: verify green on 21.

## Pre-bump golden capture (before any Phase 3 edit)

1. Boot the app on the local profile. Seed characterization data via the real
   API (one request per interesting code path) — the rows persist in the local
   database and are re-read post-bump.
2. Write `goldens-endpoints.txt` (one GET path per line). Basic-auth rides the
   URL: `BASE_URL="http://<user>:<pass>@localhost:8080"`.
3. Run `scripts/capture-goldens.sh` with
   `OUT_DIR=docs/migration/goldens/pre-bump`.
4. The script is GET-only and aborts on 4xx: capture error-body contracts
   (404, validation 400) manually with `curl | jq .` beside it.
5. Commit fixtures; branch `pre-bump` marks this commit (also the rollback
   target).

## Phase 3 — the bump (one commit per category)

1. Parent → 4.x; pin Spring Cloud 2025.1.1+ if the BOM is imported; bump
   springdoc to its Boot-4 line.
2. Compile; group errors; fix one category per commit. Expect (all hit in the
   field): starter renames incl. Undertow removal (→ Tomcat + header-count
   parity, see gotchas), `tools.jackson` + serializer API renames, Batch 6
   relocations, `RestTemplateBuilder` → `boot.restclient`, javax → jakarta,
   Testcontainers 2 coordinates, the in-house auto-config
   `@ConditionalOnClass` string check.
3. Don't guess relocated packages — index the jars:
   `./mvnw dependency:build-classpath -Dmdep.outputFile=target/cp.txt` then
   `unzip -l`/`javap` against the entries.
4. Gate: main sources compile clean (`./mvnw compile`). Remaining test-compile
   errors are Phase 5's categories by construction — record the reading.
   **MANDATORY PAUSE: any fix that changes authorization behavior.**

## Phase 4 — startup loop (Tier 2)

1. BEFORE first run: add `spring-boot-starter-batch-jdbc` (if Batch) and
   `spring-boot-starter-micrometer-metrics` (if any dashboard reads metrics);
   check `spring-boot-starter-flyway` (Flyway auto-config no longer ships in
   spring-boot-autoconfigure — a seeded DB masks the gap, so verify the
   startup log shows Flyway validating migrations).
2. Start on the local profile (`-Dmaven.test.skip=true` keeps Phase 5 out of
   the way); fix startup failures one at a time against boot4-notes Tier 2.
3. Gate: starts clean; `/actuator/health` UP; the repo's named metrics visibly
   present (a temporary
   `-Dmanagement.endpoints.web.exposure.include=...,metrics` override is fine
   for verification — document it).
   **MANDATORY PAUSE: data-affecting config (Batch metadata, transactions).**

## Phase 5 — test migration (subagent)

1. Dispatch the `test-migrator` subagent per module. It may not touch src/main
   and may never weaken an assertion; behavioral failures come back as
   findings.
2. Review its report: every `@MockitoBean`/`@MockitoSpyBean` swap (spies on
   AOP-proxied beans need human eyes), JUnit 4 rewrites with pinned values
   unchanged, new test-slice starters (`webmvc-test`, `security-test`).
3. Disposition its refused-to-fix findings as separate commits (fix in main
   code / accept / defer-with-ticket) — never inside the migration commit.
4. Gate: full suite green, same test count as baseline, none skipped.

## Phase 6 — behavioral verification (Tier 3)

1. Re-run the golden capture into `docs/migration/goldens/post-bump` — BEFORE
   dispatching the auditor, whose probes mutate the dataset. Diff and
   disposition every line (accept / fix / defer-with-ticket) in
   `docs/migration/changelog.md`. Expected Jackson-3 suspects: key reordering,
   probe groups in health, reason-phrase renames. Byte-identical external
   contracts are the pass condition.
   **MANDATORY PAUSE: every golden diff gets a human disposition.**
2. Dispatch the read-only `behavior-auditor` subagent (strongest model tier).
   Give it the assessment's Tier-3 list and let it probe the running app.
   Disposition all findings; commit fixes separately with the finding named.
3. Persist evidence under `docs/migration/` (never `target/` — it's gitignored
   and a clean build erases your proof).

## Phase 7 — skeptic review and PR

1. Fresh context (`/clear` first): review the whole branch diff hunting
   weakened assertions, smuggled behavior changes, unrelated refactors,
   leftover shims, and doc claims that aren't true in the code. Address
   docs-only findings as their own commit.
2. Write `docs/migration/pr.md`: per-phase summary, Tier-3 table with
   dispositions, deploy prerequisites (in the field: the Batch 6
   `migration/6.0` sequence script per environment; empty-map `{}` overrides;
   archiver regexes pinned to the old container's thread token), rollback
   note.
3. Open the PR with phase-per-commit history intact.
   **MANDATORY PAUSE: merge is a human decision. The runbook ends here.**

## Artifacts a finished run leaves behind

```
.claude/…                         kit (skills, agents, compile hook)
docs/migration/assessment.md      Phase 0, signed off
docs/migration/changelog.md       per-phase record, every disposition
docs/migration/goldens/           pre-bump + post-bump fixtures + diff
docs/migration/agents/            verbatim subagent reports
docs/migration/pr.md              PR body, deploy prerequisites, rollback
docs/migration/run-capture.md     how the playbook itself performed (feeds
                                  this kit's gotchas.md)
```

The last file matters most for the next repo: every surprise goes back into
`gotchas.md`, so each migration starts smarter than the one before.
