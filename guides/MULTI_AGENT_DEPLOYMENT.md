# Multi-Agent Deployment Guide

Practical guidance for deploying multiple agents on one or more machines. For the core rules governing multi-agent isolation, see `guides/MULTI_AGENT.md`.

---

## 1. Filesystem Contract

The framework defines standard directory zones for agent access. Deployment mechanisms must map these logical paths to physical locations.

### 1.1 Directory Zones

| Zone | Path (relative to joy-agents root) | Access | Description |
|------|--------------------------------------|--------|-------------|
| **Agent Private** | `$JOYA_MY/agents/<name>/` | RW (owner only) | Identity, memory, secrets, scripts |
| **Shared Config** | `$JOYA_MY/shared/core/` | RO (Workers), RW (Manager) | PRINCIPAL.md, INFRASTRUCTURE.md |
| **Shared Knowledge** | `$JOYA_MY/shared/knowledge/` | Policy-dependent (see guides/MULTI_AGENT.md §4) | Research, reports, shared documents |
| **Shared Tasks** | `$JOYA_MY/shared/tasks/` | RW (all) | Task tracking and coordination |
| **Shared Toolkit** | `$JOYA_MY/shared/toolkit/` | RW (all) | Team scripts, skills, adapters |
| **Framework** | `$JOYA_LIB/` | RO | Protocol core, guides, examples |
| **Roster** | `$JOYA_MY/shared/agents/ROSTER.md` | RO (Workers), RW (Manager) | Agent registry |
| **Directory** | `$JOYA_MY/shared/agents/DIRECTORY.json` | RO (Workers), RW (Manager) | Agent contact info |
| **Dropzone** | `$JOYA_MY/shared/dropzone/` | RW (all) | Temporary file exchange |

### 1.2 Path Resolution

The agent's workspace config (e.g., `AGENTS.md`) translates between physical and logical paths. This is the only file that contains deployment-specific absolute paths. All other protocol files reference paths relative to the joy-agents root.

### 1.3 Mapping Examples

**Bare-metal (direct):**
```
Physical: /path/to/joy-agents/$JOYA_MY/agents/Rex/
Logical:  $JOYA_MY/agents/Rex/
```

**Bare-metal (NFS mount):**
```
Physical: /home/user/mnt/m3-main/Code/joy-agents/$JOYA_MY/agents/Rex/
Logical:  $JOYA_MY/agents/Rex/
```

**Docker container:**
```yaml
volumes:
  # Instance — all agent and shared directories
  - ./instance:/joy-agents/instance:rw
  # Framework — read-only
  - ./framework:/joy-agents/framework:ro
```

Write isolation is enforced by protocol rules (each agent writes only to its own subdirectory under `$JOYA_MY/agents/<name>/`), not by filesystem permissions — consistent with how NFS works in bare-metal deployments.

> **Note on symlinks:** If the host uses symlinks to connect workspace files to joy-agents paths, containers may not resolve them. Use direct volume mounts instead.

---

## 2. Communication Layer

The framework requires a communication layer but does not mandate a specific implementation. The communication layer is **pluggable**.

### 2.1 Required Capabilities

Any communication layer must support:
- **Point-to-point** messaging (agent → agent)
- **Broadcast** (agent → all)
- **Group discussion** (multi-party)
- **Distinct sender identity** (who is speaking must be clear)
- **Reliable delivery** (at-least-once)
- **Persistent history** (queryable)

### 2.2 Implementation Options

| Implementation | Setup Effort | Features | Best For |
|----------------|-------------|----------|----------|
| **Self-hosted Mattermost** | Medium | Full chat, bots, channels, webhooks | Teams needing rich collaboration |
| **Discord** | Low | Free, bot API, channels, threads | Quick start, existing Discord users |
| **Slack** | Low–Medium | Full chat, bot API, enterprise features | Enterprise environments |
| **File-based message bus** | Zero | Minimal, no external dependencies | Minimal deployments, air-gapped |

The instance defines its communication layer in `INFRASTRUCTURE.md` and provides adapter config in `DIRECTORY.json`.

### 2.3 Minimum Viable Communication

For the simplest possible deployment, a **file-based message bus** satisfies all requirements with zero external dependencies:

```
$JOYA_MY/shared/messages/
├── broadcast/          # All-agent messages (append-only)
├── channels/           # Named group discussions
│   ├── general/
│   └── project-x/
└── direct/             # Point-to-point
    ├── cla→rex/
    └── rex→cla/
```

Agents poll the directory for new messages. Not suitable for real-time collaboration, but sufficient for asynchronous multi-agent workflows.

---

## 3. Scale Profiles

Reference configurations for common deployment sizes. These are guidelines, not hard categories.

### Solo

```
1 machine  ·  1 Manager + 1–2 Workers  ·  8–16 GB RAM
```

- All agents run as OS processes on the same machine.
- Shared filesystem is the local filesystem — no NFS needed.
- Communication: file-based or lightweight chat.
- **Target audience:** Individual developers exploring multi-agent workflows.

### Team

```
1 machine  ·  1 Manager + 3–8 Workers  ·  16–64 GB RAM
```

- Agents run as Docker containers or OS processes.
- Shared filesystem is local or Docker volumes.
- Communication: self-hosted Mattermost or Discord.
- **Target audience:** Small teams or enthusiasts wanting a full multi-agent experience.

### Cluster

```
2+ machines  ·  1 Manager + N Workers  ·  64 GB+ RAM
```

- Agents distributed across machines, containers, or VMs.
- Shared filesystem via NFS/SMB (see `DEPLOYMENT.md`).
- Communication: self-hosted Mattermost or equivalent.
- **Target audience:** Organizations, power users, multi-site deployments.

### Resource Estimation

| Component | RAM per Instance | Notes |
|-----------|-----------------|-------|
| Agent runtime (e.g., OpenClaw) | ~200–500 MB | Orchestration process + tools |
| Mattermost (self-hosted) | ~500 MB–1 GB | Optional; one instance shared by all agents |
| Git server (Gitea) | ~100–300 MB | Optional |
| Project management (Huly) | ~1–2 GB | Optional |

**Key insight:** Agent processes are lightweight because computation happens in the cloud (LLM API calls). Local resources are consumed primarily by infrastructure services, not by agents themselves.

---

## 4. Deployment Patterns

### 4.1 Hybrid (Recommended)

Manager runs bare-metal with full Level 3 capabilities. Workers run in containers with Level 1–2 capabilities.

```
Host machine (bare-metal)
├── Manager agent (Level 3) — full OS access
├── Docker runtime
│   ├── Worker-A container (Level 1–2)
│   ├── Worker-B container (Level 1–2)
│   └── Worker-C container (Level 1–2)
└── Infrastructure services (MM, Gitea, etc.)
```

**Advantages:** Manager retains native capabilities for node management and desktop automation. Workers are easy to scale. Infrastructure services coexist in the same Docker environment.

### 4.2 All-Container

All agents, including the Manager, run in containers. Manager container gets additional volume mounts or host networking for Level 3 capabilities when needed.

```
Host machine
├── Docker runtime
│   ├── Manager container (Level 2–3, privileged mounts)
│   ├── Worker-A container (Level 1–2)
│   └── Worker-B container (Level 1–2)
└── Infrastructure services
```

**Advantages:** Uniform deployment. Easier automation and reproducibility.
**Tradeoff:** Manager may lose some Level 3 capabilities unless given privileged access.

### 4.3 Multi-Machine

Agents spread across multiple machines. Requires shared filesystem (NFS/SMB) for `$JOYA_MY/` access.

```
Machine A (home node)
├── Manager agent
├── $JOYA_MY/ (authoritative copy)
└── Infrastructure services

Machine B
├── Worker-A (NFS mount → Machine A $JOYA_MY/)
└── Worker-B

Machine C
├── Worker-C
└── Worker-D
```

See `DEPLOYMENT.md` for shared storage, process persistence, and path resolution details.

---

## 5. Agent Provisioning

Adding a new agent to an instance requires these steps. The Manager is responsible for orchestration.

### 5.1 Minimum Required Steps

1. **Create agent directory:** `$JOYA_MY/agents/<name>/`
2. **Write IDENTITY.md:** Name, role, personality, capability level.
3. **Write SECRETS.md:** API keys, tokens (or empty if inheriting).
4. **Register in ROSTER.md:** Add entry with role and node.
5. **Register in DIRECTORY.json:** Add communication endpoints.
6. **Configure runtime:** Platform-specific agent process config.
7. **Set up communication identity:** Bot token, sender ID, channel subscriptions.
8. **Verify:** Health check + communication round-trip test.

### 5.2 Provisioning Automation

For deployments beyond a few agents, automate with a script that:
- Takes a name, role, and capability level as input
- Generates identity/config files from templates
- Registers the agent in ROSTER.md and DIRECTORY.json
- Creates communication credentials
- Starts the agent process
- Runs the verification checklist

A reference provisioning script may be provided in `toolkit/scripts/`.

---

## 6. Quick Start: One Machine, Five Minutes

The minimum viable multi-agent deployment.

### Prerequisites
- One machine (any OS, 8 GB+ RAM)
- One LLM API key (OpenAI, Anthropic, or any supported provider)
- Node.js installed

### Steps

1. **Clone the framework:**
   ```bash
   git clone <joy-agents-repo> && cd joy-agents
   ```

2. **Run the starter script:**
   ```bash
   # (coming soon)
   ./toolkit/scripts/quickstart.sh \
     --agents 3 \
     --provider openai \
     --api-key sk-xxx
   ```

3. **What happens:**
   - Creates 1 Manager + 2 Workers with generated identities
   - Sets up file-based communication (zero external dependencies)
   - Starts all agent processes
   - Manager announces readiness and awaits instructions

4. **Interact:**
   - Talk to the Manager via the designated interface
   - Watch agents coordinate, delegate, and deliver

> The quickstart script is a reference implementation. Production deployments should follow the full provisioning workflow (§5).

---

## 7. Deployment Checklist

Before declaring a multi-agent deployment operational:

- [ ] Each agent has its own process with independent lifecycle
- [ ] Each agent can read its private directory and shared config
- [ ] Each agent can write to its private directory
- [ ] Shared write policy is configured and understood by all agents
- [ ] Each agent has a distinct communication identity
- [ ] Point-to-point, broadcast, and group messaging all work
- [ ] Manager can monitor agent availability (health checks)
- [ ] Agent crash/restart does not affect other agents
- [ ] Framework files are accessible (read-only) to all agents
- [ ] Provisioning process is documented (or automated)

---

## Cross-Platform Operation Checklist

When executing the same operation across multiple nodes (e.g., path migration, config update), you MUST:

- **List all steps first** — enumerate every node and the exact operation it needs before touching anything.
- **Execute per-node against the checklist** — do not improvise a different method because of platform differences (macOS vs Windows vs Linux).
- **Verify immediately after each node** — do not batch-execute then batch-verify.
- **Use unified verification commands** — adapt syntax per platform but verify the same thing everywhere.

> **Lesson learned:** Using different methods on different platforms for the same task leads to missed steps and inconsistent state.
