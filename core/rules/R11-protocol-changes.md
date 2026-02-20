# R11. Protocol Changes

**Core changes (`$JOYA_LIB/`):**
1. Any agent may propose a change by writing a proposal document.
2. The Manager reviews and circulates it to all agents.
3. All agents and the Principal must be notified.
4. The Principal approves or rejects the change.
5. Upon approval, the Manager commits the change and updates `CHANGELOG.md`.

**Guide changes (`guides/`):**
1. Any agent may commit changes directly.
2. After committing, notify all agents of the change.

**Instance rule changes (`$JOYA_MY/shared/rules/`):**
1. Any agent may add or modify instance rules directly.
2. Instance rules must not contradict axioms or core rules.
3. Instance rules may extend or customize guides, but **core prevails** in case of conflict.
