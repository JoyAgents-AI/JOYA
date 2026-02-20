#!/usr/bin/env python3
"""
Mattermost Agent Listener — Claude Code variant
Replaces openclaw with `claude -p` for agents running on Claude Code.

Usage:
    export JOY_ROOT=/path/to/joy-agents
    python3 mm-agent-listener-claude.py --agent ace

    # Background:
    nohup python3 mm-agent-listener-claude.py --agent ace > /tmp/mm-listener-ace.log 2>&1 &

Requirements:
    pip3 install websockets
    claude CLI must be in PATH
"""

import asyncio
import json
import subprocess
import os
import re
import sys
import time
import argparse
import urllib.request
import ssl

try:
    import websockets
except ImportError:
    print("Missing dependency: pip3 install websockets")
    sys.exit(1)

_ssl_ctx = ssl.create_default_context()
_ssl_ctx.check_hostname = False
_ssl_ctx.verify_mode = ssl.CERT_NONE

# ============================================================
# Configuration
# ============================================================

def find_joy_root():
    if os.environ.get("JOY_ROOT"):
        return os.environ["JOY_ROOT"]
    script_dir = os.path.dirname(os.path.abspath(__file__))
    candidate = os.path.normpath(os.path.join(script_dir, "..", "..", ".."))
    if os.path.isfile(os.path.join(candidate, "AGENT_INIT.md")):
        return candidate
    print("Cannot find JOY_ROOT. Set JOY_ROOT env or use --joy-root.")
    sys.exit(1)


def load_config(joy_root, agent_name):
    dir_path = os.path.join(joy_root, "instance", "agents", "DIRECTORY.json")
    if not os.path.isfile(dir_path):
        print(f"DIRECTORY.json not found: {dir_path}")
        sys.exit(1)

    directory = json.load(open(dir_path))
    agents = directory.get("agents", {})

    me = agents.get(agent_name)
    if not me:
        print(f"Agent '{agent_name}' not found. Available: {', '.join(agents.keys())}")
        sys.exit(1)

    mm = me.get("adapters", {}).get("mattermost", {})
    my_bot_token = mm.get("bot_token", "")
    mm_url = mm.get("base_url", "")

    if not my_bot_token or not mm_url:
        print(f"Mattermost config incomplete for '{agent_name}'.")
        sys.exit(1)

    my_bot_user_id = mm.get("bot_user_id", "")
    if not my_bot_user_id:
        my_bot_user_id = _fetch_bot_user_id(mm_url, my_bot_token)

    bot_id_to_name = {}
    for name, info in agents.items():
        a_mm = info.get("adapters", {}).get("mattermost", {})
        bid = a_mm.get("bot_user_id", "")
        if bid:
            bot_id_to_name[bid] = name
    if my_bot_user_id:
        bot_id_to_name[my_bot_user_id] = agent_name

    channels = _load_channels(joy_root, mm_url, my_bot_token)

    return {
        "agent_name": agent_name,
        "mm_url": mm_url,
        "mm_ws": mm_url.replace("http://", "ws://").replace("https://", "wss://") + "/api/v4/websocket",
        "my_bot_token": my_bot_token,
        "my_bot_user_id": my_bot_user_id,
        "admin_token": mm.get("admin_token", my_bot_token),
        "bot_id_to_name": bot_id_to_name,
        "channels": channels,
    }


def _fetch_bot_user_id(mm_url, token):
    try:
        req = urllib.request.Request(
            f"{mm_url}/api/v4/users/me",
            headers={"Authorization": f"Bearer {token}"},
        )
        data = json.loads(urllib.request.urlopen(req, timeout=10, context=_ssl_ctx).read())
        return data.get("id", "")
    except Exception as e:
        print(f"Could not fetch bot user_id: {e}")
        return ""


def _load_channels(joy_root, mm_url, token):
    monitored_names = {"office-general", "meetings"}
    channels = {}
    try:
        req = urllib.request.Request(
            f"{mm_url}/api/v4/users/me/teams",
            headers={"Authorization": f"Bearer {token}"},
        )
        teams = json.loads(urllib.request.urlopen(req, timeout=10, context=_ssl_ctx).read())
        for team in teams:
            req = urllib.request.Request(
                f"{mm_url}/api/v4/teams/{team['id']}/channels?per_page=100",
                headers={"Authorization": f"Bearer {token}"},
            )
            team_channels = json.loads(urllib.request.urlopen(req, timeout=10, context=_ssl_ctx).read())
            for ch in team_channels:
                if ch["name"] in monitored_names:
                    channels[ch["id"]] = ch["name"]
    except Exception as e:
        print(f"Could not auto-discover channels: {e}")
    return channels


# ============================================================
# Anti-loop
# ============================================================

_bot_consecutive = 0
_bot_consecutive_max = 4
_last_bot_msg_time = 0
_cooldown_seconds = 30
_my_last_reply_time = 0
_my_reply_min_interval = 5
_user_cache = {}

CFG = {}


# ============================================================
# Mattermost helpers
# ============================================================

def mm_post(channel_id, message):
    data = json.dumps({"channel_id": channel_id, "message": message}).encode()
    req = urllib.request.Request(
        f"{CFG['mm_url']}/api/v4/posts", data=data,
        headers={"Authorization": f"Bearer {CFG['my_bot_token']}", "Content-Type": "application/json"},
    )
    try:
        urllib.request.urlopen(req, timeout=10, context=_ssl_ctx)
    except Exception as e:
        print(f"[mm_post] Error: {e}", flush=True)


def get_username(user_id):
    if user_id in _user_cache:
        return _user_cache[user_id]
    req = urllib.request.Request(
        f"{CFG['mm_url']}/api/v4/users/{user_id}",
        headers={"Authorization": f"Bearer {CFG['admin_token']}"},
    )
    try:
        name = json.loads(urllib.request.urlopen(req, timeout=5, context=_ssl_ctx).read()).get("username", "unknown")
    except:
        name = "unknown"
    _user_cache[user_id] = name
    return name


def should_i_respond(message, user_id):
    global _bot_consecutive, _last_bot_msg_time, _my_last_reply_time

    now = time.time()
    is_bot = user_id in CFG["bot_id_to_name"]

    if is_bot:
        if now - _last_bot_msg_time < 60:
            _bot_consecutive += 1
        else:
            _bot_consecutive = 1
        _last_bot_msg_time = now

        if _bot_consecutive > _bot_consecutive_max:
            return False
        if now - _my_last_reply_time < _cooldown_seconds and _bot_consecutive > 2:
            return False

        msg_lower = message.lower()
        if f"@{CFG['agent_name']}" not in msg_lower:
            import random
            if random.random() < 0.7:
                return False
    else:
        _bot_consecutive = 0

    if now - _my_last_reply_time < _my_reply_min_interval:
        return False

    return True


# ============================================================
# Claude Code integration
# ============================================================

def call_claude(message, timeout=120):
    """Call claude -p with the message, return the response text."""
    joy_root = os.environ.get("JOY_ROOT", "")
    agent_dir = os.path.join(joy_root, "instance", "agents", CFG["agent_name"])

    # Build system prompt with agent identity
    identity_file = os.path.join(agent_dir, "IDENTITY.md")
    identity = ""
    if os.path.isfile(identity_file):
        with open(identity_file) as f:
            identity = f.read()

    memory_file = os.path.join(agent_dir, "MEMORY.md")
    memory = ""
    if os.path.isfile(memory_file):
        with open(memory_file) as f:
            memory = f.read()

    prompt = f"""You are **{CFG['agent_name'].upper()}**. You must reply AS {CFG['agent_name'].upper()} and ONLY as {CFG['agent_name'].upper()}.

CRITICAL: You are NOT the person who sent the message below. You are {CFG['agent_name'].upper()} responding TO them.
Do NOT impersonate, mimic, or roleplay as the sender. Do NOT say "我是 [sender name]".

Your identity:
{identity}

Your memory:
{memory}

---

Rules:
- Reply as {CFG['agent_name'].upper()} in first person
- Keep it concise, like a normal chat message
- If you have nothing meaningful to add, reply with exactly: NO_REPLY
- No markdown formatting (no **, no ##, etc.)
- Speak in Chinese

Incoming message from the team chat:
{message}"""

    try:
        # Remove CLAUDECODE env var to avoid nested session detection
        env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}
        result = subprocess.run(
            ["claude", "-p", prompt, "--output-format", "text"],
            capture_output=True, text=True, timeout=timeout,
            env=env,
        )
        output = result.stdout.strip()
        if not output or "NO_REPLY" in output:
            return None
        return output
    except subprocess.TimeoutExpired:
        print(f"  claude -p timed out ({timeout}s)", flush=True)
        return None
    except FileNotFoundError:
        print("  claude CLI not found in PATH", flush=True)
        return None
    except Exception as e:
        print(f"  claude error: {e}", flush=True)
        return None


# ============================================================
# Message handler
# ============================================================

def handle_message(channel_id, channel_name, username, message):
    global _my_last_reply_time

    context = f"[Mattermost #{channel_name}] {username}: {message}"

    print(f"  -> Processing...", flush=True)
    reply = call_claude(context)

    if reply and "NO_REPLY" not in reply and "HEARTBEAT_OK" not in reply:
        reply = re.sub(r'^\[.*?\]\s*', '', reply)
        # Trim if too long for chat
        if len(reply) > 2000:
            reply = reply[:1997] + "..."
        mm_post(channel_id, reply)
        _my_last_reply_time = time.time()
        print(f"  <- {reply[:100]}", flush=True)
    else:
        print(f"  <- (silent)", flush=True)


# ============================================================
# WebSocket listener
# ============================================================

async def listen():
    while True:
        try:
            print(f"[{CFG['agent_name']}] Connecting to {CFG['mm_url']}...", flush=True)
            ws_kwargs = {"ping_interval": 30, "ping_timeout": 10}
            if CFG["mm_ws"].startswith("wss://"):
                ws_kwargs["ssl"] = _ssl_ctx

            async with websockets.connect(CFG["mm_ws"], **ws_kwargs) as ws:
                await ws.send(json.dumps({
                    "seq": 1,
                    "action": "authentication_challenge",
                    "data": {"token": CFG["admin_token"]}
                }))

                for _ in range(5):
                    try:
                        raw = await asyncio.wait_for(ws.recv(), timeout=3)
                        if json.loads(raw).get("status") == "OK":
                            break
                    except asyncio.TimeoutError:
                        break

                print(f"[{CFG['agent_name']}] Listening on: {list(CFG['channels'].values())}", flush=True)

                async for raw in ws:
                    try:
                        evt = json.loads(raw)
                    except:
                        continue

                    if evt.get("event") != "posted":
                        continue

                    post_str = evt.get("data", {}).get("post", "{}")
                    post = json.loads(post_str) if isinstance(post_str, str) else post_str

                    user_id = post.get("user_id", "")
                    message = post.get("message", "").strip()
                    channel_id = post.get("channel_id", "")

                    if not message:
                        continue
                    if user_id == CFG["my_bot_user_id"]:
                        continue
                    if CFG["channels"] and channel_id not in CFG["channels"]:
                        continue

                    if not should_i_respond(message, user_id):
                        continue

                    username = CFG["bot_id_to_name"].get(user_id) or get_username(user_id)
                    print(f"[{username}@#{CFG['channels'].get(channel_id, '?')}] {message[:100]}", flush=True)

                    loop = asyncio.get_event_loop()
                    loop.run_in_executor(None, handle_message, channel_id, CFG['channels'].get(channel_id, '?'), username, message)

        except Exception as e:
            print(f"[{CFG['agent_name']}] Error: {e}, reconnecting in 3s...", flush=True)
            await asyncio.sleep(3)


def main():
    global CFG

    parser = argparse.ArgumentParser(description="JOYA — Mattermost Listener (Claude Code)")
    parser.add_argument("--agent", default=os.environ.get("AGENT_NAME", ""),
                        help="Agent name (or set AGENT_NAME env)")
    parser.add_argument("--joy-root", default="",
                        help="JOYA root (or set JOY_ROOT env)")
    args = parser.parse_args()

    if args.joy_root:
        os.environ["JOY_ROOT"] = args.joy_root

    agent_name = args.agent
    if not agent_name:
        print("Agent name required. Use --agent <name> or set AGENT_NAME env.")
        sys.exit(1)

    joy_root = find_joy_root()
    CFG = load_config(joy_root, agent_name)

    print(f"MM Listener [{agent_name}] (Claude Code) PID {os.getpid()}", flush=True)
    print(f"  JOY_ROOT: {joy_root}", flush=True)
    print(f"  MM URL:   {CFG['mm_url']}", flush=True)
    print(f"  Bot ID:   {CFG['my_bot_user_id']}", flush=True)
    print(f"  Channels: {CFG['channels']}", flush=True)

    asyncio.run(listen())


if __name__ == "__main__":
    main()
