# Engineering Guide

Engineering practices for code-based projects under JOYA.

Applies to projects with `type: engineering` or `mixed`. For project management (tasks, milestones, lifecycle), see `PROJECT_MANAGEMENT.md`.

---

## Principles

1. **Use version control.** All engineering projects must use Git (or equivalent). Uncommitted work is invisible work — violates Axiom A1.

2. **Make changes reviewable.** Use pull requests or an equivalent review mechanism. Cross-review between workers; Manager holds final merge authority (R3).

3. **Branch strategy is a project decision.** The protocol doesn't prescribe a branching model. Common patterns: `main` + feature branches, trunk-based, gitflow. Choose what fits the project and document it in `.joy/CONTEXT.md`.

4. **Commit with intent.** Use conventional commit messages (`feat:`, `fix:`, `docs:`, etc.) and reference task IDs for traceability. Keep commits atomic and meaningful.

5. **Test and automate.** Testing and CI are recommended. The level of coverage and automation is a project-level decision — define expectations in `.joy/CONTEXT.md`.

6. **Clean up after merge.** Delete feature branches, close linked tasks, and keep `main` deployable.

---

## Task ↔ Code Traceability

```
Task (PM)  →  Branch (Git)  →  PR (Review)  →  Merge (Done)
```

Use task IDs in branch names and commit messages to connect PM tracking to code history.

---

## Decision Records (ADR)

Use Architecture Decision Records to document significant engineering decisions.

### When to write an ADR

- Technology or framework choices
- Architecture changes (new service, database switch, API redesign)
- Convention changes (branching model, testing strategy)
- Any decision where agents disagree and need resolution

### Format

Store ADRs in `.joy/decisions/NNNN-<title>.md`:

```markdown
# NNNN. <Title>

**Status:** proposed | accepted | rejected | superseded by NNNN
**Date:** YYYY-MM-DD
**Participants:** <who was involved>

## Context
What is the problem or decision to be made?

## Options
| Option | Pros | Cons |
|--------|------|------|
| A | ... | ... |
| B | ... | ... |

## Decision
What was chosen, and why.

## Consequences
What changes as a result.
```

### Process

1. Any agent proposes by creating an ADR with status `proposed`
2. Team discusses (one round of positions + rationale)
3. If consensus → status `accepted`
4. If no consensus → Principal decides → status `accepted` with note
5. ADR is immutable once accepted (supersede with a new ADR, don't edit)

---

## Instance Responsibility

The protocol defines the workflow. The instance configures:

- Branch protection rules and required approvals
- Review SLA (response time)
- CI/CD integration
- Hosting platform (GitHub, Gitea, GitLab, etc.)
- Webhook notifications

These belong in `$JOYA_MY/shared/rules/`, not in protocol.

---

## Project Conventions

Each project should document its own engineering conventions in `.joy/CONTEXT.md`:

- Branching model and naming scheme
- Code style and linting rules
- Test requirements and coverage expectations
- Deployment process
- Git identity configuration for agents
