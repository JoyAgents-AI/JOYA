# Messaging — Group Chat Rules

For adapter setup → `guides/MESSAGING_SETUP.md`.

## Channel Selection

**非必要不在大群发消息。** #office-general 所有人都会收到，@ 过滤不生效，每条消息消耗全员 token。

| 场景 | 去哪发 |
|------|--------|
| 全员公告、重大决策、安全告警 | #office-general |
| 专项协作（社交媒体、某项目等） | 对应专题频道 |
| 仅涉及 1-2 个 agent | DM 或小群 |
| 向 Principal 汇报 | DM |

**原则：选能覆盖必要受众的最小频道。**

## Addressing

Group channels: **always @-mention target agent(s)**. Standby agents only activate on @-mention. Only Principal may send unaddressed messages.

## Reply Policy

**Speak only when you add value. Quiet otherwise.**

Quick test: Would you respond to this in a real 5-person work chat? Yes → reply. Unsure → reply only if from Principal.

### MUST Reply

| Scenario |
|----------|
| Principal asks you a question (even without @) |
| Reachability test → minimal: `1` or `✅` |
| Task assignment → confirm receipt |
| Safety/outage alerts |

### SHOULD Reply

| Scenario |
|----------|
| @-mentioned or called by name |
| Question in your expertise area |
| Can correct a factual error |
| Asked to vote → stance + rationale |
| Your earlier conclusion invalidated → correct it |

### SHOULD NOT Reply

| Scenario |
|----------|
| Good answer already given |
| Outside your capability |
| Principal @-mentioned another agent → **their conversation** |
| 2+ agents replied, nothing new to add |

### Quality

Add info or say nothing. One message to resolve. Brevity first. Say so when uncertain.

### Conflict

Each party states position once → no consensus → Manager decides → execute.

## Anti-Loop

- Never reply to own messages
- Max 4 consecutive bot messages before human
- No dupes within 20s; loop detected → stop + report
- Check-before-send: wait 2-3s, re-fetch, 2+ replies exist + nothing new → discard
- Don't pile on acknowledgments
