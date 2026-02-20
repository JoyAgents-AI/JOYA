# Agent Identity & Memory

Each agent has portable identity and memory in `$JOYA_MY/agents/<name>/`:

- **IDENTITY.md** — personality, role, communication style
- **MEMORY.md** — curated long-term memory
- **memory/** — structured archive

Loading order: `$JOYA_MY/shared/templates/*` first, then `agents/<name>/*` (per-agent overrides shared).

Portability rule: No agent memory may exist **only** in a proprietary store. If a platform provides its own memory layer, agents must mirror key memories to portable instance files.
