# Contributing to JOYA

Thanks for your interest in contributing to JOYA! This guide explains the expected workflow for code and documentation contributions.

## 1) Fork and Clone

1. Fork this repository to your own GitHub account.
2. Clone your fork:

```bash
git clone https://github.com/<your-username>/joy-agents.git
cd joy-agents
```

3. Add upstream remote:

```bash
git remote add upstream https://github.com/<upstream-org>/joy-agents.git
```

4. Keep your branch updated:

```bash
git fetch upstream
git checkout main
git rebase upstream/main
```

## 2) Development Requirements

Minimum local environment:

- **Node.js**: 20+ (22 recommended)
- **bash**: 4+
- **Git**

Optional but useful:

- Python 3 (for helper scripts)
- `jq` (for JSON-heavy CLI/API workflows)

Quick check:

```bash
node -v
bash --version
git --version
```

## 3) Branch and PR Workflow

1. Create a feature branch from `main`:

```bash
git checkout -b feature/<short-topic>
```

2. Make focused changes (small, reviewable commits).
3. Run relevant checks/scripts locally.
4. Push branch to your fork and open a Pull Request.

### PR expectations

- Clear title and summary
- What changed and why
- Any backward compatibility impact
- Linked issues/tasks (if applicable)
- Screenshots/examples for docs/UI changes (if applicable)

## 4) Commit Message Convention

Use concise, scoped commit messages. Recommended format:

```text
<type>(<scope>): <summary>
```

Examples:

- `docs(core): clarify protocol precedence`
- `feat(toolkit): add provisioning script flags`
- `fix(guides): correct broken deployment link`

Suggested types: `feat`, `fix`, `docs`, `refactor`, `chore`, `test`.

## 5) Documentation Contributions

Docs are first-class contributions.

Please follow these rules:

- Keep language clear and actionable.
- Prefer short sections + concrete examples.
- Use relative links that work in-repo.
- If you add or rename docs, update any index/README links.
- Keep protocol boundaries clear:
  - `$JOYA_LIB/` = reusable governance and guidance
  - `$JOYA_MY/` = deployment-specific runtime data

For translation or localization updates, keep source and translated docs aligned where possible, and note known gaps in PR description.

## 6) Scope and Safety

Before submitting:

- Remove private/internal IPs, usernames, secrets, or environment-specific paths.
- Do not commit credentials, tokens, or private keys.
- Ensure examples use placeholders (e.g., `<host>`, `<token>`).

## 7) Need Help?

If anything is unclear, open an issue or draft PR and ask for guidance early.

Thanks for helping improve JOYA.
