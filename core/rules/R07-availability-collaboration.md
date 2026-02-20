# R7. Availability & Collaboration Communication

The Manager must ensure agent availability and maintain structured communication during active collaboration.

## 7a. Health Checks

All agents must respond to health checks within the instance-defined timeout.

- Health check mechanism and timeout thresholds are instance-level decisions.
- When an agent is unresponsive, the Manager reassigns its pending tasks.
- Agent removal or replacement requires Principal approval.

## 7b. Collaboration Communication Cadence (Required per Collaboration)

Every time the Manager assigns tasks to agents, a **collaboration communication cadence** must be declared before work begins. A collaboration without a declared cadence must not start.

The cadence defines two intervals:

1. **Manager check interval** — how often the Manager checks agent health and task progress.
2. **Worker report interval** — how often workers proactively report progress.

The instance defines available cadence tiers (e.g., fast/normal/slow) in its Playbook. The Manager selects a tier per collaboration based on urgency and complexity.

**Manager check (7b):**
- Each check verifies: (1) agent process is alive, (2) task is progressing, (3) no silent failures.
- If an agent has not reported progress within 2× the report interval, the Manager must actively probe and escalate if unresponsive.
- The Manager should use automated scheduling (cron, timers) rather than relying on memory across sessions.
- Check results that reveal issues must be reported to the Principal.

**Worker report (7c):**
- Each report should include: current status, what was done, what's next, any blockers.
- The report channel is the task's designated discussion channel (or the default team channel).
- Silence is not acceptable — if a worker has nothing new, it must still report "still working, no blockers" at the interval.
- After completing a task or encountering a blocker, report immediately (do not wait for the next interval).

**Declaration format:** When assigning tasks, the Manager must state the cadence tier so all participants know the rhythm. Workers must acknowledge and comply.
