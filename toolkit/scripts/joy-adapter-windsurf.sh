#!/usr/bin/env bash
# joy-adapter-windsurf.sh — Connect/disconnect Windsurf to JOYA
# Usage:
#   joy-adapter-windsurf.sh install <agent-name> [--joy-root <path>] [--project <path>]
#   joy-adapter-windsurf.sh uninstall <agent-name> [--project <path>]
#   joy-adapter-windsurf.sh status [--project <path>]

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

[[ -z "$ACTION" ]] && { echo "Usage: joy-adapter-windsurf.sh <install|uninstall|status> <agent-name> [--joy-root <path>] [--project <path>]"; exit 1; }

JOY_ROOT="${JOY_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
PROJECT="${PROJECT:-.}"
PROJECT="$(cd "$PROJECT" && pwd)"
AGENT_DIR="$JOY_ROOT/my/agents/$AGENT_NAME"
RULES_FILE="$PROJECT/.windsurfrules"
MARKER="$PROJECT/.joy-adapter-windsurf"

import_data() {
  echo ""
  echo "📥 Phase 1: Import existing Windsurf config"
  echo ""

  if [[ -f "$RULES_FILE" ]]; then
    local lines=$(wc -l < "$RULES_FILE")
    if [[ ! -f "$AGENT_DIR/windsurfrules.imported" ]]; then
      cp "$RULES_FILE" "$AGENT_DIR/windsurfrules.imported"
      echo "   ✅ .windsurfrules ($lines lines) → saved as windsurfrules.imported"
    else
      echo "   ⏭️  .windsurfrules: already imported"
    fi
  fi
}

link_workspace() {
  echo ""
  echo "🔗 Phase 2: Link Windsurf to JOYA"
  echo ""

  if [[ -f "$RULES_FILE" ]]; then
    cp "$RULES_FILE" "$RULES_FILE${BACKUP_SUFFIX}"
    echo "   📦 Backed up .windsurfrules"
  fi

  cat > "$RULES_FILE" << EOF
# Windsurf — JOYA

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
Check shared/projects/ for project registration before starting work.

## Team
Roster: $JOY_ROOT/my/shared/agents/ROSTER.md

## Key Rules
- **A2**: Confirm receipt before acting
- **A3**: Don't waste context — summarize, reference, don't duplicate
- **R4**: Never write secrets to memory or messages
- **R11**: Register projects in shared/projects/; project owns its doc structure
- Update MEMORY.md with important learnings after each session
EOF

  echo "   ✅ Generated .windsurfrules bridge"
}

install_adapter() {
  echo "🚀 Installing JOYA adapter for Windsurf (agent: $AGENT_NAME)"
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
  echo "✅ Done! Windsurf now reads JOYA identity in this project."
  echo "   To undo: $(basename "$0") uninstall $AGENT_NAME --project $PROJECT"
}

uninstall_adapter() {
  echo "🔓 Uninstalling JOYA adapter for Windsurf"
  [[ ! -f "$MARKER" ]] && { echo "⚠️  Not installed."; exit 1; }

  if [[ -f "$RULES_FILE${BACKUP_SUFFIX}" ]]; then
    mv "$RULES_FILE${BACKUP_SUFFIX}" "$RULES_FILE"
    echo "   ✅ Restored .windsurfrules from backup"
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
