# Deployment Guide

Principles for deploying JOYA across machines and platforms.

---

## The Three Deployment Problems

Cross-platform deployment must solve three problems:

1. **Shared storage** — All agents must access the same joy-agents directory tree.
2. **Process persistence** — Agent processes must survive session disconnects.
3. **Path resolution** — Each platform may mount the shared tree at a different path.

---

## Shared Storage

A network filesystem is required for multi-machine instances. All agents must see the same `$JOYA_MY/`, `$JOYA_LIB/`, and `toolkit/` directories. Without shared storage, agents cannot read each other's artifacts or coordinate through the filesystem.

Local-only instances (single machine) can skip this — the local filesystem is already shared.

---

## Process Persistence

Agent processes must remain running independently of how they were started. If a process dies when an SSH session closes or a terminal is quit, the agent is unreachable. Each platform has its own mechanism for persistent background processes — use whatever is native.

---

## Path Resolution

Each agent's workspace `AGENTS.md` is the sole translation layer between platform-specific paths and the joy-agents directory structure. On the home node, relative paths work. On remote nodes, use absolute mount-point paths. All other protocol files reference logical locations; only `AGENTS.md` contains physical paths.

---

## Communication Verification

After deploying or migrating an agent, verify before assigning tasks:

1. Agent can **receive** messages through its configured channel.
2. Agent can **send** messages using the sanctioned adapter.
3. Messages display the correct sender identity.
4. Agent is subscribed to all relevant channels.

See `LIFECYCLE.md` for the full migration verification checklist.

---

## OpenClaw Workspace Optimization

OpenClaw injects these workspace files into every session's system prompt: `AGENTS.md`, `SOUL.md`, `IDENTITY.md`, `USER.md`, `BOOTSTRAP.md`, `TOOLS.md`, `HEARTBEAT.md`.

Under JOYA, `AGENTS.md` already contains all loading instructions (identity, principal, playbook, etc.). The other pointer files (`SOUL.md`, `IDENTITY.md`, `USER.md`, `BOOTSTRAP.md`) become redundant — their "go read X" content duplicates what `AGENTS.md` already says.

**Rule:** Keep `SOUL.md`, `IDENTITY.md`, `USER.md`, and `BOOTSTRAP.md` as **minimal stubs** (one comment line). All loading logic lives in `AGENTS.md`. This avoids wasting ~250 tokens per session on redundant pointers.

```markdown
# Soul — managed by AGENTS.md
```

`TOOLS.md` and `HEARTBEAT.md` retain their own content (they serve OpenClaw-specific purposes not covered by `AGENTS.md`).

---

## Platform-Specific Details

- **macOS ↔ Windows NFS/SSH setup**: see `examples/deployment-macos-windows.md`
- **OpenClaw + Mattermost channel config**: see `examples/deployment-openclaw-mattermost.md`

---

## Windows Agent Path Requirements

- Windows nodes accessing shared files via NFS **must** use UNC paths (`\\host\path`).
- Do not assume `~/` or `$HOME/` resolves correctly on Windows.
- All paths in workspace pointer files must be fully-qualified UNC format.
- Avoid PowerShell `Set-Content -Encoding UTF8` when modifying Windows files — it adds a BOM. Use `node -e` or SCP instead.
