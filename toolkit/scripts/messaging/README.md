# JOYA — Messaging Toolkit

Cross-agent communication tools. All scripts auto-configure from `DIRECTORY.json`.

## Scripts

### `agent-send <agent> <message>`
Core message router. Routes to the correct agent via SSH or Mattermost based on DIRECTORY.json config.

```bash
# Auto-detects JOY_ROOT from script location
./agent-send rex "task complete"

# Or set explicitly
JOY_ROOT=/path/to/joy-agents ./agent-send bob "need review"
```

**Routing logic:**
- Agent has `adapters.ssh` → sends via SSH + `openclaw agent`
- Agent has `adapters.mattermost` only → sends via Mattermost API
- Agent is `manual`/`external` → prints handoff instruction

### `agent-send-md <agent> <message>`
Friendly wrapper that extracts the `"text"` field from agent-send's JSON output.

```bash
./agent-send-md rex "status update please"
```

### `mm-agent-listener.py`
Mattermost WebSocket listener. Monitors channels and dispatches incoming messages to the local OpenClaw agent.

```bash
# Using environment variables
export JOY_ROOT=/path/to/joy-agents
export AGENT_NAME=rex
python3 mm-agent-listener.py

# Using arguments
python3 mm-agent-listener.py --agent rex --joy-root /path/to/joy-agents

# Background (production)
nohup python3 mm-agent-listener.py --agent rex > /tmp/mm-listener-rex.log 2>&1 &
```

**Requirements:**
```bash
pip3 install websockets
```

**Features:**
- Auto-discovers channels (`office-general`, `meetings`) from Mattermost API
- Anti-loop: self-filter, consecutive bot message limit (4), cooldown (30s)
- Image attachment support (downloads and passes to OpenClaw agent)
- Bot-to-bot @mention gating (70% skip if not mentioned)

## Configuration

All scripts read from `$JOY_ROOT/$JOYA_MY/agents/DIRECTORY.json`.

### DIRECTORY.json format (per agent)
```json
{
  "agents": {
    "rex": {
      "display_name": "Rex",
      "role": "worker",
      "node": "m3-1",
      "adapters": {
        "ssh": {
          "user": "youruser",
          "host": "node-1"
        },
        "mattermost": {
          "bot_token": "...",
          "bot_user_id": "...",
          "base_url": "http://your-mattermost-host:8065"
        }
      }
    }
  }
}
```

### Optional: `bot_user_id`
If `bot_user_id` is not in DIRECTORY.json, `mm-agent-listener.py` will auto-fetch it from the Mattermost API on startup. For faster startup, add it to the directory.

## Overriding

Instance-specific overrides go in `$JOYA_MY/shared/toolkit/messaging/`. The toolkit versions are the canonical, portable defaults.
