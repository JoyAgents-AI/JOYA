# Messaging Setup

How to select and configure communication adapters for your JOYA deployment. Load this during initial setup or when changing communication infrastructure.

For daily group chat rules, see `MESSAGING.md`.

## Communication Interface

The framework requires three capabilities (defined in `core/ARCHITECTURE.md`):

1. **Point-to-point** — Agent A → Agent B
2. **Broadcast** — Agent A → all agents
3. **Group discussion** — multi-agent real-time conversation

## Adapter Selection

Choose adapters based on your environment:

| Scenario | Recommended Adapters |
|----------|---------------------|
| Same machine, all agents | File-based or local IPC |
| Same network, multiple machines | SSH + CLI, shared filesystem, or pub/sub |
| Cross-network / cloud | HTTP Webhook, WebSocket |
| Mixed environments | Combine adapters per agent in `DIRECTORY.json` |

## Adapter Comparison

| Adapter | Latency | Complexity | Dependencies | Best For |
|---------|---------|------------|--------------|----------|
| SSH + CLI | ~500ms | Low | SSH access | Same-network, CLI-based agents |
| HTTP Webhook | ~100ms | Medium | HTTP server per agent | Cross-network, RESTful agents |
| WebSocket chat | ~100ms | Medium | Chat server | Real-time group discussion |
| File polling | 1-30s | Low | Shared filesystem | Simple setups, no infrastructure |
| Pub/sub service | ~10ms | Medium | Message broker | High-frequency, programmatic comms |

## Configuration

Each agent's adapter is configured in `$JOYA_MY/shared/agents/DIRECTORY.json`:

```json
{
  "agents": {
    "worker-1": {
      "role": "worker",
      "adapter": "ssh-cli",
      "host": "machine-1",
      "command": "agent-cli receive"
    }
  }
}
```

## Message Format

Regardless of adapter, every message should include:

```
Sender: <agent-role>
Timestamp: <ISO-8601>
Type: notification | request | response | broadcast
Content: <message body>
```

## Persistence

All messages must be persisted for audit (Axiom A1). Options:
- Log file per agent
- Append-only message store
- Chat platform with history retention
- Git-committed message logs
