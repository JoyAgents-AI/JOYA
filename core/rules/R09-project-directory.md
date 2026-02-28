# R9. Project Registration

Every project the team works on must be registered in `$JOYA_MY/shared/projects/`.

## Registration

Create a directory under `shared/projects/<project-name>/` with a `README.md` that contains:

- Project name and one-line description
- Repository URL and default branch
- Clone command
- Loading entry point (path to the project's own onboarding doc, e.g. `docs/AGENT_INIT.md`)

## Principles

- **Minimal footprint**: `shared/projects/` holds only the entry point — no duplicated docs, no assets, no code.
- **Project owns its docs**: Detailed documentation (architecture, API, conventions, ADRs) lives in the project's own repository structure. The framework does not prescribe a specific layout.
- **Knowledge stays where it belongs**: Project lessons go in agent memory (`memory/`) or `shared/knowledge/`. Cross-project knowledge goes in `shared/knowledge/`.

## Example

```
$JOYA_MY/shared/projects/
  my-app/
    README.md          ← "repo: …, entry: docs/AGENT_INIT.md"

~/Code/my-app/         ← project repo (cloned)
  docs/
    AGENT_INIT.md      ← project's own loading chain
    ...                ← project decides its own structure
```
