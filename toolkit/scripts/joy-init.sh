#!/usr/bin/env bash
# joy-init.sh — Register a project in shared/projects/
# Usage:
#   joy-init.sh [--name <project-name>] [--repo <url>] [--branch <branch>] [--entry <path>]
#
# Options:
#   --name <name>      Project name (default: directory name)
#   --repo <url>       Repository URL
#   --branch <branch>  Default branch (default: main)
#   --entry <path>     Loading entry point in repo (default: docs/AGENT_INIT.md)
#
# Environment:
#   JOYA_MY            Path to instance data (required)

set -euo pipefail

# --- Parse arguments ---
PROJECT_NAME=""
REPO_URL=""
BRANCH="main"
ENTRY="docs/AGENT_INIT.md"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      PROJECT_NAME="$2"
      shift 2
      ;;
    --repo)
      REPO_URL="$2"
      shift 2
      ;;
    --branch)
      BRANCH="$2"
      shift 2
      ;;
    --entry)
      ENTRY="$2"
      shift 2
      ;;
    *)
      # Positional: treat as project name if not set
      if [[ -z "$PROJECT_NAME" ]]; then
        PROJECT_NAME="$1"
      fi
      shift
      ;;
  esac
done

if [[ -z "$PROJECT_NAME" ]]; then
  echo "Usage: joy-init.sh --name <project-name> --repo <url> [--branch <branch>] [--entry <path>]"
  exit 1
fi

# --- Resolve JOYA_MY ---
if [[ -z "${JOYA_MY:-}" ]]; then
  echo "❌ JOYA_MY not set. Point it to your instance data directory."
  exit 1
fi

PROJECTS_DIR="$JOYA_MY/shared/projects"
PROJECT_DIR="$PROJECTS_DIR/$PROJECT_NAME"

# --- Check if already registered ---
if [[ -f "$PROJECT_DIR/README.md" ]]; then
  echo "⚠️  Project '$PROJECT_NAME' already registered at $PROJECT_DIR/README.md"
  echo "   Edit it directly or remove it to re-register."
  exit 1
fi

# --- Create registration ---
echo "🎉 Registering project: $PROJECT_NAME"

mkdir -p "$PROJECT_DIR"

cat > "$PROJECT_DIR/README.md" << EOF
# $PROJECT_NAME

- **Repo**: $REPO_URL
- **Branch**: \`$BRANCH\`
- **Clone**: \`git clone $REPO_URL ~/Code/$PROJECT_NAME && cd ~/Code/$PROJECT_NAME && git checkout $BRANCH\`
- **Loading entry point**: \`$ENTRY\`
EOF

# --- Summary ---
echo ""
echo "✅ Registered at: $PROJECT_DIR/README.md"
echo ""
cat "$PROJECT_DIR/README.md"
echo ""
echo "📝 Next steps:"
echo "   1. Review the README.md above"
echo "   2. Ensure the repo has a loading entry point at: $ENTRY"
echo "   3. Update $PROJECTS_DIR/README.md project table"
echo "   4. Notify your agent team"
