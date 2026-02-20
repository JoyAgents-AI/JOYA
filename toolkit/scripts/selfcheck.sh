#!/usr/bin/env bash
# selfcheck.sh — JOYA agent self-check
# Usage: selfcheck.sh [joya-root] [agent-name]
#   joya-root defaults to ~/joya
#   agent-name defaults to hostname-based detection
#
# Exit codes: 0=all pass, 1=partial fail, 2=severe fail

set -uo pipefail

ROOT="${1:-$HOME/joya}"
AGENT_NAME="${2:-}"
LIB="$ROOT/lib"
MY="$ROOT/my"

# Auto-detect agent name if not provided
if [[ -z "$AGENT_NAME" ]]; then
  # Look for agent dirs and pick first one with our hostname in identity
  for d in "$MY"/agents/*/; do
    [[ -d "$d" ]] || continue
    [[ "$(basename "$d")" == "_shared" ]] && continue
    AGENT_NAME="$(basename "$d")"
    break
  done
fi

AGENT_DIR="$MY/agents/$AGENT_NAME"
OVERALL=0
PASS=0
FAIL=0

check() {
  local name="$1"
  shift
  if "$@" 2>/dev/null; then
    echo "  ✅ $name"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $name"
    FAIL=$((FAIL + 1))
    return 1
  fi
}

echo "🔍 JOYA Self-Check"
echo "   Root: $ROOT"
echo "   Agent: $AGENT_NAME"
echo ""

# --- Protocol files ---
echo "📋 Protocol"
check "AXIOMS.md readable"       test -r "$LIB/core/AXIOMS.md"         || OVERALL=1
check "RULES.md readable"        test -r "$LIB/core/RULES.md"          || OVERALL=1
check "AGENT_INIT.md readable"   test -r "$LIB/AGENT_INIT.md"          || OVERALL=2
echo ""

# --- Agent identity ---
echo "📋 Agent identity"
check "Agent dir exists"         test -d "$AGENT_DIR"                   || OVERALL=2
check "IDENTITY.md readable"     test -r "$AGENT_DIR/IDENTITY.md"       || OVERALL=1
check "MEMORY.md readable"       test -r "$AGENT_DIR/MEMORY.md"         || OVERALL=1
echo ""

# --- File I/O ---
echo "📋 File I/O"
if check "Write test" touch "$AGENT_DIR/.selfcheck.tmp"; then
  rm -f "$AGENT_DIR/.selfcheck.tmp"
else
  OVERALL=2
fi
echo ""

# --- Instance config ---
echo "📋 Instance config"
check "PRINCIPAL.md exists"      test -f "$MY/shared/core/PRINCIPAL.md"  || OVERALL=1
check "PLAYBOOK.md exists"       test -f "$MY/shared/core/PLAYBOOK.md"   || true
check "INFRASTRUCTURE.md exists" test -f "$MY/shared/core/INFRASTRUCTURE.md" || true
echo ""

# --- Basic tools ---
echo "📋 Tools"
check "git available"            command -v git                          || OVERALL=1
check "curl available"           command -v curl                         || true
check "python3 available"        command -v python3                      || true
echo ""

# --- Summary ---
TOTAL=$((PASS + FAIL))
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $OVERALL -eq 0 ]]; then
  echo "🎉 All $TOTAL checks passed!"
elif [[ $OVERALL -eq 1 ]]; then
  echo "⚠️  DEGRADED — $PASS/$TOTAL passed"
else
  echo "❌ SEVERE — $PASS/$TOTAL passed"
fi

exit $OVERALL
