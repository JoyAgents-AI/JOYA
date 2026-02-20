# Communication

Three required capabilities:

| Capability | Description |
|---|---|
| **Point-to-point** | One agent → one recipient |
| **Broadcast** | One agent → all agents |
| **Group discussion** | Multi-party conversation |

The instance provides concrete adapters. Adapter config → `DIRECTORY.json`. All messages must be persisted for audit (A1) and include sender, timestamp, content.
