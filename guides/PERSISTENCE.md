# Instance Persistence Guide

How to protect `$JOYA_MY/` data from loss.

---

## Why This Matters

The `$JOYA_MY/` directory contains agent identities, memories, configuration, credentials, and knowledge — all gitignored from the protocol repo. It has **no backup by default**. Losing it means losing your agents' accumulated experience. Back it up.

---

## Options

| Method | Versioned | Auto-sync | Handles secrets | Best for |
|--------|:---------:|:---------:|:---------------:|----------|
| **Private Git repo** | Yes | On commit | With git-crypt | Teams with existing Git infrastructure |
| **Cloud sync** (iCloud, Dropbox, Syncthing) | Partial | Yes | No | Solo setups, quick start |
| **Periodic rsync** | No | Via cron | No | Air-gapped or multi-node environments |

---

## Option A: Private Git Repo (Recommended for teams)

Initialize `$JOYA_MY/` as its own Git repo with a private remote. For secrets, either gitignore sensitive files (storing credentials in a password manager) or use `git-crypt` to encrypt them in-repo. If multiple nodes need access, either share via NFS with one node owning Git operations, or have each node clone independently.

**Key consideration**: Export and safely store the git-crypt key — losing it means losing access to encrypted files.

---

## Option B: Cloud Sync

Move or symlink `$JOYA_MY/` to a synced folder (iCloud, Dropbox, Syncthing). Simple and automatic, but no version history, no secret handling, and eventually-consistent across machines. Works well for single-machine setups or personal backup. If using with multiple agents, designate one writer to avoid conflict copies.

---

## Option C: Periodic rsync

Use `rsync -avz --delete` to mirror `$JOYA_MY/` to a backup location on a schedule (cron or launchd). No version history — only latest state preserved. Good as a supplement to other methods or for air-gapped environments. Note that `--delete` mirrors deletions; omit it for append-only backups.

---

**Note:** Persistence is optional but strongly recommended. The framework does not require any specific backup method — choose what fits your environment, or skip if you accept the risk.

## Document Your Choice

After setting up persistence, record it in `$JOYA_MY/shared/core/PLAYBOOK.md` under **Synchronization**: method, remote/destination, how secrets are handled, which node owns writes, and any secondary backup.
