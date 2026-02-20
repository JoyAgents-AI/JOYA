#!/usr/bin/env bash
# joy-validate.sh — Validate a JOYA instance against the protocol
# Usage: joy-validate.sh [joy-agents-root]

set -euo pipefail

ROOT="${1:-.}"
ERRORS=0
WARNINGS=0

pass()  { echo "  ✅ $1"; }
fail()  { echo "  ❌ $1"; ERRORS=$((ERRORS + 1)); }
warn()  { echo "  ⚠️  $1"; WARNINGS=$((WARNINGS + 1)); }

echo "🔍 Validating JOYA: $ROOT"
echo ""

# --- Protocol structure ---
echo "📋 Protocol structure"
[[ -f "$ROOT/protocol/core/AXIOMS.md" ]]        && pass "AXIOMS.md exists"        || fail "AXIOMS.md missing"
[[ -f "$ROOT/protocol/core/RULES.md" ]]          && pass "RULES.md exists"          || fail "RULES.md missing"
[[ -f "$ROOT/protocol/core/ARCHITECTURE.md" ]]   && pass "ARCHITECTURE.md exists"   || fail "ARCHITECTURE.md missing"
[[ -f "$ROOT/protocol/core/ACCOUNTABILITY.md" ]]  && pass "ACCOUNTABILITY.md exists" || fail "ACCOUNTABILITY.md missing"
[[ -f "$ROOT/protocol/core/CHANGELOG.md" ]]       && pass "CHANGELOG.md exists"      || fail "CHANGELOG.md missing"
echo ""

# --- Instance structure ---
echo "📋 Instance structure"
[[ -d "$ROOT/instance" ]]                         && pass "instance/ exists"         || fail "instance/ missing"
[[ -d "$ROOT/instance/agents" ]]                  && pass "instance/agents/ exists"  || fail "instance/agents/ missing"
[[ -f "$ROOT/instance/agents/ROSTER.md" ]]        && pass "ROSTER.md exists"         || fail "ROSTER.md missing"
[[ -f "$ROOT/instance/agents/DIRECTORY.json" ]]   && pass "DIRECTORY.json exists"    || fail "DIRECTORY.json missing"
[[ -d "$ROOT/instance/shared/config" ]]                  && pass "instance/shared/core/ exists"  || fail "instance/shared/core/ missing"
[[ -f "$ROOT/instance/shared/core/PRINCIPAL.md" ]]     && pass "PRINCIPAL.md exists"      || fail "PRINCIPAL.md missing"
echo ""

# --- Manager requirement (R11) ---
echo "📋 Manager requirement (R11)"
if [[ -f "$ROOT/instance/agents/ROSTER.md" ]]; then
  if grep -qi "manager" "$ROOT/instance/agents/ROSTER.md"; then
    pass "At least one Manager found in ROSTER.md"
  else
    fail "No Manager role found in ROSTER.md — R11 requires exactly one"
  fi
fi
echo ""

# --- Agent directories ---
echo "📋 Agent identity files"
if [[ -f "$ROOT/instance/agents/DIRECTORY.json" ]]; then
  # Extract agent names from DIRECTORY.json (simple grep, no jq dependency)
  AGENTS=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$ROOT/instance/agents/DIRECTORY.json" | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
  for agent in $AGENTS; do
    AGENT_DIR="$ROOT/instance/agents/$agent"
    if [[ -d "$AGENT_DIR" ]]; then
      [[ -f "$AGENT_DIR/IDENTITY.md" ]] && pass "$agent: IDENTITY.md exists" || warn "$agent: IDENTITY.md missing (recommended)"
    else
      warn "$agent: agent directory missing (instance/agents/$agent/)"
    fi
  done
fi
echo ""

# --- _shared directory ---
echo "📋 Shared traits"
[[ -d "$ROOT/instance/agents/_shared" ]] && pass "_shared/ exists" || warn "_shared/ missing (recommended)"
echo ""

# --- Override validation (R9) ---
echo "📋 Override validation (R9)"
if [[ -d "$ROOT/instance/shared/rules" ]]; then
  for rule_file in "$ROOT"/instance/shared/rules/*.md; do
    [[ -f "$rule_file" ]] || continue
    basename_f=$(basename "$rule_file")
    [[ "$basename_f" == "README.md" ]] && continue

    # Check for override/patch targets
    target=$(grep -m1 "^overrides:" "$rule_file" 2>/dev/null | sed 's/overrides:[[:space:]]*//' || true)
    if [[ -n "$target" && ! -f "$ROOT/$target" ]]; then
      fail "Override target not found: $target (in $basename_f)"
    fi

    target=$(grep -m1 "^patches:" "$rule_file" 2>/dev/null | sed 's/patches:[[:space:]]*//' || true)
    if [[ -n "$target" && ! -f "$ROOT/$target" ]]; then
      fail "Patch target not found: $target (in $basename_f)"
    fi

    # Check axiom override attempt
    if grep -q "overrides:.*AXIOMS" "$rule_file" 2>/dev/null || grep -q "patches:.*AXIOMS" "$rule_file" 2>/dev/null; then
      fail "Axiom override/patch attempted in $basename_f — axioms are immutable (R9)"
    fi
  done
  pass "Override files scanned"
fi
echo ""

# --- Project .joy/ directories ---
echo "📋 Project registrations"
if [[ -d "$ROOT/instance/shared/projects" ]]; then
  for proj_dir in "$ROOT"/instance/shared/projects/*/; do
    [[ -d "$proj_dir" ]] || continue
    proj_name=$(basename "$proj_dir")
    [[ -f "$proj_dir/META.md" ]]  && pass "Project $proj_name: META.md exists"  || warn "Project $proj_name: META.md missing"
    [[ -f "$proj_dir/PATHS.md" ]] && pass "Project $proj_name: PATHS.md exists" || warn "Project $proj_name: PATHS.md missing"

    # Check if .joy/ exists at project root
    if [[ -f "$proj_dir/PATHS.md" ]]; then
      proj_root=$(grep -m1 "^root:" "$proj_dir/PATHS.md" 2>/dev/null | sed 's/root:[[:space:]]*//' || true)
      if [[ -n "$proj_root" && -d "$proj_root" ]]; then
        [[ -d "$proj_root/.joy" ]] && pass "Project $proj_name: .joy/ exists at $proj_root" || warn "Project $proj_name: .joy/ missing at $proj_root — run joy-init.sh"
      fi
    fi
  done
else
  warn "instance/shared/projects/ missing"
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
