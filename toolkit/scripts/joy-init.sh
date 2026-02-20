#!/usr/bin/env bash
# joy-init.sh — Initialize .joy/ directory structure in a project
# Usage:
#   joy-init.sh [--name <project-name>] [--existing] [target-dir]
#
# Options:
#   --name <name>    Project name (default: directory name)
#   --existing       Onboarding mode: adds TODO markers for audit
#   target-dir       Project root (default: current directory)

set -euo pipefail

# --- Parse arguments ---
PROJECT_NAME=""
EXISTING=false
TARGET_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      PROJECT_NAME="$2"
      shift 2
      ;;
    --existing)
      EXISTING=true
      shift
      ;;
    *)
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

TARGET_DIR="${TARGET_DIR:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
PROJECT_NAME="${PROJECT_NAME:-$(basename "$TARGET_DIR")}"
JOY_DIR="$TARGET_DIR/.joy"
TODAY=$(date +%Y-%m-%d)

# --- Check if already initialized ---
if [[ -d "$JOY_DIR" ]]; then
  echo "⚠️  .joy/ already exists at $JOY_DIR"
  echo "   Use this directory directly or remove it to re-initialize."
  exit 1
fi

# --- Create structure ---
echo "🎉 Initializing JOYA project: $PROJECT_NAME"
echo "   Directory: $TARGET_DIR/.joy/"

mkdir -p "$JOY_DIR"/{knowledge,tasks,scripts}

# --- PROJECT.md ---
if [[ "$EXISTING" == true ]]; then
  AUDIT_NOTE="<!-- TODO: Agent should audit codebase and fill in details -->"
else
  AUDIT_NOTE=""
fi

cat > "$JOY_DIR/PROJECT.md" << EOF
# Project: $PROJECT_NAME

## Overview
<!-- One paragraph: what is this project and why does it exist -->
$AUDIT_NOTE

## Status
active

## Principal Goal
<!-- What does the Principal want to achieve -->

## Tech Stack
<!-- Languages, frameworks, key dependencies -->

## Repository
<!-- Git remote URL -->

## Team
| Agent | Role | Responsibility |
|-------|------|----------------|

## Created
$TODAY
EOF

# --- CONTEXT.md ---
cat > "$JOY_DIR/CONTEXT.md" << EOF
# Context

## Architecture
<!-- High-level architecture overview, key components -->
$AUDIT_NOTE

## Conventions
<!-- Coding style, naming conventions, commit rules specific to this project -->

## Key Files
<!-- The 5-10 most important files/directories and what they do -->

## Current State
<!-- What's been done, what's in progress, what's next -->

## Gotchas
<!-- Non-obvious things that will trip agents up -->
EOF

# --- knowledge/decisions.md ---
cat > "$JOY_DIR/knowledge/decisions.md" << EOF
# Key Decisions

<!-- Format:
### [YYYY-MM-DD] Decision title
**Context:** Why this decision was needed
**Decision:** What was decided
**Rationale:** Why this option was chosen
-->
EOF

# --- tasks/BACKLOG.md ---
cat > "$JOY_DIR/tasks/BACKLOG.md" << EOF
# Backlog

<!-- Format:
| Priority | Task | Assignee | Status |
|----------|------|----------|--------|
-->

| Priority | Task | Assignee | Status |
|----------|------|----------|--------|
EOF

# --- .gitkeep for scripts ---
touch "$JOY_DIR/scripts/.gitkeep"

# --- Summary ---
echo ""
echo "✅ Created .joy/ structure:"
echo ""
find "$JOY_DIR" -type f | sort | while read -r f; do
  echo "   ${f#$TARGET_DIR/}"
done
echo ""

if [[ "$EXISTING" == true ]]; then
  echo "📋 Existing project mode — TODO markers added."
  echo "   Assign an agent to audit the codebase and fill in:"
  echo "   - .joy/PROJECT.md (project identity)"
  echo "   - .joy/CONTEXT.md (technical context)"
  echo "   - .joy/knowledge/decisions.md (known decisions)"
  echo "   - .joy/tasks/BACKLOG.md (import existing issues)"
else
  echo "📝 Next steps:"
  echo "   1. Fill in .joy/PROJECT.md"
  echo "   2. Fill in .joy/CONTEXT.md"
  echo "   3. Register in instance/shared/projects/"
  echo "   4. Notify your agent team"
fi
