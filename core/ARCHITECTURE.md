# Architecture — Index

Workspace structure, roles, and permissions for JOYA deployments.

## Design Philosophy

JOYA separates **framework** (`$JOYA_LIB/`) from **instance** (`$JOYA_MY/`).

- `$JOYA_LIB/` — Governance layer: `core/` (mandatory), `guides/` (defaults), `examples/`, `toolkit/`
- `$JOYA_MY/` — Deployment-specific: agent identities, config, rules, working data

**Precedence:** Framework Core (Axioms > Rules) > Guides > Instance Rules > Agent Config

**Index + Lazy Load:** Every large document and directory uses index-first design. The index is small and always loaded; details live in sub-files, loaded only when the scenario arises. This minimizes per-session context cost while keeping all knowledge reachable. Pattern: `RULES.md` → `rules/`, `ARCHITECTURE.md` → `arch/`, `INFRASTRUCTURE.md` → `infra/`, `knowledge/INDEX.md`, `archive/INDEX.md`.

**Resource Scheduling:** Model and thinking level are runtime costs that should match task complexity. Agents SHOULD dynamically adjust both dimensions — use lighter models and lower thinking for simple tasks, heavier models and deeper thinking for complex ones. Each agent defines a **primary model** (full capability) and a **downgrade model** (cost-efficient), with clear escalation/de-escalation criteria. See `CONTEXT_OPTIMIZATION.md` Pattern G for design guidance; instances define concrete mappings in `$JOYA_MY/shared/rules/` or agent IDENTITY files.

Instance rules may extend or customize guides, but may never contradict protocol.

---

## Section Index

| File | Content | Load When |
|------|---------|-----------|
| `arch/SHARED_GOVERNANCE.md` | CHANGELOG audit, INDEX.md conventions, archival rules | **When writing to shared/** |
| `arch/DIRECTORY.md` | Full directory structure + environment variables | When looking up directory structure |
| `arch/PERMISSIONS.md` | Permission matrix + extension mechanism | When resolving permission issues |
| `arch/ROLES.md` | Manager / Worker role definitions | When resolving role issues |
| `arch/DEPLOYMENT.md` | Multi-machine deployment: Syncthing, NFS, Git | When troubleshooting deployment/sync |
| `arch/COMMUNICATION.md` | Communication capability requirements | When adapting communication |
| `arch/IDENTITY.md` | Identity and memory portability | When handling identity/memory issues |
| `arch/SKILLS.md` | Three-layer tool resolution priority | When resolving tool/skill issues |
| `arch/PROJECTS.md` | Project management capabilities | When starting a project |
| `arch/MEMORY_LIFECYCLE.md` | Memory lifecycle: three-tier decay + GC rules | When writing memory / running GC |
| `arch/CUSTOMIZATION.md` | Instance customization mechanism | When customizing rules |
