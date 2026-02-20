# File-Based Project Management

A reference implementation of [PROJECT_MANAGEMENT.md](../guides/PROJECT_MANAGEMENT.md) using plain files. Use this when the instance has no external PM tool.

---

## 1. Directory Structure

**In project root (`.joy/`):**
```
<project-root>/
  └── .joy/
      ├── PROJECT.md       # Required: name, type, status, goal, team
      ├── CONTEXT.md       # Required: architecture, conventions, current state
      ├── knowledge/       # Lessons, patterns, decisions
      ├── tasks/           # Local task tracking
      └── scripts/         # Project-specific agent tools
```

**In instance registry:**
```
$JOYA_MY/shared/projects/<name>/
  ├── META.md     # name, type, status, created
  └── PATHS.md    # root path, joy dir, repo, board URL
```

**Non-code projects:** If no Git repo exists, `.joy/` lives under `$JOYA_MY/shared/projects/<name>/joy/`.

---

## 2. Field Tables

### Project

| Field | Required | Description |
|-------|----------|-------------|
| name | ✓ | Human-readable project name |
| type | ✓ | `engineering` / `research` / `design` / `ops` / `mixed` |
| status | ✓ | Lifecycle state |
| goal | ✓ | What the Principal wants to achieve |
| owner | ✓ | Manager or delegated lead agent |
| team | ✓ | Assigned agents and roles |
| repo | | Git remote URL (if applicable) |
| board | | External PM tool URL (instance-specific) |

### Task

| Field | Required | Description |
|-------|----------|-------------|
| id | ✓ | Unique identifier (format defined by instance) |
| title | ✓ | Short description |
| status | ✓ | `backlog` → `todo` → `in_progress` → `review` → `done` |
| assignee | | Agent responsible |
| priority | | `critical` / `high` / `normal` / `low` |
| type | | `feature` / `bug` / `research` / `doc` / `infra` / `design` |
| parent | | Parent task or epic (for decomposition) |
| milestone | | Which milestone this belongs to |
| deliverable | | Expected output (PR, document, report, artifact) |
| due | | Deadline (optional) |

### Milestone

| Field | Required | Description |
|-------|----------|-------------|
| name | ✓ | e.g. `v0.1-mvp`, `2026-W08`, `Phase 1` |
| goal | ✓ | What success looks like |
| start | ✓ | Start date |
| end | ✓ | Target end date |
| tasks | | Task list for this milestone |

---

## 3. Initialization

### New Project

1. Create `.joy/` directory
2. Write `PROJECT.md` and `CONTEXT.md`
3. Register in `$JOYA_MY/shared/projects/<name>/`
4. **Git check** (engineering/mixed only): If no `.git/` exists, recommend initializing before development
5. Notify team

### Import Existing Project

1. Audit codebase/materials
2. Create `.joy/` and write `CONTEXT.md`
3. **Git check** (same as above)
4. Import tasks into `.joy/tasks/BACKLOG.md`
5. Log decisions in `.joy/knowledge/decisions.md`
6. Register in `$JOYA_MY/shared/projects/`

---

## 4. Iteration Directory

```
$JOYA_MY/shared/iterations/YYYY-WXX/
  ├── PLAN.md      # Goals, task list, carry-overs, risks
  ├── REVIEW.md    # Retrospective: what worked, what didn't, action items
  └── METRICS.md   # Completion rate, carry-over rate, blocker count (optional)
```

### Flow

1. **Plan**: Manager creates `PLAN.md` with iteration goal (from Principal's objectives), task assignments, and carry-over items.
2. **Execute**: Workers pick up tasks. Blockers escalated to Manager immediately (R6).
3. **Review**: Manager facilitates retrospective — what worked, what didn't, lessons learned, action items for next iteration.
4. **Learn**: Durable lessons extracted to `.joy/knowledge/` (project) or `$JOYA_MY/shared/knowledge/` (cross-project). See `KNOWLEDGE.md`.

---

## 5. Non-Engineering Project Types

| Project Type | Deliverables | Tracking | Review |
|-------------|-------------|----------|--------|
| engineering | Code, PRs, releases | Git + `.joy/tasks/` | Code review (`ENGINEERING.md`) |
| research | Reports, analyses, findings | `.joy/tasks/` | Manager review |
| design | Specs, mockups, prototypes | `.joy/tasks/` | Team feedback |
| ops | Configs, deployments, docs | `.joy/tasks/` | Checklist verify |
| mixed | Varies | `.joy/tasks/` | Per deliverable type |
