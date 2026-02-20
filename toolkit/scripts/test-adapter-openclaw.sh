#!/usr/bin/env bash
# test-adapter-openclaw.sh — Test suite for joy-adapter-openclaw.sh
#
# Usage:
#   test-adapter-openclaw.sh                    # test on current OS
#   test-adapter-openclaw.sh --mock-os windows  # simulate Windows behavior
#   test-adapter-openclaw.sh --mock-os linux    # simulate Linux behavior
#   test-adapter-openclaw.sh --mock-os macos    # simulate macOS behavior
#
# Runs in a temporary sandbox. Does NOT touch any real workspace or joya directory.
# Exit code 0 = all tests passed, 1 = some failed.

set -uo pipefail
# Note: NOT using set -e — test assertions handle errors themselves

MOCK_OS=""
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ADAPTER="$SCRIPT_DIR/joy-adapter-openclaw.sh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mock-os) MOCK_OS="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# Colors
RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[0;33m' CYAN='\033[0;36m' NC='\033[0m'

PASS=0 FAIL=0 TOTAL=0

assert() {
  local desc="$1"; shift
  TOTAL=$((TOTAL + 1))
  local result=0
  "$@" 2>/dev/null || result=$?
  if [[ $result -eq 0 ]]; then
    echo -e "   ${GREEN}✅ $desc${NC}"
    PASS=$((PASS + 1))
  else
    echo -e "   ${RED}❌ $desc${NC}"
    FAIL=$((FAIL + 1))
  fi
}

assert_not() {
  local desc="$1"; shift
  TOTAL=$((TOTAL + 1))
  local result=0
  "$@" 2>/dev/null || result=$?
  if [[ $result -ne 0 ]]; then
    echo -e "   ${GREEN}✅ $desc${NC}"
    PASS=$((PASS + 1))
  else
    echo -e "   ${RED}❌ $desc (expected false, got true)${NC}"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local desc="$1" file="$2" pattern="$3"
  TOTAL=$((TOTAL + 1))
  if grep -q "$pattern" "$file" 2>/dev/null; then
    echo -e "   ${GREEN}✅ $desc${NC}"
    PASS=$((PASS + 1))
  else
    echo -e "   ${RED}❌ $desc (pattern '$pattern' not in $file)${NC}"
    FAIL=$((FAIL + 1))
  fi
}

# =============================================================
# SETUP SANDBOX
# =============================================================
SANDBOX=$(mktemp -d)
trap 'rm -rf "$SANDBOX"' EXIT

JOY_ROOT="$SANDBOX/joya"
WORKSPACE="$SANDBOX/workspace"

setup_sandbox() {
  # Create minimal joya structure
  mkdir -p "$JOY_ROOT/lib/core"
  mkdir -p "$JOY_ROOT/lib/guides"
  mkdir -p "$JOY_ROOT/lib/toolkit/scripts"
  mkdir -p "$JOY_ROOT/my/agents/testbot"
  mkdir -p "$JOY_ROOT/my/agents/_shared"
  mkdir -p "$JOY_ROOT/my/shared/config"

  echo "# JOYA — Agent Entry Point" > "$JOY_ROOT/lib/AGENT_INIT.md"
  echo "1.2.0" > "$JOY_ROOT/lib/VERSION"
  echo "# Architecture" > "$JOY_ROOT/lib/core/ARCHITECTURE.md"
  echo "# Rules" > "$JOY_ROOT/lib/core/RULES.md"
  echo "# Lifecycle" > "$JOY_ROOT/lib/guides/LIFECYCLE.md"

  cat > "$JOY_ROOT/my/agents/testbot/IDENTITY.md" << 'EOF'
# TestBot

## Profile
- **Name:** TestBot
- **Role:** Worker
- **Model:** test-model-v1
EOF

  echo "# TestBot Memory" > "$JOY_ROOT/my/agents/testbot/MEMORY.md"
  echo "# Principal" > "$JOY_ROOT/my/shared/core/PRINCIPAL.md"
  echo "# Playbook" > "$JOY_ROOT/my/shared/core/PLAYBOOK.md"
  echo "# Infrastructure" > "$JOY_ROOT/my/shared/core/INFRASTRUCTURE.md"

  cat > "$JOY_ROOT/my/agents/ROSTER.md" << 'EOF'
# Roster
| Agent | Role | Status |
|-------|------|--------|
| TestBot | Worker | active |
EOF

  echo '{"agents":[]}' > "$JOY_ROOT/my/agents/DIRECTORY.json"

  # Create workspace with fake existing content (to test import + backup)
  mkdir -p "$WORKSPACE"
  echo "# Old Soul - should be backed up" > "$WORKSPACE/SOUL.md"
  echo "# Old Memory - should be imported" > "$WORKSPACE/MEMORY.md"
  echo "line2" >> "$WORKSPACE/MEMORY.md"
  echo "line3" >> "$WORKSPACE/MEMORY.md"
  echo "line4" >> "$WORKSPACE/MEMORY.md"
  echo "line5" >> "$WORKSPACE/MEMORY.md"
  echo "line6 - enough to trigger import" >> "$WORKSPACE/MEMORY.md"
  echo "# Old Identity" > "$WORKSPACE/IDENTITY.md"
  echo "# My Tools" > "$WORKSPACE/TOOLS.md"

  # Copy adapter to sandbox (so it can be found)
  cp "$ADAPTER" "$JOY_ROOT/lib/toolkit/scripts/"
  chmod +x "$JOY_ROOT/lib/toolkit/scripts/joy-adapter-openclaw.sh"
}

# =============================================================
# MOCK OS SUPPORT
# =============================================================
# If --mock-os is set, we patch the adapter to force the OS detection
prepare_adapter() {
  local adapter_path="$JOY_ROOT/lib/toolkit/scripts/joy-adapter-openclaw.sh"

  if [[ -n "$MOCK_OS" ]]; then
    # Override the detect_os function result
    case "$MOCK_OS" in
      windows)
        sed -i.bak 's/^detect_os$/OS_TYPE="windows"; USE_SYMLINKS=false/' "$adapter_path"
        ;;
      linux)
        sed -i.bak 's/^detect_os$/OS_TYPE="linux"; USE_SYMLINKS=true/' "$adapter_path"
        ;;
      macos)
        sed -i.bak 's/^detect_os$/OS_TYPE="macos"; USE_SYMLINKS=true/' "$adapter_path"
        ;;
      *)
        echo "Unknown mock OS: $MOCK_OS"; exit 1
        ;;
    esac
    rm -f "${adapter_path}.bak"
  fi
}

# =============================================================
# TEST CASES
# =============================================================

test_install() {
  local adapter="$JOY_ROOT/lib/toolkit/scripts/joy-adapter-openclaw.sh"
  echo -e "\n${CYAN}── Test: install ──${NC}"

  local output
  output=$("$adapter" install testbot --joy-root "$JOY_ROOT" --workspace "$WORKSPACE" 2>&1)
  local exit_code=$?

  assert "install exits 0" test $exit_code -eq 0

  # Bridge files created
  assert "AGENTS.md exists" test -f "$WORKSPACE/AGENTS.md"
  assert "SOUL.md exists" test -f "$WORKSPACE/SOUL.md"
  assert "IDENTITY.md exists" test -f "$WORKSPACE/IDENTITY.md"
  assert "USER.md exists" test -f "$WORKSPACE/USER.md"
  assert "BOOTSTRAP.md exists" test -f "$WORKSPACE/BOOTSTRAP.md"
  assert "HEARTBEAT.md exists" test -f "$WORKSPACE/HEARTBEAT.md"

  # Bridge files contain JOYA reference
  assert_contains "AGENTS.md references JOYA" "$WORKSPACE/AGENTS.md" "JOYA"
  assert_contains "AGENTS.md has agent path" "$WORKSPACE/AGENTS.md" "testbot"
  # Stub files should reference AGENTS.md (minimal content)
  assert_contains "SOUL.md is stub" "$WORKSPACE/SOUL.md" "managed by AGENTS.md"
  assert_contains "IDENTITY.md is stub" "$WORKSPACE/IDENTITY.md" "managed by AGENTS.md"
  assert_contains "USER.md is stub" "$WORKSPACE/USER.md" "managed by AGENTS.md"

  # MEMORY.md handling depends on OS
  if [[ "${MOCK_OS:-$OS_TYPE}" == "windows" ]] || [[ "$USE_SYMLINKS" == false ]]; then
    assert "MEMORY.md is a regular file (Windows pointer)" test -f "$WORKSPACE/MEMORY.md" -a ! -L "$WORKSPACE/MEMORY.md"
    assert_contains "MEMORY.md pointer references agent dir" "$WORKSPACE/MEMORY.md" "JOYA"
  else
    assert "MEMORY.md is a symlink" test -L "$WORKSPACE/MEMORY.md"
    local link_target
    link_target=$(readlink "$WORKSPACE/MEMORY.md")
    assert "MEMORY.md symlink points to agent dir" echo "$link_target" | grep -q "testbot"
  fi

  # Marker file
  assert "marker file exists" test -f "$WORKSPACE/.joy-adapter-openclaw"
  assert_contains "marker has agent name" "$WORKSPACE/.joy-adapter-openclaw" "agent=testbot"
  assert_contains "marker has os type" "$WORKSPACE/.joy-adapter-openclaw" "os="
  assert_contains "marker has symlinks flag" "$WORKSPACE/.joy-adapter-openclaw" "symlinks="

  # Backups created
  assert "SOUL.md backup exists" test -f "$WORKSPACE/SOUL.md.bak.pre-joy"
  assert "IDENTITY.md backup exists" test -f "$WORKSPACE/IDENTITY.md.bak.pre-joy"

  # Import: TOOLS.md copied to agent dir
  assert "TOOLS.md imported to agent dir" test -f "$JOY_ROOT/my/agents/testbot/TOOLS.md"

  # Agent subdirs created
  assert "agent/memory/ dir created" test -d "$JOY_ROOT/my/agents/testbot/memory"
  assert "agent/scripts/ dir created" test -d "$JOY_ROOT/my/agents/testbot/scripts"
  assert "agent/skills/ dir created" test -d "$JOY_ROOT/my/agents/testbot/skills"

  # Output contains success message
  assert "output says Done" echo "$output" | grep -q "Done"
  assert "output says verify passed" echo "$output" | grep -q "8 passed, 0 failed"
}

test_status() {
  local adapter="$JOY_ROOT/lib/toolkit/scripts/joy-adapter-openclaw.sh"
  echo -e "\n${CYAN}── Test: status (installed) ──${NC}"

  local output
  output=$("$adapter" status testbot --joy-root "$JOY_ROOT" --workspace "$WORKSPACE" 2>&1)
  local exit_code=$?

  assert "status exits 0" test $exit_code -eq 0
  assert "status shows INSTALLED" echo "$output" | grep -q "INSTALLED"
  assert "status shows agent name" echo "$output" | grep -q "testbot"
  assert "status shows OS" echo "$output" | grep -q "OS:"
  assert "status shows Framework version" echo "$output" | grep -q "Framework v1.2.0"
  assert "status shows bridge files OK" echo "$output" | grep -q "AGENTS.md"
}

test_reinstall_blocked() {
  local adapter="$JOY_ROOT/lib/toolkit/scripts/joy-adapter-openclaw.sh"
  echo -e "\n${CYAN}── Test: reinstall blocked ──${NC}"

  local output
  output=$("$adapter" install testbot --joy-root "$JOY_ROOT" --workspace "$WORKSPACE" 2>&1 || true)

  assert "reinstall warns already installed" echo "$output" | grep -q "Already installed"
}

test_reinstall_force() {
  local adapter="$JOY_ROOT/lib/toolkit/scripts/joy-adapter-openclaw.sh"
  echo -e "\n${CYAN}── Test: reinstall with FORCE ──${NC}"

  local output
  output=$(FORCE=true "$adapter" install testbot --joy-root "$JOY_ROOT" --workspace "$WORKSPACE" 2>&1)
  local exit_code=$?

  assert "force reinstall exits 0" test $exit_code -eq 0
  assert "force reinstall says Done" echo "$output" | grep -q "Done"
}

test_uninstall() {
  local adapter="$JOY_ROOT/lib/toolkit/scripts/joy-adapter-openclaw.sh"
  echo -e "\n${CYAN}── Test: uninstall ──${NC}"

  local output
  output=$("$adapter" uninstall testbot --joy-root "$JOY_ROOT" --workspace "$WORKSPACE" 2>&1)
  local exit_code=$?

  assert "uninstall exits 0" test $exit_code -eq 0

  # Marker removed
  assert_not "marker file removed" test -f "$WORKSPACE/.joy-adapter-openclaw"

  # Backups restored
  assert "SOUL.md restored from backup" test -f "$WORKSPACE/SOUL.md"
  assert_contains "SOUL.md has original content" "$WORKSPACE/SOUL.md" "Old Soul"
  assert "IDENTITY.md restored" test -f "$WORKSPACE/IDENTITY.md"
  assert_contains "IDENTITY.md has original content" "$WORKSPACE/IDENTITY.md" "Old Identity"

  # Backup files cleaned up
  assert_not "backup file removed after restore" test -f "$WORKSPACE/SOUL.md.bak.pre-joy"

  # Joy export created
  if [[ "${MOCK_OS:-}" != "windows" ]] && [[ "$USE_SYMLINKS" != false ]]; then
    assert "MEMORY.md.joy-export created" test -f "$WORKSPACE/MEMORY.md.joy-export"
  fi
}

test_status_not_installed() {
  local adapter="$JOY_ROOT/lib/toolkit/scripts/joy-adapter-openclaw.sh"
  echo -e "\n${CYAN}── Test: status (not installed) ──${NC}"

  local output
  output=$("$adapter" status testbot --joy-root "$JOY_ROOT" --workspace "$WORKSPACE" 2>&1)

  assert "status shows NOT INSTALLED" echo "$output" | grep -q "NOT INSTALLED"
}

test_missing_agent_dir() {
  local adapter="$JOY_ROOT/lib/toolkit/scripts/joy-adapter-openclaw.sh"
  echo -e "\n${CYAN}── Test: install with missing agent dir ──${NC}"

  local output
  output=$("$adapter" install nonexistent --joy-root "$JOY_ROOT" --workspace "$WORKSPACE" 2>&1 || true)

  assert "fails with error" echo "$output" | grep -q "Agent dir not found"
}

test_missing_framework() {
  local adapter="$JOY_ROOT/lib/toolkit/scripts/joy-adapter-openclaw.sh"
  echo -e "\n${CYAN}── Test: install with missing framework ──${NC}"

  # Temporarily hide AGENT_INIT.md
  mv "$JOY_ROOT/lib/AGENT_INIT.md" "$JOY_ROOT/lib/AGENT_INIT.md.hidden"

  local output
  output=$("$adapter" install testbot --joy-root "$JOY_ROOT" --workspace "$WORKSPACE" 2>&1 || true)

  assert "fails with framework error" echo "$output" | grep -q "Framework not found"

  # Restore
  mv "$JOY_ROOT/lib/AGENT_INIT.md.hidden" "$JOY_ROOT/lib/AGENT_INIT.md"
}

# =============================================================
# RUN
# =============================================================
DETECTED_OS=$(uname -s)
if [[ -n "$MOCK_OS" ]]; then
  echo -e "${YELLOW}🧪 Testing joy-adapter-openclaw.sh — mock OS: $MOCK_OS (real: $DETECTED_OS)${NC}"
else
  echo -e "${YELLOW}🧪 Testing joy-adapter-openclaw.sh — OS: $DETECTED_OS${NC}"
fi
echo "   Sandbox: $SANDBOX"
echo ""

# Detect OS for conditional assertions (mirror adapter's logic)
case "$(uname -s)" in
  Linux*)   OS_TYPE="linux" ;;
  Darwin*)  OS_TYPE="macos" ;;
  CYGWIN*|MINGW*|MSYS*) OS_TYPE="windows" ;;
  *) OS_TYPE="unknown" ;;
esac
USE_SYMLINKS=true
[[ "$OS_TYPE" == "windows" ]] && USE_SYMLINKS=false
# Override if mocking
if [[ -n "$MOCK_OS" ]]; then
  [[ "$MOCK_OS" == "windows" ]] && USE_SYMLINKS=false || USE_SYMLINKS=true
fi

setup_sandbox
prepare_adapter

test_install
test_status
test_reinstall_blocked
test_reinstall_force
test_uninstall
test_status_not_installed
test_missing_agent_dir
test_missing_framework

echo ""
echo -e "════════════════════════════════════════════════"
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}✅ All $TOTAL tests passed${NC}"
else
  echo -e "${RED}❌ $FAIL/$TOTAL tests failed${NC}"
fi
echo -e "════════════════════════════════════════════════"

exit $FAIL
