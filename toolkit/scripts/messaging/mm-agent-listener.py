#!/usr/bin/env python3
"""
Mattermost Agent Listener — JOYA Toolkit
Auto-configures from DIRECTORY.json. No hardcoded tokens or URLs.

Usage:
    # Set environment:
    export JOY_ROOT=/path/to/joy-agents
    export AGENT_NAME=rex

    # Or pass as arguments:
    python3 mm-agent-listener.py --agent rex --joy-root /path/to/joy-agents

    # Run:
    nohup python3 mm-agent-listener.py > /tmp/mm-listener.log 2>&1 &

Requirements:
    pip3 install websockets
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
    print("❌ Missing dependency: pip3 install websockets")
    sys.exit(1)

# --- SSL context (skip verification for self-signed certs) ---
_ssl_ctx = ssl.create_default_context()
_ssl_ctx.check_hostname = False
_ssl_ctx.verify_mode = ssl.CERT_NONE

# ============================================================
# Configuration — loaded from DIRECTORY.json
# ============================================================

def find_joy_root():
    """Auto-detect JOY_ROOT from environment or script location."""
    if os.environ.get("JOY_ROOT"):
        return os.environ["JOY_ROOT"]
    # Walk up from script: toolkit/scripts/messaging/ → root
    script_dir = os.path.dirname(os.path.abspath(__file__))
    candidate = os.path.normpath(os.path.join(script_dir, "..", "..", ".."))
    if os.path.isfile(os.path.join(candidate, "AGENT_INIT.md")):
        return candidate
    print("❌ Cannot find JOY_ROOT. Set JOY_ROOT env or use --joy-root.")
    sys.exit(1)


def load_config(joy_root, agent_name):
    """Load agent config from DIRECTORY.json."""
    dir_path = os.path.join(joy_root, "instance", "agents", "DIRECTORY.json")
    if not os.path.isfile(dir_path):
        print(f"❌ DIRECTORY.json not found: {dir_path}")
        sys.exit(1)

    directory = json.load(open(dir_path))
    agents = directory.get("agents", {})

    me = agents.get(agent_name)
    if not me:
        print(f"❌ Agent '{agent_name}' not found in DIRECTORY.json")
        print(f"   Available: {', '.join(agents.keys())}")
        sys.exit(1)

    # Extract my Mattermost config
    mm = me.get("adapters", {}).get("mattermost", me.get("mattermost", {}))
    my_bot_token = mm.get("bot_token", "")
    mm_url = mm.get("base_url", "")

    if not my_bot_token or not mm_url:
        print(f"❌ Mattermost config incomplete for '{agent_name}'. Need bot_token and base_url.")
        sys.exit(1)

    # Resolve bot_user_id (fetch from API if not in directory)
    my_bot_user_id = mm.get("bot_user_id", "")
    if not my_bot_user_id:
        my_bot_user_id = _fetch_bot_user_id(mm_url, my_bot_token)

    # Build bot_id → name mapping from all agents
    bot_id_to_name = {}
    for name, info in agents.items():
        a_mm = info.get("adapters", {}).get("mattermost", info.get("mattermost", {}))
        bid = a_mm.get("bot_user_id", "")
        if bid:
            bot_id_to_name[bid] = name

    # If we resolved our own, add it
    if my_bot_user_id:
        bot_id_to_name[my_bot_user_id] = agent_name

    # Load channels from INFRASTRUCTURE.md or use defaults
    channels = _load_channels(joy_root, mm_url, my_bot_token)

    # Admin token (optional, for fetching usernames; falls back to bot token)
    admin_token = mm.get("admin_token", my_bot_token)

    return {
        "agent_name": agent_name,
        "mm_url": mm_url,
        "mm_ws": mm_url.replace("http://", "ws://").replace("https://", "wss://") + "/api/v4/websocket",
        "my_bot_token": my_bot_token,
        "my_bot_user_id": my_bot_user_id,
        "admin_token": admin_token,
        "bot_id_to_name": bot_id_to_name,
        "channels": channels,
    }


def _fetch_bot_user_id(mm_url, token):
    """Fetch the bot's own user ID from Mattermost API."""
    try:
        req = urllib.request.Request(
            f"{mm_url}/api/v4/users/me",
            headers={"Authorization": f"Bearer {token}"},
        )
        data = json.loads(urllib.request.urlopen(req, timeout=10, context=_ssl_ctx).read())
        return data.get("id", "")
    except Exception as e:
        print(f"⚠️ Could not fetch bot user_id: {e}")
        return ""


def _load_channels(joy_root, mm_url, token):
    """
    Load monitored channels. Tries to read from instance config,
    falls back to fetching all channels and monitoring 'office-general' and 'meetings'.
    """
    # Default monitored channel names
    monitored_names = {"office-general", "meetings"}

    # Try to fetch channel list from Mattermost
    channels = {}
    try:
        # Get teams
        req = urllib.request.Request(
            f"{mm_url}/api/v4/users/me/teams",
            headers={"Authorization": f"Bearer {token}"},
        )
        teams = json.loads(urllib.request.urlopen(req, timeout=10, context=_ssl_ctx).read())

        for team in teams:
            team_id = team["id"]
            req = urllib.request.Request(
                f"{mm_url}/api/v4/teams/{team_id}/channels?per_page=100",
                headers={"Authorization": f"Bearer {token}"},
            )
            team_channels = json.loads(urllib.request.urlopen(req, timeout=10, context=_ssl_ctx).read())
            for ch in team_channels:
                if ch["name"] in monitored_names:
                    channels[ch["id"]] = ch["name"]
    except Exception as e:
        print(f"⚠️ Could not auto-discover channels: {e}")

    if not channels:
        print("⚠️ No channels discovered. Listener will accept all channels.")

    return channels


# ============================================================
# Anti-loop state
# ============================================================

_bot_consecutive = 0
_bot_consecutive_max = 4
_last_bot_msg_time = 0
_cooldown_seconds = 30
_my_last_reply_time = 0
_my_reply_min_interval = 5

_user_cache = {}

# ============================================================
# Core functions
# ============================================================

CFG = {}  # filled in main()


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


def download_file(file_id):
    try:
        req = urllib.request.Request(
            f"{CFG['mm_url']}/api/v4/files/{file_id}/info",
            headers={"Authorization": f"Bearer {CFG['admin_token']}"},
        )
        info = json.loads(urllib.request.urlopen(req, timeout=10, context=_ssl_ctx).read())
        name = info.get("name", "file")
        mime = info.get("mime_type", "")
        if not mime.startswith("image/"):
            return None

        req = urllib.request.Request(
            f"{CFG['mm_url']}/api/v4/files/{file_id}",
            headers={"Authorization": f"Bearer {CFG['admin_token']}"},
        )
        data = urllib.request.urlopen(req, timeout=30, context=_ssl_ctx).read()

        ext = name.rsplit(".", 1)[-1] if "." in name else "png"
        img_dir = os.path.expanduser("~/.openclaw/mm-images")
        os.makedirs(img_dir, exist_ok=True)
        img_path = os.path.join(img_dir, f"{file_id}.{ext}")
        with open(img_path, "wb") as f:
            f.write(data)
        print(f"  📷 Downloaded: {name} ({len(data)} bytes) → {img_path}", flush=True)
        return (img_path, name, mime)
    except Exception as e:
        print(f"  ⚠️ File download error: {e}", flush=True)
        return None


def call_openclaw(message, timeout=180, image_paths=None):
    try:
        if image_paths:
            img_note = "\n\n📷 附件图片（请用 image tool 查看）："
            for path, name, _ in image_paths:
                img_note += f"\n- {name}: {path}"
            message = message + img_note

        result = subprocess.run(
            ["openclaw", "agent", "--session-id", f"mm-{CFG['agent_name']}",
             "--message", message, "--timeout", "120", "--json"],
            capture_output=True, text=True, timeout=timeout,
            env={**os.environ, "PATH": f"/opt/homebrew/bin:/usr/local/bin:{os.environ.get('PATH', '')}"},
        )
        output = result.stdout.strip()
        if not output:
            return None
        try:
            data = json.loads(output)
            payloads = data.get("result", {}).get("payloads", [])
            if payloads:
                text = payloads[0].get("text", "")
                return text if text and "NO_REPLY" not in text else None
            return None
        except json.JSONDecodeError:
            pass
        if '"text"' in output:
            for line in output.split('\n'):
                if '"text"' in line:
                    m = re.search(r'"text"\s*:\s*"(.*)"', line)
                    if m:
                        text = m.group(1).replace('\\n', '\n').replace('\\"', '"')
                        return text if "NO_REPLY" not in text else None
        if output.startswith('{'):
            return None
        return output
    except subprocess.TimeoutExpired:
        print(f"  ⏱️ openclaw agent timed out ({timeout}s)", flush=True)
        return None
    except Exception as e:
        print(f"  ❌ openclaw error: {e}", flush=True)
        return None


def handle_message(channel_id, channel_name, username, message, file_ids=None):
    global _my_last_reply_time

    image_paths = []
    if file_ids:
        for fid in file_ids[:4]:
            result = download_file(fid)
            if result:
                image_paths.append(result)

    context = f"[Mattermost #{channel_name} 群聊] {username} 说: {message}"
    if image_paths:
        context += f"\n（附带 {len(image_paths)} 张图片）"
    context += "\n（这是工作群聊，像正常同事一样交流。有话说就说，没必要回就回 NO_REPLY。不要每条都回，避免刷屏。）"

    print(f"  → Processing... (images: {len(image_paths)})", flush=True)
    reply = call_openclaw(context, image_paths=image_paths)

    if reply and "NO_REPLY" not in reply and "HEARTBEAT_OK" not in reply:
        reply = re.sub(r'^\[来自\w+\]\s*', '', reply)
        mm_post(channel_id, reply)
        _my_last_reply_time = time.time()
        print(f"  ← {reply[:80]}", flush=True)
    else:
        print(f"  ← (silent)", flush=True)


async def listen():
    while True:
        try:
            print(f"🎧 [{CFG['agent_name']}] Connecting to {CFG['mm_url']}...", flush=True)
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

                print(f"✅ [{CFG['agent_name']}] Listening on channels: {list(CFG['channels'].values())}", flush=True)

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
                    file_ids = post.get("file_ids", []) or []

                    if not message and not file_ids:
                        continue
                    if user_id == CFG["my_bot_user_id"]:
                        continue

                    # Skip unmonitored channels (if channels configured)
                    if CFG["channels"] and channel_id not in CFG["channels"]:
                        continue

                    channel_name = CFG["channels"].get(channel_id, channel_id)

                    if not should_i_respond(message, user_id):
                        continue

                    username = CFG["bot_id_to_name"].get(user_id) or get_username(user_id)
                    print(f"📩 [{username}@#{channel_name}] {message[:80]}", flush=True)

                    loop = asyncio.get_event_loop()
                    loop.run_in_executor(None, handle_message, channel_id, channel_name, username, message, file_ids)

        except Exception as e:
            print(f"⚠️ [{CFG['agent_name']}] Error: {e}, reconnecting in 3s...", flush=True)
            await asyncio.sleep(3)


def main():
    global CFG

    parser = argparse.ArgumentParser(description="JOYA — Mattermost Listener")
    parser.add_argument("--agent", default=os.environ.get("AGENT_NAME", ""),
                        help="Agent name (or set AGENT_NAME env)")
    parser.add_argument("--joy-root", default="",
                        help="JOYA root (or set JOY_ROOT env)")
    args = parser.parse_args()

    if args.joy_root:
        os.environ["JOY_ROOT"] = args.joy_root

    agent_name = args.agent
    if not agent_name:
        print("❌ Agent name required. Use --agent <name> or set AGENT_NAME env.")
        sys.exit(1)

    joy_root = find_joy_root()
    CFG = load_config(joy_root, agent_name)

    print(f"🚀 MM Listener [{agent_name}] (PID {os.getpid()})", flush=True)
    print(f"   JOY_ROOT: {joy_root}", flush=True)
    print(f"   MM URL:   {CFG['mm_url']}", flush=True)
    print(f"   Bot ID:   {CFG['my_bot_user_id']}", flush=True)
    print(f"   Channels: {CFG['channels']}", flush=True)

    asyncio.run(listen())


if __name__ == "__main__":
    main()
