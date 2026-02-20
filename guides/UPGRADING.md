# Upgrading Guide

How to upgrade the JOYA protocol when a new version is released.

---

## Version Scheme

JOYA follows semantic versioning:

- **Major** (v1 → v2): Breaking changes to core axioms or rules. Instance adjustments required.
- **Minor** (v1.0 → v1.1): New rules, guides, or features. Backward compatible.
- **Patch** (v1.0.0 → v1.0.1): Fixes and clarifications. Drop-in safe.

The current version is recorded in `$JOYA_LIB/VERSION` (single-line semver string) and detailed in `core/CHANGELOG.md`.

---

## Upgrade Procedure

### 1. Review the changelog

Read `CHANGELOG.md` for the target version. Note any breaking changes, new rules, or deprecated features.

### 2. Back up current protocol

```bash
cp -r $JOYA_LIB/ protocol.bak/
```

### 3. Update $JOYA_LIB/

Replace `$JOYA_LIB/` with the new version. Methods:

- **Git**: `git pull` or merge from upstream.
- **Manual**: Download and overwrite `$JOYA_LIB/` directory.

### 4. Check instance compatibility

Review your `$JOYA_MY/shared/rules/` overrides and patches:

- Do any reference rules that were renumbered or removed?
- Do any conflict with new rules?

### 5. Run validation

```bash
toolkit/scripts/joy-validate.sh
```

Fix any issues reported.

### 6. Bump `$JOYA_LIB/VERSION`

Update the version string in `$JOYA_LIB/VERSION` to match the new release.

### 7. Notify all agents

Broadcast: "Protocol upgraded to vX.Y.Z. All agents must re-read $JOYA_LIB/."

### 8. Verify rollout

Ask all agents: "Report framework version". Each agent responds with their loaded `$JOYA_LIB/VERSION` value. Confirm all match the expected version. Any mismatch → that agent needs to restart their session or re-read the file.

---

## Breaking Change Policy

- Core axioms will not change without a major version bump.
- Rule renumbering is avoided; deprecated rules are marked rather than removed.
- New rules are appended (not inserted) to minimize reference breakage.
- When a breaking change is unavoidable, a migration section is included in the CHANGELOG.

---

## Instance Override Safety

The override mechanism is designed to survive upgrades:

- `$JOYA_MY/shared/rules/` files reference target paths (`overrides: guides/X.md`).
- If the target file is renamed, the override will stop matching — the validation script flags this.
- If a new core rule conflicts with an instance patch, the validation script flags this.

Upgrades never modify `$JOYA_MY/`. Your data is always safe.

---

## Directory Migration Procedure

Any directory structure change must follow these steps:

1. **Pre-migration:** Compare source and target file counts in full. Confirm nothing is missing before proceeding.
2. **Migration:** Copy or move files. Rename the old path to `.bak` rather than deleting it (`mv old old.bak`).
3. **Reference update:** Update every reference — symlinks, pointer files, scripts, launchd/systemd configs, git hooks.
4. **Per-node verification:** Verify file accessibility on every node individually. Do not verify only on the local machine.
5. **Observation period:** Keep the old path (`.bak`) for 3–7 days. Confirm no remaining dependencies before removal.
6. **Cleanup:** Delete the old path and `.bak`.
