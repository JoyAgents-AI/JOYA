# Directory Map

## Recommended Layout

```
~/joya/
├── lib/    # Framework ($JOYA_LIB) — git clone of the JOYA repo
└── my/     # Instance ($JOYA_MY) — private, not in framework repo
```

**Environment variables:** `JOYA_LIB` and `JOYA_MY`

**Resolution priority:** CLI argument > environment variable > default `~/joya/lib` and `~/joya/my`

## Structure

```
joya/
├── lib/                             # $JOYA_LIB — Governance layer (framework)
│   ├── AGENT_INIT.md                # Agent entry point
│   ├── core/                        # Mandatory (changes require Principal approval)
│   │   ├── AXIOMS.md, RULES.md, ARCHITECTURE.md, ACCOUNTABILITY.md, CHANGELOG.md
│   ├── guides/                      # How-to docs (any agent may update + notify)
│   │   ├── COMMUNICATION.md, ENGINEERING.md, LIFECYCLE.md, TOOLKIT.md, ...
│   ├── examples/                    # Reference implementations (informational)
│   └── toolkit/                     # Official tools (read-only for users)
│       ├── adapters/, scripts/, skills/, starter/
└── my/                              # $JOYA_MY — Deployment-specific (user-managed)
    ├── agents/
    │   └── <name>/                  # Per-agent: IDENTITY.md, MEMORY.md, toolkit/, memory/
    └── shared/
        ├── core/                # PRINCIPAL.md, INFRASTRUCTURE.md, PLAYBOOK.md
        ├── agents/              # ROSTER.md, DIRECTORY.json (team-wide, all nodes)
        ├── templates/           # Shared traits inherited by all agents (SHARED.md, IDENTITY_TEMPLATE.md)
        ├── secrets/             # Team-shared credentials
        │   ├── SECRETS.md       # Text credentials (tokens, passwords)
        │   └── credentials/     # Non-text credentials (certs, keys, service accounts)
        ├── rules/               # Instance-specific rules (may extend/override guides)
        ├── toolkit/             # Team-shared skills, scripts, adapters (may extend lib/toolkit/)
        ├── knowledge/           # Active team knowledge base (INDEX.md required)
        ├── archive/             # Centralized archive (INDEX.md + YYYY-MM/ subdirs)
        ├── projects/, iterations/, tasks/, meetings/, scores/
        └── dropzone/            # Agent file exchange area (naming: <agent>-<topic>.<ext>)
```
