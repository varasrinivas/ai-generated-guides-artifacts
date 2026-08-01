# boot4-kit

Claude Code plugin encoding our Spring Boot 3.5 → 4.x migration playbook: phased
skill-commands, migration subagents, and a post-edit compile-gate hook. This repo doubles
as its own plugin **marketplace**, so consuming it needs no copying — just a settings stub.

This is the reference implementation of Sheet 08 of the companion guide,
[`code-migration-using-claude/spring-boot-3-to-4-migration-guide.html`](https://github.com/varasrinivas/ai-generated-guides/blob/main/code-migration-using-claude/spring-boot-3-to-4-migration-guide.html)
in the [guides repo](https://github.com/varasrinivas/ai-generated-guides). To use it for real, extract this directory
into its own internal git repo (e.g. `https://git.acme.internal/platform/boot4-kit.git`).

## Layout

```
boot4-kit/
├── .claude-plugin/
│   ├── plugin.json                 # plugin manifest (name, description)
│   └── marketplace.json            # this repo as marketplace "acme-plugins"
├── skills/
│   ├── migrate-phase/SKILL.md      # /migrate-phase <n> — one phase, gated
│   ├── migrate-boot4/SKILL.md      # /migrate-boot4 — full orchestrator, human-launch only
│   └── boot4-migration/            # the playbook: phases, ground truth, gotchas
│       ├── SKILL.md
│       ├── references/
│       │   ├── phases/             # phase-0.md … phase-7.md — goal, steps, gate,
│       │   │                       #   stop rules per phase (what /migrate-phase reads)
│       │   ├── boot4-notes.md      # condensed ground truth
│       │   └── gotchas.md          # symptom → cause → fix, grows per migration
│       └── scripts/capture-goldens.sh
├── agents/
│   ├── test-migrator.md            # test migration; never weakens assertions
│   └── behavior-auditor.md         # read-only Tier-3 audit (no Edit tool)
├── hooks/hooks.json                # compile after every edit; feedback within seconds
└── tools/sync-kit.sh               # no-plugin path: vendor the kit into a repo
```

Only the manifests live under `.claude-plugin/`; skills, agents, and hooks sit at the
plugin root.

## Consuming it in a service repo

Commit this stub as `.claude/settings.json` — the entire per-repo footprint:

```json
{
  "extraKnownMarketplaces": {
    "acme-plugins": {
      "source": { "source": "url",
                  "url": "https://git.acme.internal/platform/boot4-kit.git" }
    }
  },
  "enabledPlugins": { "boot4-kit@acme-plugins": true }
}
```

Anyone opening the repo gets the kit after a single workspace-trust prompt, namespaced:
`/boot4-kit:migrate-phase 3`, `/boot4-kit:migrate-boot4`, plus the subagents and the
compile-gate hook. Updates propagate on `/plugin marketplace update` or the automatic
background refresh. Private hosting works over normal git auth (SSH or HTTPS).

## Consuming without the plugin system (vendoring)

If plugins/marketplaces are not an option, the same kit ships as plain files committed
into each service repo. Use `tools/sync-kit.sh <path-to-repo>`: it copies `skills/` and
`agents/` into the repo's `.claude/` on a `chore/boot4-kit-<commit>` branch — push it and
the PR review is the adoption gate. Loop it over a `repos.txt` for the fleet. Mapping
rules: the `.claude-plugin/` manifests are not copied (nothing reads them when vendored);
merge `hooks/hooks.json` into each repo's `.claude/settings.json` `"hooks"` block once
(settings.json also carries per-repo permissions and is never overwritten by the script);
and vendored commands have no namespace — `/migrate-phase`, not `/boot4-kit:migrate-phase`.
Vendored files are read-only by convention in service repos: fixes land here and return
via the next sync PR.

## Running it

Installing the kit is not the same as running it. From a cold start in a service repo:

**Once per repo**

1. Commit the `.claude/settings.json` stub above (or vendor with `tools/sync-kit.sh`).
2. Open the repo with `claude` and accept the workspace-trust prompt.
3. Confirm the kit is visible: `/plugin` should show `boot4-kit` enabled, and the commands
   appear namespaced as `/boot4-kit:migrate-phase` and `/boot4-kit:migrate-boot4`
   (unnamespaced — `/migrate-phase` — if you vendored instead).
4. Merge `hooks/hooks.json` into the repo's `.claude/settings.json` `"hooks"` block if you
   vendored; the plugin path installs it for you.
5. Write `CLAUDE.md` for the repo. Copy the template from Sheet 03 of the guide and fill in
   the real module names, build command, and rules.

**Then, per phase**

```
/boot4-kit:migrate-phase 0     # Plan Mode + strongest model tier; no edits
                               #   -> docs/migration/assessment.md, then STOPS

# a human reads assessment.md and signs it off — this gate is the point

/boot4-kit:migrate-phase 1     # each run ends at a green ./mvnw clean verify,
/boot4-kit:migrate-phase 2     #   a phase commit, and a changelog.md entry
...
```

Switch off auto-accept for Phase 3's Security DSL category and Phase 4's data-affecting
config, and back on for the mechanical ones — the phase files say which is which.

`/boot4-kit:migrate-boot4` runs the whole 0-7 sequence with the same gates, resuming from
the last phase commit. It will not start on its own — `disable-model-invocation: true`
means a human has to type it.

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

`plugin.json` deliberately omits `version`: every commit to this repo is a new plugin
version, which suits weekly iteration. For staged rollouts, add an explicit `version`
field instead — and remember to bump it on every release, or consumers will never update.

## What stays per-repo (on purpose)

`CLAUDE.md`, `assessment.md`, `changelog.md`, and the permissions block of
`.claude/settings.json` are repo-specific state, not shared recipe. The migration's
mandatory human gates (assessment sign-off, Security 7 defaults, golden-output diffs,
PR review) are encoded in the skills and are not to be automated away.

## Feeding the kit

Every surprise from a real migration goes into
`skills/boot4-migration/references/gotchas.md` (symptom → cause → fix). One commit here
teaches every remaining service in the fleet.
