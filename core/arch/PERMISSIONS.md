# Permission Matrix

| Directory | Principal | Manager | Worker |
|---|---|---|---|
| `$JOYA_LIB/` | RW | Read + Propose | Read |
| `guides/` | RW | RW | RW |
| `$JOYA_MY/agents/` | RW | RW | Read |
| `$JOYA_MY/shared/core/` | RW | RW | Read |
| `$JOYA_MY/shared/rules/` | RW | RW | RW |
| `$JOYA_MY/shared/tasks/` | RW | RW | RW |
| `$JOYA_MY/shared/meetings/` | RW | RW | RW |
| `$JOYA_MY/shared/scores/` | RW | RW | Read |
| `$JOYA_MY/shared/toolkit/` | RW | RW | RW |
| `$JOYA_MY/agents/<own>/*` | RW | RW | RW |
| `$JOYA_MY/agents/<own>/SECRETS.md` | RW | RW | RW |
| `$JOYA_MY/shared/secrets/` | RW | RW | Read |
| `toolkit/*` | RW | Read | Read |

Notes:
- "Propose" = may draft but needs Principal approval to merge.
- All `guides/` writes require post-commit notification to all agents.
- The Principal has unrestricted access.

## Permission Extension

Role defaults apply to all agents of that role. Instances may adjust via:

**Permission groups:** Named groups in `$JOYA_MY/shared/core/` that grant or revoke sets of permissions.

**Personal overrides:** Per-agent via `$JOYA_MY/agents/<name>/permissions.md`.

**Priority:** Role default < Permission group < Personal override.

Group names and granularity are instance decisions. Describe permission boundaries in natural language.
