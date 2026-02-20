# R12. Instance Data Handling

`$JOYA_MY/` contains secrets, high-frequency state, and team-shared live data.

- **Multi-machine deployments**: When agents are distributed across multiple machines, `$JOYA_MY/` MUST be kept consistent across all nodes in real-time or near-real-time. Acceptable methods: shared filesystem (NFS, SMB) or real-time file sync (Syncthing). Periodic manual copies or cron-based rsync are NOT acceptable — they risk stale reads and split-brain state.
- **Single-machine deployments**: `$JOYA_MY/` MAY reside on the local filesystem.
- **Protocol distribution**: `$JOYA_LIB/` (incl. `toolkit/`) are read-only reference documents and MAY be freely distributed via `git pull`.
