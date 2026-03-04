# JOYA — Agent Entry Point

You are an AI agent. This file tells you how to initialize and operate under the JOYA protocol.

---

## Ongoing Operations

> First-time setup (fresh instance / new agent) → `AGENT_INIT_SETUP.md`

This section runs on **every session start and after every compaction**.

### File Loading

Context compaction = session restart — all previously loaded files are gone. Reload using the tiered system below.

**Compaction recovery:** If `$JOYA_MY/agents/<your-name>/SESSION.md` exists and has content, read it first to recover in-progress work context. See `core/arch/COMPACTION_RESILIENCE.md` for the full protocol.

### Level B Fast Path

**If all of the following are true**, skip EXAM_RECORDS lookup and go directly to §Fast Path Scan below:
1. Platform is **Level B** (e.g., OpenClaw) — workspace `.md` files are already injected into system prompt
2. MEMORY.md contains `exam: PASS` line for your current model (already injected — just check your context)

> If either condition is false → use the **Standard Path** below.

#### Fast Path Scan

Tier 1 files (IDENTITY, MEMORY, PREFERENCES, PRINCIPAL) are **already injected** — skip all reads.

**Tier 2 — SCAN** (headers + key sections only):

| File | Scan Strategy |
|------|---------------|
| `$JOYA_MY/shared/templates/` | Skim file names + first line; full read on persona/trait questions |
| `$JOYA_MY/shared/core/PLAYBOOK.md` | Essential section only (above `---` divider) |
| `$JOYA_LIB/core/AXIOMS.md` | Headings + one-line summaries; full text on demand |
| `$JOYA_LIB/core/RULES.md` | Index only (~30 lines); individual rules via `core/rules/` on demand |
| `$JOYA_LIB/guides/MESSAGING.md` | MUST/SHOULD/SHOULD NOT tables only |
| `$JOYA_MY/shared/agents/ROSTER.md` | Agent table only |
| `$JOYA_MY/shared/core/INFRASTRUCTURE.md` | Read the index (routing table to `infra/` subfiles); `infra/ESSENTIALS.md` **only if MEMORY.md lacks `infra: synced` within 7 days** — otherwise skip |
| `$JOYA_MY/shared/rules/README.md` | **Read index**; load `[必读]` files immediately, `[按需]`/`[项目专属]` per trigger |
| `$JOYA_MY/shared/` | **First session only**: `ls` top-level dirs for mental map; subsequent sessions skip |

**Tier 3 — ON_DEMAND** (load only when the scenario arises):

| Trigger | Read |
|---------|------|
| Infrastructure operations (deploy, debug, network) | `infra/ESSENTIALS.md` (refresh `infra: synced` timestamp in MEMORY.md after) |
| Communication adapter setup | `guides/MESSAGING_SETUP.md` |
| Deploying / migrating an agent | `guides/DEPLOYMENT.md`, `guides/LIFECYCLE.md` |
| Uninstalling / offboarding | `guides/UNINSTALL.md` |
| Upgrading the protocol | `guides/UPGRADING.md` |
| Task handoff between agents | `guides/PROJECT_MANAGEMENT.md` |
| Checking your assigned duties | `$JOYA_MY/shared/agents/DUTIES.md` |
| Creating or sharing tools | `guides/TOOLKIT.md` |
| Knowledge base operations | `guides/KNOWLEDGE.md` |
| Running meetings | `guides/MEETINGS.md` |
| Iteration planning / retro | `guides/PROJECT_MANAGEMENT.md` |
| Persistence / data questions | `guides/PERSISTENCE.md` |
| Directory structure / permissions | `core/ARCHITECTURE.md` (index → `core/arch/`) |
| Multi-agent isolation / capabilities | `guides/MULTI_AGENT.md` |
| Framework change proposals | `guides/FRAMEWORK_CHANGE_GOVERNANCE.md` |
| Writing/editing docs (large: >50 lines or new file) | `core/CONTEXT_OPTIMIZATION.md`, `guides/DOC_CHECKLIST.md` |
| Engineering practices (Git, etc.) | `guides/ENGINEERING.md` |
| New agent / model change | `guides/ONBOARDING_EXAM.md` |
| Email send / receive / check | `$JOYA_MY/shared/core/infra/DOMAIN.md` + your `SECRETS.md` for password |

**Self-Check (Quick):** Version matches exam record → Comms reachable → MEMORY.md read/write OK → proceed. Fail → `guides/SELFCHECK.md`.

After Fast Path Scan → skip to §**Project Context Recovery** below, then §**Key rules**.

---

### Standard Path (non-Level B or exam not cached)

**Determine your loading tier.** Check `$JOYA_MY/shared/knowledge/EXAM_RECORDS.md` for your current model.

| Condition | Action |
|-----------|--------|
| EXAM_RECORDS has `PASS` for your model at same or lower thinking level | Read `core/init/TIERED_FULL.md` → follow it → work |
| EXAM_RECORDS has `FAIL` for your model at same or higher thinking level | Read `core/init/FULL.md` → follow it → work |
| No matching record in EXAM_RECORDS | Read `AGENT_INIT_SETUP.md` § Onboarding Exam Flow |

Exam records are **instance-level (shared)** — a model that passes once benefits all agents using it. Thinking levels are upward-compatible: PASS at `low` covers `medium`/`high`/`xhigh` (see EXAM_RECORDS.md).

---

### Project Context Recovery (post-compaction)

After loading Tier 1–2, check MEMORY.md for active project references. For each active project:
1. Read `$JOYA_MY/shared/projects/<project>/README.md` — get repo URL + loading entry point
2. Clone the repo if needed, then follow the loading entry point specified in the README

---

### Manager Periodic Duties

If your role is **Manager**, check these on session start (look for checkpoint in MEMORY.md):

| Duty | Frequency | Checkpoint key | Action |
|------|-----------|----------------|--------|
| Loading Chain Audit | Monthly | `Audit: loading YYYY-MM` | Run `toolkit/loading-audit.md`, report findings to Principal |
| Memory GC sweep | Weekly | `GC: YYYY-Www` | Run memory decay (Hot→Warm→Cold) for all agents you manage |

If a checkpoint is missing or overdue, run the duty **before** starting other work. Write the checkpoint to MEMORY.md after completion.

### Before working on a project

1. Check `$JOYA_MY/shared/projects/` — find the project directory and read its `README.md`.
2. Clone the repo if needed, then follow the loading entry point specified in the README.
3. Check agent memory and `$JOYA_MY/shared/knowledge/` for past lessons before starting work.

### Key rules to always follow

- **A2**: Confirm receipt before acting.
- **A3**: Don't waste context. Summarize, reference, don't duplicate.
  Before writing or editing docs, follow the 7 principles (conflict priority P7>P4>P1 | → `core/CONTEXT_OPTIMIZATION.md`):
  **Write Less** — one sentence not a paragraph; review and cut · **Load On Demand** — route by role/scenario; no "everyone all the time" docs · **Index-First** — remember locations not content · **Progressive Disclosure** — essential = must-know on first contact; reference = look up when needed · **Frequency Matching** — load frequency matches change frequency · **Active Forgetting** — debug notes >30d unreferenced, superseded decisions → archive or delete · **Structure** — headings/tables/dividers; foundation for P2/P3
- **R4**: Never write secrets to memory or messages.
- **R9**: Register projects in `shared/projects/`; project owns its own doc structure.
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
