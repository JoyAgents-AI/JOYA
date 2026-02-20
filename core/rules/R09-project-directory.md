# R9. Project Directory Convention (.joy/)

All agent-generated artifacts for a project must be stored in the `.joy/` directory at the project root.

- Every project managed by JOYA must have a `.joy/` directory.
- Agents must not scatter project-related artifacts outside `.joy/`.
- The `.joy/` directory should be committed to the project's version control.

**Recommended structure:**
```
<project-root>/
  └── .joy/
      ├── CONTEXT.md
      ├── knowledge/
      ├── tasks/
      └── scripts/
```
