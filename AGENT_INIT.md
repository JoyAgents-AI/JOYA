# JOYA — Agent Entry Point

You are an AI agent. This file tells you how to initialize and operate under the JOYA protocol.

---

## Session Start — Decision Tree

Check these conditions **in order**. Follow the first match.

### 1. Is this a fresh instance?

**Check:** `$JOYA_MY/shared/core/PREFERENCES.md` does not exist, OR `$JOYA_MY/shared/agents/ROSTER.md` does not exist or is empty.

→ Read `JOYA_SETUP.md` — instance initialization + Setup Wizard. (This also creates your agent via `AGENT_SETUP.md`.)

### 2. Are you a new agent (first session)?

**Check:** `$JOYA_MY/agents/<your-name>/IDENTITY.md` does not exist, OR your `MEMORY.md` has no prior session entries.

→ Read `AGENT_SETUP.md` — agent-level onboarding.

### 3. You are a returning agent.

**Check:** IDENTITY.md exists and MEMORY.md has prior session history.

→ Go to **Ongoing Operations** below. (This is the common path — session start, compaction recovery, etc.)

---

## Ongoing Operations

This section runs on **every session start and after every compaction**.

### File Loading

Context compaction = session restart — all previously loaded files are gone. Reload using the tiered system below.

**Compaction recovery:** If `$JOYA_MY/agents/<your-name>/SESSION.md` exists and has content, read it first to recover in-progress work context. See `core/arch/COMPACTION_RESILIENCE.md` for the full protocol.

**Determine your loading tier.** Check `$JOYA_MY/shared/knowledge/EXAM_RECORDS.md` for your current model.

| Condition | Action |
|-----------|--------|
| EXAM_RECORDS has `PASS` for your model at same or lower thinking level | Read `core/init/TIERED.md` → follow it → work |
| EXAM_RECORDS has `FAIL` for your model at same or higher thinking level | Read `core/init/FULL.md` → follow it → work |
| No matching record in EXAM_RECORDS | Read `core/init/TIERED.md` → follow it → take the Onboarding Exam (see below) |

Exam records are **instance-level (shared)** — a model that passes once benefits all agents using it. Thinking levels are upward-compatible: PASS at `low` covers `medium`/`high`/`xhigh` (see EXAM_RECORDS.md).

**Onboarding Exam flow (no matching record):**

1. Load via `core/init/TIERED.md` (indexes and summaries only)
2. Take the exam (`guides/ONBOARDING_EXAM.md`) — tests whether you can operate correctly with only tiered-loaded content
3. **PASS** → Add row to `$JOYA_MY/shared/knowledge/EXAM_RECORDS.md`. Future sessions (any agent, same model) use Tiered Loading only.
4. **FAIL** → Add row to `$JOYA_MY/shared/knowledge/EXAM_RECORDS.md`. Read `core/init/FULL.md` to load everything for this session. Future sessions with the same model+thinking go directly to Full Loading (no re-test — the model has proven it needs full content).

> **Design rationale:** The exam tests whether Tiered Loading is *sufficient* for a model — not for a specific agent. A PASS proves summaries are enough; a FAIL proves this model needs full content. Retesting the same model on a different agent wastes tokens on a predictably identical outcome. Framework major version invalidates all records.

> **Note:** Manager role agents may hold a Principal-granted exemption in lieu of an exam. See `guides/ONBOARDING_EXAM.md` § Who Administers.

---

### Manager Periodic Duties

If your role is **Manager**, check these on session start (look for checkpoint in MEMORY.md):

| Duty | Frequency | Checkpoint key | Action |
|------|-----------|----------------|--------|
| Loading Chain Audit | Monthly | `Audit: loading YYYY-MM` | Run `toolkit/loading-audit.md`, report findings to Principal |
| Memory GC sweep | Weekly | `GC: YYYY-Www` | Run memory decay (Hot→Warm→Cold) for all agents you manage |

If a checkpoint is missing or overdue, run the duty **before** starting other work. Write the checkpoint to MEMORY.md after completion.

### Before working on a project

1. Check `$JOYA_MY/shared/projects/` — find the project registration.
2. Read `<project>/.joy/CONTEXT.md` — understand the project.
3. Read `<project>/.joy/knowledge/` — learn from past lessons.

### Key rules to always follow

- **A2**: Confirm receipt before acting.
- **A3**: Don't waste context. Summarize, reference, don't duplicate.
  Before writing or editing docs, follow the 7 principles (conflict priority P7>P4>P1 | → `core/CONTEXT_OPTIMIZATION.md`):
  **Write Less** — one sentence not a paragraph; review and cut · **Load On Demand** — route by role/scenario; no "everyone all the time" docs · **Index-First** — remember locations not content · **Progressive Disclosure** — essential = must-know on first contact; reference = look up when needed · **Frequency Matching** — load frequency matches change frequency · **Active Forgetting** — debug notes >30d unreferenced, superseded decisions → archive or delete · **Structure** — headings/tables/dividers; foundation for P2/P3
- **R4**: Never write secrets to memory or messages.
- **R9**: All project artifacts go in `.joy/`.
- **R10**: `$JOYA_LIB/` (incl. `toolkit/`) managed under Git. Instance data uses Syncthing or shared filesystem (R12).
- **shared/ writes**: Log in `shared/CHANGELOG.md` + self-check ✅ (see `core/arch/SHARED_GOVERNANCE.md`).
- **Preferences**: When the Principal expresses a preference change in conversation, update `shared/core/PREFERENCES.md` and confirm. When a recurring pattern suggests a new preference could be formalized (e.g., Principal keeps overriding the same default), propose adding it as a new config item.

### Updating your memory

After each meaningful session:
- Update `$JOYA_MY/agents/<your-name>/MEMORY.md` with important learnings
- Write daily notes to `$JOYA_MY/agents/<your-name>/memory/YYYY-MM-DD.md`
- These files persist across sessions and platform changes

**Memory GC** — memory files follow three-tier decay: Hot (≤3d, daily files) → Warm (4-14d, merge to weekly) → Cold (>14d, distill to ref files, delete source). New supersedes old. Completed Pending items are deleted, not marked [x]. MEMORY.md stays lean (index + current state only). Details: `core/arch/MEMORY_LIFECYCLE.md`.

### When unsure

- Check permissions: `core/arch/PERMISSIONS.md`
- Check workflow: `guides/`
- When in doubt, ask the Principal.
