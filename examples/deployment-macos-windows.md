# Example: macOS ↔ Windows NFS/SSH Deployment

Implements: `guides/DEPLOYMENT.md`

Platform-specific details for deploying JOYA across macOS and Windows machines using NFS.

---

## Network Filesystem Setup

### macOS as Home Node (NFS Export)

- Use `-mapall=<user>` in `/etc/exports` to map all anonymous access to the correct local user.
- Ensure `o+rX` permissions on all exported files to avoid access denied errors from remote clients.
- Example: `/Users/youruser -mapall=youruser -alldirs -network 192.168.1.0 -mask 255.255.255.0`

### Windows as Remote Node (NFS Client)

- **Mounts are per-logon-session**: An SSH session cannot see mounts created by a desktop session, and vice versa. Agent processes must start from the same session that mounts the share.
- **Recommended startup flow**: Use a Startup folder VBS script that first mounts the NFS share, then starts the agent gateway in the same session.
- **Symlinks do not work over NFS**: `mklink /D` and `mklink /J` do not reliably resolve across NFS mounts. Use direct mount point paths instead (e.g., `Z:\Code\joy-agents\`).
- **AnonymousUid/Gid**: If access is denied, configure NFS client UID mapping via registry: `HKLM\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default` — set `AnonymousUid` and `AnonymousGid` to match the export user. Requires reboot.

### SMB Alternative

- macOS SMB auth can be unreliable (NTLM hash mismatch). NFS is generally more reliable for macOS → Windows sharing.
- If using SMB, ensure persistent credentials with `net use /persistent:yes` and correct user/password.

---

## Windows-Specific Notes

### Process Lifetime

- SSH child processes are killed when the SSH session disconnects. Do not rely on SSH to start persistent agent processes.
- **Recommended**: Use Startup folder scripts (VBS wrapper → CMD batch) or Windows scheduled tasks (`schtasks /SC ONLOGON`) for persistent agent gateways.
- Desktop shortcuts (`start-agent.cmd`) are useful for manual restarts.

### SSH Environment

- Windows OpenSSH default shell is `cmd.exe`. Ensure the PATH includes Node.js and npm global directories.
- Watch for stray `.bat` or `.cmd` files in the user's home directory — `cmd.exe` may auto-execute them.
- `administrators_authorized_keys` must have correct permissions: `SYSTEM:(R)` and `Administrators:(R)` only.

---

## Cross-Platform Path Resolution

- Each agent's workspace `AGENTS.md` is the sole translation layer between platform-specific paths and the joy-agents directory structure.
- On the home node: relative paths (e.g., `../../Code/joy-agents/`) work when the workspace is within the same filesystem tree.
- On remote nodes: use absolute mount point paths (e.g., `Z:/Code/joy-agents/` on Windows).
- Use forward slashes in AGENTS.md even on Windows (most tools accept both).
