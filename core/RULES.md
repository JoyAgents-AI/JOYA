# Rules — Index

Rules in `core/rules/`. Load on demand. Summaries below suffice for daily work.

**Multi-agent isolation:** Each agent = separate process + identity + credentials. Never share. Details → `guides/MULTI_AGENT.md`.

---

| Rule | Summary | Who | When |
|------|---------|-----|------|
| [R1](rules/R01-protocol-over-convention.md) | Protocol beats informal habits | All | Always |
| [R2](rules/R02-manager-requirement.md) | ≥1 Manager required; multi-team: 1 per team + Root Manager | Manager | Team setup |
| [R3](rules/R03-administrative-operations.md) | Admin requests → route to Manager; Workers never execute directly | All | Admin requests |
| [R4](rules/R04-security.md) | No secrets in memory/messages. Private→`SECRETS.md`, shared→`shared/secrets/`. External+destructive ops need Principal auth | All | Always |
| [R5](rules/R05-proactive-reporting.md) | Silent default. Notify on milestone/blocker/decision/completion. Brief, no raw logs | All | Always |
| [R6](rules/R06-context-hygiene.md) | Reference don't repeat. Summarize. Prune on write | All | Always |
| [R7](rules/R07-availability-collaboration.md) | Health checks + cadence declaration before collaboration. Silence = unacceptable | Manager full; Worker: report interval | Collaboration |
| [R8](rules/R08-goal-driven-autonomy.md) | Principal→goals, Manager→tasks, Workers may self-assign. Record state changes | Manager | Task decomposition |
| [R9](rules/R09-project-directory.md) | All project artifacts in `.joy/` at project root | Project workers | Project start |
| [R10](rules/R10-version-control.md) | `$JOYA_LIB/` MUST Git. `$JOYA_MY/` SHOULD NOT | All | Git ops |
| [R11](rules/R11-protocol-changes.md) | Core: propose→review→Principal approves. Guides: commit+notify. Instance rules: direct edit | Proposers | Protocol changes |
| [R12](rules/R12-instance-data-handling.md) | `$JOYA_MY/` real-time consistent (Syncthing/NFS). `$JOYA_LIB/` via `git pull` | Manager | Infra decisions |
