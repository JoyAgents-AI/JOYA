# Tiered Loading

Efficient loading: indexes and summaries first, full content on demand.

## Tier 1 — MUST_LOAD (full read)

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

## Checkpoints

Some files are one-time setup. Check MEMORY.md for completion records before loading:
- `Comms: verified` → skip `shared/rules/COMMS_READINESS.md`
- `MM: onboarded` → skip `shared/rules/ONBOARDING_AUTO.md`
- No record? → Read the file and complete the setup, then write the checkpoint.

## Auto-downgrade

Framework major version bump, model change, or thinking level change → exam record is invalidated. Next session, the agent goes through the Tiered Loading → Exam flow again.

## Tier 3 — ON_DEMAND (load only when the scenario arises)

| Trigger | Read |
|---------|------|
| Communication adapter setup | `guides/MESSAGING_SETUP.md` |
| Deploying / migrating an agent | `guides/DEPLOYMENT.md`, `guides/LIFECYCLE.md` |
| Uninstalling / offboarding | `guides/UNINSTALL.md` |
| Upgrading the protocol | `guides/UPGRADING.md` |
| Task handoff between agents | `guides/PROJECT_MANAGEMENT.md` |
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

## Self-Check (Quick)

3 items. Fast validation that the basics work.

1. **Version** — `VERSION` matches your exam record's major.minor (skip this check if no exam record yet)
2. **Comms** — Can reach the messaging system (send a test or verify config)
3. **Memory** — Can read and write your MEMORY.md

If all pass → proceed to work. If any fail → escalate to Full Check (`guides/SELFCHECK.md`).

### Optional: Loading Chain Audit

Run `toolkit/loading-audit.md` monthly or when compactions feel too frequent. Measures token budget across all layers and flags redundancy/bloat.
