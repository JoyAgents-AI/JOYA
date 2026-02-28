#!/usr/bin/env bash
# joy-validate.sh — Validate a JOYA instance against the protocol
# Usage: joy-validate.sh [joya-root]
#   joya-root defaults to ~/joya (parent of lib/ and my/)
#
# Expected structure:
#   <root>/lib/          — Framework (this repo)
#   <root>/my/           — Instance data
#   <root>/my/agents/    — Agent directories + ROSTER.md + DIRECTORY.json
#   <root>/my/shared/core/ — PRINCIPAL.md, PLAYBOOK.md, INFRASTRUCTURE.md

set -euo pipefail

ROOT="${1:-$HOME/joya}"
LIB="$ROOT/lib"
MY="$ROOT/my"
ERRORS=0
WARNINGS=0

pass()  { echo "  ✅ $1"; }
fail()  { echo "  ❌ $1"; ERRORS=$((ERRORS + 1)); }
warn()  { echo "  ⚠️  $1"; WARNINGS=$((WARNINGS + 1)); }

echo "🔍 Validating JOYA: $ROOT"
echo "   lib: $LIB"
echo "   my:  $MY"
echo ""

# --- Protocol structure (lib/core/) ---
echo "📋 Protocol structure"
[[ -f "$LIB/core/AXIOMS.md" ]]          && pass "AXIOMS.md exists"          || fail "AXIOMS.md missing"
[[ -f "$LIB/core/RULES.md" ]]           && pass "RULES.md exists"           || fail "RULES.md missing"
[[ -f "$LIB/core/ARCHITECTURE.md" ]]    && pass "ARCHITECTURE.md exists"    || fail "ARCHITECTURE.md missing"
[[ -f "$LIB/core/ACCOUNTABILITY.md" ]]  && pass "ACCOUNTABILITY.md exists"  || fail "ACCOUNTABILITY.md missing"
[[ -f "$LIB/core/CHANGELOG.md" ]]       && pass "CHANGELOG.md exists"       || fail "CHANGELOG.md missing"
[[ -f "$LIB/AGENT_INIT.md" ]]           && pass "AGENT_INIT.md exists"      || fail "AGENT_INIT.md missing"
echo ""

# --- Instance structure (my/) ---
echo "📋 Instance structure"
[[ -d "$MY" ]]                           && pass "my/ exists"                || fail "my/ missing"
[[ -d "$MY/agents" ]]                    && pass "my/agents/ exists"         || fail "my/agents/ missing"
# ROSTER.md and DIRECTORY.json can be in my/agents/ or my/shared/agents/
ROSTER=""; DIRECTORY=""
[[ -f "$MY/agents/ROSTER.md" ]]          && ROSTER="$MY/agents/ROSTER.md"
[[ -f "$MY/shared/agents/ROSTER.md" ]]   && ROSTER="$MY/shared/agents/ROSTER.md"
[[ -f "$MY/agents/DIRECTORY.json" ]]     && DIRECTORY="$MY/agents/DIRECTORY.json"
[[ -f "$MY/shared/agents/DIRECTORY.json" ]] && DIRECTORY="$MY/shared/agents/DIRECTORY.json"
[[ -n "$ROSTER" ]]    && pass "ROSTER.md exists ($ROSTER)"       || fail "ROSTER.md missing"
[[ -n "$DIRECTORY" ]] && pass "DIRECTORY.json exists ($DIRECTORY)" || fail "DIRECTORY.json missing"
[[ -d "$MY/shared/core" ]]              && pass "my/shared/core/ exists"    || fail "my/shared/core/ missing"
[[ -f "$MY/shared/core/PRINCIPAL.md" ]] && pass "PRINCIPAL.md exists"       || fail "PRINCIPAL.md missing"
[[ -f "$MY/shared/core/PLAYBOOK.md" ]]  && pass "PLAYBOOK.md exists"       || warn "PLAYBOOK.md missing"
[[ -f "$MY/shared/core/INFRASTRUCTURE.md" ]] && pass "INFRASTRUCTURE.md exists" || warn "INFRASTRUCTURE.md missing"
echo ""

# --- Manager requirement (R11) ---
echo "📋 Manager requirement (R11)"
if [[ -n "$ROSTER" ]]; then
  if grep -qi "manager" "$ROSTER"; then
    pass "At least one Manager found in ROSTER.md"
  else
    fail "No Manager role found in ROSTER.md — R11 requires exactly one"
  fi
fi
echo ""

# --- Agent directories ---
echo "📋 Agent identity files"
if [[ -n "$DIRECTORY" ]]; then
  # Support both v2 ("name": "x") and v3 (top-level keys under "agents")
  AGENTS=$(python3 -c "
import json, sys
with open('$DIRECTORY') as f:
    d = json.load(f)
a = d.get('agents', d)
if isinstance(a, dict):
    print(' '.join(a.keys()))
elif isinstance(a, list):
    print(' '.join(x.get('name','') for x in a))
" 2>/dev/null || grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$DIRECTORY" | sed 's/.*"\([^"]*\)".*/\1/')
  for agent in $AGENTS; do
    AGENT_DIR="$MY/agents/$agent"
    if [[ -d "$AGENT_DIR" ]]; then
      [[ -f "$AGENT_DIR/IDENTITY.md" ]] && pass "$agent: IDENTITY.md exists" || warn "$agent: IDENTITY.md missing (recommended)"
    else
      warn "$agent: agent directory missing (my/agents/$agent/)"
    fi
  done
fi
echo ""

# --- Shared traits ---
echo "📋 Shared traits"
[[ -d "$MY/agents/_shared" ]] && pass "_shared/ exists" || warn "_shared/ missing (recommended)"
echo ""

# --- Override validation (R9) ---
echo "📋 Override validation (R9)"
if [[ -d "$MY/shared/rules" ]]; then
  for rule_file in "$MY"/shared/rules/*.md; do
    [[ -f "$rule_file" ]] || continue
    basename_f=$(basename "$rule_file")
    [[ "$basename_f" == "README.md" ]] && continue

    target=$(grep -m1 "^overrides:" "$rule_file" 2>/dev/null | sed 's/overrides:[[:space:]]*//' || true)
    if [[ -n "$target" ]]; then
      # Resolve $JOYA_LIB and $JOYA_MY references
      resolved="${target//\$JOYA_LIB/$LIB}"
      resolved="${resolved//\$JOYA_MY/$MY}"
      resolved="${resolved%%#*}"  # strip anchor
      if [[ ! -f "$resolved" ]]; then
        warn "Override target not found: $target (in $basename_f)"
      fi
    fi

    target=$(grep -m1 "^patches:" "$rule_file" 2>/dev/null | sed 's/patches:[[:space:]]*//' || true)
    if [[ -n "$target" ]]; then
      resolved="${target//\$JOYA_LIB/$LIB}"
      resolved="${resolved//\$JOYA_MY/$MY}"
      resolved="${resolved%%#*}"
      if [[ ! -f "$resolved" ]]; then
        warn "Patch target not found: $target (in $basename_f)"
      fi
    fi

    if grep -q "overrides:.*AXIOMS" "$rule_file" 2>/dev/null || grep -q "patches:.*AXIOMS" "$rule_file" 2>/dev/null; then
      fail "Axiom override/patch attempted in $basename_f — axioms are immutable (R9)"
    fi
  done
  pass "Override files scanned"
fi
echo ""

# --- Project registrations ---
echo "📋 Project registrations"
if [[ -d "$MY/shared/projects" ]]; then
  for proj_dir in "$MY"/shared/projects/*/; do
    [[ -d "$proj_dir" ]] || continue
    proj_name=$(basename "$proj_dir")
    [[ -f "$proj_dir/README.md" ]] && pass "Project $proj_name: README.md exists" || warn "Project $proj_name: README.md missing"
  done
else
  warn "my/shared/projects/ missing"
fi
echo ""

# --- Framework version ---
echo "📋 Framework version"
if [[ -f "$LIB/VERSION" ]]; then
  pass "VERSION: $(cat "$LIB/VERSION")"
else
  warn "VERSION file not found"
fi
echo ""

# --- Summary ---
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
  echo "🎉 All checks passed!"
elif [[ $ERRORS -eq 0 ]]; then
  echo "✅ Passed with $WARNINGS warning(s)"
else
  echo "❌ $ERRORS error(s), $WARNINGS warning(s)"
fi
exit $ERRORS
