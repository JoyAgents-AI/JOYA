# Tiered Loading

Efficient loading: indexes and summaries first, full content on demand.

## Platform Injection Detection

Some platforms (e.g., OpenClaw) inject workspace files (MEMORY.md, IDENTITY.md, etc.) into the system prompt automatically. Before reading a Tier 1 file:

1. Check if its content is already visible in your current context (e.g., can you see your MEMORY.md sections without reading a file?)
2. If yes → **skip the read** — the platform already injected it.
3. If no → read it normally.

This avoids double-loading and saves ~3000 tokens per duplicated file per session.

## Tier 1 — MUST_LOAD (full read, unless already injected)

1. `$JOYA_MY/agents/<your-name>/IDENTITY.md` — who you are
2. `$JOYA_MY/agents/<your-name>/PREFERENCES.md` — how you operate (overrides instance defaults)
3. `$JOYA_MY/agents/<your-name>/MEMORY.md` — your state and context
4. `VERSION` — framework version (1 line)
5. `$JOYA_MY/shared/core/PRINCIPAL.md` — who you serve
6. `$JOYA_MY/shared/core/PREFERENCES.md` — instance preferences (reporting, autonomy, resources, maintenance)

## Tier 2 — SCAN (headers + key sections only)

| File | Scan Strategy |
|------|---------------|
| `$JOYA_MY/shared/templates/` | Skim file names + first line of each; full read only if persona/trait questions arise |
| `PLAYBOOK.md` | **Essential section only** (above `---` divider); project/Manager sections on demand |
| `AXIOMS.md` | Read headings + one-line summaries; full text on demand |
| `DESIGN_PHILOSOPHY.md` | Skip unless writing/reviewing framework docs |
| `RULES.md` | Index only (~30 lines); individual rules in `core/rules/` loaded on demand |
| `MESSAGING.md` | MUST/SHOULD/SHOULD NOT tables only |
| `ROSTER.md` | Agent table only |
| `INFRASTRUCTURE.md` | **Quick Reference section only** (above the `---` divider); detailed sections on demand |
| `$JOYA_MY/shared/rules/` | **README.md index only**; individual rules per trigger/role (see index) |

## Project Context Recovery (post-compaction)

After loading Tier 1–2, check MEMORY.md for active project references. For each active project:

1. Read `$JOYA_MY/shared/projects/<project>.md` — get repo path + recovery entry
2. Read the L2 recovery doc (usually `docs/PROJECT_CONTEXT.md` in the repo)
3. If `<repo>/.joy/CONTEXT.md` exists → read it for role-specific quick start

This ensures project context survives compaction without bloating MEMORY.md with implementation details.

**Team-level knowledge belongs in shared/, not personal MEMORY:**
- Content policies, DM rules, comms rules → `$JOYA_MY/shared/rules/` or `shared/core/PREFERENCES.md`
- Project architecture, API specs, schemas → project repo docs or `.joy/knowledge/`
- Personal MEMORY should store **pointers** ("see shared/rules/X.md"), not full copies

## Checkpoints

Some files are one-time setup. Check MEMORY.md for completion records before loading:
- `Comms: verified` → skip `shared/rules/COMMS_READINESS.md`
- `MM: onboarded` → skip `shared/rules/ONBOARDING_AUTO.md`
- No record? → Read the file and complete the setup, then write the checkpoint.

## Exam Records (shared)

Exam results are stored in `$JOYA_MY/shared/knowledge/EXAM_RECORDS.md` — **instance-level, not per-agent**.
A model that passes the exam once qualifies all agents using that model+thinking+version combo.

**On session start:** Check EXAM_RECORDS for your current model. If PASS → proceed. If missing → exam needed.

## Auto-downgrade

Framework **major** version bump → all exam records invalidated. Next session, any agent on an unrecorded combo goes through Tiered Loading → Exam.

Model change → check EXAM_RECORDS for the new model. Thinking level change → upward-compatible (PASS at `low` covers `medium`+`high`+`xhigh`; only downward needs a new record). See EXAM_RECORDS.md.

## Tier 3 — ON_DEMAND (load only when the scenario arises)

| Trigger | Read |
|---------|------|
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

## Self-Check (Quick)

3 items. Fast validation that the basics work.

1. **Version** — `VERSION` matches your exam record's major.minor (skip this check if no exam record yet)
2. **Comms** — Can reach the messaging system (send a test or verify config)
3. **Memory** — Can read and write your MEMORY.md

If all pass → proceed to work. If any fail → escalate to Full Check (`guides/SELFCHECK.md`).

### Optional: Loading Chain Audit

Run `toolkit/loading-audit.md` monthly or when compactions feel too frequent. Measures token budget across all layers and flags redundancy/bloat.
