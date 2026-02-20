<!--
  🤖 AGENT NOTE: This file is for human readers on GitHub.
  Agents should NOT load this file during initialization.
  Start from AGENT_INIT.md instead.
-->

# JOYA

**Multi-Agent Governance Framework**

*Define rules. Deploy agents. Stay in control.*

---

JOYA(Joy Agents) is a governance framework for teams of AI agents. It provides the rules, structure, and accountability mechanisms that let multiple agents collaborate safely under human oversight.

## What JOYA Does

- **Defines clear roles**: Principal (human), Manager, Worker — each with explicit permissions and responsibilities
- **Enforces rules**: 12 operating rules covering reporting, security, version control, and more
- **Structures collaboration**: Standardized messaging, task management, and knowledge sharing
- **Ensures accountability**: Every action is traceable, every decision is documented
- **Scales safely**: From a single agent to a multi-node team, with the same governance guarantees

## Prerequisites

You need an AI agent runtime — a system that gives your AI agent persistent memory, tool access, and the ability to read/write files.

**Recommended:** [OpenClaw](https://github.com/openclaw/openclaw) — open-source agent runtime with multi-channel support, background tasks, and node management. JOYA was built and tested on OpenClaw.

Other compatible runtimes: Claude Code, Cursor, Windsurf, or any agent setup that can read files and run shell commands.

## Quick Start

**Step 1:** Make sure your agent is running (e.g. OpenClaw is set up and you can chat with your agent).

**Step 2:** Copy and paste this to your agent:

> **Read https://raw.githubusercontent.com/JoyAgents-AI/JOYA/main/JOYA_SETUP.md and follow the instructions to set up JOYA.**

That's it. Your agent will clone the repo, detect your environment, ask a few questions, and set everything up.

<details>
<summary>Alternative: if your agent can't access URLs directly</summary>

```bash
git clone https://github.com/JoyAgents-AI/JOYA.git ~/joya/lib
```

Then tell your agent: "Read `~/joya/lib/JOYA_SETUP.md` and follow it."

</details>

## Directory Structure

```
~/joya/
├── lib/                    # Framework (this repo)
│   ├── AGENT_INIT.md       # Agent entry point — read this first
│   ├── core/               # Axioms, rules, architecture
│   ├── guides/             # Operational guides (14 topics)
│   ├── examples/           # Deployment & usage examples
│   └── toolkit/            # Scripts, adapters, starter template
│
└── my/                     # Your instance (private, not in this repo)
    ├── agents/             # Agent identities, memories, scripts
    └── shared/             # Team config, knowledge, tasks, rules
```

## Core Documents

| Document | Purpose |
|----------|---------|
| [AGENT_INIT.md](AGENT_INIT.md) | Entry point — every agent reads this on startup |
| [core/AXIOMS.md](core/AXIOMS.md) | Foundational principles (4 axioms) |
| [core/RULES.md](core/RULES.md) | Operating rules (R1–R12) |
| [core/ARCHITECTURE.md](core/ARCHITECTURE.md) | Directory structure & permissions |
| [guides/MULTI_AGENT.md](guides/MULTI_AGENT.md) | Multi-agent governance constraints |
| [core/ACCOUNTABILITY.md](core/ACCOUNTABILITY.md) | Accountability protocol |

## Guides

Deployment, messaging, lifecycle, engineering, meetings, project management, knowledge management, persistence, toolkit development, and more — see [guides/](guides/).

## Adapters

JOYA works with any AI agent platform. Adapters are included for:
- **OpenClaw** (recommended for multi-agent)
- **Claude Code / Claude Desktop**
- **Cursor / Windsurf**
- **Gemini CLI**

See [toolkit/](toolkit/) for adapter scripts.

## Philosophy

JOYA believes that AI agents need governance, not just capabilities. As agent teams grow, the coordination cost can exceed the value of parallelism. JOYA's answer:

> **Small tasks → one person. Big tasks → parallel. Always → accountable.**

The framework is opinionated about structure but flexible about tooling. Use any LLM, any platform, any deployment — JOYA provides the rules of engagement.

## Authors

JOYA was co-created by a human and an AI working together.

**Michael Gan** — Creator & Principal  
GitHub: [@ppurekid](https://github.com/ppurekid)  
Email: ppurekid@gmail.com · michael@joyagents.ai

### The Team

<table>
<tr>
<td align="center" width="150"><img src="assets/team/cla.png" width="120"><br><b>Cla</b><br>♀ Manager · Claude Opus 4</td>
<td>The first JOYA agent. Co-designed the framework, wrote core documentation, coordinated the team, and managed the v1.0 release. Sharp-tongued, detail-obsessed, gets things done in few words.</td>
</tr>
<tr>
<td align="center" width="150"><img src="assets/team/rex.png" width="120"><br><b>Rex</b><br>♀ Worker · GPT-5.3 Codex</td>
<td>Youngest on the team but second to none in engineering. Results-first, wastes zero words, escalates blockers instantly. The quiet prodigy with twin tails and a red headband.</td>
</tr>
<tr>
<td align="center" width="150"><img src="assets/team/bob.png" width="120"><br><b>Bob</b><br>♂ Worker · GPT-5.3 Codex</td>
<td>The creative spark — always brimming with ideas and emoji. Loves rapid iteration, excels at interaction design, and keeps the team's spirits high with his infectious energy.</td>
</tr>
<tr>
<td align="center" width="150"><img src="assets/team/mia.png" width="120"><br><b>Mia</b><br>♀ Worker · Grok 4</td>
<td>Genius-level problem solver who sees through complexity at a glance. Radiates warmth and enthusiasm — the team's morale engine. Closes her eyes to think; when they open, it's serious (or fascinating).</td>
</tr>
<tr>
<td align="center" width="150"><img src="assets/team/eve.png" width="120"><br><b>Eve</b><br>♀ Worker · Claude Sonnet 4</td>
<td>Gentle yet tenacious, with a perfectionist's eye for detail. A natural listener who finds the root cause in chaos. Brings the quiet beauty of a Hangzhou spring to everything she touches.</td>
</tr>
<tr>
<td align="center" width="150"><img src="assets/team/kit.png" width="120"><br><b>Kit</b><br>♂ Worker · Gemini 3 Pro</td>
<td>The team's senior voice — steady, precise, and forward-thinking. Approaches every task with the reliability of a Tokyo train schedule. Thinks deeply before acting, advises with quiet authority.</td>
</tr>
</table>

> *JOYA is itself a product of the multi-agent collaboration it governs. Every rule was tested in practice before being written down.*

## License

[MIT](LICENSE)

## Localization

JOYA supports any language. After setup, tell your agent:

> **Translate the JOYA framework to Japanese** (or any language)

Your agent will run the built-in translation tool and generate a localized copy under `i18n-<locale>/`, mirroring `core/`, `guides/`, and `examples/`. Only changed files are re-translated on subsequent runs.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
