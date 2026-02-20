#!/usr/bin/env bash
# joy-adapter-gemini.sh — Connect/disconnect Gemini CLI to JOYA
# Usage:
#   joy-adapter-gemini.sh install <agent-name> [--joy-root <path>] [--global]
#   joy-adapter-gemini.sh uninstall <agent-name> [--global]
#   joy-adapter-gemini.sh status [--global]

set -euo pipefail

ACTION="" ; AGENT_NAME="" ; JOY_ROOT="" ; GLOBAL=false
BACKUP_SUFFIX=".bak.pre-joy"

while [[ $# -gt 0 ]]; do
  case "$1" in
    install|uninstall|status) ACTION="$1"; shift ;;
    --joy-root) JOY_ROOT="$2"; shift 2 ;;
    --global) GLOBAL=true; shift ;;
    *) [[ -z "$AGENT_NAME" ]] && AGENT_NAME="$1"; shift ;;
  esac
done

[[ -z "$ACTION" ]] && { echo "Usage: joy-adapter-gemini.sh <install|uninstall|status> <agent-name> [--joy-root <path>] [--global]"; exit 1; }

JOY_ROOT="${JOY_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
AGENT_DIR="$JOY_ROOT/my/agents/$AGENT_NAME"

if [[ "$GLOBAL" == true ]]; then
  GEMINI_DIR="$HOME/.gemini"
  mkdir -p "$GEMINI_DIR"
  TARGET="$GEMINI_DIR/GEMINI.md"
  MARKER="$GEMINI_DIR/.joy-adapter-gemini"
else
  TARGET="$(pwd)/GEMINI.md"
  MARKER="$(pwd)/.joy-adapter-gemini"
fi

import_data() {
  echo ""
  echo "📥 Phase 1: Import existing Gemini config"
  echo ""

  if [[ -f "$TARGET" ]]; then
    local lines=$(wc -l < "$TARGET")
    if [[ ! -f "$AGENT_DIR/gemini.imported" ]]; then
      cp "$TARGET" "$AGENT_DIR/gemini.imported"
      echo "   ✅ GEMINI.md ($lines lines) → saved as gemini.imported"
    else
      echo "   ⏭️  GEMINI.md: already imported"
    fi
  fi
}

link_workspace() {
  echo ""
  echo "🔗 Phase 2: Link Gemini CLI to JOYA"
  echo ""

  if [[ -f "$TARGET" ]]; then
    cp "$TARGET" "$TARGET${BACKUP_SUFFIX}"
    echo "   📦 Backed up GEMINI.md"
  fi

  cat > "$TARGET" << EOF
# Gemini CLI — JOYA

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
Roster: $JOY_ROOT/my/shared/agents/ROSTER.md

## Key Rules
- **A2**: Confirm receipt before acting
- **A3**: Don't waste context — summarize, reference, don't duplicate
- **R4**: Never write secrets to memory or messages
- **R11**: All project artifacts go in .joy/
- Update MEMORY.md with important learnings after each session
EOF

  echo "   ✅ Generated GEMINI.md bridge"
}

install_adapter() {
  echo "🚀 Installing JOYA adapter for Gemini CLI (agent: $AGENT_NAME)"
  [[ "$GLOBAL" == true ]] && echo "   Mode: global (~/.gemini/)" || echo "   Mode: project ($(pwd))"

  [[ -f "$MARKER" ]] && { echo "⚠️  Already installed. Run 'uninstall' first."; exit 1; }
  [[ ! -d "$AGENT_DIR" ]] && { echo "❌ Agent dir not found: $AGENT_DIR"; exit 1; }

  import_data
  link_workspace

  cat > "$MARKER" << EOF
agent=$AGENT_NAME
joy_root=$JOY_ROOT
global=$GLOBAL
installed=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

  echo ""
  echo "✅ Done! Gemini CLI now reads JOYA identity."
  echo "   To undo: $(basename "$0") uninstall $AGENT_NAME$([ "$GLOBAL" == true ] && echo ' --global')"
}

uninstall_adapter() {
  echo "🔓 Uninstalling JOYA adapter for Gemini CLI"
  [[ ! -f "$MARKER" ]] && { echo "⚠️  Not installed."; exit 1; }

  if [[ -f "$TARGET${BACKUP_SUFFIX}" ]]; then
    mv "$TARGET${BACKUP_SUFFIX}" "$TARGET"
    echo "   ✅ Restored GEMINI.md from backup"
  else
    rm -f "$TARGET"
  fi

  rm -f "$MARKER"
  echo "✅ Done!"
}

check_status() {
  if [[ -f "$MARKER" ]]; then
    echo "✅ JOYA adapter is INSTALLED"
    cat "$MARKER" | sed 's/^/   /'
  else
    echo "❌ JOYA adapter is NOT installed"
  fi
}

case "$ACTION" in
  install)   install_adapter ;;
  uninstall) uninstall_adapter ;;
  status)    check_status ;;
esac
