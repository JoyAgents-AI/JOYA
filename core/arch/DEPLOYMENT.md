# Multi-Machine Deployment

- **`$JOYA_LIB/` (including `toolkit/`)**: Distribute via Git (`git pull --ff-only`). Read-only, safe to have independent copies.
- **`$JOYA_MY/`**: MUST be consistent across all machines. Real-time or near-real-time consistency is required — never periodic manual copies.

## Deployment Models

| Model | Mechanism | Best For | Trade-offs |
|-------|-----------|----------|------------|
| **Shared Filesystem** | NFS / SMB mount | Same LAN, low latency | Single point of failure; network mount fragility |
| **Real-time File Sync** | Syncthing (recommended) | Cross-network / WAN / mixed OS | Local copies = zero-latency reads; automatic conflict resolution |
| **Single Machine** | Local filesystem | Solo deployments | No sync needed |

### Shared Filesystem (NFS/SMB)

The machine hosting `$JOYA_MY/` is the **home node**. Others mount it remotely. Best for same-LAN setups.

> ⚠️ **Windows**: NFS on Windows has known issues (per-logon-session mount visibility, UNC path handling). Prefer Syncthing for Windows nodes.

### Real-time File Sync (Syncthing)

For cross-network deployments, Syncthing provides:
- **Local copies** on each node — reads are instant, no network dependency
- **Real-time bidirectional sync** — changes propagate in seconds
- **Graceful disconnection handling** — agents continue working offline
- **Conflict resolution** — the **home node** wins conflicts

**Multi-folder isolation (recommended for teams):** Split `$JOYA_MY/` into multiple Syncthing folders:
- `joya-shared` → `shared/` → all nodes
- `joya-agent-<name>` → `agents/<name>/` → home node + agent's node only

This ensures agents physically cannot access other agents' private files.

**Important**: Syncthing is NOT a replacement for Git. `$JOYA_LIB/` changes must go through Git commits.

### lib/ Distribution via Git

- One node (typically Manager's) is the sole commit + push source
- Other nodes: `git pull --ff-only origin main` (manual or automated via cron)
- Recovery: `git checkout . && git clean -fd`

## Cross-Platform Paths

- `AGENTS.md` in each agent's workspace is the **sole translation layer** between platform-specific paths and the JOYA root.
- All protocol files use relative paths.
- Platform-specific deployment details → `guides/DEPLOYMENT.md`.
