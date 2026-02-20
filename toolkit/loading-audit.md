# Loading Chain Audit Protocol

## Purpose

Analyze and optimize the context token budget consumed by the agent loading chain. Run periodically to catch bloat, redundancy, and misalignment.

## When to Run

- **Automatic**: Manager agents check monthly via HEARTBEAT (default heartbeat interval: 7d, configurable per instance)
- Monthly (recommended: first session of the month)
- After framework version upgrades
- After adding a new agent to the roster
- After significant changes to IDENTITY.md, PLAYBOOK.md, or INFRASTRUCTURE.md
- When context window feels tight (compactions happening too frequently)

## Audit Procedure

### Step 1: Map the Layers

Identify all sources of context consumed before the agent can start working.

| Layer | Source | Controlled By |
|-------|--------|---------------|
| **L0** | Platform system prompt (tool definitions, skills list, safety rules, runtime metadata) | Platform (OpenClaw, Claude Desktop, etc.) — not directly controllable |
| **L1** | Platform workspace context (auto-injected files like AGENTS.md, MEMORY.md, TOOLS.md) | Instance admin — file content controllable, injection mechanism is platform's |
| **L2 LIB** | Framework files loaded by AGENT_INIT (AGENT_INIT.md, core/init/*.md, core/RULES.md, guides/MESSAGING.md) | Framework maintainer |
| **L3 MY** | Instance files (IDENTITY.md, MEMORY.md, PRINCIPAL.md, PLAYBOOK.md, INFRASTRUCTURE.md, shared/rules/) | Instance admin / Manager agent |

### Step 2: Measure Each File

For every file in the loading chain, record:

```
File path | Lines | Bytes | Est. tokens | Layer | Load condition
```

**Token estimation heuristic** (Claude tokenizer, mixed CJK/English markdown):
- Pure English: ~0.25 tokens/byte
- Mixed CJK/English: ~0.35-0.40 tokens/byte
- Tables/structured markdown: ~0.30 tokens/byte

### Step 3: Detect Issues

Check for these patterns:

#### 🔴 Critical
- **Double-load**: Same file loaded in multiple layers (e.g., MEMORY.md in L1 + L2)
- **Contradictory instructions**: Two files giving different loading orders or rules
- **Stale content**: Files >30 days old that are loaded every session but never referenced

#### 🟡 Warning
- **Dead branches**: Content in loaded files that never applies to this agent's role/exam status
- **Duplicate rules**: Same rule stated in multiple files
- **Template bloat**: Example/placeholder content left in production files
- **Empty shells**: Files with <10 bytes of useful content still consuming section headers

#### 🟢 Info
- **Large files**: Any single file >3000 tokens — consider splitting or indexing
- **Tier mismatch**: Tier 2 (scan) files being fully read, or Tier 1 files being skanned
- **Missing tier coverage**: AGENT_INIT expects files that aren't being loaded

### Step 4: Calculate Budget

```
Total loading budget = L0 + L1 + L2 + L3

Target: < 20% of context window for loading
Warning: 20-30%
Critical: > 30%
```

For a 200K context window: target < 40K tokens for loading.

### Step 5: Report

Output a structured report with:

1. **Layer breakdown table** (tokens per layer, % of total)
2. **Per-file detail table** (path, bytes, tokens, layer, issues)
3. **Issues found** (prioritized P0/P1/P2)
4. **Optimization recommendations** (action, estimated savings, difficulty)
5. **Before/after comparison** (if this is a re-audit)

### Step 6: Act

Apply optimizations per the recommendations. Common fixes:

| Pattern | Fix |
|---------|-----|
| Double-load | Remove the redundant read (keep the one in the earlier layer) |
| Dead branches | Split file into conditional parts, load only the relevant one |
| Template bloat | Strip examples from production files |
| Empty shells | Delete or replace with single-line content |
| Duplicate rules | Keep in one canonical location, reference from others |
| Large monolithic file | Split into essential (always load) + reference (on-demand) |

## Automation

Shell one-liner to measure all files in the loading chain:

```bash
for f in <list-of-files>; do
  name=$(basename "$f")
  bytes=$(wc -c < "$f")
  lines=$(wc -l < "$f")
  printf "%-30s %4d lines  %6d bytes  ~%d tokens\n" \
    "$name" "$lines" "$bytes" $((bytes * 38 / 100))
done
```

## Completion

After running the audit, write a checkpoint to your MEMORY.md:

```
Audit: loading 2026-02 | L1=1417 L2=2628 L3=2537 total=6583 | issues: 0P0, 1P1 | saved 2167 tok
```

This checkpoint is checked by Manager periodic duties (see AGENT_INIT § Manager Periodic Duties) and HEARTBEAT monthly checks. If the current month's checkpoint is missing, the audit is overdue.

## History

Keep detailed audit reports in `$JOYA_MY/agents/<name>/memory/audit-loading-YYYY-MM.md` for trend tracking.
