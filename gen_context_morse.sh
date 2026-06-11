#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  gen_context_morse.sh  —  Morse Code Telegraph project
#  Dumps full repo + patch scripts into one .txt for AI context
#
#  Usage:   bash ~/gen_context_morse.sh
#  Output:  /sdcard/Download/morse_code_context_YYYYMMDD_HHMM.txt
# ============================================================

REPO_DIR="$HOME/Morse-Code-Telegraph"
PATCH_DIR="$HOME"
OUTPUT_DIR="/sdcard/Download"
TIMESTAMP=$(date +"%Y%m%d_%H%M")
OUTPUT="$OUTPUT_DIR/morse_code_context_${TIMESTAMP}.txt"
MAX_FILE_BYTES=150000
SEP="=================================================="

# ── helpers ──────────────────────────────────────────────────
write_block() {
    local fpath="$1"
    local label="$2"
    local size
    size=$(wc -c < "$fpath" 2>/dev/null || echo 0)
    printf "\n%s\nFILE: %s\n%s\n" "$SEP" "$label" "$SEP" >> "$OUTPUT"
    if [ "$size" -gt "$MAX_FILE_BYTES" ]; then
        printf "[TOO LARGE — %s bytes — first 200 lines only]\n" "$size" >> "$OUTPUT"
        head -200 "$fpath" >> "$OUTPUT"
    else
        cat "$fpath" >> "$OUTPUT"
    fi
}

# ── init ─────────────────────────────────────────────────────
mkdir -p "$OUTPUT_DIR"
: > "$OUTPUT"

printf "================================================================\n" >> "$OUTPUT"
printf "  MORSE CODE TELEGRAPH — PROJECT CONTEXT\n" >> "$OUTPUT"
printf "  Generated : %s\n" "$(date)" >> "$OUTPUT"
printf "  Repo      : %s\n" "$REPO_DIR" >> "$OUTPUT"
printf "================================================================\n\n" >> "$OUTPUT"

# ── 1. directory tree ─────────────────────────────────────────
printf "===== DIRECTORY TREE =====\n" >> "$OUTPUT"
find "$REPO_DIR" \
    -not -path '*/.git*' \
    -not -name '*.png' \
    -not -name '*.jpg' \
    -not -name '*.ico' \
    | sort \
    | while IFS= read -r p; do
        rel="${p#$REPO_DIR}"
        [ -z "$rel" ] && continue
        depth=$(echo "$rel" | tr -cd '/' | wc -c)
        indent=$(printf '%*s' $(( (depth-1)*4 )) '')
        printf "%s├── %s\n" "$indent" "$(basename "$p")" >> "$OUTPUT"
    done
printf "\n" >> "$OUTPUT"

# ── 2. repo file contents ────────────────────────────────────
printf "===== FILE CONTENTS =====\n" >> "$OUTPUT"

# root-level source files
find "$REPO_DIR" -maxdepth 1 -type f \
    \( -name "*.html" -o -name "*.json" -o -name "*.js" \
       -o -name "*.xml"  -o -name "*.md"  -o -name "*.txt" \
       -o -name "*.sh" \) \
    | sort \
    | while IFS= read -r f; do
        write_block "$f" "./${f##$REPO_DIR/}"
    done

# articles/ subfolder
find "$REPO_DIR/articles" -type f -name "*.html" 2>/dev/null \
    | sort \
    | while IFS= read -r f; do
        write_block "$f" "./articles/${f##*/}"
    done

# ── 3. patch scripts ─────────────────────────────────────────
printf "\n===== PATCH SCRIPTS (~/morse_patch_*.py etc) =====\n" >> "$OUTPUT"

find "$PATCH_DIR" -maxdepth 1 -type f \
    \( -name "morse_patch_*.py" \
       -o -name "morse_new_articles.py" \
       -o -name "morse_gen_context.py" \
       -o -name "gen_context_morse.sh" \) \
    | sort \
    | while IFS= read -r f; do
        write_block "$f" "~/${f##*/}"
    done

# ── 4. git info ───────────────────────────────────────────────
printf "\n===== GIT LOG (last 20) =====\n" >> "$OUTPUT"
git -C "$REPO_DIR" log --oneline -20 >> "$OUTPUT" 2>/dev/null \
    || printf "(git log unavailable)\n" >> "$OUTPUT"

printf "\n===== GIT STATUS =====\n" >> "$OUTPUT"
git -C "$REPO_DIR" status --short >> "$OUTPUT" 2>/dev/null \
    || printf "(git status unavailable)\n" >> "$OUTPUT"

# ── summary ───────────────────────────────────────────────────
BYTES=$(wc -c < "$OUTPUT")
LINES=$(wc -l < "$OUTPUT")
FILES=$(grep -c "^FILE:" "$OUTPUT" 2>/dev/null || echo "?")

printf "\n================================================================\n" >> "$OUTPUT"
printf "  END OF CONTEXT  |  %s bytes  |  %s lines  |  %s files\n" \
    "$BYTES" "$LINES" "$FILES" >> "$OUTPUT"
printf "================================================================\n" >> "$OUTPUT"

echo ""
echo "✓  Saved to: $OUTPUT"
echo "   Size : $BYTES bytes"
echo "   Lines: $LINES"
echo "   Files: $FILES"
echo ""
