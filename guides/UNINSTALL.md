# Uninstall Guide

How to cleanly disconnect an agent or an entire instance from JOYA.

---

## Single Agent Exit

When one agent leaves the team but others remain:

1. **Follow offboarding** in `guides/LIFECYCLE.md` (task reassignment, memory archival, roster update).
2. **Remove JOYA references** from the agent's runtime config (e.g., remove `AGENT_INIT.md` from OpenClaw workspace files, remove project knowledge entries from Claude).
3. **Optionally export memories** — copy `$JOYA_MY/agents/<name>/` to a standalone directory for the agent to keep outside JOYA.
4. The agent's runtime continues working normally — JOYA was never invasive.

---

## Full Instance Teardown

When the Principal wants to stop using JOYA entirely:

### Step 1: Export what matters

Before removing anything, the Manager should:

- Export each agent's `IDENTITY.md`, `MEMORY.md`, and `RELATIONSHIPS.md` to standalone locations outside the JOYA directory.
- Export project knowledge: copy any project-specific knowledge from `shared/projects/` or `shared/knowledge/` to each project's own docs.
- Export cross-project knowledge: save `$JOYA_MY/shared/knowledge/` somewhere accessible.

### Step 2: Disconnect agents

For each agent, remove JOYA references from their runtime:

| Runtime | What to remove |
|---------|---------------|
| OpenClaw | Remove joy-agents path from workspace files; remove `AGENT_INIT.md` references from `SOUL.md` or `AGENTS.md` |
| Claude Code | Remove joy-agents files from project knowledge |
| Cursor | Remove joy-agents references from `.cursor/` rules |
| Other | Remove any file-read directives pointing to the joy-agents directory |

### Step 3: Clean up projects

For each managed project:

- Remove the project's entry from `$JOYA_MY/shared/projects/`
- Project repos are unaffected — their docs belong to the project, not to JOYA

### Step 4: Remove the instance

```bash
# Option A: Archive (recommended)
mv joy-agents/ joy-agents-archived/

# Option B: Delete
rm -rf joy-agents/
```

### Step 5: Verify agents are clean

Ask each agent: *"Do you have any JOYA rules or protocols loaded?"* — they should answer no.

If an agent still references JOYA files, check its startup configuration for remaining file paths.

---

## After Uninstall

Agents stop following JOYA rules/axioms. They **keep** their identity, memories, and knowledge — those belong to the agent.

## Rollback / Re-joining

- **Partial setup rollback:** Remove `$JOYA_MY/` and runtime references to `AGENT_INIT.md`.
- **Re-joining later:** Restore from archive, import agent files back to `$JOYA_MY/agents/`, read `AGENT_INIT.md` again.
