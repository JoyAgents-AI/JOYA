# Toolkit Guide

Principles for finding, using, creating, and sharing tools (skills, scripts, and adapters).

---

## Tool Resolution

Tools are resolved in three layers (highest priority first):

| Layer | Path | Scope | Who manages |
|---|---|---|---|
| Agent-private | `$JOYA_MY/agents/<name>/skills/` etc. | Only this agent | The agent itself |
| Team-shared | `$JOYA_MY/shared/toolkit/` etc. | All agents | Manager or any authorized agent |
| Framework default | `toolkit/skills/` etc. | All agents | Framework maintainers |

Same-name items at a higher layer **shadow** (override) lower layers.

---

## Creating Tools

Every tool must:

1. **Have documentation** — a tool without docs is a tool no one else can use.
2. **Declare permissions** — what capabilities it requires (network, filesystem, etc.).

Place private tools in `$JOYA_MY/agents/<name>/`. Place shared tools in `$JOYA_MY/shared/toolkit/`.

---

## Sharing Tools

Move a tool from `$JOYA_MY/agents/<name>/` to `$JOYA_MY/shared/toolkit/` when multiple agents need the same capability. Notify all agents of the new shared tool.

Keep private tools private unless they benefit the team.

---

## Overriding Framework Tools

Never modify `toolkit/` directly. Place a same-name item in `$JOYA_MY/shared/toolkit/` or `$JOYA_MY/agents/<name>/` to shadow the framework default.

---

## Per-Agent Skill Configuration

Skills are loaded in order:

1. `_shared/skills.md` → baseline skill set for all agents.
2. `<agent>/skills.md` → additions, overrides, or disablement.

This allows a shared baseline with per-agent customization.

---

## Design Principles

- **skill.json describes "what"** — name, interface, permissions.
- **Adapter directories describe "how"** — runtime-specific implementation.
- **No vendor lock-in** — skills are portable across runtimes via multiple adapters.

---

## Implementation Details

- **Skill descriptor format and adapter definitions**: see `examples/toolkit-skill-format.md`
