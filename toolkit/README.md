# Toolkit

Official tools shipped with the framework. Users don't modify these — override via `$JOYA_MY/` instead.

## scripts/

- `joy-init.sh` — Initialize project registration in `shared/projects/`
- `joy-validate.sh` — Validate instance against the protocol
- `joy-translate.sh` — Translate framework documents
- `selfcheck.sh` — Agent self-check script
- `joy-adapter-*.sh` — Communication adapter scripts (OpenClaw, Cursor, Windsurf, Claude Code, Gemini)
- `messaging/` — Mattermost listener scripts

## starter/

A complete instance template. Copy to `$JOYA_MY/` to bootstrap a new deployment:

```bash
cp -r toolkit/starter/ $JOYA_MY/
```
