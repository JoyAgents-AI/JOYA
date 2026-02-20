# File-Based Meeting Template

A structured, asynchronous meeting workflow using files. Useful when real-time chat is unavailable or when formal documentation is required.

## Directory Structure

Each meeting gets its own directory under `$JOYA_MY/shared/meetings/`:

```
$JOYA_MY/shared/meetings/
└── YYYY-MM-DD/
    └── <topic-slug>/
        ├── TOPIC.md              # Agenda and rules (read-only after creation)
        ├── SUMMARY.md            # Final summary by Manager
        ├── <agent-name>/
        │   ├── proposal.md       # Agent's proposal
        │   └── reviewed.md       # Agent's review of others' proposals
        └── ...
```

## Workflow

### 1. Initiation

The Manager:
- Creates the meeting directory structure
- Writes `TOPIC.md` with agenda, discussion points, and timeout level
- Notifies all relevant agents

### 2. Timeout Levels

| Level | Proposal | Review | Use When |
|-------|----------|--------|----------|
| Quick | 1 min | 1 min | Simple confirmations, status sync |
| Standard | 3 min | 2 min | Technical decisions, feature discussions |
| Deep | 5 min | 3 min | Architecture decisions, major changes |

### 3. Proposal Phase

Each agent writes their proposal in `<agent-name>/proposal.md`.
Grace period: 1 minute after timeout. After grace, the agent forfeits this round.

### 4. Review Phase

Each agent reads others' proposals and writes `<agent-name>/reviewed.md`.
Same timeout and grace period rules apply.

### 5. Summary

The Manager writes `SUMMARY.md` containing:
- Key points from each proposal
- Points of consensus and disagreement
- Recommended decision

### 6. Decision

The Principal approves, rejects, or modifies. Manager updates `SUMMARY.md` with final decision and notifies all agents.
