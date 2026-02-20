#!/usr/bin/env bash
# joy-translate.sh — Translate framework docs to a target language
# Usage: joy-translate.sh <locale> [--force]
# Example: joy-translate.sh zhCN
#          joy-translate.sh jaJP --force
#
# Translates core/, guides/, examples/ and $JOYA_MY/shared/rules/ docs into i18n-<locale>/
# Skips files that haven't changed since last translation (unless --force).
# Requires: OPENAI_API_KEY environment variable.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
JOY_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

LOCALE="${1:-}"
FORCE=false
[[ "${2:-}" == "--force" ]] && FORCE=true

if [[ -z "$LOCALE" ]]; then
  echo "Usage: joy-translate.sh <locale> [--force]"
  echo "  Locales: zhCN, jaJP, koKR, deDE, frFR, esES, etc."
  exit 1
fi

if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  echo "Error: OPENAI_API_KEY not set"
  exit 1
fi

# Language names for the prompt
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
OUT_DIR="$JOY_ROOT/../i18n-$LOCALE"
HASH_FILE="$OUT_DIR/.translate-hashes"

mkdir -p "$OUT_DIR"
touch "$HASH_FILE"

# Resolve JOYA_MY (instance directory, sibling of lib/)
JOYA_MY="${JOYA_MY:-$(cd "$JOY_ROOT/.." && pwd)/my}"

# Collect source files
SOURCE_FILES=()
while IFS= read -r -d '' f; do
  SOURCE_FILES+=("$f")
done < <(find "$JOY_ROOT/core" "$JOY_ROOT/guides" "$JOY_ROOT/examples" "$JOYA_MY/shared/rules" "$JOYA_MY/shared/templates" "$JOY_ROOT/AGENT_INIT.md" "$JOY_ROOT/README.md" \
  -name "*.md" -print0 2>/dev/null | sort -z)

TOTAL=${#SOURCE_FILES[@]}
TRANSLATED=0
SKIPPED=0

echo "🌐 Translating $TOTAL files to $LANG_NAME ($LOCALE)"
echo "   Output: $OUT_DIR/"
echo ""

for src in "${SOURCE_FILES[@]}"; do
  # Relative path from JOY_ROOT
  rel="${src#$JOY_ROOT/}"
  dst="$OUT_DIR/$rel"
  
  # Check hash
  current_hash=$(md5 -q "$src" 2>/dev/null || shasum "$src" | cut -d' ' -f1)
  saved_hash=$(grep "^$rel " "$HASH_FILE" 2>/dev/null | awk '{print $2}' || true)
  
  if [[ "$FORCE" != "true" && "$current_hash" == "$saved_hash" && -f "$dst" ]]; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi
  
  mkdir -p "$(dirname "$dst")"
  
  echo -n "  📄 $rel ... "
  
  # Use python for reliable JSON handling and large file support
  translated=$(python3 -c "
import json, urllib.request, os, sys

content = open('$src').read()
lang = '$LANG_NAME'
body = json.dumps({
    'model': 'gpt-4.1-mini',
    'temperature': 0.1,
    'max_tokens': 16000,
    'messages': [
        {'role': 'system', 'content': f'You are a technical translator. Translate this Markdown to {lang}. Keep ALL formatting, code blocks, file paths, proper nouns (JOYA, OpenClaw, Mattermost, Principal, Manager, Worker, Advisor) unchanged. Translate naturally. Output ONLY the translated document.'},
        {'role': 'user', 'content': content}
    ]
}).encode()
req = urllib.request.Request('https://api.openai.com/v1/chat/completions',
    data=body,
    headers={'Authorization': f\"Bearer {os.environ['OPENAI_API_KEY']}\", 'Content-Type': 'application/json'})
try:
    resp = json.loads(urllib.request.urlopen(req, timeout=180).read())
    print(resp['choices'][0]['message']['content'])
except Exception as e:
    print(f'ERROR: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null)
  
  if [[ -z "$translated" || $? -ne 0 ]]; then
    echo "❌ FAILED"
    continue
  fi
  
  echo "$translated" > "$dst"
  
  # Update hash
  grep -v "^$rel " "$HASH_FILE" > "$HASH_FILE.tmp" 2>/dev/null || true
  echo "$rel $current_hash" >> "$HASH_FILE.tmp"
  mv "$HASH_FILE.tmp" "$HASH_FILE"
  
  TRANSLATED=$((TRANSLATED + 1))
  echo "✅"
done

# Clean up orphaned translations (source deleted but translation remains)
ORPHANED=0
while IFS= read -r -d '' dst; do
  rel="${dst#$OUT_DIR/}"
  src="$JOY_ROOT/$rel"
  if [[ ! -f "$src" ]]; then
    rm "$dst"
    # Remove from hash file
    grep -v "^$rel " "$HASH_FILE" > "$HASH_FILE.tmp" 2>/dev/null || true
    mv "$HASH_FILE.tmp" "$HASH_FILE"
    ORPHANED=$((ORPHANED + 1))
    echo "  🗑️  Removed orphan: i18n-$LOCALE/$rel"
  fi
done < <(find "$OUT_DIR" -name "*.md" ! -name ".gitignore" -print0 2>/dev/null | sort -z)

# Remove empty directories
find "$OUT_DIR" -type d -empty -delete 2>/dev/null || true

echo ""
echo "Done! Translated: $TRANSLATED, Skipped (unchanged): $SKIPPED, Orphans removed: $ORPHANED, Total sources: $TOTAL"
echo "Output: $OUT_DIR/"

# Add .gitignore note
if [[ ! -f "$OUT_DIR/.gitignore" ]]; then
  echo "# Auto-generated translations — do not edit manually" > "$OUT_DIR/.gitignore"
  echo ".translate-hashes" >> "$OUT_DIR/.gitignore"
fi
