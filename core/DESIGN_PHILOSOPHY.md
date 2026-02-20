# Design Philosophy

The principles behind JOYA's architecture. Not rules to follow mechanically — a lens for discovering problems and evaluating solutions.

Read this when: writing/reviewing framework docs, designing new features, running audits, or when something feels wrong but you can't articulate why.

---

## 1. Context is Currency

Every token loaded into an agent's context has a cost: money, attention, and displacement of useful information. Treat context like memory in embedded systems — budget it, measure it, optimize it.

**Implications:**
- Measure before optimizing (loading chain audit)
- Never load what you don't need right now
- Redundancy = bug (same content in two places = two costs)

## 2. Index, Don't Inline

Large or complex content should be split: a **lean index** (always loaded) pointing to **detail files** (loaded on demand). The index gives the agent enough to know *what exists* and *when to load it*.

**Pattern:**
```
FILE.md              ← index: key:value + one-line pointers
  subdirectory/
    detail-a.md      ← full content, loaded when scenario arises
    detail-b.md
```

**Applied to:** INFRASTRUCTURE.md, PREFERENCES.md, MEMORY.md, RULES.md

## 3. Separate Identity, Preferences, and Memory

Three fundamentally different kinds of agent data. Mixing them causes bloat and confusion.

| File | What | Changes | Load |
|------|------|---------|------|
| IDENTITY.md | Who you are (persona, role, expertise) | Rarely | Always |
| PREFERENCES.md | How you operate (rules, habits, strategies) | As patterns evolve | Index always, details on demand |
| MEMORY.md | What happened (events, state, decisions) | Every session | Always |

## 4. Configuration Hierarchy

Preferences flow from general to specific. Each level only contains overrides and extensions — never duplicates the parent.

```
Framework defaults (in code/docs)
  ↓ overridden by
shared/core/PREFERENCES.md (instance-level)
  ↓ overridden by
agents/<name>/PREFERENCES.md (agent-level)
```

Corollary: if an agent preference matches the instance default, don't write it.

## 5. Conditional Loading

Not all agents need the same files. Branch the loading chain by role, exam status, or scenario — don't make everyone read everything.

**Pattern:**
```
AGENT_INIT.md (router — decision tree)
  ├─ Fresh instance → JOYA_SETUP.md
  ├─ New agent     → AGENT_SETUP.md
  └─ Returning     → Tiered or Full loading (based on exam record)
```

Corollary: every file should know its audience. If only Managers read it, say so at the top.

## 6. Detect, Don't Ask

When information is available from the environment, obtain it programmatically. Only ask the user questions that require genuine human judgment.

**Auto-detect:** timezone, language, OS, platform, channels, node count
**Must ask:** reporting style, autonomy level, cost sensitivity

## 7. Preferences Are Alive

Configuration isn't a one-time setup event. It's a continuous process:

```
Setup Wizard → passive detection → proactive suggestion → dynamic growth → periodic review
```

- **Passive**: Manager recognizes preference changes in natural conversation
- **Proactive**: Manager suggests config changes when patterns indicate mismatch
- **Growth**: New preference items emerge from usage, added to PREFERENCES.md
- **No special commands**: Users never need to remember a trigger phrase

## 8. Frequency Matches Volatility

How often a file is loaded should match how often it changes and how often it's needed.

| Volatility | Load strategy | Example |
|-----------|---------------|---------|
| Static (months) | Tier 2 scan / on-demand | AXIOMS.md, DESIGN_PHILOSOPHY.md |
| Slow (weeks) | Tier 1 but lean index | PREFERENCES.md, INFRASTRUCTURE.md |
| Active (daily) | Tier 1 full read | MEMORY.md |
| Hot (per-task) | Tier 3 on-demand | Project CONTEXT.md, detail files |

Corollary: if a file changes monthly but loads every session, it's over-scheduled. If it changes daily but loads on-demand, it'll go stale.

## 9. Single Source of Truth

Every piece of configuration or knowledge lives in exactly one canonical location. Other files may reference it (by path), never duplicate it.

**Violations to watch for:**
- Same rule stated in AGENT_INIT.md and PLAYBOOK.md
- Same config value in PREFERENCES.md and IDENTITY.md
- Same team info in MEMORY.md and ROSTER.md

## 10. Framework ≠ Instance

Cleanly separate what belongs to all JOYA installations (`lib/`) from what belongs to this specific deployment (`my/`). Framework code should never contain instance-specific values, and instance data should never modify framework files.

| Layer | Path | Managed by | Versioned via |
|-------|------|------------|---------------|
| Framework | `$JOYA_LIB/` | Framework maintainer | Git |
| Instance | `$JOYA_MY/` | Instance admin / Manager | Syncthing / filesystem |

## 11. Self-Inspection Drives Evolution

The framework must be able to examine and optimize itself. Don't rely on users or maintainers to notice problems — build mechanisms that surface them automatically.

**The loop:**
```
Measure (audit) → Discover (find anomalies) → Fix → Measure again
```

**Built-in self-inspection mechanisms:**
- **Loading Chain Audit**: periodically measure context budget, detect redundancy and bloat
- **Memory GC**: decay stale knowledge, prevent unbounded growth
- **Preference pattern detection**: Manager observes recurring overrides → proposes config changes
- **Proactive suggestion**: Manager notices mismatches between config and behavior → suggests adjustment

**Why this matters:** AI frameworks accumulate cruft silently — files grow, rules duplicate, dead branches persist. Unlike traditional software, there's no compiler warning or failing test. The only defense is regular self-inspection, built into the framework's own operating rhythm.

**Corollary:** Every optimization mechanism should itself be auditable. If the audit protocol becomes bloated, audit the audit.

---

*These principles are discovered, not invented — each emerged from solving a real problem. When you find a new one, add it here.*
