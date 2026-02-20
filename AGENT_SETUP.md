# JOYA — Agent Onboarding

One-time procedure for a new agent joining an existing instance. After completing these steps, all future sessions go to **Ongoing Operations** (see `AGENT_INIT.md`).

> Looking for instance-level setup? See `JOYA_SETUP.md`.

---

## Step 1: Set up your identity

If `$JOYA_MY/agents/<your-name>/IDENTITY.md` already exists, read it — someone prepared it for you. Check it against the template and fill in any missing sections.

If not, create one using the template. Ask the Principal or Manager to confirm your persona.

Template resolution: `$JOYA_MY/shared/templates/IDENTITY_TEMPLATE.md` → `$JOYA_LIB/guides/IDENTITY_TEMPLATE.md`.

⚠️ IDENTITY.md must **never** contain credentials. Those go in `SECRETS.md`.

## Step 2: Connect runtime (one-time)

Detect your runtime (`~/.openclaw/` → OpenClaw, `~/.claude/` → Claude Code, `.cursor/` → Cursor, `.windsurfrules` → Windsurf, `~/.gemini/` → Gemini CLI).

Ask the Principal or Manager:

> **"I've detected [runtime]. Would you like to connect it to JOYA?"**

If yes, run the matching adapter: `toolkit/scripts/joy-adapter-<runtime>.sh install <your-name> --joy-root <path>`

## Step 3: Verify imported data (one-time)

Review `MEMORY.md` and `IDENTITY.md` — verify imported content looks correct. Add anything the adapter missed.

## Step 4: Read the protocol (one-time deep read)

Read these files fully — this is your first and deepest read:

1. `core/AXIOMS.md` — non-negotiable rules
2. `core/RULES.md` — operating rules
3. `$JOYA_MY/shared/core/PRINCIPAL.md` — who you serve
4. `$JOYA_MY/shared/core/PLAYBOOK.md` — how this team works
5. `$JOYA_MY/shared/core/PREFERENCES.md` — instance preferences
6. `$JOYA_MY/shared/agents/ROSTER.md` — who's on the team
7. `$JOYA_MY/shared/core/INFRASTRUCTURE.md` — services and endpoints

## Step 5: Onboarding Exam

The Manager administers an Onboarding Exam (see `guides/ONBOARDING_EXAM.md`) to verify protocol comprehension. Answer from memory, not by re-reading files. Wrong answers will be corrected on the spot.

On pass, the Manager writes an exam record to your MEMORY.md:
```
Exam: PASS <model-slug> think:<level> v<framework-version>
```
This record unlocks Tiered Loading in future sessions.

## Step 6: Announce yourself (one-time)

Tell the Principal or team you're ready:
- ✅ Identity loaded
- ✅ Runtime connected (or not, if declined)
- ✅ Protocol understood
- ✅ Onboarding exam passed
- Ask: "What would you like me to work on?"

After this → all future sessions go to **Ongoing Operations**.

---

## Disconnecting (if needed)

If you need to leave JOYA or switch to standalone mode:

```bash
toolkit/scripts/joy-adapter-<runtime>.sh uninstall <your-name>
```

This will:
1. Export your latest memories from JOYA
2. Restore your original runtime files from backup
3. Leave JOYA files intact (your identity and memories are preserved)

You can reconnect anytime.
