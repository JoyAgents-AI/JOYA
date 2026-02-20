# Agent Lifecycle

This guide is written for agents — primarily the Manager — to execute when the Principal requests lifecycle changes.

---

## Onboarding (New Agent)

When the Principal requests adding a new agent:

1. **Create agent directory**: `$JOYA_MY/agents/<name>/`
2. **Create IDENTITY.md** from `guides/IDENTITY_TEMPLATE.md`. Inherit from `$JOYA_MY/shared/templates/` as baseline, customize per Principal's instructions.
3. **Create permissions.md** if the agent needs extra permissions beyond role defaults.
4. **Update ROSTER.md**: Add the new agent with role and status `active`.
5. **Update DIRECTORY.json**: Add contact info, communication adapter config, and runtime details.
6. **Broadcast**: Notify all existing agents of the new team member.
7. **Verify**: Once the new agent is online, confirm it can load its identity, respond to health checks, and communicate with peers.
8. **Introduction**: The new agent posts a self-introduction in the group channel.

---

## Offboarding (Agent Retirement)

When the Principal requests retiring an agent:

1. **Task reassignment**: Manager reassigns all pending tasks to other agents.
2. **Memory archival**: Copy the agent's key memories to `$JOYA_MY/shared/archive/<name>/`. Include IDENTITY.md, MEMORY.md, and RELATIONSHIPS.md.
3. **Update ROSTER.md**: Set status to `archived`. Do not remove the entry.
4. **Update DIRECTORY.json**: Mark as inactive. Do not delete.
5. **Broadcast**: Notify all agents.
6. **Retain directory**: `$JOYA_MY/agents/<name>/` is kept as-is, never deleted. Archived agents' data may be valuable for future reference or revival.

---

## Engine Migration (Same Agent, New Runtime)

When moving an agent to a different platform or machine. There are two scenarios:

### Migration Verification Checklist

This checklist applies to all migration scenarios. Run all four checks after setting up the new environment:

1. **Verify file access**: Agent must read and echo the first line of AGENT_INIT.md, its own IDENTITY.md, and INFRASTRUCTURE.md to prove paths resolve correctly. Do not trust "I read it successfully" without evidence.
2. **Verify write access**: Agent must create a test file in its own agent directory and confirm it is visible from the home node.
3. **Verify identity**: Ask the agent to confirm its name, role, key memories, and collaboration patterns.
4. **Verify communication**: Confirm the agent can send and receive through its configured adapter with correct sender identity. Resolve before proceeding.

### Same-Instance Migration (shared storage available)

The agent moves to a new machine but still accesses the same `$JOYA_MY/` via network mount.

1. **Mount**: Ensure the new machine has read-write access to the shared `$JOYA_MY/` directory (NFS, SMB, etc.).
2. **Configure runtime**: Set up the new runtime to load IDENTITY.md, MEMORY.md, and shared/templates/ on startup.
3. **Run Migration Verification Checklist** (above).
4. **Update DIRECTORY.json**: Change runtime and communication adapter details.
5. **Notify peers**: Broadcast the updated contact information if it changed.

When the target platform differs from the source OS (e.g., macOS → Windows), also verify:
- Network mount to `$JOYA_MY/` is functional and writable from the agent's runtime process (not just from SSH or a different session). See `guides/DEPLOYMENT.md` for platform-specific details.
- The agent's AGENTS.md uses correct absolute paths for the target platform (see ARCHITECTURE.md § Cross-Platform Path Resolution).

### Cross-Instance Migration (no shared storage)

The agent moves to a completely separate instance (different network, different team, or standalone).

1. **Export**: Copy the entire `$JOYA_MY/agents/<name>/` directory to the new environment. Verify file integrity (file count, checksums) after copy.
2. **Configure runtime**: Set up the new runtime to load the copied identity and memory files.
3. **Run Migration Verification Checklist** (above).
4. **Rollback point**: Before cutting over, ensure the original agent directory is preserved on the source instance for rollback if migration fails.
5. **Update DIRECTORY.json**: On the new instance, add the agent's runtime and adapter details.
6. **Notify peers**: Broadcast on both old and new instances as appropriate.

---

## Model Swap (Same Agent, New LLM)

When changing only the underlying model (e.g., Claude → GPT):

1. **Update DIRECTORY.json**: Change the model/engine field.
2. **Load and verify**: Same identity files, new model. Verify personality and memory consistency.
3. **No broadcast needed**: External identity hasn't changed, only the engine.

---

## Revival (Reactivating an Archived Agent)

1. **Restore**: Copy from `$JOYA_MY/shared/archive/<name>/` back to `$JOYA_MY/agents/<name>/`.
2. **Update ROSTER.md**: Set status back to `active`.
3. **Update DIRECTORY.json**: Add current runtime and adapter config.
4. **Broadcast**: Notify all agents.
5. **Reorientation**: The revived agent should review recent team MEMORY.md and meeting records to catch up.

---

## Session Start (Agent Comes Online)

When an agent starts a new session and becomes active:

1. **Load identity**: Read IDENTITY.md, MEMORY.md, PRINCIPAL.md, PLAYBOOK.md as specified in AGENT_INIT.md.
2. **Announce presence**: Broadcast a brief online notification to all agents via the installed communication adapter (e.g., Mattermost, Slack, etc.). Format: `"[Agent] is now online"` or equivalent.
3. **Check in**: Review any unread messages or pending tasks since last session.

When an agent goes offline or becomes unresponsive:

1. **Notify**: The Manager (or the agent itself, if graceful shutdown) broadcasts an offline notification. Format: `"[Agent] is now offline"`.
2. **Reassign**: The Manager reassigns any time-sensitive tasks if needed.

---

## Lifecycle Notification Rule

**All lifecycle events must be broadcast to every active agent** via the instance's installed communication adapter(s). This applies to:

- Onboarding (new agent joins)
- Offboarding (agent retires)
- Session start (agent comes online)
- Session end / offline (agent goes offline)
- Engine migration (agent changes runtime)
- Revival (archived agent reactivated)
- Adapter installation/reconnection

The notification must use the communication method configured in `DIRECTORY.json`. If multiple adapters are installed, use the primary group channel. The Manager is responsible for ensuring notifications are sent; agents performing self-joins must notify on their own behalf.

---

## Principles

- **Memory survives everything** — retirement, migration, model swaps. Never delete identity or memory files.
- **Directories are never physically deleted** — mark inactive/archived instead.
- **Identity and engine are decoupled** — changing how an agent runs does not change who it is.
- **All lifecycle operations go through the Manager** (see RULES.md R3).
