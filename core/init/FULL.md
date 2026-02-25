# Full Loading

Fallback for agents who did not pass the Onboarding Exam under Tiered Loading. Read all files completely to ensure full comprehension.

## Platform Injection Detection

Same as Tiered Loading: if your platform already injected a file into context, skip the read. See `core/init/TIERED.md § Platform Injection Detection`.

## Steps

1. `$JOYA_MY/agents/<your-name>/IDENTITY.md` — who you are
2. `$JOYA_MY/agents/<your-name>/PREFERENCES.md` — how you operate
3. `$JOYA_MY/agents/<your-name>/MEMORY.md` — your recent context
4. `$JOYA_MY/shared/templates/` — shared traits
5. `$JOYA_MY/shared/core/PRINCIPAL.md` — who you serve
6. `$JOYA_MY/shared/core/PREFERENCES.md` — instance preferences
7. `$JOYA_MY/shared/core/PLAYBOOK.md` — how this instance works
8. `$JOYA_MY/shared/core/INFRASTRUCTURE.md` — services, endpoints, tokens
9. `core/AXIOMS.md` — the four axioms
10. `core/RULES.md` — rule index (then read all individual rules in `core/rules/`)
11. `guides/MESSAGING.md` — group chat reply policy and anti-loop rules
12. `$JOYA_MY/shared/agents/ROSTER.md` — who's on the team
13. `VERSION` — framework version string
14. `$JOYA_MY/shared/rules/` — all instance-specific rules
15. **Run Self-Check** (Full) — see below

## Self-Check (Full)

Run the full procedure defined in `guides/SELFCHECK.md` (9 items: protocol, version, paths, system, comms, file I/O, memory, tools, git).

**Instance extensions:** `$JOYA_MY/shared/rules/selfcheck.md` may add custom checks.

**Degraded mode:** If critical checks fail, enter read-only analysis + core responses only. Manager or Principal clears after fix confirmed.

## Directory Quick Reference

```
$JOYA_LIB/
  core/              → Axioms, rules, architecture
  guides/            → How-to guides
  toolkit/           → Official tools, scripts, adapters
$JOYA_MY/
  agents/<name>/     → Per-agent: IDENTITY.md, MEMORY.md, SECRETS.md, toolkit/, memory/
  shared/core/       → Governance: PRINCIPAL.md, PLAYBOOK.md, INFRASTRUCTURE.md
  shared/agents/     → ROSTER.md, DIRECTORY.json
  shared/secrets/    → Team-shared credentials
  shared/rules/      → Instance-specific rules
  shared/projects/   → Project registry
  shared/dropzone/   → Agent file exchange area
```
