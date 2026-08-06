---
name: audit-tier3
description: Audit a migrated Spring Boot service for silent Tier-3
  behavior changes — Jackson serialization, PropertyMapper nulls,
  Batch metadata, Security 7 defaults. Use after a Boot 4 bump
  compiles and starts, before opening the PR.
---
Audit this repository for behavior that changed silently. Work
references/tier3-checklist.md in order; it has the specifics.

Run this through the behavior-auditor custom agent, whose `tools:`
list carries no `edit`. A Copilot skill's `allowed-tools` can only
pre-approve tools, never remove them, so the agent's allowlist (or a
plan-mode session) is what makes "audit, not fix" structural rather
than merely requested.

Rules:
- You are auditing, not fixing. Report findings; never edit
  application code to make one go away.
- Every finding carries file/line, the old behavior, the new
  behavior, and the evidence (a config, a DTO, or a golden diff).
- If you cannot verify a suspicion, mark it UNVERIFIED and say why.
  A confident guess is the failure mode this skill exists to avoid.

Write docs/migration/behavior-review.md: one entry per finding, each
tagged KEEP / CHANGE / NEEDS-HUMAN-DECISION. A finding with no
disposition is not done.

Stop and report if you cannot complete the checklist. A partial audit
reported as complete is worse than no audit.
