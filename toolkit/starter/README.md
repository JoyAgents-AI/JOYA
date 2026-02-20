# Instance Starter Template

Copy this directory to `$JOYA_MY/` to bootstrap your JOYA deployment.

```bash
cp -r toolkit/starter/ $JOYA_MY/
```

Then:
1. Edit `shared/core/PRINCIPAL.md` with your identity.
2. Rename `agents/my-agent/` to your agent's name.
3. Fill in `agents/<name>/IDENTITY.md`.
4. Configure communication adapter in `agents/DIRECTORY.json`.
5. Start your agent and verify it loads its identity correctly.
