# ai-generated-guides-artifacts

Runnable artifacts for the guides in
[varasrinivas/ai-generated-guides](https://github.com/varasrinivas/ai-generated-guides).

The guides explain the reasoning; these are the files you actually install. Each kit is the
reference implementation of Sheet 07 of its guide, and every code block on that sheet is
reproduced from these files byte for byte.

| Kit | Agent | Guide |
|---|---|---|
| [`boot4-kit/`](boot4-kit/) | Claude Code | *Migrating Spring Boot 3.x → 4.0 with Claude Code* |
| [`boot4-kit-codex/`](boot4-kit-codex/) | OpenAI Codex | *Migrating Spring Boot 3.x → 4.0 with OpenAI Codex* |
| [`boot4-kit-copilot/`](boot4-kit-copilot/) | GitHub Copilot CLI | *Migrating Spring Boot 3.x → 4.0 with GitHub Copilot* |

All three encode the same eight-phase Spring Boot 3.5 → 4.x migration playbook: phased
skills, migration subagents, a post-edit compile-gate hook, and per-phase rule files
distilled from a real pilot migration. What differs is only the agent harness they are
written against — `CLAUDE.md` vs `AGENTS.md`, a permissions allowlist vs a sandbox plus
approval policy vs per-tool approvals, markdown subagents vs TOML vs `.agent.md`,
`/name` vs `$name` vs `/name` invocation, and where a repo's copy lives (`.claude/`,
`.agents/` + `.codex/`, or `.github/`).

## Using one

Read the kit's own `README.md` — each has a **Running it** section covering first-run
setup, the command sequence, and the two behaviours that look like bugs and are not.

In short: extract the kit you want into its own internal git repo, then either install it
as a plugin (Claude Code) or vendor it into each service repo with `tools/sync-kit.sh`
(any of the three). The kits are written to be forked and edited — the phase files in
particular are meant to absorb what each migration teaches.

## What stays out of these kits, deliberately

Per-repo state — `CLAUDE.md` / `AGENTS.md`, `docs/migration/assessment.md`,
`docs/migration/changelog.md`, and the sandbox/approval configuration — is repo-specific,
not shared recipe. So are the migration's mandatory human gates: assessment sign-off,
Security 7 default changes, golden-output diffs, and PR review. Those are encoded in the
skills as stopping points and are not to be automated away.

## Keeping them honest

The guides repo carries `tools/check-guides.py`, which verifies that every code block in a
guide still matches the file here that it names, that the Spring Boot content is identical
across all three kits, and that the kits reference migration state under `docs/migration/`. It
finds this repo as a sibling checkout, or wherever `GUIDES_ARTIFACTS` points:

```
git clone https://github.com/varasrinivas/ai-generated-guides.git
git clone https://github.com/varasrinivas/ai-generated-guides-artifacts.git
cd ai-generated-guides && python tools/check-guides.py
```

Edit a kit file here and the check will tell you which guide block went stale.
