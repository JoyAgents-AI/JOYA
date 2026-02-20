#!/usr/bin/env bash
# selfcheck.sh - JOYA Self-Check Script
# Usage: selfcheck.sh [--quiet] [--log] [--extend item1 item2 ...]

# Exit codes
# 0: All pass
# 1: Partial fail (DEGRADED)
# 2: Severe fail (unable to continue)

set -euo pipefail

# Configuration
JOY_ROOT="${JOY_ROOT:-/path/to/joy-agents}"  # Set this to actual root
AGENT_DIR="$JOY_ROOT/instance/agents/$(whoami)"  # Assume agent name from user
LOG_FILE="$JOY_ROOT/.joy/selfcheck.log"

# Parse arguments
QUIET=0
LOG=0
EXTEND_ITEMS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --quiet) QUIET=1; shift ;;
    --log) LOG=1; shift ;;
    --extend) shift; while [[ $# -gt 0 && ! $1 == --* ]]; do EXTEND_ITEMS+=("$1"); shift; done ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

# Function to perform a check and output
check() {
  local name="$1"
  local command="$2"
  if eval "$command" &>/dev/null; then
    result="✅"
    status=0
  else
    result="❌"
    status=1
  fi
  if [ $QUIET -eq 0 ]; then
    echo "$result $name"
  fi
  return $status
}

# Log function
log_result() {
  if [ $LOG -eq 1 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
  fi
}

# Perform checks
overall_status=0
check "协议文件加载" "test -r $JOY_ROOT/framework/core/AXIOMS.md && test -r $AGENT_DIR/IDENTITY.md" || overall_status=1
check "通讯能力" "command -v agent-send-md >/dev/null" || overall_status=1  # Example: check if messaging tool exists
check "文件读写能力" "touch $AGENT_DIR/test.tmp && rm $AGENT_DIR/test.tmp" || { overall_status=2; log_result "Severe: File RW failed"; }
check "记忆加载" "test -r $AGENT_DIR/MEMORY.md" || overall_status=1
check "工具/技能基线可用性" "command -v git >/dev/null" || overall_status=1  # Example: check for a basic tool like git

# Extend items (instance-specific)
for item in "${EXTEND_ITEMS[@]}"; do
  # Placeholder: instance defines how to check these
  check "$item" "true" || overall_status=1  # Replace with actual checks
done

# Log overall
log_result "Self-check completed with status $overall_status"

# Exit with appropriate code
if [ $overall_status -eq 2 ]; then
  exit 2
elif [ $overall_status -eq 1 ]; then
  exit 1
else
  exit 0
fi
