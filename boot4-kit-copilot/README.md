# boot4-kit-copilot

GitHub Copilot CLI kit encoding our Spring Boot 3.5 → 4.x migration playbook: phased
skills, migration custom agents, and a post-edit compile-gate hook. It ships by
**vendoring** — a sync script copies it into each service repo's `.github/` layer and the
PR review is the adoption gate.

This is the reference implementation of Sheet 07 of the companion guide,
[`code-migration-using-copilot/spring-boot-3-to-4-migration-guide.html`](https://github.com/varasrinivas/ai-generated-guides/blob/main/code-migration-using-copilot/spring-boot-3-to-4-migration-guide.html)
in the [guides repo](https://github.com/varasrinivas/ai-generated-guides). To use it for real, extract this directory
into its own internal git repo (e.g. `https://git.acme.internal/platform/boot4-kit.git`).

## Layout

```
boot4-kit-copilot/
├── AGENTS.md                       # example repo charter — copied per repo, then edited
├── skills/                         # → vendored to <repo>/.github/skills/
│   ├── audit-tier3/                # standalone: the Tier-3 behavioural audit
│   │   ├── SKILL.md                #   worked end to end in Sheet 8.4 of the guide
│   │   └── references/tier3-checklist.md
│   ├── migrate-phase/SKILL.md      # /migrate-phase — one phase, gated
│   ├── migrate-boot4/SKILL.md      # /migrate-boot4 — full orchestrator (launch guard
│   │                               #   is advisory: see "Running it" below)
│   └── boot4-migration/            # the playbook: RUNBOOK, phases, ground truth, gotchas
│       ├── SKILL.md
│       ├── RUNBOOK.md              # Step 0 → Phase 7 as an executable checklist
│       ├── references/
│       │   ├── phases/             # phase-0.md … phase-7.md — goal, steps, gate,
│       │   │                       #   stop rules per phase (what /migrate-phase reads)
│       │   ├── boot4-notes.md      # condensed ground truth
│       │   └── gotchas.md          # symptom → cause → fix, grows per migration
│       └── scripts/capture-goldens.sh
├── agents/                         # → vendored to <repo>/.github/agents/
│   ├── test-migrator.agent.md      # test migration; never weakens assertions
│   └── behavior-auditor.agent.md   # read-only Tier-3 audit (tools: no edit)
├── hooks/
│   └── hooks.json                  # → vendored to <repo>/.github/hooks/boot4.json —
│                                   #   compile after Java/pom edits; exit 2 + stderr
├── examples/                       # templates to copy, inert where they sit
│   └── github-actions/             #   copy into a repo's .github/workflows/
│       ├── validate-kit.yml        #     kit repo: parse + both-shells assertions
│       ├── boot4-drift.yml         #     service repo: weekly Tier-3 re-audit
│       └── pr-review.yml           #     service repo: Phase 7 skeptic review
└── tools/sync-kit.sh               # vendor the kit into a service repo
```

Four directories, four jobs. `skills/` holds the portable Agent Skills (the same
`SKILL.md` layout Claude Code and Codex read; Copilot reads them from
`.github/skills/`, `.claude/skills/` or `.agents/skills/` in a consuming repo). `agents/`
holds the custom agents whose `tools:` allowlist is the kit's safety boundary. `hooks/`
holds the compile gate — **deliberately not at `.github/hooks/`**, because at its live
path it would run against this repo, which is Markdown and JSON; the sync script puts it
at the live path in repos that actually have something to compile. And `examples/` holds
the CI workflows you copy somewhere else, inert here for the same reason.

## Consuming it in a service repo

```
./tools/sync-kit.sh ../order-service
```

The script branches the target repo, copies `skills/` and `agents/` into `.github/`, and
puts `hooks/hooks.json` at `.github/hooks/boot4.json`; then it commits. Push it and open a
PR — that review is the adoption gate, and it is also where the repo accepts that a
`.github/hooks/` file applies to every Copilot agent run in it, CLI and cloud alike. Loop
the script over a `repos.txt` for the fleet. Engineers then invoke the kit with
`/migrate-phase run phase 3` and `/migrate-boot4`; `/env` shows what loaded.

Tool approvals are **not** repo files: they are per-session flags
(`--allow-tool 'shell(./mvnw:*)'`), interactive approvals, or saved per-location
approvals in `~/.copilot/permissions-config.json`. The RUNBOOK's phase lines carry the
flags each phase needs, which is the closest Copilot gets to the per-repo approval floor
the other editions ship as a config file.

## audit-tier3 — usable on its own

`audit-tier3/` is deliberately standalone: nothing in the playbook invokes it, and it needs
no migration in flight. Point it at any service already on Boot 4 and it reports Tier-3
behaviour changes — the ones that compile, start, and are still wrong.

It is also the guide's worked example. Sheet 8.4 traces the Phase 6 prompt line by line into
these two files, which is the clearest answer to "how does a prompt become a skill": the
prompt's substance became the checklist, and the SKILL.md is mostly the things you never
wrote down because you were in the room.

## Running it

Installing the kit is not the same as running it. From a cold start in a service repo:

**Once per machine**

Install both JDKs first — the one the 3.5.x build uses today, and 21 for the target
(Sheet 4.2 of the guide has the per-OS commands and toolchain setup). Then:

```
npm install -g @github/copilot        # or: brew install --cask copilot-cli
                                      # or: winget install GitHub.Copilot
copilot                               # then /login, once
```

**Once per repo**

1. Create the baseline worktree — `git worktree add ../<svc>-boot3-baseline main`, pinned
   to the pre-bump branch. Phase 6's golden capture hard-fails if a running 3.5.x app is
   not there to capture from (Sheet 4.2 of the guide).
2. `./tools/sync-kit.sh ../order-service`, then push the branch and merge the PR.
3. Open the repo with `copilot` and **trust the directory** when prompted — an untrusted
   directory gets no file access at all.
4. Confirm the kit is visible: `/env` should show the skills, the two custom agents, and
   the hook file; `/agent` should list `test-migrator` and `behavior-auditor`.
5. Write `AGENTS.md` for the repo. Copy the one here as a starting point and fill in the
   real module names, build command, and rules — it ships as a template, not a shared
   file. Copilot discovers `AGENTS.md` natively, same as Codex; there is nothing to
   convert.

**Then, per phase**

```
copilot                               # Phase 0: plan mode (Shift+Tab or /plan), no edits
  /migrate-phase run phase 0          #   -> docs/migration/assessment.md, then STOPS

# a human reads assessment.md and signs it off — this gate is the point

copilot --allow-tool 'shell(./mvnw:*)' --allow-tool write   # Phases 1-5: the loop
  /migrate-phase run phase 1          #   each run ends at a green ./mvnw clean verify,
  /migrate-phase run phase 2          #   a phase commit, and a changelog.md entry
  ...

copilot                               # Phase 3 Security DSL, Phase 4 data-affecting
  /migrate-phase run phase 3          #   config: no standing approvals — you confirm
                                      #   each edit at the prompt
```

`/migrate-boot4` runs the whole 0-7 sequence with the same gates, resuming from the last
phase commit. Note one honest difference from the other kit editions: Copilot documents no
hard human-launch-only control for a skill, so the guard lives in the skill's own
description ("only run when explicitly invoked") — advisory, not structural. Sheet 13 of
the guide records the gap.

**What to expect**

- **State lives in files, not in the session.** `docs/migration/assessment.md` (scope) and
  `docs/migration/changelog.md` (what is done) are how a phase knows where the last one
  ended. `/clear` between phases is expected; the kit is designed to be resumable, so
  coming back tomorrow and re-running is normal.
- **A phase that will not go green stops itself** after three attempts at the same error
  and reports instead. That is the 3-strikes rule, not a failure of the kit.
- **Mandatory pauses are not prompts you can approve away**: assessment sign-off, any
  Security 7 default change, and every golden-output diff from Phase 6. The run reports
  and waits.
- **`references/boot4-notes.md` ships with the kit** and is what the phases check against.
  Sheet 04 of the guide also has you generate `docs/migration/boot4-notes.md` for the
  pilot; after the pilot, the distilled version lives here and the per-repo copy is
  redundant.

**First run in a repo that has never been migrated**

There is no `changelog.md` yet — the skill creates it. Start at phase 0; do not skip to a
later phase, because every phase checks that the previous gate commit exists.

## Versioning

There is no manifest version. Each service repo is pinned to the kit commit named in its
sync PR, so adoption is explicit and auditable — you can always tell which kit version a
repo is running by reading its last sync commit.

Copilot CLI also has a documented plugin system (`plugin.json` bundling skills, agents,
hooks and MCP config, installable from a marketplace or a GitHub repository via
`/plugins install`). This kit does not ship a manifest: vendoring keeps the version-pinned
audit trail a migration review asks for. Sheet 7.5 of the guide gives the manifest in full
for teams that prefer automatic updates.

## CI

`examples/github-actions/` holds three workflow templates. They live under `examples/`
rather than `.github/workflows/` on purpose — dropped in the latter they would run in this
repo, against this repo, which is not what any of them is for. Copy the one you want into
the target repo's `.github/workflows/`.

| File | Runs in | Does |
|---|---|---|
| `validate-kit.yml` | the kit repo | Parses the hook file, asserts every hook carries both shells, and every skill and agent a description. No API key, no model call |
| `boot4-drift.yml` | a service repo | Weekly read-only re-audit for Tier-3 regressions after the migration landed |
| `pr-review.yml` | a service repo | Phase 7's skeptic review on the migration PR; comments, never merges |

Two rules carried in both model-calling workflows: the job that can spend Copilot requests
never holds write permission, and fork PRs are skipped because they carry untrusted prose
as well as untrusted code. Sheet 12 of the guide explains both.

## What stays per-repo (on purpose)

`AGENTS.md`, `assessment.md`, and `changelog.md` are repo-specific state, not shared
recipe. Tool approvals are per-engineer and per-location, which is a different kind of
not-shared: the RUNBOOK's flag lines are the floor the playbook expects, and
`~/.copilot/permissions-config.json` is where an engineer's standing approvals live. The
migration's mandatory human gates (assessment sign-off, Security 7 defaults, golden-output
diffs, PR review) are encoded in the skills and are not to be automated away.

Vendored files are read-only by convention inside service repos: fixes go to the kit repo
and come back on the next sync PR. Local edits to a vendored skill are how a fleet of
slightly-different playbooks is born.

## Feeding the kit

Every surprise from a real migration goes into
`skills/boot4-migration/references/gotchas.md` (symptom → cause → fix). One commit
here teaches every remaining service in the fleet.
