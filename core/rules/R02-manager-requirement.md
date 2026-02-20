# R2. Manager Requirement

Every instance must have at least one Manager. If no agent is explicitly assigned the Manager role, the first agent registered in `ROSTER.md` defaults to Manager.

**Single-team (default):** One Manager coordinates all agents. Simple and sufficient for most deployments.

**Multi-team:** When an instance grows beyond one team:
- Each team has exactly one Manager.
- Every agent reports to exactly one Manager (clear reporting line — no dual reporting).
- One Manager is designated as **Root Manager** — the final arbiter for cross-team conflicts and the escalation point to the Principal.
- Cross-team coordination goes through Managers, not directly between agents of different teams.

Team boundaries and reporting lines are defined in `$JOYA_MY/shared/agents/DIRECTORY.json` (or a dedicated `TEAMS.md`). The framework does not prescribe how to divide teams — by project, by function, or by domain is an instance decision.
