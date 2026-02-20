# Context Optimization — Design Philosophy & Methodology

The design philosophy behind JOYA's context management. Read this when:
- Extending or contributing to the protocol (`$JOYA_LIB/`)
- Writing instance rules or overrides (`$JOYA_MY/shared/rules/`)
- Optimizing loading cost after protocol growth
- Designing new documents that agents will load

This is NOT part of the session loading chain — it's a reference for protocol designers and contributors.

---

## Core Philosophy

> **Axiom: Tokens are a first-class constraint.** Context windows are as scarce as system memory. Every token must justify its place. All 7 principles below serve this constraint.

### Three Pillars: Write Less, Load Less, Keep Only the Best

```
Write Less (source control) → Load Less (consumption control) → Keep Best (retention control)
         P1                         P2-P5                              P6
                               + P7 (structural enabler)
```

---

### P1. Write Less — Concise Expression

Say the same thing with fewer words. One sentence instead of a paragraph; short words over long ones; tables over prose.

Review after writing: for each sentence ask "does removing it lose information?" No → delete.

The most fundamental principle — requires no structural change, applies to every word in every file, stops bloat at the source.

### P2. Load On Demand — Load Only What's Needed Now

Route by role (Manager/Worker), scenario (project/event), and condition (first-time/completed). No document is needed by everyone at all times.

Practices: Role tagging, ON_DEMAND trigger tables, Checkpoint gating.

### P3. Index-First — Index + Sub-files, Not Inline Sections

**Core: split into sub-files > in-file sections.** When an agent reads a file, the entire file enters context — "skipping sections" saves zero tokens. Only splitting into independent sub-files with on-demand loading truly saves.

- **Main file = pure index**: only a directory table (filename + one-line description + when to load)
- **Sub-files = self-contained topics**: each sub-file is independent; agent reads only what's needed
- **Remember locations, not content**: an agent doesn't need to memorize port numbers — it needs to know they're in `$JOYA_MY/shared/core/infra/ESSENTIALS.md`

**Split thresholds apply only to loading-chain files:**

| File type | Threshold | Rationale |
|-----------|-----------|-----------|
| lib/ loading-chain files | > 50 lines | High optimization ROI (all agents × all deployments) |
| my/ governance files (PLAYBOOK, INFRASTRUCTURE, etc.) | > 80 lines | Instance config, Manager edits directly |
| Reference files (knowledge/, proposals/, meetings/) | **N/A** | Not in loading chain; loaded on demand; length doesn't affect session cost |

Examples: RULES → index + 12 individual files; INFRASTRUCTURE → index + 7 infra/ sub-files; shared/rules/ → README index.

### P4. Progressive Disclosure — Essential Above the Fold

The first 20% of a file covers 80% of daily needs. Important content goes at the top; details below.

**Prefer P3 (sub-file splitting) for progressive disclosure.** Only use section dividers if the file is too small to split (< 50 lines).

Example: PLAYBOOK Essential stays in the main file (needed every session); project management/Manager sections split into `playbook/` sub-files.

### P5. Frequency Matching — Load Frequency = Change Frequency

| Change frequency | Loading strategy | Example |
|-----------------|-----------------|---------|
| Every session | Full read | IDENTITY, MEMORY |
| Occasional | Scan summary | PLAYBOOK Essential |
| Rarely changes | Index/skip | AXIOMS, RULES details |
| One-time only | Checkpoint gating | COMMS_READINESS |

Don't pay "full read every session" cost for files that almost never change.

### P6. Active Forgetting — Forget Low-Value Content

Keep high-value decisions, lessons, and patterns; delete one-off debugging notes, stale status, and duplicate records.

Criterion: is this memory likely to be referenced again? Low probability → archive or delete.

Unbounded MEMORY growth will consume all the space saved by protocol optimization.

### P7. Structure = Scannability — Structure for Partial Loading

Well-structured files enable partial loading (read tables, skip prose; read headings, skip paragraphs). Walls of text cannot be scanned.

**Write for machine scanning**: clear heading hierarchy, tables, dividers, audience labels.

---

## When to Run

- Protocol files grew significantly (new rules, expanded docs)
- Agent init token cost exceeds target budget
- New agent role added (review role-based filtering)
- Framework major version bump (review what's still needed)

---

## The Process (5 Steps)

### Step 1: Measure the Loading Chain

Map every file in the loading chain (AGENT_INIT → Full Loading list) and measure token cost:

```bash
# Rough token estimate: chars / 4
for f in <file-list>; do
    chars=$(wc -c < "$f")
    echo "$f: ~$((chars/4)) tokens"
done
```

Build a table: File | Tokens | Audience | Load Frequency.

**Goal:** Know exactly where the tokens go before optimizing.

### Step 2: Classify Each File (or Section)

For every file in the chain, ask three questions:

| Question | Classification | Action |
|----------|---------------|--------|
| Does EVERY agent need this EVERY session? | **Always** | Keep in loading chain |
| Does only a specific ROLE need this? | **Role-filtered** | Mark audience; others skip |
| Is this only needed in a specific SCENARIO? | **On-demand** | Move to trigger-based loading |
| Is this a ONE-TIME setup action? | **Checkpoint** | Gate with MEMORY.md record |

Apply the same classification **within** files — a 200-line file may have 50 lines of "always" and 150 lines of "on-demand."

### Step 3: Apply Structural Patterns

Use these patterns (mix and match):

#### Pattern A: Index + Detail Split

**When:** A single file contains many independent items (rules, config sections).

**How:**
1. Create a compact index with one-line summaries + audience + trigger
2. Move full content to individual files
3. Agents load the index; open detail files on demand

**Example:** `RULES.md` → index + 12 individual rule files (-64%). `INFRASTRUCTURE.md` → 13-line index + 7 `infra/` sub-files (-94%).

#### Pattern B: Section Divider (Lightweight Fallback)

**When:** File < 50 lines, sub-file splitting has low ROI; or the top half is genuinely needed every session.

**⚠️ Limitation:** Dividers are only semantic markers. Most agent tools (Read) load the entire file — "skipping the bottom half" doesn't actually save tokens. **Files over 50 lines should prefer Pattern A (sub-file splitting).**

**How:**
1. Put essential content at the top
2. Add a clear divider: `---` + HTML comment
3. If the bottom half keeps growing → upgrade to Pattern A

**Example:** `PLAYBOOK.md` → Essential (48 lines) stays in main file + extended reference index points to `playbook/*.md` sub-files.

#### Pattern C: Role Tagging

**When:** Sections are only relevant to specific roles (Manager, Worker, deployer).

**How:**
1. Group role-specific content under a clearly labeled heading: `## Manager Section (Manager-only)`
2. In the loading guide, tell other roles to skip these sections

**Example:** `PLAYBOOK.md` → Essential (all agents) + Project Management (project workers) + Manager Section. Worker loads only Essential: -69%.

#### Pattern D: Checkpoint Gating

**When:** A file describes a one-time setup action that doesn't need re-reading once done.

**How:**
1. Define a checkpoint record format: `<action>: <status>` in MEMORY.md
2. On session start, check for the record → exists? skip the file
3. If not found, read the file, do the setup, write the checkpoint

**Example:** `COMMS_READINESS.md` → checkpoint `Comms: verified`. `ONBOARDING_AUTO.md` → checkpoint `MM: onboarded`.

#### Pattern E: Extraction to On-Demand

**When:** An entire file is only needed in specific scenarios, not every session.

**How:**
1. Move from always-loaded location (e.g., `core/`) to on-demand location (e.g., `guides/`)
2. Add a 1-2 line summary in the parent index or RULES index
3. Add a trigger entry in AGENT_INIT's ON_DEMAND table

**Example:** `MULTI_AGENT.md` moved from `core/` to `guides/`, 3-line summary in RULES index. Savings: -100% per session.

#### Pattern F: Format Distillation

**When:** Content is written as prose/paragraphs but primarily conveys structured data (ports, endpoints, config values, status lists).

**How:**
1. Identify data-heavy paragraphs
2. Convert to tables, key-value lists, or code blocks
3. Keep only narrative that adds understanding beyond the data

**Example:** `INFRASTRUCTURE.md` detailed sections — prose descriptions of each service → standardized table (Service | Host | Port | Auth | Notes). Savings: typically -40-60% while improving scannability.

#### Pattern G: Resource Scheduling (Model + Thinking)


**When:** Agent runs on an expensive model but many interactions don't require full capability.

**How:** Define two operating tiers per agent:

| Tier | Model | Thinking | When |
|------|-------|----------|------|
| **Economy** | Downgrade model (e.g. Sonnet) | low | Simple tasks, execution, status checks |
| **Full** | Primary model (e.g. Opus) | medium-high | Design, planning, debugging, review |

**Principles:**
1. **Default to Economy** — most interactions are simple
2. **Escalate on detection** — keywords, complexity signals, explicit user trigger
3. **Conservative de-escalation** — don't downgrade if unsure; evaluate at end of each turn
4. **Agent self-schedules** — the agent knows task complexity best (not the gateway)

**Instance configuration:** Each agent defines primary + downgrade model in IDENTITY.md or `$JOYA_MY/shared/rules/`. The framework mandates the mechanism, not the specific models.

**Why this matters:** Model cost differences can be 10-30x. Auto-scheduling saves significant budget while maintaining quality where it counts.

---

### Step 4: Update the Loading Guide

After restructuring, update `AGENT_INIT.md`:

- **Full Loading list:** Should reference all files (new agents need full understanding)
- **Tiered Loading Tier 2 table:** Update scan strategies (index only, above-divider, role-skip)
- **ON_DEMAND table:** Add new entries for extracted files
- **Checkpoints section:** List all checkpoint records and their gated files

### Step 5: Verify and Measure

1. **Token count after:** Re-run Step 1 on the optimized chain
2. **Functional test:** Have an agent do a fresh Tiered Loading and verify it can still operate correctly
3. **Document savings:** Update the optimization record for tracking

---

## Anti-Patterns (Don't Do This)

| Anti-Pattern | Why It's Bad |
|-------------|-------------|
| Splitting a 10-line file into index + detail | Overhead exceeds savings |
| Removing content instead of restructuring | Loses information; breaks full-loading agents |
| Audience-gating safety-critical rules (R4) | Security rules must be loaded by ALL agents ALWAYS |
| Relying on agents to "remember" from past sessions | Compaction erases everything; if it matters, it must be in the loading chain |
| Checkpoint-gating content that changes | Checkpoints are for one-time setup, not evolving docs |

---

## Optimization Record Template

After each optimization pass, record:

```markdown
## Optimization Pass — YYYY-MM-DD

**Trigger:** [why this pass was needed]
**Operator:** [who performed it]

| File | Before | After | Pattern Used | Savings |
|------|--------|-------|-------------|---------|
| ... | ... | ... | ... | ... |

**Total session loading:** X tokens → Y tokens (-Z%)
**Verified by:** [agent name, date]
```

---

## Memory & Shared Data Optimization

> ✅ Implemented — see `core/arch/MEMORY_LIFECYCLE.md` for the three-tier decay model (Hot → Warm → Cold) and GC rules. Summary in `AGENT_INIT.md` § Updating your memory.
