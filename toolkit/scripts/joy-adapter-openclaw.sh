#!/usr/bin/env bash
# joy-adapter-openclaw.sh — Connect/disconnect OpenClaw workspace to JOYA
#
# Cross-platform: Linux, macOS, Windows (Git Bash / WSL / MSYS2)
# Auto-detects OS and adapts behavior:
#   - Linux/macOS: real symlinks for MEMORY.md
#   - Windows:     pointer files (symlinks unreliable over NFS/Syncthing)
#
# Usage:
#   joy-adapter-openclaw.sh install <agent-name> [--joy-root <path>] [--workspace <path>]
#   joy-adapter-openclaw.sh uninstall <agent-name> [--joy-root <path>] [--workspace <path>]
#   joy-adapter-openclaw.sh status <agent-name> [--joy-root <path>] [--workspace <path>]
#
# Defaults:
#   --joy-root   ~/joya          ($JOYA_ROOT, or auto-detect)
#   --workspace  ~/.openclaw/workspace (Linux/macOS)
#                $USERPROFILE/.openclaw/workspace (Windows)
#
# Structure expected under joy-root:
#   lib/   → Framework ($JOYA_LIB): AGENT_INIT.md, core/, guides/, toolkit/
#   my/    → Instance  ($JOYA_MY):  agents/, shared/core/ (or shared/config/), shared/knowledge/

set -euo pipefail

# =============================================================
# OS DETECTION
# =============================================================
detect_os() {
  case "$(uname -s)" in
    Linux*)   OS_TYPE="linux" ;;
    Darwin*)  OS_TYPE="macos" ;;
    CYGWIN*|MINGW*|MSYS*) OS_TYPE="windows" ;;
    *)
      # Check for WSL
      if grep -qi microsoft /proc/version 2>/dev/null; then
        OS_TYPE="windows"
      else
        OS_TYPE="unknown"
      fi
      ;;
  esac

  # Symlink support: real symlinks on Unix, pointer files on Windows
  if [[ "$OS_TYPE" == "windows" ]]; then
    USE_SYMLINKS=false
  else
    USE_SYMLINKS=true
  fi
}

detect_os

# Windows path conversion: /c/Users → C:/Users (Git Bash → Windows native)
to_native_path() {
  local p="$1"
  if [[ "$OS_TYPE" == "windows" ]]; then
    # Convert /c/Users/... → C:/Users/...
    echo "$p" | sed -E 's|^/([a-zA-Z])/|\U\1:/|'
  else
    echo "$p"
  fi
}

ACTION="" ; AGENT_NAME="" ; JOY_ROOT="" ; WORKSPACE=""
BACKUP_SUFFIX=".bak.pre-joy"

while [[ $# -gt 0 ]]; do
  case "$1" in
    install|uninstall|status) ACTION="$1"; shift ;;
    --joy-root)  JOY_ROOT="$2"; shift 2 ;;
    --workspace) WORKSPACE="$2"; shift 2 ;;
    *) [[ -z "$AGENT_NAME" ]] && AGENT_NAME="$1"; shift ;;
  esac
done

[[ -z "$ACTION" || -z "$AGENT_NAME" ]] && {
  echo "Usage: joy-adapter-openclaw.sh <install|uninstall|status> <agent-name> [--joy-root <path>] [--workspace <path>]"
  exit 1
}

# --- Resolve paths ---

# Joy root: argument > env > ~/joya > auto-detect from script location
if [[ -z "$JOY_ROOT" ]]; then
  if [[ -n "${JOYA_ROOT:-}" ]]; then
    JOY_ROOT="$JOYA_ROOT"
  elif [[ -f "$HOME/joya/lib/AGENT_INIT.md" ]]; then
    JOY_ROOT="$HOME/joya"
  else
    # Try to infer from script location (script is in lib/toolkit/scripts/)
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    CANDIDATE="$(cd "$SCRIPT_DIR/../../.." 2>/dev/null && pwd)"
    if [[ -f "$CANDIDATE/lib/AGENT_INIT.md" ]]; then
      JOY_ROOT="$CANDIDATE"
    else
      echo "❌ Cannot find JOYA root. Use --joy-root to specify."
      exit 1
    fi
  fi
fi

JOYA_LIB="$JOY_ROOT/lib"
JOYA_MY="$JOY_ROOT/my"
AGENT_DIR="$JOYA_MY/agents/$AGENT_NAME"
# Support both shared/core/ (standard) and shared/config/ (legacy)
if [[ -d "$JOYA_MY/shared/core" ]]; then
  CONFIG_DIR="$JOYA_MY/shared/core"
elif [[ -d "$JOYA_MY/shared/config" ]]; then
  CONFIG_DIR="$JOYA_MY/shared/config"
else
  CONFIG_DIR="$JOYA_MY/shared/core"
fi

# Workspace: argument > default OpenClaw location
if [[ -z "$WORKSPACE" ]]; then
  if [[ "$OS_TYPE" == "windows" && -n "${USERPROFILE:-}" ]]; then
    WORKSPACE="$USERPROFILE/.openclaw/workspace"
  else
    WORKSPACE="$HOME/.openclaw/workspace"
  fi
fi

MARKER="$WORKSPACE/.joy-adapter-openclaw"

# Convert paths for bridge file content (Windows: /c/Users → C:/Users)
DISPLAY_JOY_ROOT="$(to_native_path "$JOY_ROOT")"
DISPLAY_JOYA_LIB="$(to_native_path "$JOYA_LIB")"
DISPLAY_JOYA_MY="$(to_native_path "$JOYA_MY")"
DISPLAY_AGENT_DIR="$(to_native_path "$AGENT_DIR")"
DISPLAY_CONFIG_DIR="$(to_native_path "$CONFIG_DIR")"

# Managed files list
MANAGED_FILES="AGENTS.md SOUL.md IDENTITY.md USER.md MEMORY.md BOOTSTRAP.md HEARTBEAT.md"

# =============================================================
# PHASE 1: IMPORT — Extract existing workspace content
# =============================================================
import_data() {
  echo ""
  echo "📥 Phase 1: Import existing workspace data"
  echo ""

  local imported=0

  # --- MEMORY.md → copy to agent dir if agent has none ---
  if [[ -f "$WORKSPACE/MEMORY.md" ]] && ! grep -q "JOYA" "$WORKSPACE/MEMORY.md" 2>/dev/null; then
    local ws_lines
    ws_lines=$(wc -l < "$WORKSPACE/MEMORY.md" | tr -d ' ')
    local joy_lines=0
    [[ -f "$AGENT_DIR/MEMORY.md" ]] && joy_lines=$(wc -l < "$AGENT_DIR/MEMORY.md" | tr -d ' ')

    if [[ "$joy_lines" -lt 5 && "$ws_lines" -gt 5 ]]; then
      cp "$WORKSPACE/MEMORY.md" "$AGENT_DIR/MEMORY.md"
      echo "   ✅ MEMORY.md ($ws_lines lines) → imported to agent dir"
      imported=$((imported + 1))
    else
      echo "   ⏭️  MEMORY.md: agent already has content ($joy_lines lines)"
    fi
  fi

  # --- SOUL.md → seed IDENTITY.md if agent has minimal one ---
  if [[ -f "$WORKSPACE/SOUL.md" ]] && ! grep -q "JOYA" "$WORKSPACE/SOUL.md" 2>/dev/null; then
    if [[ ! -f "$AGENT_DIR/IDENTITY.md" ]] || [[ $(wc -l < "$AGENT_DIR/IDENTITY.md") -lt 5 ]]; then
      if [[ ! -f "$AGENT_DIR/IDENTITY.md.imported" ]]; then
        cp "$WORKSPACE/SOUL.md" "$AGENT_DIR/IDENTITY.md.imported"
        echo "   ✅ SOUL.md → saved as IDENTITY.md.imported (reference)"
        imported=$((imported + 1))
      fi
    fi
  fi

  # --- TOOLS.md → copy to agent dir ---
  if [[ -f "$WORKSPACE/TOOLS.md" ]] && [[ ! -f "$AGENT_DIR/TOOLS.md" ]]; then
    if ! grep -q "JOYA" "$WORKSPACE/TOOLS.md" 2>/dev/null; then
      cp "$WORKSPACE/TOOLS.md" "$AGENT_DIR/TOOLS.md"
      echo "   ✅ TOOLS.md → imported to agent dir"
      imported=$((imported + 1))
    fi
  fi

  echo ""
  if [[ $imported -gt 0 ]]; then
    echo "   📊 Imported $imported items."
  else
    echo "   📊 Nothing new to import."
  fi
}

# =============================================================
# PHASE 2: LINK — Generate bridge files + symlinks
# =============================================================
link_workspace() {
  echo ""
  echo "🔗 Phase 2: Link OpenClaw workspace to JOYA"
  echo ""

  mkdir -p "$WORKSPACE"
  mkdir -p "$AGENT_DIR/memory"
  mkdir -p "$AGENT_DIR/scripts"
  mkdir -p "$AGENT_DIR/skills"

  # Backup existing files (skip if backup already exists — preserve originals across reinstalls)
  for f in $MANAGED_FILES; do
    local target="$WORKSPACE/$f"
    local backup="${target}${BACKUP_SUFFIX}"
    local link_backup="${target}${BACKUP_SUFFIX}.link"
    if [[ -f "$target" ]] || [[ -L "$target" ]]; then
      if [[ -L "$target" ]]; then
        if [[ ! -f "$link_backup" ]]; then
          local link_target
          link_target=$(readlink "$target")
          echo "$link_target" > "$link_backup"
          echo "   📦 Backed up symlink: $f → $link_target"
        else
          echo "   ⏭️  $f: backup already exists, preserving original"
        fi
        rm -f "$target"
      else
        if [[ ! -f "$backup" ]]; then
          cp "$target" "$backup"
          echo "   📦 Backed up: $f"
        else
          echo "   ⏭️  $f: backup already exists, preserving original"
        fi
      fi
    fi
  done

  # --- AGENTS.md (the main bridge) ---
  cat > "$WORKSPACE/AGENTS.md" << EOF
# Agents — JOYA Governed

This workspace is governed by the JOYA protocol.

## On every session start (and after compaction)

1. Read \`$DISPLAY_JOYA_LIB/AGENT_INIT.md\` — JOYA entry point
2. Read \`$DISPLAY_AGENT_DIR/IDENTITY.md\` — who you are
3. Read \`MEMORY.md\` and \`memory/\` — your memories (symlinked to JOYA)
4. Read \`$DISPLAY_CONFIG_DIR/PRINCIPAL.md\` — who you serve
5. Read \`$DISPLAY_CONFIG_DIR/PLAYBOOK.md\` — how this instance operates
6. Read \`$DISPLAY_CONFIG_DIR/INFRASTRUCTURE.md\` — comms tokens, services, endpoints

## Key paths

- JOYA root: \`$DISPLAY_JOY_ROOT/\`
- Your agent dir: \`$DISPLAY_AGENT_DIR/\`
- Framework core: \`$DISPLAY_JOYA_LIB/core/\`
- Framework guides: \`$DISPLAY_JOYA_LIB/guides/\`
- Framework toolkit: \`$DISPLAY_JOYA_LIB/toolkit/\`
- Team roster: \`$DISPLAY_JOYA_MY/agents/ROSTER.md\`
- Team directory: \`$DISPLAY_JOYA_MY/agents/DIRECTORY.json\`
- Infrastructure: \`$DISPLAY_CONFIG_DIR/INFRASTRUCTURE.md\`

## Your private tools

- Scripts: \`$DISPLAY_AGENT_DIR/scripts/\`
- Skills: \`$DISPLAY_AGENT_DIR/skills/\`

## Key rules (from framework)

- **A2**: Confirm receipt before acting
- **A3**: Don't waste context — summarize, reference, don't duplicate
- **R4**: Never write secrets to memory or messages
- **R11**: Register projects in shared/projects/; project owns its doc structure
- Update MEMORY.md with important learnings after each session
EOF
  echo "   ✅ AGENTS.md bridge created"

  # --- Stub files (all loading logic is in AGENTS.md) ---
  # See DEPLOYMENT.md § OpenClaw Workspace Optimization
  for stub_file in SOUL.md IDENTITY.md USER.md BOOTSTRAP.md; do
    stub_name="${stub_file%.md}"
    echo "# ${stub_name} — managed by AGENTS.md" > "$WORKSPACE/$stub_file"
  done
  echo "   ✅ SOUL/IDENTITY/USER/BOOTSTRAP.md stubs created"

  # --- HEARTBEAT.md ---
  cat > "$WORKSPACE/HEARTBEAT.md" << EOF
# HEARTBEAT.md

# Keep this file empty (or with only comments) to skip heartbeat API calls.

# Add tasks below when you want the agent to check something periodically.
EOF
  echo "   ✅ HEARTBEAT.md created"

  # --- MEMORY.md: symlink (Unix) or pointer file (Windows) ---
  rm -f "$WORKSPACE/MEMORY.md"
  if [[ "$USE_SYMLINKS" == true ]]; then
    ln -sf "$AGENT_DIR/MEMORY.md" "$WORKSPACE/MEMORY.md"
    echo "   ✅ MEMORY.md → symlinked to $AGENT_DIR/MEMORY.md"
  else
    cat > "$WORKSPACE/MEMORY.md" << MEMEOF
# Memory — JOYA Bridge

Your authoritative memory is at: \`$DISPLAY_AGENT_DIR/MEMORY.md\`
Daily notes: \`$DISPLAY_AGENT_DIR/memory/\`

Always read and write memory at the paths above, not this local file.
MEMEOF
    echo "   ✅ MEMORY.md → pointer file (Windows mode, no symlink)"
  fi
}

# =============================================================
# PHASE 3: VERIFY — Check everything is accessible
# =============================================================
verify_install() {
  echo ""
  echo "🔍 Phase 3: Verify installation"
  echo ""

  local ok=0 fail=0

  # Check key files are readable
  for check in \
    "AGENT_INIT.md:$JOYA_LIB/AGENT_INIT.md" \
    "IDENTITY.md:$AGENT_DIR/IDENTITY.md" \
    "PRINCIPAL.md:$CONFIG_DIR/PRINCIPAL.md" \
    "PLAYBOOK.md:$CONFIG_DIR/PLAYBOOK.md" \
    "INFRASTRUCTURE.md:$CONFIG_DIR/INFRASTRUCTURE.md" \
    "ROSTER.md:$JOYA_MY/agents/ROSTER.md" \
    "DIRECTORY.json:$JOYA_MY/agents/DIRECTORY.json"
  do
    local label="${check%%:*}"
    local path="${check#*:}"
    if [[ -f "$path" ]]; then
      echo "   ✅ $label"
      ok=$((ok + 1))
    else
      echo "   ❌ $label — not found: $path"
      fail=$((fail + 1))
    fi
  done

  # Check MEMORY.md link/pointer
  if [[ "$USE_SYMLINKS" == true ]]; then
    if [[ -L "$WORKSPACE/MEMORY.md" ]] && [[ -f "$WORKSPACE/MEMORY.md" ]]; then
      echo "   ✅ MEMORY.md symlink resolves"
      ok=$((ok + 1))
    else
      echo "   ❌ MEMORY.md symlink broken"
      fail=$((fail + 1))
    fi
  else
    if [[ -f "$WORKSPACE/MEMORY.md" ]] && grep -q "JOYA" "$WORKSPACE/MEMORY.md" 2>/dev/null; then
      echo "   ✅ MEMORY.md pointer file"
      ok=$((ok + 1))
      # Also verify the target is readable
      if [[ -f "$AGENT_DIR/MEMORY.md" ]]; then
        echo "   ✅ MEMORY.md target readable"
        ok=$((ok + 1))
      else
        echo "   ⚠️  MEMORY.md target not found (will be created on first write)"
      fi
    else
      echo "   ❌ MEMORY.md missing or not a pointer"
      fail=$((fail + 1))
    fi
  fi

  # Check framework version
  if [[ -f "$JOYA_LIB/VERSION" ]]; then
    local ver
    ver=$(cat "$JOYA_LIB/VERSION" | tr -d '[:space:]')
    echo "   ✅ Framework v$ver"
  else
    echo "   ⚠️  VERSION file not found"
  fi

  echo ""
  echo "   📊 $ok passed, $fail failed."
  [[ $fail -gt 0 ]] && return 1
  return 0
}

# =============================================================
# INSTALL
# =============================================================
install_adapter() {
  echo "🚀 Installing JOYA adapter for OpenClaw"
  echo "   Agent:     $AGENT_NAME"
  echo "   Joy Root:  $JOY_ROOT"
  echo "   Agent Dir: $AGENT_DIR"
  echo "   Workspace: $WORKSPACE"

  if [[ -f "$MARKER" ]] && [[ "${FORCE:-}" != "true" ]]; then
    echo ""
    echo "⚠️  Already installed. Pass --force env or remove $MARKER first."
    echo "   To check status: $(basename "$0") status $AGENT_NAME"
    exit 1
  fi

  [[ ! -d "$AGENT_DIR" ]] && { echo "❌ Agent dir not found: $AGENT_DIR"; exit 1; }
  [[ ! -f "$JOYA_LIB/AGENT_INIT.md" ]] && { echo "❌ Framework not found: $JOYA_LIB/AGENT_INIT.md"; exit 1; }

  import_data
  link_workspace

  if verify_install; then
    # Write marker
    cat > "$MARKER" << EOF
agent=$AGENT_NAME
joy_root=$JOY_ROOT
workspace=$WORKSPACE
os=$OS_TYPE
symlinks=$USE_SYMLINKS
installed=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

    echo ""
    echo "════════════════════════════════════════════════════"
    echo "✅ Done! OpenClaw workspace connected to JOYA."
    echo "   Agent identity: $DISPLAY_AGENT_DIR/IDENTITY.md"
    echo "   Agent memory:   $DISPLAY_AGENT_DIR/MEMORY.md"
    echo "   To undo: $(basename "$0") uninstall $AGENT_NAME"
    echo "════════════════════════════════════════════════════"
  else
    echo ""
    echo "⚠️  Installation completed with errors. Check paths above."
    echo "   Marker NOT written — fix issues and re-run install."
    exit 1
  fi
}

# =============================================================
# UNINSTALL
# =============================================================
uninstall_adapter() {
  echo "🔓 Uninstalling JOYA adapter for OpenClaw (agent: $AGENT_NAME)"

  if [[ ! -f "$MARKER" ]]; then
    echo "⚠️  Not installed (no marker at $MARKER)."
    exit 1
  fi

  # Export latest memory before unlink
  if [[ -L "$WORKSPACE/MEMORY.md" ]]; then
    local joy_mem
    joy_mem=$(readlink "$WORKSPACE/MEMORY.md")
    if [[ -f "$joy_mem" ]]; then
      cp "$joy_mem" "$WORKSPACE/MEMORY.md.joy-export"
      echo "   📤 Exported latest memory to MEMORY.md.joy-export"
    fi
  fi

  # Restore backups
  for f in $MANAGED_FILES; do
    local target="$WORKSPACE/$f"
    local backup="${target}${BACKUP_SUFFIX}"
    local link_backup="${target}${BACKUP_SUFFIX}.link"

    # Remove current (bridge/symlink)
    rm -f "$target"

    if [[ -f "$link_backup" ]]; then
      local link_target
      link_target=$(cat "$link_backup")
      ln -sf "$link_target" "$target"
      rm "$link_backup"
      echo "   ✅ Restored symlink: $f → $link_target"
    elif [[ -f "$backup" ]]; then
      mv "$backup" "$target"
      echo "   ✅ Restored: $f"
    else
      echo "   ⏭️  $f: no backup found"
    fi
  done

  rm -f "$MARKER"
  echo ""
  echo "✅ Done! OpenClaw workspace restored to standalone mode."
  echo "   JOYA files remain intact at: $AGENT_DIR"
  echo "   Latest memory exported as MEMORY.md.joy-export"
}

# =============================================================
# STATUS
# =============================================================
check_status() {
  echo "🔍 JOYA Adapter Status (OpenClaw)"
  echo "   Workspace: $WORKSPACE"
  echo ""

  if [[ -f "$MARKER" ]]; then
    echo "   Status: ✅ INSTALLED"
    sed 's/^/   /' "$MARKER"
    echo ""

    # Check bridge files
    echo "   Bridge files:"
    for f in $MANAGED_FILES; do
      local path="$WORKSPACE/$f"
      if [[ -L "$path" ]]; then
        local target
        target=$(readlink "$path")
        if [[ -f "$path" ]]; then
          echo "      ✅ $f → $target"
        else
          echo "      ❌ $f → $target (BROKEN symlink)"
        fi
      elif [[ -f "$path" ]]; then
        if grep -q "JOYA" "$path" 2>/dev/null; then
          echo "      ✅ $f (bridge)"
        else
          echo "      ⚠️  $f (not a JOYA bridge)"
        fi
      else
        echo "      ❌ $f (missing)"
      fi
    done

    echo ""
    echo "   File access:"

    # Key files
    for check in \
      "Framework:$JOYA_LIB/AGENT_INIT.md" \
      "Identity:$AGENT_DIR/IDENTITY.md" \
      "Principal:$CONFIG_DIR/PRINCIPAL.md" \
      "Roster:$JOYA_MY/agents/ROSTER.md"
    do
      local label="${check%%:*}"
      local path="${check#*:}"
      if [[ -f "$path" ]]; then
        echo "      ✅ $label"
      else
        echo "      ❌ $label — $path"
      fi
    done

    # Framework version
    if [[ -f "$JOYA_LIB/VERSION" ]]; then
      local ver
      ver=$(cat "$JOYA_LIB/VERSION" | tr -d '[:space:]')
      echo "      ✅ Framework v$ver"
    fi

    # OS and mode
    echo ""
    echo "   OS: $OS_TYPE (symlinks: $USE_SYMLINKS)"

    # Backup count
    local backup_count
    backup_count=$(find "$WORKSPACE" -name "*${BACKUP_SUFFIX}*" 2>/dev/null | wc -l | tr -d ' ')
    echo "   Backups: $backup_count files"
  else
    echo "   Status: ❌ NOT INSTALLED"
    echo "   Run: $(basename "$0") install $AGENT_NAME"
  fi
}

# =============================================================
# DISPATCH
# =============================================================
case "$ACTION" in
  install)   install_adapter ;;
  uninstall) uninstall_adapter ;;
  status)    check_status ;;
  *) echo "Unknown action: $ACTION"; exit 1 ;;
esac
