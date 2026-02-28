# File-Based Project Management

A reference implementation of [PROJECT_MANAGEMENT.md](../guides/PROJECT_MANAGEMENT.md) using plain files. Use this when the instance has no external PM tool.

---

## 1. Project Registration

Register every project in the instance registry:

```
$JOYA_MY/shared/projects/
  <project-name>/
    README.md          # Repo URL, clone command, loading entry point
```

The README answers one question: **where is the project and how do I start?**

**Non-code projects** without a repo may keep their docs directly in the `shared/projects/<name>/` directory.

---

## 2. Project Documentation

The project's own documentation lives in its repo. Structure is up to the project.

**Recommended minimum:**
- A loading entry point (e.g. `docs/AGENT_INIT.md` or `README.md`) that tells agents what to read
- Engineering conventions (branching, commit format, deployment)
- Architecture overview
- ADR directory for significant decisions

**Example:**
```
<project-repo>/
  docs/
    AGENT_INIT.md      # Loading entry point for agents
    TEAM_ROLES.md      # Who does what
    ops/
      GIT-WORKFLOW.md
      DEPLOYMENT.md
    design/
      ARCHITECTURE.md
      adr/
        ADR-001-*.md
```

---

## 3. Field Tables

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

## 4. Initialization

### New Project

1. Create the project repo (or directory)
2. Write initial docs (at minimum, a loading entry point)
3. Register in `$JOYA_MY/shared/projects/<name>/README.md`
4. **Git check** (engineering/mixed only): Initialize Git if needed
5. Notify team

### Import Existing Project

1. Audit codebase/materials
2. Write a loading entry point in the project docs
3. Register in `$JOYA_MY/shared/projects/<name>/README.md`
4. **Git check** (same as above)
5. Import tasks into the chosen PM tool (or project docs)

---

## 5. Iteration Directory

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
4. **Learn**: Durable lessons go to agent memory or `$JOYA_MY/shared/knowledge/` (cross-project). See `KNOWLEDGE.md`.

---

## 6. Non-Engineering Project Types

| Project Type | Deliverables | Tracking | Review |
|-------------|-------------|----------|--------|
| engineering | Code, PRs, releases | Git + PM tool or task files | Code review (`ENGINEERING.md`) |
| research | Reports, analyses, findings | PM tool or task files | Manager review |
| design | Specs, mockups, prototypes | PM tool or task files | Team feedback |
| ops | Configs, deployments, docs | PM tool or task files | Checklist verify |
| mixed | Varies | PM tool or task files | Per deliverable type |
