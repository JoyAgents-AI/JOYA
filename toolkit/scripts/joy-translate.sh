#!/usr/bin/env bash
# joy-translate.sh — Generate translation task list for agent-native translation
#
# Instead of calling external APIs, this script generates a file list
# that the agent translates using its own LLM capabilities.
#
# Usage: joy-translate.sh <locale> [--force] [--list-only]
#   locale:     zhCN, jaJP, koKR, deDE, frFR, esES, etc.
#   --force:    re-translate all files (ignore hash cache)
#   --list-only: just list files that need translation, don't prompt
#
# The agent should:
# 1. Run this script to get the file list
# 2. Switch to a low-cost model (per PREFERENCES.md)
# 3. Read each source file, translate, write to output path
# 4. Run this script again with --update-hashes to mark completion

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
JOY_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
JOYA_LIB="$JOY_ROOT/lib"
JOYA_MY="$JOY_ROOT/my"

LOCALE="${1:-}"
FORCE=false
LIST_ONLY=false
UPDATE_HASHES=false

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=true; shift ;;
    --list-only) LIST_ONLY=true; shift ;;
    --update-hashes) UPDATE_HASHES=true; shift ;;
    *) shift ;;
  esac
done

if [[ -z "$LOCALE" ]]; then
  echo "Usage: joy-translate.sh <locale> [--force] [--list-only]"
  echo "  Locales: zhCN, jaJP, koKR, deDE, frFR, esES, ptBR, ruRU, etc."
  echo ""
  echo "This generates a translation task list. Your agent translates using its own capabilities."
  echo "No API keys needed."
  exit 1
fi

# Language names
get_lang_name() {
  case "$1" in
    zhCN) echo "Simplified Chinese" ;;
    zhTW) echo "Traditional Chinese" ;;
    jaJP) echo "Japanese" ;;
    koKR) echo "Korean" ;;
    deDE) echo "German" ;;
    frFR) echo "French" ;;
    esES) echo "Spanish" ;;
    ptBR) echo "Brazilian Portuguese" ;;
    ruRU) echo "Russian" ;;
    *) echo "$1" ;;
  esac
}

LANG_NAME="$(get_lang_name "$LOCALE")"
OUT_DIR="$JOYA_LIB/i18n-$LOCALE"
HASH_FILE="$OUT_DIR/.translate-hashes"

mkdir -p "$OUT_DIR"
touch "$HASH_FILE"

# Collect source files
SOURCES=()
for dir in "$JOYA_LIB/core" "$JOYA_LIB/guides" "$JOYA_LIB/examples"; do
  [[ -d "$dir" ]] || continue
  while IFS= read -r -d '' f; do
    SOURCES+=("$f")
  done < <(find "$dir" -name "*.md" -print0 2>/dev/null | sort -z)
done

# Also include instance rules/templates if they exist
for dir in "$JOYA_MY/shared/rules" "$JOYA_MY/shared/templates"; do
  [[ -d "$dir" ]] || continue
  while IFS= read -r -d '' f; do
    SOURCES+=("$f")
  done < <(find "$dir" -name "*.md" -print0 2>/dev/null | sort -z)
done

TOTAL=${#SOURCES[@]}
NEED_TRANSLATE=0
SKIPPED=0

# Determine which files need translation
TODO_FILE="$OUT_DIR/.translate-todo"
> "$TODO_FILE"

for src in "${SOURCES[@]}"; do
  # Compute relative path from JOYA root
  rel="${src#$JOYA_LIB/}"
  if [[ "$src" == "$JOYA_MY"* ]]; then
    rel="${src#$JOYA_MY/}"
  fi
  dst="$OUT_DIR/$rel"

  # Check hash
  current_hash=$(md5sum "$src" 2>/dev/null | cut -d' ' -f1 || md5 -q "$src" 2>/dev/null)
  cached_hash=$(grep "^$rel " "$HASH_FILE" 2>/dev/null | awk '{print $2}')

  if [[ "$FORCE" == false && "$current_hash" == "$cached_hash" && -f "$dst" ]]; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  echo "$src → $dst" >> "$TODO_FILE"
  NEED_TRANSLATE=$((NEED_TRANSLATE + 1))
done

if [[ "$UPDATE_HASHES" == true ]]; then
  # Update hashes for all existing translations
  updated=0
  for src in "${SOURCES[@]}"; do
    rel="${src#$JOYA_LIB/}"
    if [[ "$src" == "$JOYA_MY"* ]]; then
      rel="${src#$JOYA_MY/}"
    fi
    dst="$OUT_DIR/$rel"
    if [[ -f "$dst" ]]; then
      current_hash=$(md5sum "$src" 2>/dev/null | cut -d' ' -f1 || md5 -q "$src" 2>/dev/null)
      grep -v "^$rel " "$HASH_FILE" > "$HASH_FILE.tmp" 2>/dev/null || true
      echo "$rel $current_hash" >> "$HASH_FILE.tmp"
      mv "$HASH_FILE.tmp" "$HASH_FILE"
      updated=$((updated + 1))
    fi
  done
  echo "✅ Updated hashes for $updated files"
  exit 0
fi

echo "🌐 JOYA Translation: $LANG_NAME ($LOCALE)"
echo "   Output: $OUT_DIR/"
echo "   Total sources: $TOTAL"
echo "   Need translation: $NEED_TRANSLATE"
echo "   Skipped (unchanged): $SKIPPED"
echo ""

if [[ $NEED_TRANSLATE -eq 0 ]]; then
  echo "✅ All files up to date!"
  rm -f "$TODO_FILE"
  exit 0
fi

if [[ "$LIST_ONLY" == true ]]; then
  echo "Files to translate:"
  cat "$TODO_FILE"
  exit 0
fi

echo "📋 Translation task list: $TODO_FILE"
echo ""
echo "Instructions for your agent:"
echo "  1. Switch to a low-cost model (per PREFERENCES.md translation.model)"
echo "  2. For each file in $TODO_FILE:"
echo "     - Read the source file"
echo "     - Translate to $LANG_NAME"
echo "     - Keep ALL formatting, code blocks, file paths, proper nouns unchanged"
echo "     - Proper nouns to keep: JOYA, OpenClaw, Principal, Manager, Worker, Advisor"
echo "     - Write translated content to the destination path"
echo "  3. After all files are done, run:"
echo "     $0 $LOCALE --update-hashes"
echo ""
echo "Tell your agent:"
echo "  Read $TODO_FILE and translate each file to $LANG_NAME. Use a low-cost model."

# Add .gitignore
if [[ ! -f "$OUT_DIR/.gitignore" ]]; then
  cat > "$OUT_DIR/.gitignore" << 'EOF'
# Auto-generated translations — do not edit manually
.translate-hashes
.translate-todo
EOF
fi
