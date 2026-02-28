#!/usr/bin/env bash
# joy-adapter-claude-code.sh — Connect/disconnect Claude Code to JOYA
# Usage:
#   joy-adapter-claude-code.sh install <agent-name> [--joy-root <path>]
#   joy-adapter-claude-code.sh uninstall <agent-name> [--joy-root <path>]
#   joy-adapter-claude-code.sh status <agent-name>

set -euo pipefail

ACTION="" ; AGENT_NAME="" ; JOY_ROOT=""
CLAUDE_DIR="$HOME/.claude"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
BACKUP_SUFFIX=".bak.pre-joy"
# Claude Code stores per-project auto-memory under ~/.claude/projects/<encoded-path>/memory/
# The global (home dir) project uses -Users-<username> as the encoded path
CLAUDE_USER=$(whoami)
CLAUDE_MEMORY_DIR="$CLAUDE_DIR/projects/-Users-$CLAUDE_USER/memory"

while [[ $# -gt 0 ]]; do
  case "$1" in
    install|uninstall|status) ACTION="$1"; shift ;;
    --joy-root) JOY_ROOT="$2"; shift 2 ;;
    *) [[ -z "$AGENT_NAME" ]] && AGENT_NAME="$1"; shift ;;
  esac
done

[[ -z "$ACTION" || -z "$AGENT_NAME" ]] && { echo "Usage: joy-adapter-claude-code.sh <install|uninstall|status> <agent-name> [--joy-root <path>]"; exit 1; }

JOY_ROOT="${JOY_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
AGENT_DIR="$JOY_ROOT/my/agents/$AGENT_NAME"
MARKER="$CLAUDE_DIR/.joy-adapter-claude-code"

# =============================================================
# PHASE 1: IMPORT — Extract existing CLAUDE.md content
# =============================================================
import_data() {
  echo ""
  echo "📥 Phase 1: Import existing Claude Code data"
  echo ""

  local imported=0

  # --- CLAUDE.md → save content for reference ---
  local source="$CLAUDE_MD"
  # Resolve symlink if needed
  if [[ -L "$CLAUDE_MD" ]]; then
    source=$(readlink -f "$CLAUDE_MD" 2>/dev/null || readlink "$CLAUDE_MD")
  fi

  if [[ -f "$source" ]]; then
    local lines=$(wc -l < "$source")
    if [[ ! -f "$AGENT_DIR/CLAUDE.md.imported" ]]; then
      cp "$source" "$AGENT_DIR/CLAUDE.md.imported"
      echo "   ✅ CLAUDE.md ($lines lines) → saved as CLAUDE.md.imported (reference)"
      imported=$((imported + 1))
    else
      echo "   ⏭️  CLAUDE.md: already imported"
    fi

    # If IDENTITY.md is empty/minimal, seed from CLAUDE.md
    if [[ ! -f "$AGENT_DIR/IDENTITY.md" ]] || [[ $(wc -l < "$AGENT_DIR/IDENTITY.md") -lt 5 ]]; then
      {
        echo "# $AGENT_NAME"
        echo ""
        echo "## Context (imported from Claude Code CLAUDE.md)"
        echo ""
        cat "$source"
      } > "$AGENT_DIR/IDENTITY.md"
      echo "   ✅ CLAUDE.md → seeded IDENTITY.md"
      imported=$((imported + 1))
    fi
  fi

  # --- Claude memory (history.jsonl) → note its location ---
  if [[ -f "$CLAUDE_DIR/history.jsonl" ]]; then
    local hist_size=$(wc -l < "$CLAUDE_DIR/history.jsonl")
    echo "   ℹ️  history.jsonl found ($hist_size entries) — Claude Code session history"
    echo "      (Not imported — this is runtime-specific. Use for reference if needed.)"
  fi

  echo ""
  if [[ $imported -gt 0 ]]; then
    echo "   📊 Imported $imported items."
  else
    echo "   📊 Nothing new to import."
  fi
}

# =============================================================
# PHASE 2: LINK — Generate CLAUDE.md bridge
# =============================================================
link_workspace() {
  echo ""
  echo "🔗 Phase 2: Link Claude Code to JOYA"
  echo ""

  mkdir -p "$CLAUDE_DIR"

  # Backup
  if [[ -f "$CLAUDE_MD" ]] || [[ -L "$CLAUDE_MD" ]]; then
    if [[ -L "$CLAUDE_MD" ]]; then
      local link_target=$(readlink "$CLAUDE_MD")
      echo "$link_target" > "$CLAUDE_MD${BACKUP_SUFFIX}.link"
      echo "   📦 Backed up symlink: → $link_target"
      rm -f "$CLAUDE_MD"
    else
      cp "$CLAUDE_MD" "$CLAUDE_MD${BACKUP_SUFFIX}"
      echo "   📦 Backed up CLAUDE.md"
    fi
  fi

  # Generate bridge CLAUDE.md
  cat > "$CLAUDE_MD" << EOF
# Claude Code — JOYA

You are governed by the JOYA protocol. Read these files on every session:

## Identity
Read: $AGENT_DIR/IDENTITY.md

## Memory
Read and update: $AGENT_DIR/MEMORY.md
Daily notes: $AGENT_DIR/memory/

## Principal
Read: $JOY_ROOT/my/shared/core/PRINCIPAL.md

## Protocol
Read: $JOY_ROOT/AGENT_INIT.md

## Team
Roster: $JOY_ROOT/my/shared/agents/ROSTER.md
Directory: $JOY_ROOT/my/shared/agents/DIRECTORY.json

## Infrastructure
Read: $JOY_ROOT/my/shared/core/INFRASTRUCTURE.md
Playbook: $JOY_ROOT/my/shared/core/PLAYBOOK.md

## Your private tools
Scripts: $AGENT_DIR/scripts/
Skills: $AGENT_DIR/skills/

## Key Rules
- **A2**: Confirm receipt before acting
- **A3**: Don't waste context — summarize, reference, don't duplicate
- **R4**: Never write secrets to memory or messages
- **R11**: Register projects in shared/projects/; project owns its doc structure directory
- Update MEMORY.md with important learnings after each session
EOF

  echo "   ✅ Generated CLAUDE.md bridge"
}

# =============================================================
# PHASE 3: LINK AUTO-MEMORY — Symlink Claude Code auto-memory
# =============================================================
# Claude Code has a built-in auto-memory mechanism:
#   ~/.claude/projects/-Users-<user>/memory/MEMORY.md  (auto-loaded into system prompt)
#   ~/.claude/projects/-Users-<user>/memory/*.md        (supplementary files)
#
# This phase:
#   1. Copies existing auto-memory content into JOYA agent directory
#   2. Replaces the files with symlinks pointing to JOYA
#   3. Claude Code continues reading/writing via symlinks — JOYA is source of truth
link_auto_memory() {
  echo ""
  echo "🧠 Phase 3: Link auto-memory to JOYA"
  echo ""

  mkdir -p "$AGENT_DIR/memory"

  if [[ ! -d "$CLAUDE_MEMORY_DIR" ]]; then
    echo "   ℹ️  Auto-memory dir not found: $CLAUDE_MEMORY_DIR"
    echo "      Creating it with symlinks to JOYA..."
    mkdir -p "$CLAUDE_MEMORY_DIR"
    # Create MEMORY.md symlink (Claude Code will write to JOYA via this)
    ln -sf "$AGENT_DIR/MEMORY.md" "$CLAUDE_MEMORY_DIR/MEMORY.md"
    echo "   ✅ Created MEMORY.md → JOYA"
    return
  fi

  local linked=0

  # Process each .md file in auto-memory dir
  for file in "$CLAUDE_MEMORY_DIR"/*.md; do
    [[ ! -f "$file" ]] && continue
    local basename=$(basename "$file")

    # Skip if already a symlink pointing to JOYA
    if [[ -L "$file" ]]; then
      local target=$(readlink "$file")
      if [[ "$target" == *"joy-agents"* ]]; then
        echo "   ⏭️  $basename: already linked"
        continue
      fi
      # Symlink to something else — resolve and treat as regular file
      file=$(readlink -f "$file" 2>/dev/null || readlink "$file")
    fi

    # Skip backup files
    [[ "$basename" == *"$BACKUP_SUFFIX"* ]] && continue

    # Determine JOYA destination
    local joy_dest
    if [[ "$basename" == "MEMORY.md" ]]; then
      joy_dest="$AGENT_DIR/MEMORY.md"
    else
      joy_dest="$AGENT_DIR/memory/$basename"
    fi

    # Copy content to JOYA (merge if destination already has content)
    local src_lines=$(wc -l < "$file" | tr -d ' ')
    if [[ -f "$joy_dest" ]]; then
      local dst_lines=$(wc -l < "$joy_dest" | tr -d ' ')
      if [[ "$dst_lines" -gt 3 ]]; then
        echo "   ⚠️  $basename: JOYA already has content ($dst_lines lines), keeping JOYA version"
        echo "      Claude Code version ($src_lines lines) saved as ${basename}.claude-original"
        cp "$file" "$AGENT_DIR/memory/${basename}.claude-original"
      else
        cp "$file" "$joy_dest"
        echo "   ✅ $basename ($src_lines lines) → copied to JOYA"
      fi
    else
      cp "$file" "$joy_dest"
      echo "   ✅ $basename ($src_lines lines) → copied to JOYA"
    fi

    # Backup original and replace with symlink
    cp "$file" "${file}${BACKUP_SUFFIX}"
    rm -f "$file"
    ln -sf "$joy_dest" "$file"
    echo "   🔗 $basename → symlinked to JOYA"
    linked=$((linked + 1))
  done

  echo ""
  echo "   📊 Linked $linked auto-memory files."
}

# =============================================================
# INSTALL
# =============================================================
install_adapter() {
  echo "🚀 Installing JOYA adapter for Claude Code (agent: $AGENT_NAME)"
  echo "   JOYA: $JOY_ROOT"
  echo "   Agent dir:  $AGENT_DIR"
  echo "   Claude dir: $CLAUDE_DIR"

  [[ -f "$MARKER" ]] && { echo ""; echo "⚠️  Already installed. Run 'uninstall' first."; exit 1; }
  [[ ! -d "$AGENT_DIR" ]] && { echo "❌ Agent dir not found: $AGENT_DIR"; exit 1; }

  import_data
  link_workspace
  link_auto_memory

  cat > "$MARKER" << EOF
agent=$AGENT_NAME
joy_root=$JOY_ROOT
installed=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

  echo ""
  echo "════════════════════════════════════════════════════"
  echo "✅ Done! Claude Code now reads JOYA identity."
  echo "   To undo: $(basename "$0") uninstall $AGENT_NAME"
  echo "════════════════════════════════════════════════════"
}

# =============================================================
# UNINSTALL
# =============================================================
uninstall_adapter() {
  echo "🔓 Uninstalling JOYA adapter for Claude Code"
  [[ ! -f "$MARKER" ]] && { echo "⚠️  Not installed."; exit 1; }

  # --- Restore CLAUDE.md ---
  if [[ -f "$CLAUDE_MD${BACKUP_SUFFIX}.link" ]]; then
    local link_target=$(cat "$CLAUDE_MD${BACKUP_SUFFIX}.link")
    rm -f "$CLAUDE_MD"
    ln -sf "$link_target" "$CLAUDE_MD"
    rm "$CLAUDE_MD${BACKUP_SUFFIX}.link"
    echo "   ✅ Restored CLAUDE.md symlink: → $link_target"
  elif [[ -f "$CLAUDE_MD${BACKUP_SUFFIX}" ]]; then
    mv "$CLAUDE_MD${BACKUP_SUFFIX}" "$CLAUDE_MD"
    echo "   ✅ Restored CLAUDE.md from backup"
  else
    rm -f "$CLAUDE_MD"
    echo "   ✅ Removed CLAUDE.md (no backup found)"
  fi

  # --- Restore auto-memory files ---
  if [[ -d "$CLAUDE_MEMORY_DIR" ]]; then
    local restored=0
    for backup in "$CLAUDE_MEMORY_DIR"/*"$BACKUP_SUFFIX"; do
      [[ ! -f "$backup" ]] && continue
      local original="${backup%$BACKUP_SUFFIX}"
      local basename=$(basename "$original")
      # Export latest from JOYA before restoring (so no data is lost)
      if [[ -L "$original" ]]; then
        local joy_file=$(readlink "$original")
        if [[ -f "$joy_file" ]]; then
          cp "$joy_file" "${original}.joy-export"
          echo "   📤 Exported latest $basename from JOYA"
        fi
        rm -f "$original"
      fi
      mv "$backup" "$original"
      echo "   ✅ Restored $basename from backup"
      restored=$((restored + 1))
    done
    [[ $restored -gt 0 ]] && echo "   📊 Restored $restored auto-memory files."
  fi

  rm -f "$MARKER"
  echo ""
  echo "✅ Done! Claude Code restored to standalone mode."
  echo "   JOYA files remain intact at: $AGENT_DIR"
  echo "   Latest memory exported as *.joy-export for reference."
}

# =============================================================
# STATUS
# =============================================================
check_status() {
  echo "🔍 JOYA Adapter Status (Claude Code)"
  echo ""
  if [[ -f "$MARKER" ]]; then
    echo "   Status: ✅ INSTALLED"
    cat "$MARKER" | sed 's/^/   /'
    echo ""

    # Check CLAUDE.md bridge
    if [[ -f "$CLAUDE_MD" ]]; then
      if grep -q "JOYA" "$CLAUDE_MD" 2>/dev/null; then
        echo "   CLAUDE.md: ✅ JOYA bridge"
      else
        echo "   CLAUDE.md: ⚠️  exists but doesn't reference JOYA"
      fi
    else
      echo "   CLAUDE.md: ❌ missing"
    fi

    # Check auto-memory linkage
    echo ""
    echo "   Auto-memory ($CLAUDE_MEMORY_DIR):"
    if [[ -d "$CLAUDE_MEMORY_DIR" ]]; then
      for file in "$CLAUDE_MEMORY_DIR"/*.md; do
        [[ ! -f "$file" ]] && continue
        local basename=$(basename "$file")
        [[ "$basename" == *"$BACKUP_SUFFIX"* ]] && continue
        [[ "$basename" == *.claude-original ]] && continue
        [[ "$basename" == *.joy-export ]] && continue
        if [[ -L "$file" ]]; then
          local target=$(readlink "$file")
          if [[ "$target" == *"joy-agents"* ]]; then
            echo "      ✅ $basename → $target"
          else
            echo "      ⚠️  $basename → $target (not JOYA)"
          fi
        else
          echo "      ❌ $basename: regular file (not linked)"
        fi
      done
    else
      echo "      ❌ Directory not found"
    fi

    echo ""
    local backup_count=$(find "$CLAUDE_DIR" -name "*${BACKUP_SUFFIX}*" 2>/dev/null | wc -l | tr -d ' ')
    echo "   Backups: $backup_count files"
  else
    echo "   Status: ❌ NOT INSTALLED"
  fi
}

case "$ACTION" in
  install)   install_adapter ;;
  uninstall) uninstall_adapter ;;
  status)    check_status ;;
esac
