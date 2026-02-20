# Project Management Guide

How to define, manage, and close projects under JOYA.

For engineering-specific practices (Git, branching, PR, code review), see `ENGINEERING.md`.

---

## 1. Project Model

A **Project** is any sustained effort with a goal, a team, and deliverables — not limited to code.

**Core entities:**
- **Project** — has a name, type, status, goal, owner, and team
- **Milestone** — a time-boxed phase with a goal and success criteria
- **Task** — an atomic unit of work with a status, assignee, and deliverable

**Project types:** engineering, research, design, ops, mixed.

**Project roles:** lead, contributor, reviewer. The Manager (R3) retains final authority.

---

## 2. Lifecycle & States

**Project lifecycle:**
`draft → active → paused → completed → archived`

- **draft**: created, awaiting Principal approval
- **active**: approved, team assigned, work in progress
- **paused**: blocked or deprioritized; in-progress tasks return to backlog
- **completed**: all milestones met or Principal declares done; knowledge extracted
- **archived**: preserved, no active work

**Task workflow:**
`backlog → todo → in_progress → review → done`

Exception states: `blocked`, `rejected`, `superseded`.

---

## 3. Decomposition

```
Goal → Epic (large, spans milestones) → Task (atomic, ≤1 iteration) → Subtask (optional)
```

Each task has a clear **deliverable** — what "done" looks like.

---

## 4. The `.joy/` Directory (R9)

Every project MUST have a `.joy/` directory in its root. This is the project's structured home for metadata, context, knowledge, and task tracking.

Non-code projects without a repo may place `.joy/` under the instance project registry.

---

## 5. Task Rules

- Manager assigns, or worker self-assigns with Manager confirmation
- One assignee per task
- Confirm receipt before starting (A2)
- Unique ID per task; format decided by instance
- `blocked` must describe what's needed to unblock
- Only assignee transitions own task state (Manager may reassign/cancel)
- Update status promptly — stale status is invisible work (A1)
- Engineering tasks: code review per `ENGINEERING.md`

---

## 6. Iteration Cycles

Iterations are time-boxed: **plan → execute → review → learn**.

The instance decides cadence (daily, weekly, bi-weekly). The Manager maintains the rhythm. Durable lessons go to `.joy/knowledge/` or `$JOYA_MY/shared/knowledge/`.

---

## 7. Instance Responsibility

The protocol defines **what** to track. The instance decides **how**:

- PM tool (external board, file-based, etc.)
- Task ID format and tracking mechanism
- Iteration cadence and review SLA
- Notification setup

These are configured in `$JOYA_MY/shared/rules/`, not in protocol.

For a file-based reference implementation, see [`examples/pm-file-based.md`](../examples/pm-file-based.md).

---

## 8. Agent Join Order

When joining a project, read in order:
META.md → PATHS.md → PROJECT.md → CONTEXT.md → knowledge → tasks.

---

## 9. Cross-Project Coordination

- Manager maintains awareness of all active projects
- Resource conflicts escalated to Principal
- Shared lessons extracted to `$JOYA_MY/shared/knowledge/`
- Inter-project dependencies tracked as blocked tasks with references
