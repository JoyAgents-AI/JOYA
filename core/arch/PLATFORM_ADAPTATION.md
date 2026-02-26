# Platform Adaptation

> **Audience:** All agents, runtime integrators  
> **Load:** Tier 2 (scan on session start); full read when adapting to a new runtime  
> **Problem:** JOYA's loading chain assumes agents can execute file reads at session start, but runtimes vary widely in their injection and lifecycle capabilities.

## The Gap

JOYA's `AGENT_INIT.md` loading chain requires:
1. Agent receives AGENT_INIT.md content
2. Agent **executes** file read instructions sequentially
3. Agent completes Tier 1 loading before handling user messages

This works when the runtime provides an execution entry point (CLI session, session_start hook). It fails when:
- The runtime injects files as **static text** (no instruction execution)
- There is no lifecycle hook before the first user message
- Compaction clears context with no re-initialization trigger

These are not edge cases — they describe most production runtimes today.

## Runtime Capability Levels

| Level | Capabilities | Examples |
|-------|-------------|----------|
| **A** | session_start hook + file read execution + compaction hook | Custom orchestrators, LangGraph with lifecycle |
| **B** | Static file injection into system prompt (workspace context) | OpenClaw, Cursor, Windsurf, Claude Projects |
| **C** | System prompt only, no file injection | Raw API calls, simple chat wrappers |

### Level A — Full Lifecycle

The runtime can trigger AGENT_INIT.md execution automatically. JOYA's loading chain works as designed.

**Adapter requirements:** Point session_start hook at `$JOYA_LIB/AGENT_INIT.md`. Wire compaction hook to re-execute Tier 1 loading.

### Level B — Static Injection

The runtime embeds workspace files into the system prompt as plain text. The agent sees file contents but cannot control load order or follow cross-file references.

**Adapter requirements:**
1. **Inline all Tier 1 content** directly into workspace files — no bridge/pointer files
2. **Include a loading manifest** (see below) for Tier 2/3 on-demand files
3. **Include adaptation instructions** in AGENTS.md telling the agent what's pre-loaded vs. what needs manual reads

**Key constraint:** Bridge files (files containing `Read <path>` instructions) are interpreted as literal text, not executable commands. Every file injected into workspace context must contain its actual content.

### Level C — Bare Minimum

No file injection. The agent must bootstrap entirely from system prompt instructions.

**Adapter requirements:**
1. System prompt includes the loading manifest (compact form)
2. Agent self-initiates full Tier 1 loading on first message
3. Agent must detect compaction (summary block at conversation start) and re-load

## Loading Manifest

A machine-readable declaration of files the agent needs, enabling runtimes to automate loading regardless of capability level.

**Location:** `$JOYA_MY/agents/<name>/MANIFEST.yaml` (per-agent, since paths may vary)

```yaml
# MANIFEST.yaml — Platform Adaptation Loading Manifest
# Machine-readable file loading declaration for JOYA agents.
# Runtimes use this to automate file injection or agent-initiated loading.

version: "1.0"
agent: "<name>"

# Files that MUST be available in agent context at session start.
# Level A: loaded by hook. Level B: inlined in workspace. Level C: agent self-loads.
tier1:
  - path: "$JOYA_MY/agents/<name>/IDENTITY.md"
    inline: true          # Should be inlined in workspace context if possible
    description: "Agent identity and personality"
  - path: "$JOYA_MY/agents/<name>/MEMORY.md"
    inline: true
    description: "Long-term memory and state"
  - path: "$JOYA_MY/shared/core/PRINCIPAL.md"
    inline: true
    description: "Principal identity and preferences"
  - path: "$JOYA_MY/shared/core/PREFERENCES.md"
    inline: false         # Too dynamic; load on demand
    trigger: always       # But should be loaded every session
    description: "Instance preferences (autonomy, content policy, etc.)"
  - path: "$JOYA_MY/shared/agents/ROSTER.md"
    inline: false
    trigger: on_reference # Load when agent config/model questions arise
    description: "Team roster and model assignments"

# Files loaded only when specific scenarios arise.
tier2:
  - path: "$JOYA_MY/shared/core/INFRASTRUCTURE.md"
    trigger: on_reference
    description: "Infrastructure services and endpoints"
  - path: "$JOYA_MY/agents/<name>/SESSION.md"
    trigger: on_compaction  # Load after compaction to recover work context
    description: "Working state WAL"

# Scan-only files (headers + key sections, not full content)
tier2_scan:
  - path: "$JOYA_MY/shared/agents/ROSTER.md"
    scan: "agent table only"
  - path: "$JOYA_MY/shared/core/INFRASTRUCTURE.md"
    scan: "Quick Reference section only"
```

### Manifest Triggers

| Trigger | When to load |
|---------|-------------|
| `always` | Every session start and after every compaction |
| `on_compaction` | Only after compaction recovery |
| `on_reference` | When matching keywords appear in conversation (see `keywords` field) |
| `on_heartbeat` | During periodic heartbeat checks |

**`on_reference` keyword matching:** Add a `keywords` list to help agents detect when a file is relevant:

```yaml
  - path: "$JOYA_MY/shared/core/INFRASTRUCTURE.md"
    trigger: on_reference
    keywords: ["IP", "endpoint", "port", "服务器", "部署", "deploy", "service"]
    description: "Infrastructure services and endpoints"
```

Keywords are hints, not strict filters — agents should also load the file when the broader topic clearly applies even without exact keyword matches.

### How Runtimes Use the Manifest

- **Level A:** session_start hook reads MANIFEST.yaml, loads all `trigger: always` files automatically, queues others for lazy loading.
- **Level B:** Deployment script reads MANIFEST.yaml, generates workspace files with `inline: true` content pre-embedded, and includes the remaining entries as a readable on-demand table in AGENTS.md.
- **Level C:** Manifest is serialized into system prompt. Agent parses it on first message and self-loads.
- **Heartbeat:** Any runtime can use the manifest to verify required files are still in context. If missing (post-compaction), re-load.

## Bridge File Standard

When a workspace file needs to reference another file's content:

**❌ Don't (ambiguous — runtime may not execute):**
```markdown
# Identity
Read ../../joya/my/agents/cla/IDENTITY.md for your full identity definition.
```

**✅ Do (explicit metadata in YAML front-matter):**
```yaml
---
type: bridge
target: /Users/michael/joya/my/agents/cla/IDENTITY.md
inline_for: [level_b, level_c]
---
```

**✅ Or better — inline the content directly** (preferred for Level B runtimes):
```markdown
# Cla

## Profile
- **Name:** Cla
...actual content here...
```

Bridge files with YAML front-matter give deployment tools a parseable signal: "this file is a pointer, resolve it before injecting." Plain-text `Read X` instructions are invisible to tooling.

## Compaction × Adaptation

After compaction, the agent's context is reset. Recovery depends on runtime level:

| Level | Tier 1 Recovery | Work Context Recovery |
|-------|----------------|----------------------|
| **A** | Automatic (compaction hook re-loads) | SESSION.md auto-loaded |
| **B** | Automatic (workspace context re-injected by runtime) | Agent reads SESSION.md on detecting compaction |
| **C** | Agent must self-detect and re-load all Tier 1 | Agent reads SESSION.md on detecting compaction |

**Detection signals for agents (check any):**
1. MEMORY.md content is NOT visible in current context (Level B: should always be injected)
2. `SESSION.md` exists with content but you have no memory of the work described in it
3. Conversation starts with a summary/recap block (runtime-specific; e.g., Claude uses `[conversation_summary]`)
4. You cannot recall your name, role, or Principal without reading a file

If **any** signal is true, assume compaction occurred and execute recovery.

## Adaptation Checklist

When deploying JOYA on a new runtime:

- [ ] Determine runtime capability level (A/B/C)
- [ ] Generate MANIFEST.yaml for each agent
- [ ] For Level B: Inline all `inline: true` files into workspace; add on-demand table to AGENTS.md
- [ ] For Level B: Ensure no bridge/pointer files in workspace — all must contain actual content
- [ ] For Level C: Serialize compact manifest into system prompt
- [ ] Test compaction recovery: does the agent retain identity and rules after context reset?
- [ ] Test Tier 2 loading: can the agent find and read on-demand files when needed?

---

*This spec emerged from production experience with JOYA agents on OpenClaw (Level B runtime), where bridge files and missing lifecycle hooks caused identity loss after compaction (2026-02-26).*
