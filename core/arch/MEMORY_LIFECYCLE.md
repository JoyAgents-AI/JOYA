# Memory Lifecycle

Agent memory (`$JOYA_MY/agents/<name>/memory/`) follows a **three-tier decay** model to prevent unbounded growth and stale data.

## Three Tiers

| Tier | Age | Format | Action |
|------|-----|--------|--------|
| **Hot** | ≤ 3 days | Daily files (`2026-02-20.md`) | Keep as-is |
| **Warm** | 4–14 days | Weekly summary (`week-2026-W08.md`) | Merge dailies → weekly, delete originals |
| **Cold** | > 14 days | Distilled into `MEMORY.md` or `ref-*.md` | Extract lasting lessons, delete weekly |

## GC Rules

1. **New supersedes old** — If a newer entry corrects or updates an older one, only the newer version survives the merge.
2. **Lessons upgrade** — Recurring patterns or hard-won knowledge graduate to `MEMORY.md` (or `memory/ref-*.md`). The source daily/weekly file is then deleted.
3. **Legacy files** — Files named `*-legacy.md` (compaction artifacts) should be reviewed and merged or deleted during the first GC pass.
4. **Topic files** — Files like `2026-02-20-some-topic.md` follow the same decay as their date prefix. If the topic produced lasting knowledge, extract it before deletion.

## GC Trigger

- **Session end**: When writing daily memory, check for files eligible for Warm/Cold transitions.
- **Heartbeat** (optional): Periodic GC as a heartbeat task.

## MEMORY.md Hygiene

- `MEMORY.md` is loaded every session — keep it **lean** (index + current state only).
- Stable reference data → `memory/ref-*.md` sub-files, loaded on demand via `memory_search`.
- **Pending section**: Only open items. Completed items are deleted, not marked `[x]`.
- **No stale pointers**: Remove "Active Discussion" or similar sections once resolved.

## Index + Lazy Load

`MEMORY.md` should follow the same index-first pattern as other framework files:
- Always loaded: Team roster, comms, pending items, sub-file index
- On-demand: Infrastructure details, agent notes, lessons learned, historical sessions

## Compaction Resilience

Compaction is lossy — information only in conversation can be permanently lost. See `core/arch/COMPACTION_RESILIENCE.md` for the three-layer defense protocol (Write-Through, SESSION.md, Post-Compaction Self-Check).
