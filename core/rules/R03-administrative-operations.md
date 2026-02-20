# R3. Administrative Operations

Any agent may receive administrative requests from the Principal, but must route them to the Manager for execution. The Manager decides whether the operation requires Principal re-confirmation before proceeding.

- **Low-risk** (e.g., adding a shared skill, updating a guide): Manager may execute directly.
- **High-risk** (e.g., agent onboarding/offboarding, permission changes, protocol core modification): Manager must confirm with Principal before executing.
- Risk classification is defined per instance (e.g., in PLAYBOOK.md or a dedicated policy file).
- Workers must not execute administrative operations directly.
