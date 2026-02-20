#!/usr/bin/env bash
# joy-adapter-cursor.sh — Connect/disconnect Cursor to JOYA
# Usage:
#   joy-adapter-cursor.sh install <agent-name> [--joy-root <path>] [--project <path>]
#   joy-adapter-cursor.sh uninstall <agent-name> [--project <path>]
#   joy-adapter-cursor.sh status [--project <path>]

set -euo pipefail

ACTION="" ; AGENT_NAME="" ; JOY_ROOT="" ; PROJECT=""
BACKUP_SUFFIX=".bak.pre-joy"

while [[ $# -gt 0 ]]; do
  case "$1" in
    install|uninstall|status) ACTION="$1"; shift ;;
    --joy-root) JOY_ROOT="$2"; shift 2 ;;
    --project) PROJECT="$2"; shift 2 ;;
    *) [[ -z "$AGENT_NAME" ]] && AGENT_NAME="$1"; shift ;;
  esac
done

[[ -z "$ACTION" ]] && { echo "Usage: joy-adapter-cursor.sh <install|uninstall|status> <agent-name> [--joy-root <path>] [--project <path>]"; exit 1; }

JOY_ROOT="${JOY_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
PROJECT="${PROJECT:-.}"
PROJECT="$(cd "$PROJECT" && pwd)"
AGENT_DIR="$JOY_ROOT/instance/agents/$AGENT_NAME"
RULES_FILE="$PROJECT/.cursorrules"
RULES_DIR="$PROJECT/.cursor"
MARKER="$PROJECT/.joy-adapter-cursor"

import_data() {
  echo ""
  echo "📥 Phase 1: Import existing Cursor config"
  echo ""

  # Save existing .cursorrules content
  if [[ -f "$RULES_FILE" ]]; then
    local lines=$(wc -l < "$RULES_FILE")
    if [[ ! -f "$AGENT_DIR/cursorrules.imported" ]]; then
      cp "$RULES_FILE" "$AGENT_DIR/cursorrules.imported"
      echo "   ✅ .cursorrules ($lines lines) → saved as cursorrules.imported"
    else
      echo "   ⏭️  .cursorrules: already imported"
    fi
  fi

  # Save existing .cursor/rules if directory exists
  if [[ -d "$RULES_DIR" ]]; then
    local rule_count=$(find "$RULES_DIR" -type f -name "*.md" -o -name "*.mdc" 2>/dev/null | wc -l | tr -d ' ')
    if [[ $rule_count -gt 0 && ! -d "$AGENT_DIR/cursor-rules.imported" ]]; then
      mkdir -p "$AGENT_DIR/cursor-rules.imported"
      cp -r "$RULES_DIR/"* "$AGENT_DIR/cursor-rules.imported/" 2>/dev/null || true
      echo "   ✅ .cursor/ ($rule_count rule files) → saved as cursor-rules.imported/"
    else
      echo "   ⏭️  .cursor/: already imported or empty"
    fi
  fi
}

link_workspace() {
  echo ""
  echo "🔗 Phase 2: Link Cursor to JOYA"
  echo ""

  if [[ -f "$RULES_FILE" ]]; then
    cp "$RULES_FILE" "$RULES_FILE${BACKUP_SUFFIX}"
    echo "   📦 Backed up .cursorrules"
  fi

  cat > "$RULES_FILE" << EOF
# Cursor — JOYA

You are governed by the JOYA protocol.

## Identity
Read: $AGENT_DIR/IDENTITY.md

## Memory
Read and update: $AGENT_DIR/MEMORY.md
Daily notes: $AGENT_DIR/memory/

## Principal
Read: $JOY_ROOT/my/shared/core/PRINCIPAL.md

## Protocol
Read: $JOY_ROOT/AGENT_INIT.md

## Project
If this project has a .joy/ directory, read .joy/CONTEXT.md before starting work.

## Team
Roster: $JOY_ROOT/instance/agents/ROSTER.md

## Key Rules
- **A2**: Confirm receipt before acting
- **A3**: Don't waste context — summarize, reference, don't duplicate
- **R4**: Never write secrets to memory or messages
- **R11**: All project artifacts go in .joy/
- Update MEMORY.md with important learnings after each session
EOF

  echo "   ✅ Generated .cursorrules bridge"
}

install_adapter() {
  echo "🚀 Installing JOYA adapter for Cursor (agent: $AGENT_NAME)"
  echo "   Project: $PROJECT"

  [[ -f "$MARKER" ]] && { echo "⚠️  Already installed. Run 'uninstall' first."; exit 1; }
  [[ ! -d "$AGENT_DIR" ]] && { echo "❌ Agent dir not found: $AGENT_DIR"; exit 1; }

  import_data
  link_workspace

  cat > "$MARKER" << EOF
agent=$AGENT_NAME
joy_root=$JOY_ROOT
project=$PROJECT
installed=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

  echo ""
  echo "✅ Done! Cursor now reads JOYA identity in this project."
  echo "   To undo: $(basename "$0") uninstall $AGENT_NAME --project $PROJECT"
}

uninstall_adapter() {
  echo "🔓 Uninstalling JOYA adapter for Cursor"
  [[ ! -f "$MARKER" ]] && { echo "⚠️  Not installed."; exit 1; }

  if [[ -f "$RULES_FILE${BACKUP_SUFFIX}" ]]; then
    mv "$RULES_FILE${BACKUP_SUFFIX}" "$RULES_FILE"
    echo "   ✅ Restored .cursorrules from backup"
  else
    rm -f "$RULES_FILE"
  fi

  rm -f "$MARKER"
  echo "✅ Done!"
}

check_status() {
  if [[ -f "$MARKER" ]]; then
    echo "✅ JOYA adapter is INSTALLED"
    cat "$MARKER" | sed 's/^/   /'
  else
    echo "❌ JOYA adapter is NOT installed in $PROJECT"
  fi
}

case "$ACTION" in
  install)   install_adapter ;;
  uninstall) uninstall_adapter ;;
  status)    check_status ;;
esac
