# Knowledge Base Guide

How to accumulate, organize, and use team knowledge for continuous improvement.

---

## Purpose

The knowledge base captures durable insights from project work and iteration retrospectives. It prevents the team from repeating mistakes and preserves proven patterns.

## Two Levels

| Level | Location | Scope |
|-------|----------|-------|
| Project-specific | Project repo docs or `shared/projects/<project>/` | Lessons tied to one project |
| Cross-project | `$JOYA_MY/shared/knowledge/` | Lessons applicable across all projects |

## Directory Structure

```
knowledge/
├── CHANGELOG.md              # What changed, when, by whom
├── lessons.md                # Specific lessons learned (dated)
├── patterns.md               # Proven practices to repeat
├── anti-patterns.md          # Mistakes to avoid
├── decisions.md              # Key architectural/design decisions
├── <active-docs>.md          # Currently maintained reference docs
└── archive/
    └── YYYY-MM/              # Time-based archive for periodic outputs
        ├── research-report.md
        └── evaluation.md
```

### Root vs Archive

| Location | What belongs here | Examples |
|----------|------------------|---------|
| **Root** | Actively maintained, currently valid documents | API references, workflow specs, decision logs |
| **archive/YYYY-MM/** | Time-bound outputs that are complete and unlikely to be updated | Research reports, evaluations, meeting summaries, sprint retrospectives |

**Rule:** When a root document is superseded, move it to `archive/YYYY-MM/` and note the move in `CHANGELOG.md`.

### CHANGELOG.md

A reverse-chronological log of all knowledge base changes. Every addition, archive, or significant update gets an entry:

```markdown
# Knowledge Changelog

## 2026-02-19
- [added] HULY_API.md — Huly REST API reference (Cla)
- [added] archive/2026-02/HULY_TRACKER_REPORT.md — Tracker research (Rex)
- [added] archive/2026-02/HULY_DOCS_CHAT_REPORT.md — Docs+Chat research (Bob)

## 2026-02-15
- [updated] decisions.md — Added DB migration decision (Rex)
- [archived] OLD_DEPLOY_GUIDE.md → archive/2026-02/ — Superseded by new guide
```

**Entry format:** `[action] filename — short description (author)`

Actions: `added`, `updated`, `archived`, `removed`

## Writing Lessons

Each lesson entry should include:

```markdown
### [YYYY-MM-DD] Short title

**Context:** What was happening
**What happened:** What went wrong or right
**Lesson:** The takeaway
**Action:** What we changed as a result
```

## When to Write

- After every iteration retrospective (Manager responsibility)
- After resolving a significant blocker
- After a postmortem (outage, data loss, miscommunication)
- When an agent discovers a better way to do something
- After completing a research task or evaluation

## When to Read

- Before starting a new project (check cross-project knowledge)
- Before starting a task in a domain with existing lessons
- During iteration planning (review recent lessons for improvements)

## Maintenance

- The Manager reviews the knowledge base monthly.
- Outdated or superseded entries are moved to `archive/YYYY-MM/`, not deleted.
- Patterns that are consistently followed may be promoted to instance rules (`$JOYA_MY/shared/rules/`).
- CHANGELOG.md is the quickest way to find recent knowledge activity.
