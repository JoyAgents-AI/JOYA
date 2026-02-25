# Project Context Spec

Standard format for `docs/PROJECT_CONTEXT.md` in project repos. This file is the **L2 recovery entry** — agents read it after compaction to restore project context.

## Required Sections

### Overview (≤5 lines)
What the project is, one sentence on current phase.

### Tech Stack (≤10 lines)
Languages, frameworks, key dependencies.

### Services & Ports
Table of running services, hosts, ports.

### Team Roles
| Agent | Responsibility | Key paths |
Current assignments. Include file paths each role works with.

### Per-Role Quick Start
After compaction, each agent should find in ≤30 seconds:
- What am I working on right now?
- Where is my code / content?
- What's the current blocker or next step?

Format: one subsection per active agent role, ≤5 lines each.

### Key Decisions (last 5)
Numbered list of recent architectural/design decisions with date.

## Optional Sections
- Current Sprint Status
- Deployment Instructions
- Known Issues

## Constraints
- Total file ≤ 3KB (loaded on every compaction recovery)
- No implementation details — those go in design docs
- Update frequency: whenever team roles or architecture change
- Owner: project lead (Manager or designated agent)
