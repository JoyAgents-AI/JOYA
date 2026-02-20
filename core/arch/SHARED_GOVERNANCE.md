# shared/ Governance

`shared/` content is a context tax on every agent. Quality control here has multiplied ROI.

## CHANGELOG

All changes to `shared/` MUST be logged in `shared/CHANGELOG.md`:

```
| Date | Agent | Action | File | Summary | Self-check | Audit |
```

- **Self-check**: Writer validates against the instance's write quality rules (e.g. `DOC_CHECKLIST.md`), marks ✅ after passing.
- **Audit**: Manager reviews content quality, marks ✅ after approval.
- Unlogged changes to `shared/` are a protocol violation.

Instances define specific quality checks in `$JOYA_MY/shared/rules/`. The framework mandates the mechanism (CHANGELOG + dual flags), not the check items.

## INDEX.md Convention

Directories with accumulating content MUST have an `INDEX.md`:
- `knowledge/INDEX.md` — active knowledge base entries
- `archive/INDEX.md` — archived items with origin and reason

Adding a file without updating its directory's INDEX.md is a violation.

## Archive Rules

- **Trigger**: completed / superseded / >30 days unreferenced
- **Action**: move to `archive/YYYY-MM/`, update `archive/INDEX.md`
- **Cleanup**: quarterly, entries >3 months with no references → permanent delete
