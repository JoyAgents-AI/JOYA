# Framework Change Governance

Unified governance for framework-level changes — reduce "change first, review later" risk; ensure auditability, traceability, and rollback capability.

## Scope

A change enters the framework change process if it meets **any** of the following criteria:

1. Modifies principle-level content in `$JOYA_LIB/*` or shared `guides/*`
2. Affects default behavior of 2 or more agents
3. Involves security boundaries, permission models, or data handling rules
4. Involves instance-level operational aspects (deployment, scheduling, notifications, recovery strategies)

## Multi-Agent Review Requirement

Framework-level proposals and content changes must be discussed by **at least 3 agents** (including the proposer) before submission to the Principal. This avoids single-perspective blind spots and reduces errors.

| Phase | Who | Purpose |
|-------|-----|---------|
| Draft | Proposer (1 agent) | Write initial proposal |
| Peer Review | Proposer + ≥2 reviewers | Challenge assumptions, find gaps, suggest improvements |
| Submission | Proposer | Submit refined proposal to Principal for approval |

**Rules:**
- Reviewers must be from different roles or specializations when possible
- Each reviewer must provide substantive feedback (not just "+1")
- Disagreements are recorded in the proposal; Principal resolves
- Instance rules define how to select reviewers (e.g., by rotation, expertise, or availability)

## Default Process (Review Before Execution)

| Step | Requirement | Output |
|------|-------------|--------|
| 1. Proposal | Change description (purpose, scope, risk, rollback plan) | Change Proposal |
| 2. Peer Review | ≥3 agents discuss; reviewers provide written feedback | Review Notes |
| 3. Decision | Principal: Approved / Rejected / More Info Needed | Decision Record |
| 4. Execution | Implement per approved content | Commit / Deploy |
| 4b. Verify | If path/structure changed: update healthcheck manifest + run cross-node validation | Healthcheck Pass |
| 5. Record | Document decision, version, owner, timestamp | Governance Log |

## Emergency Exception (Stop the Bleeding First, Review After)

**Applicable scenarios**: Service outage, security risk, data risk, full-team blockage

**Mechanism**:
- Minimal stop-the-bleeding change may be executed first
- Review and documentation must be completed **within 24 hours**
- Must clearly state:
  - Reason for emergency
  - What was changed
  - Impact scope
  - Follow-up fix and rollback plan

## Cross-Node Validation (Step 4b)

Changes involving path renames, directory restructuring, or file relocation **must** update the healthcheck manifest (`$JOYA_MY/shared/core/infra/healthcheck.conf`) and run cross-node validation before recording as complete.

This catches stale references in:
- Agent bridge files (`~/.openclaw/workspace/*.md`) — not managed by Syncthing
- Instance documents that cross-reference moved files
- Gateway configs that embed framework paths

The healthcheck is triggered automatically by the `lib/` post-commit hook. Manual runs: `joy-healthcheck`.

## Rollback and Audit

Every framework change must include:

- Executable rollback steps
- Rollback trigger conditions
- Rollback owner
- Verification checkpoints (how to confirm recovery after rollback)

Review conclusions and execution results are archived under `.joy/governance/`.

## Governance Mode

Default: **balanced** (Manager gate + team review)

Aligned with the framework governance role defined in PLAYBOOK — avoids parallel dual-track rules.
