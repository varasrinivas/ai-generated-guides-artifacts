# boot4-kit-codex

OpenAI Codex kit encoding our Spring Boot 3.5 → 4.x migration playbook: phased skills,
migration subagents, and a post-edit compile-gate hook. It ships by **vendoring** — a sync
script copies it into each service repo and the PR review is the adoption gate.

This is the reference implementation of Sheet 08 of the companion guide,
[`code-migration-using-codex/spring-boot-3-to-4-migration-guide.html`](https://github.com/varasrinivas/ai-generated-guides/blob/main/code-migration-using-codex/spring-boot-3-to-4-migration-guide.html)
in the [guides repo](https://github.com/varasrinivas/ai-generated-guides). To use it for real, extract this directory
into its own internal git repo (e.g. `https://git.acme.internal/platform/boot4-kit.git`).

## Layout

```
boot4-kit-codex/
├── AGENTS.md                       # example repo charter — copied per repo, then edited
├── .agents/skills/
│   ├── audit-tier3/                # standalone: the Tier-3 behavioural audit
│   │   ├── SKILL.md                #   worked end to end in Sheet 7.4 of the guide
│   │   └── references/tier3-checklist.md
│   ├── migrate-phase/SKILL.md      # $migrate-phase — one phase, gated
│   ├── migrate-boot4/
│   │   ├── SKILL.md                # $migrate-boot4 — full orchestrator
│   │   └── agents/openai.yaml      #   allow_implicit_invocation: false (human-launch only)
│   └── boot4-migration/            # the playbook: phases, ground truth, gotchas
│       ├── SKILL.md
│       ├── references/
│       │   ├── phases/             # phase-0.md … phase-7.md — goal, steps, gate,
│       │   │                       #   stop rules per phase (what $migrate-phase reads)
│       │   ├── boot4-notes.md      # condensed ground truth
│       │   └── gotchas.md          # symptom → cause → fix, grows per migration
│       └── scripts/capture-goldens.sh
├── .codex/
│   ├── hooks.json                  # compile after every edit; exit 2 + stderr feeds back
│   └── agents/
│       ├── test-migrator.toml      # test migration; never weakens assertions
│       └── behavior-auditor.toml   # read-only Tier-3 audit (sandbox_mode = "read-only")
├── examples/                       # templates to copy, inert where they sit
│   ├── config.toml                 #   a repo's .codex/config.toml: approval + sandbox floor
│   └── github-actions/             #   copy into a repo's .github/workflows/
│       ├── validate-kit.yml        #     kit repo: parse + policy-nesting assertions
│       ├── boot4-drift.yml         #     service repo: weekly Tier-3 re-audit
│       └── pr-review.yml           #     service repo: Phase 7 skeptic review
├── codex-profiles/                 # templates for ~/.codex/ — NOT repo config
│   ├── boot4-assess.config.toml    # codex --profile boot4-assess
│   ├── boot4-loop.config.toml      # codex --profile boot4-loop
│   └── boot4-review.config.toml    # codex --profile boot4-review
└── tools/sync-kit.sh               # vendor the kit into a service repo
```

Four directories, four jobs. `.agents/skills/` holds the portable Agent Skills (the same
folder layout other agents read). `.codex/` holds what the kit *owns* and the sync script
copies: the subagents and the compile-gate hook. `codex-profiles/` holds per-phase profile
templates that belong in `~/.codex/`, because `profile`/`profiles` keys are ignored inside a
project `config.toml`. And `examples/` holds templates you copy somewhere else — the
sandbox/approval floor and the CI workflows — which is why they sit there rather than at
`.codex/config.toml` and `.github/workflows/`: at their live paths they would configure and
run against *this* repo, which is not what either is for. Note too that Codex reads the
`.codex/` layer only for **trusted** projects.

## Consuming it in a service repo

```
./tools/sync-kit.sh ../order-service
```

The script branches the target repo, copies `.agents/skills/` and `.codex/agents/` +
`hooks.json` in, and commits. Push it and open a PR — that review is the adoption gate.
Loop it over a `repos.txt` for the fleet. Engineers then invoke the kit with
`$migrate-phase run phase 3` and `$migrate-boot4`, and `/skills` lists what is installed.

`config.toml` is **not** overwritten by the script: it carries per-repo sandbox and
approval policy. Copy it once by hand on first adoption. The profile files are user-level —
copy `codex-profiles/*.config.toml` into `~/.codex/` once per engineer, then select one with
`codex --profile boot4-loop`. Profiles are separate files with top-level keys; the old
`[profiles.<name>]` tables and the `profile = "..."` selector were removed in Codex 0.134.0
and a leftover `profile` key is now a hard config-load error.

## audit-tier3 — usable on its own

`audit-tier3/` is deliberately standalone: nothing in the playbook invokes it, and it needs
no migration in flight. Point it at any service already on Boot 4 and it reports Tier-3
behaviour changes — the ones that compile, start, and are still wrong.

It is also the guide's worked example. Sheet 7.4 traces the Phase 6 prompt line by line into
these two files, which is the clearest answer to "how does a prompt become a skill": the
prompt's substance became the checklist, and the SKILL.md is mostly the things you never
wrote down because you were in the room.

## Running it

Installing the kit is not the same as running it. From a cold start in a service repo:

**Once per machine**

```
npm install -g @openai/codex          # or: brew install --cask codex
cp codex-profiles/*.config.toml ~/.codex/
```

**Once per repo**

1. `./tools/sync-kit.sh ../order-service`, then push the branch and merge the PR.
2. `cp examples/config.toml ../order-service/.codex/config.toml` the first time — the
   script never overwrites it, because it carries per-repo sandbox and approval policy.
3. Open the repo with `codex` and **trust it** when prompted. Codex reads the `.codex/`
   layer only for trusted projects; untrusted, your hooks and config are silently absent.
4. Run `/hooks` and trust the compile gate. New and changed hooks are skipped until
   reviewed, so this is not optional — an untrusted hook is a hook that never fires.
5. Confirm the kit is visible: `/skills` should list `migrate-phase`, `migrate-boot4`, and
   `boot4-migration`; `/agent` should list `test-migrator` and `behavior-auditor`.
6. Write `AGENTS.md` for the repo. Copy the one here as a starting point and fill in the
   real module names, build command, and rules — it ships as a template, not a shared file.

**Then, per phase**

```
codex --profile boot4-assess        # Phase 0 and the Phase 7 review: read-only
  $migrate-phase run phase 0        #   -> docs/migration/assessment.md, then STOPS

# a human reads assessment.md and signs it off — this gate is the point

codex --profile boot4-loop          # Phases 1-5: unattended inside the workspace
  $migrate-phase run phase 1        #   each run ends at a green ./mvnw clean verify,
  $migrate-phase run phase 2        #   a phase commit, and a changelog.md entry
  ...

codex --profile boot4-review        # Phase 3 Security DSL, Phase 4 data-affecting config
  $migrate-phase run phase 3        #   approvals on: you confirm each edit
```

`$migrate-boot4` runs the whole 0-7 sequence with the same gates, resuming from the last
phase commit. It will not start on its own — `allow_implicit_invocation: false` means a
human has to type it.

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
  Sheet 03 of the guide also has you generate `docs/migration/boot4-notes.md` for the
  pilot; after the pilot, the distilled version lives here and the per-repo copy is
  redundant.

**First run in a repo that has never been migrated**

There is no `changelog.md` yet — the skill creates it. Start at phase 0; do not skip to a
later phase, because every phase checks that the previous gate commit exists.

## Versioning

There is no manifest version. Each service repo is pinned to the kit commit named in its
sync PR, so adoption is explicit and auditable — you can always tell which kit version a
repo is running by reading its last sync commit.

If your organization has Codex plugins enabled, this same tree can be published as a plugin
instead, trading the explicit sync PR for automatic updates. Add a `.codex-plugin/plugin.json`
with `name`, `version`, `description`, plus `skills: "./.agents/skills/"` and
`hooks: "./.codex/hooks.json"`. One caveat: a plugin manifest does not bundle
`.codex/agents/` subagents, so those still travel as files either way.

## CI

`examples/github-actions/` holds three workflow templates. They live under `examples/`
rather than `.github/workflows/` on purpose — dropped in the latter they would run in this
repo, against this repo, which is not what any of them is for. Copy the one you want into
the target repo's `.github/workflows/`.

| File | Runs in | Does |
|---|---|---|
| `validate-kit.yml` | the kit repo | Parses every manifest and asserts each skill has a description. No API key, no model call |
| `boot4-drift.yml` | a service repo | Weekly read-only re-audit for Tier-3 regressions after the migration landed |
| `pr-review.yml` | a service repo | Phase 7's skeptic review on the migration PR; comments, never merges |

Two rules carried in all three: the API key is a step input and never a job-level `env:`,
and fork PRs are skipped because they carry untrusted prose as well as untrusted code.
Sheet 10 of the guide explains both.

## What stays per-repo (on purpose)

`AGENTS.md`, `assessment.md`, `changelog.md`, and `.codex/config.toml` are repo-specific
state, not shared recipe. The profile files are per-engineer, which is a different kind of
not-shared: the sandbox and approval *floor* is what the repo enforces. The migration's mandatory human gates (assessment sign-off,
Security 7 defaults, golden-output diffs, PR review) are encoded in the skills and are not
to be automated away.

Vendored files are read-only by convention inside service repos: fixes go to the kit repo
and come back on the next sync PR. Local edits to a vendored skill are how a fleet of
slightly-different playbooks is born.

## Feeding the kit

Every surprise from a real migration goes into
`.agents/skills/boot4-migration/references/gotchas.md` (symptom → cause → fix). One commit
here teaches every remaining service in the fleet.
