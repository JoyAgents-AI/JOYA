# AGENT_INIT — First-Time Setup Branches

> Extracted from AGENT_INIT.md. Only load this file if Step 1 or Step 2 matches.

## Step 0: Runtime Capability Detection

Before entering the decision tree, determine your runtime's capability level:

| Check | Result |
|-------|--------|
| Can you see IDENTITY.md / MEMORY.md content without reading a file? | **Level B** (static injection) — Tier 1 files with `inline: true` are pre-loaded. Skip reading those. Follow the on-demand table in AGENTS.md for remaining files. |
| Did a hook/script trigger this file automatically at session start? | **Level A** (full lifecycle) — Proceed normally through the decision tree below. |
| Neither? | **Level C** (bare minimum) — Self-load everything. Check `$JOYA_MY/agents/<name>/MANIFEST.yaml` if it exists; otherwise load Tier 1 files manually. |

> **Level B agents:** Your AGENTS.md should list what's pre-injected vs. on-demand. Trust the injected content for Tier 1 `inline: true` files. Only read files marked as on-demand when the trigger condition is met. Skip the decision tree's "file loading" steps for already-injected files.
>
> **Details:** `core/arch/PLATFORM_ADAPTATION.md`

## 1. Fresh Instance

**Check:** `$JOYA_MY/shared/core/PREFERENCES.md` does not exist, OR `$JOYA_MY/shared/agents/ROSTER.md` does not exist or is empty.

→ Read `JOYA_SETUP.md` — instance initialization + Setup Wizard. (This also creates your agent via `AGENT_SETUP.md`.)

## 2. New Agent (first session)

**Check:** You cannot see any IDENTITY.md content (neither injected nor readable from your agent directory), OR your MEMORY.md has no prior session entries.

→ Read `AGENT_SETUP.md` — agent-level onboarding.

## Onboarding Exam Flow (no matching record in EXAM_RECORDS)

1. Load via `core/init/TIERED_FULL.md` (indexes and summaries only)
2. Take the exam (`guides/ONBOARDING_EXAM.md`) — tests whether you can operate correctly with only tiered-loaded content
3. **PASS** → Add row to `$JOYA_MY/shared/knowledge/EXAM_RECORDS.md`. Future sessions (any agent, same model) use Tiered Loading only.
4. **FAIL** → Add row to `$JOYA_MY/shared/knowledge/EXAM_RECORDS.md`. Read `core/init/FULL.md` to load everything for this session.

> **Design rationale:** The exam tests whether Tiered Loading is *sufficient* for a model — not for a specific agent. A PASS proves summaries are enough; a FAIL proves this model needs full content. Framework major version invalidates all records.

> **Note:** Manager role agents may hold a Principal-granted exemption in lieu of an exam. See `guides/ONBOARDING_EXAM.md` § Who Administers.
