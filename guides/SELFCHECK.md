# Self-Check Guide

Agent self-verification procedure. Ensures all dependencies are functional before accepting tasks.

---

## When to Run

### Full Check (complete report)

| Trigger | Reason |
|---------|--------|
| Session first start | Agent coming online |
| After compaction | Equivalent to session restart — all loaded files are gone |
| After gateway restart | Configuration may have changed |
| After migration/deployment | New environment needs verification |
| After model switch | Confirm new model works correctly |

### Quick Check (brief report — only list changed items)

| Trigger | Reason |
|---------|--------|
| After framework upgrade | Version/paths may have changed |
| After NFS/shared storage changes | Paths and permissions may be invalid |
| After extended offline period | Environment may have changed |

---

## Check Items

### 1. Protocol Loaded

Verify core files are accessible. Loading depth depends on Onboarding Exam status (see Tiered Loading in AGENT_INIT.md):

**Tier 1 (always full read):** IDENTITY.md, MEMORY.md, VERSION, PRINCIPAL.md
**Tier 2 (scan headers + key sections):** PLAYBOOK.md, AXIOMS.md, RULES.md, MESSAGING.md, ROSTER.md, INFRASTRUCTURE.md, instance rules
**Tier 3 (on demand):** Guides, examples, detailed infrastructure history

If no Onboarding Exam record in MEMORY.md → load all files fully (Tier 1 behavior for everything).

### 2. Framework Version

Read `VERSION`. Remember the version string for reporting.

### 3. Path Verification

Resolve and report **absolute paths** for:
- JOYA root directory
- Your agent directory (`$JOYA_MY/agents/<name>/`)
- Your MEMORY.md

This catches NFS mount errors, broken symlinks, and path misconfiguration.

### 4. System Information

Report:
- Node name and IP address
- Operating system
- Agent engine and version (e.g., OpenClaw 2026.2.14, Claude Code, Cursor)
- Current model and thinking level

### 5. Communication

- Send a test message through your configured channel
- Confirm sender identity displays correctly (your bot name, not someone else's)
- Report: channel name, bot username, chatmode, requireMention setting

### 6. File I/O

- Create a test file in your agent directory
- Verify it exists
- Delete it
- This proves write access and catches NFS/mount permission issues

### 7. Memory Loaded

- MEMORY.md is readable
- Contains key context (not empty or corrupted)

### 8. Tools

- At least one core capability available (exec, message, file ops)

### 9. Git Sync

- Report current `git rev-parse --short HEAD` (or equivalent)
- Manager uses this to verify all agents see the same framework version

---

## Report Format

### Full Report

```
✅ JOYA v<version> Online

## System
- Node: <node name> (<IP>)
- OS: <operating system>
- Engine: <agent engine + version>
- Model: <model> | thinking: <level>

## Paths
- Root: <absolute path>
- Agent dir: <absolute path>
- MEMORY.md: <absolute path>
- Git HEAD: <short hash>

## Communication
- Channel: <channel> ✅
- Bot: @<bot_name>
- chatmode: <onmessage|oncall>
- requireMention: <true|false>

## Capabilities
- File I/O: ✅ (write test passed)
- Tools: ✅
```

### Quick Report

```
✅ JOYA v<version> self-check passed
- <list only changed or noteworthy items>
```

### Failure Report

```
⚠️ JOYA v<version> check failed
- <failed items with details>
- <attempted fixes>
- <current status: DEGRADED or OFFLINE>
```

Agents SHOULD use the Principal's configured language for the actual report text. The templates above are structural examples — adapt the language, keep the structure.

---

## Failure Handling

1. **Auto-repair**: On failure, attempt to fix (max 2 retries)
2. **Report**: If still failing, report `DEGRADED` with details
3. **Degraded mode**: Read-only analysis + core responses only
4. **Recovery**: Manager or Principal clears degraded status after fix confirmed
5. **Silent failure is never acceptable** — always report

---

## Manager Responsibility

The Manager SHOULD actively monitor the team's self-check status:

1. **Watch for reports**: When agents come online, check that their READY/DEGRADED reports arrive in the team channel.
2. **Detect missing reports**: If an agent is expected to be online but hasn't reported, proactively check its status (gateway process, logs, connectivity).
3. **Act on DEGRADED**: When a DEGRADED report arrives, diagnose and fix the issue promptly. Don't wait for the agent or Principal to escalate.
4. **Periodic health checks**: During routine work, be aware of agent availability. If an agent stops responding or shows errors, investigate without being asked.
5. **Post-fix verification**: After fixing an issue, confirm the agent passes self-check before marking it resolved.

The Manager is the team's first line of defense against silent failures. Agents report their own status; the Manager ensures no report goes unnoticed.

---

## Instance Extension

Instances may add custom check items in `$JOYA_MY/shared/rules/selfcheck.md`.

Custom items are appended to the framework checks. They follow the same pass/fail/report pattern.

Example custom checks:
- GPU availability for inference nodes
- External service connectivity (ComfyUI, Plane, etc.)
- Database connection verification
- Specific port/endpoint reachability

---

## Important

All reported values MUST be read from actual system state (config files, environment, runtime). Do not guess or assume values. If you cannot determine a field, report it as `unknown`.
