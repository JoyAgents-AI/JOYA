# Multi-Agent

> **Scope:** This document defines multi-agent governance constraints. For deployment steps, see `guides/MULTI_AGENT_DEPLOYMENT.md`.

Runtime isolation and coexistence rules for multi-agent deployments.

This document defines the **boundaries and guarantees** required when multiple agents operate within the same instance. For organizational structure (roles, permissions), see `core/ARCHITECTURE.md`.

---

## 1. Core Principle

Each named agent is a **separate runtime process** with its own identity, memory, credentials, and communication channel. This follows directly from the framework's identity model (`core/ARCHITECTURE.md` §7).

An agent's runtime boundary is its process. Two agents must never share:
- Identity files (IDENTITY.md, MEMORY.md)
- Credentials (SECRETS.md, credentials/)
- Communication identity (bot token, sender ID)
- Process lifecycle (one crashing must not kill another)

They **may** share:
- Read-only framework files
- Read-only shared config
- A writable shared knowledge area (with policy — see §4)
- Network infrastructure (same LAN, same services)

---

## 2. Isolation Model

### 2.1 Process Isolation (Required)

Every named agent runs as an independent OS-level process. The specific mechanism is deployment-dependent:

- Separate OS processes
- Docker containers
- Virtual machines
- Separate physical machines

All mechanisms are valid. The framework does not prescribe one — it only requires that the isolation guarantees in §1 are met.

### 2.2 Sub-Agent Sessions

An agent's runtime may support spawning ephemeral sub-sessions for parallel task execution (e.g., OpenClaw's `sessions_spawn`). These sub-sessions:
- Share the parent agent's identity and credentials
- Are temporary — no persistent identity
- Are an **internal optimization**, not a substitute for named agents

**Rule:** Sub-agent sessions must not be used to simulate independent named agents. If a workstream needs its own identity, memory, or communication channel, it must be a named agent.

---

## 3. Runtime Capability Levels

Not every agent needs every capability. The framework defines three levels to guide task assignment and deployment decisions.

### Level 1 — Core (Required for all agents)

| Capability | Description |
|------------|-------------|
| Runtime | Language runtime for the agent platform (e.g., Node.js) |
| Network | HTTP/HTTPS/WebSocket to LLM APIs and internal services |
| File I/O | Read/write access to agent-private and shared directories |
| Shell | Execute CLI commands within the agent's environment |
| Communication | Send/receive messages through at least one channel |

Any deployment mechanism that provides Level 1 can run a JOYA agent.

### Level 2 — Extended (Recommended for Workers)

| Capability | Description |
|------------|-------------|
| SSH | Connect to other nodes in the instance |
| Git | Clone, commit, push to team repositories |
| Cross-node files | Access files on other machines (NFS, shared volume) |
| Background processes | Run persistent daemons or watchers |

### Level 3 — Native (Recommended for Manager)

| Capability | Description |
|------------|-------------|
| Host OS access | Control host-level services, process management |
| Device access | Paired devices, cameras, hardware peripherals |
| Desktop automation | Browser control, GUI automation |
| Node management | Start/stop/monitor other agents' processes |

Level 3 generally requires bare-metal or VM deployment (not containers).

### Capability Declaration

Each agent should declare its capability level in its identity or config:

```yaml
capabilities:
  level: 2
  extras: [docker, gpu]
  limitations: [no-browser]
```

The Manager uses capability declarations to assign tasks appropriately.

---

## 4. Shared Write Policy

When multiple agents can write to shared directories (e.g., `shared/knowledge/`), a write policy prevents conflicts. Instances must choose one.

### `shared` — Direct Write (Default)

All agents write directly to the shared directory. Coordination is by convention:

1. **Unique filenames.** Include the agent name or topic to avoid collisions.
2. **Single-writer per file.** Each file has one designated author. Other agents request edits through messaging.
3. **Append-friendly formats.** Prefer formats where concurrent appends don't corrupt data.

### `delegated` — Manager-Mediated

Workers write only to their private directory (`$JOYA_MY/agents/<name>/`). Shared directory writes are performed by the Manager on request:

1. Worker produces content in their private directory.
2. Worker sends the content or file reference to the Manager via messaging.
3. Manager reviews and writes to the shared directory.

### Configuration

Set the policy in `$JOYA_MY/shared/core/PLAYBOOK.md`:

```yaml
shared_write_policy: shared  # or delegated
```

If not specified, `shared` applies.
