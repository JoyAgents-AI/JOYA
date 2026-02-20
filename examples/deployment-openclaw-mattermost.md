# Example: OpenClaw + Mattermost Channel Configuration

Implements: `guides/DEPLOYMENT.md`

How to configure an OpenClaw-based agent to receive and send messages via Mattermost.

---

## Configuration Format

Add the following under `channels.mattermost` in `openclaw.json`:

```json
{
  "channels": {
    "mattermost": {
      "baseUrl": "http://<MM_SERVER>:8065",
      "token": "<AGENT_BOT_TOKEN>",
      "chatmode": "onmessage",
      "dmPolicy": "open",
      "groupPolicy": "open",
      "groups": {
        "*": {
          "requireMention": false
        }
      }
    }
  }
}
```

## Key Field Descriptions

| Field | Description |
|-------|-------------|
| `baseUrl` | Mattermost server address — note: use `baseUrl`, **not** `url` |
| `token` | This agent's own bot token (see INFRASTRUCTURE.md) |
| `chatmode` | `"oncall"` — respond only when @-mentioned or via DM |
| `dmPolicy` | `"open"` — accept all DMs |
| `groupPolicy` | `"open"` — accept all group messages |

---

## Common Mistakes

- Use `baseUrl` (not `url`)
- Use the correct agent token
- For group messages without @, set both:
  - `chatmode: "onmessage"`
  - `groups: {"*": {"requireMention": false}}`
- After config changes, do a **full gateway restart** (not SIGUSR1 hot reload)

---

## Post-Configuration Verification

1. Restart the gateway: `openclaw gateway restart` (or remotely via API)
2. Send the agent a DM in MM and confirm it replies
3. @-mention the agent in a group channel and confirm it responds

---

## Remote Configuration (via Gateway API)

If the agent is already running on a remote node, you can patch the config via the gateway API:

```bash
# View current config
curl -s -H "Authorization: Bearer <GATEWAY_TOKEN>" \
  http://<NODE_IP>:18789/api/config | jq .

# Patch config (auto-restarts)
curl -s -X PATCH -H "Authorization: Bearer <GATEWAY_TOKEN>" \
  -H "Content-Type: application/json" \
  http://<NODE_IP>:18789/api/config \
  -d '{"channels":{"mattermost":{"baseUrl":"...","token":"...","chatmode":"oncall","dmPolicy":"open","groupPolicy":"open"}}}'
```
